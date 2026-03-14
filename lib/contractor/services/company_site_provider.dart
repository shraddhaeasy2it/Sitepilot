import 'package:flutter/material.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/api_ser.dart' as api_ser;
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import 'package:ecoteam_app/contractor/services/chat_service.dart';
import 'package:ecoteam_app/contractor/models/chat_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecoteam_app/contractor/services/api_service_login.dart';

class CompanySiteProvider extends ChangeNotifier {
  String? _selectedCompanyId;
  String? _selectedCompanyName;
  List<Map<String, dynamic>> _companies = [];
  final Map<String, List<Site>> _companySites = {};
  
  // API Configuration
  final String _baseUrl = 'https://app.ecoteamsolar.com';
  bool _isLoading = false;
  final Set<String> _permissions = {};
  int? _currentUserId;

  String? get selectedCompanyId => _selectedCompanyId;
  String? get selectedCompanyName => _selectedCompanyName;
  List<String> get companyNames => _companies.map((c) => c['name'] as String).toList();
  List<Map<String, dynamic>> get companies => _companies;
  bool get isLoading => _isLoading;
  int? get currentUserId => _currentUserId;
  
  // Permissions Loading State
  bool _isPermissionsLoading = false;
  bool get isPermissionsLoading => _isPermissionsLoading;
  Set<String> get permissions => _permissions;

  // Notification Count
  int _unreadNotificationCount = 0;
  int get unreadNotificationCount => _unreadNotificationCount;

  // Chat Notification Count
  int _unreadChatCount = 0;
  int get unreadChatCount => _unreadChatCount;

  // Get sites for the currently selected company only
  List<Site> get sites => _selectedCompanyId != null 
      ? _companySites[_selectedCompanyId!] ?? [] 
      : [];

  // Helper methods
  String _parseStatus(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'completed') return 'completed';
    if (statusLower == 'on hold') return 'on hold';
    return 'ongoing';
  }

  Future<void> _loadPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      _permissions.clear();
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        
        // Extract Current User ID
        if (userData['user'] != null && userData['user']['id'] != null) {
           _currentUserId = int.tryParse(userData['user']['id'].toString());
           print('DEBUG: Current User ID loaded: $_currentUserId');
        } else if (userData['id'] != null) {
           _currentUserId = int.tryParse(userData['id'].toString());
           print('DEBUG: Current User ID loaded (from root): $_currentUserId');
        }
        
        List<dynamic>? roles;
        
        // Check for 'roles' at root
        if (userData['roles'] is List) {
           roles = userData['roles'];
        } 
        // Check for 'roles' inside 'user'
        else if (userData['user'] != null && userData['user']['roles'] is List) {
           roles = userData['user']['roles'];
        }
        // Check for singular 'role'
        else if (userData['role'] != null) {
           if (userData['role'] is List) {
              roles = userData['role'];
           } else if (userData['role'] is Map) {
              roles = [userData['role']];
           }
        }
        
        if (roles != null) {
          print('DEBUG: Found ${roles.length} roles in storage.');
          for (var role in roles) {
            print('DEBUG: Processing role: ${role['name'] ?? 'Unknown'}');
            final permissions = role['permissions'] as List<dynamic>?;
            if (permissions != null) {
              print('DEBUG: Found ${permissions.length} permissions in role.');
              for (var permission in permissions) {
                if (permission['name'] != null) {
                    final permName = permission['name'].toString().trim();
                    _permissions.add(permName);
                    // print('DEBUG: Added Permission: "$permName"'); 
                }
              }
            } else {
               print('DEBUG: No permissions list found in role.');
            }
          }
        } else {
           print('DEBUG: No roles found in stored user data.');
        }
      }
      print('DEBUG: Total Loaded Permissions: ${_permissions.length}');
      // Check specifically for machinery manage
      if (_permissions.contains('machinery manage')) {
         print('DEBUG: "machinery manage" PERMISSION FOUND in list!');
      } else {
         print('DEBUG: "machinery manage" PERMISSION NOT FOUND in list.');
      }
      notifyListeners();

    } catch (e) {
      print('Error loading permissions: $e');
    }
  }

  Future<void> fetchUnreadNotificationCount() async {
    try {
      final response = await api_ser.ApiService().fetchUserNotifications(page: 1);
      if (response != null && response.status == 'success') {
  
        int count = 0;

        for (var n in response.data.data) {
          if (n.readAt == null) {
            count++;
          }
        }
        _unreadNotificationCount = count;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching notification count: $e');
    }
  }

  // Active chat tracking to prevent race conditions
  String? _activeChatId;
  
  void setActiveChatId(String? id) {
    _activeChatId = id;
  }
  
  void setUnreadChatCount(int count) {
    _unreadChatCount = count;
    notifyListeners();
  }

  Future<void> fetchUnreadChatCount() async {
    try {
      final result = await ChatService().getContacts(
        workspaceId: _selectedCompanyId,
      );
      
      int totalUnread = 0;
      
      if (result['chats'] != null) {
        for (var chat in result['chats']) {
           if (chat is ChatContact) {
             // If this is the active chat, assume 0 unread locally
             // regardless of what API says (as API might be stale)
             if (_activeChatId != null && chat.userId == _activeChatId) {
                print("DEBUG: Ignoring unread count for active chat: ${_activeChatId}");
                continue;
             }
             totalUnread += chat.unreadCount ?? 0;
           }
        }
      }
      
      _unreadChatCount = totalUnread;
      notifyListeners();
    } catch (e) {
      print('Error fetching chat count: $e');
    }
  }

  void reduceUnreadChatCount(int amount) {
    if (amount > 0) {
      _unreadChatCount = (_unreadChatCount - amount).clamp(0, 999);
      notifyListeners();
    }
  }

  Future<void> refreshPermissions() async {
    // print('Refreshing permissions from API...');
    _isPermissionsLoading = true;
    notifyListeners();
    
    try {
      // IMPROVED: Do NOT call refreshToken() here. It rotates the token and invalidates parallel requests.
      // Instead, verify with direct permission fetch using the CURRENT token.
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      bool permissionsUpdated = false;

      if (token != null) {
          // Attempt direct fetch first (lightweight)
          try {
            final permResponse = await ApiService.fetchRolePermissions(token);
            
            if (permResponse['status'] == 1 && permResponse['data'] != null) {
               final userDataStr = prefs.getString('user_data');
               if (userDataStr != null) {
                   Map<String, dynamic> userData = json.decode(userDataStr);
                   
                   // Merge roles
                   if (permResponse['data']['roles'] != null) {
                      userData['roles'] = permResponse['data']['roles'];
                      if (userData['user'] != null && userData['user'] is Map) {
                         userData['user']['roles'] = permResponse['data']['roles'];
                      }
                      
                      await prefs.setString('user_data', json.encode(userData));
                      await _loadPermissions();
                      permissionsUpdated = true;
                      // print('Permissions refreshed via direct fetch.');
                   }
               }
            }
          } catch (e) {
            print('refreshPermissions: Direct fetch warning: $e');
          }
      }
      
      // If direct fetch didn't happen or failed to update, try refreshUserProfile (which uses DioService safe retry)
      if (!permissionsUpdated) {
          // print('Direct fetch skipped/failed. Trying refreshUserProfile...');
          bool success = await ApiService.refreshUserProfile();
          if (success) {
            await _loadPermissions();
            // print('Permissions refreshed via profile.');
          }
      }

    } catch (e) {
      print('Error refreshing permissions: $e');
    } finally {
       _isPermissionsLoading = false;
       notifyListeners();
    }
  }

  bool hasPermission(String permissionName) {
    return _permissions.contains(permissionName);
  }

  Future<bool> _hasPermission(String permissionName) async {
    if (_permissions.isEmpty) {
      await _loadPermissions();
    }
    return _permissions.contains(permissionName);
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // _getAuthHeaders REMOVED - Handled by DioService interceptor

  Future<void> loadCompanies() async {
    try {
      await _loadPermissions();
      _setLoading(true);
      print('Loading companies from API...');
      
      final prefs = await SharedPreferences.getInstance();
      
      try {
        final response = await DioService.instance.dio.get('/workspaces');
        print('Workspaces API Response Status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = response.data;
          final workspaces = data['workspaces'] as List;
          print('Found ${workspaces.length} workspaces from API.');
          
          // Clear existing data
          _companies.clear();
          _companySites.clear();
          
          // Add ONLY active workspaces as companies
          int activeCount = 0;
          int inactiveCount = 0;
          
          for (var workspace in workspaces) {
            if (workspace['status'] == 'active') { 
              final workspaceName = workspace['name'];
              final workspaceId = workspace['id'].toString();
              
              _companies.add({
                'id': workspaceId,
                'name': workspaceName,
                'status': workspace['status'],
                'contact_person': workspace['contact_person'],
                'phone': workspace['phone'],
                'email': workspace['email'],
                'address': workspace['address'],
                'city': workspace['city'],
                'state': workspace['state'],
                'pincode': workspace['pincode'],
                'country': workspace['country'],
                'website': workspace['website'],
                'cin_no': workspace['cin_no'],
                'terms_and_conditions': workspace['terms_and_conditions'],
                'logo': workspace['logo'],
                'gst_number': workspace['gst_number'],
                'pan_number': workspace['pan_number'],
                'bank_name': workspace['bank_name'],
                'account_number': workspace['account_number'],
                'ifsc_code': workspace['ifsc_code'],
                'created_by': workspace['created_by'],
              });
              
              // Initialize sites map for this company
              _companySites[workspaceId] = [];
              activeCount++;
            } else {
              inactiveCount++;
            }
          }
          
          print('Loaded $activeCount active companies and $inactiveCount inactive companies');
          print('Active companies: ${_companies.map((c) => c['name'])}');
          
          // Save workspaces to local storage as fallback/cache
          await prefs.setString('stored_workspaces', json.encode(workspaces));
          
          // Select first company if available
          if (_companies.isNotEmpty) {
            // Keep the selected company if it still exists
            if (_selectedCompanyId != null && _companySites.containsKey(_selectedCompanyId)) {
              final company = _getCompanyById(_selectedCompanyId!);
              _selectedCompanyName = company?['name'];
            } else {
              _selectedCompanyId = _companies.first['id'].toString();
              _selectedCompanyName = _companies.first['name'];
            }
            print('Selected company: $_selectedCompanyName (ID: $_selectedCompanyId)');
          } else {
            _selectedCompanyId = null;
            _selectedCompanyName = null;
            print('No active companies found');
          }

          notifyListeners();

          // Fetch sites for the initially selected company via API
          if (_selectedCompanyId != null) {
            await loadSitesForCompany(_selectedCompanyId!);
          }
          return;
        }
      } catch (apiError) {
        print('Error fetching workspaces from API: $apiError');
        print('Falling back to local storage...');
      }

      // FALLBACK TO LOCAL STORAGE
      final storedWorkspaces = prefs.getString('stored_workspaces');

      if (storedWorkspaces != null) {
        final workspaces = json.decode(storedWorkspaces) as List;
        print('Found ${workspaces.length} workspaces in storage.');
        
        // Clear existing data
        _companies.clear();
        _companySites.clear();
        
        // Add ONLY active workspaces as companies
        int activeCount = 0;
        int inactiveCount = 0;
        
        for (var workspace in workspaces) {
          if (workspace['status'] == 'active') { 
            final workspaceName = workspace['name'];
            final workspaceId = workspace['id'].toString();
            
            _companies.add({
              'id': workspaceId,
              'name': workspaceName,
              'status': workspace['status'],
              'contact_person': workspace['contact_person'],
              'phone': workspace['phone'],
              'email': workspace['email'],
              'address': workspace['address'],
              'city': workspace['city'],
              'state': workspace['state'],
              'pincode': workspace['pincode'],
              'country': workspace['country'],
              'website': workspace['website'],
              'cin_no': workspace['cin_no'],
              'terms_and_conditions': workspace['terms_and_conditions'],
              'logo': workspace['logo'],
              'gst_number': workspace['gst_number'],
              'pan_number': workspace['pan_number'],
              'bank_name': workspace['bank_name'],
              'account_number': workspace['account_number'],
              'ifsc_code': workspace['ifsc_code'],
              'created_by': workspace['created_by'],
            });
            
            // Initialize sites map for this company
            _companySites[workspaceId] = [];
            activeCount++;
          } else {
            inactiveCount++;
          }
        }
        
        print('Loaded $activeCount active companies and $inactiveCount inactive companies from fallback');
        
        // Select first company if available
        if (_companies.isNotEmpty) {
          if (_selectedCompanyId == null || !_companySites.containsKey(_selectedCompanyId)) {
            _selectedCompanyId = _companies.first['id'].toString();
            _selectedCompanyName = _companies.first['name'];
          }
        } else {
          _selectedCompanyId = null;
          _selectedCompanyName = null;
        }

        notifyListeners();

        // Fetch sites for the initially selected company via API
        if (_selectedCompanyId != null) {
          await loadSitesForCompany(_selectedCompanyId!);
        }

      } else {
        print('No stored workspaces found. Please login again.');
        _companies.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading workspaces: $e');
      _showError('Failed to load companies: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSitesForCompany(String companyId) async {
    try {
      _setLoading(true);
      final company = _getCompanyById(companyId);
      print('Loading sites for company: ${company?['name']} (ID: $companyId)');
      
      final response = await DioService.instance.dio.get(
        '/projects',
        queryParameters: {
          'site_id': 0,
          'workspace_id': companyId,
        },
      );

      print('Sites API Response Status: ${response.statusCode}');
      print('🔴 FETCH PROJECTS RESPONSE: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final projects = data['projects'] as List? ?? [];
        
        // Clear existing sites for this company
        _companySites[companyId] = [];
        
        // Filter projects: Since API already filters, we trust the response.
        int sitesCount = 0;
        if (projects.isNotEmpty) {
           print('🔴 FIRST PROJECT RAW JSON: ${projects.first}');
           if (projects.first.containsKey('address')) {
              print('🔴 Address field found: "${projects.first['address']}"');
           } else {
              print('🔴 Address field MISSING in response');
           }
        }
        for (var project in projects) {
          try {
            final site = Site.fromJson(project);
            _companySites[companyId]!.add(site);
            sitesCount++;
          } catch (e) {
             print('🔴 Error parsing site ${project['id']}: $e');
             // Print stack trace if needed or just the project data
             print('Problematic Data: $project');
          }
        }
        
        print('Loaded $sitesCount sites for company ID: $companyId');
        notifyListeners();
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading sites for company $companyId: $e');
      _showError('Failed to load sites: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void selectCompany(String companyId) {
    final company = _getCompanyById(companyId);
    if (company != null) {
      _selectedCompanyId = companyId;
      _selectedCompanyName = company['name'];
      print('Company selected: $_selectedCompanyName (ID: $_selectedCompanyId)');

      // Fetch sites for this workspace from API
      loadSitesForCompany(companyId);
      notifyListeners();
    } else {
      print('Company not found with ID: $companyId');
    }
  }


  Future<void> addSite(Site site) async {
    if (_selectedCompanyId == null) {
      _showError('No company selected');
      return;
    }

    try {
      _setLoading(true);
      
      print('Adding site for workspace: $_selectedCompanyId');

      // Prepare site data with required fields
      final siteData = {
        'name': site.name,
        'description': site.description ?? site.name,
        'budget': site.budget.toInt(),
        'workspace': int.parse(_selectedCompanyId!),
        'start_date': site.startDate,
        'end_date': site.endDate,
        'status': site.status.toLowerCase(),
        'created_by': _currentUserId ?? 10,
        if (site.latitude != null) 'latitude': site.latitude,
        if (site.longitude != null) 'longitude': site.longitude,
        if (site.address != null) 'address': site.address,
      };

      print('Site data: $siteData');

      final response = await DioService.instance.dio.post(
        '/projects',
        data: siteData,
      );

      print('Add site response: ${response.statusCode}');
      print('Add site response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        
        // Handle different response formats
        dynamic projectData;
        if (data['project'] != null) {
          projectData = data['project'];
        } else if (data['data'] != null) {
          projectData = data['data'];
        } else {
          projectData = data; // Assume the response is the project itself
        }

        final newSite = Site(
          id: projectData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: projectData['name'] ?? site.name,
          companyId: _selectedCompanyId!,
          status: _parseStatus(projectData['status']?.toString() ?? site.status),
          startDate: projectData['start_date']?.toString() ?? site.startDate,
          endDate: projectData['end_date']?.toString() ?? site.endDate,
          budget: _parseDouble(projectData['budget']) ?? site.budget,
          progress: _parseDouble(projectData['progress']) ?? site.progress,
          description: projectData['description']?.toString() ?? site.description ?? site.name,
        );

        // Refresh the list from the server to ensure we have the latest data including IDs and any server-side processing
        await loadSitesForCompany(_selectedCompanyId!);
        
        _showSuccess('Site "${site.name}" added successfully!');
      } else {
        throw Exception('Failed to add site: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding site: $e');
      _showError('Failed to add site: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSite(String siteId) async {
    try {
      _setLoading(true);
      
      final response = await DioService.instance.dio.delete('/projects/$siteId');

      print('Delete site response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Find which company the site belongs to and remove from local storage
        String? companyId;

        for (var entry in _companySites.entries) {
          final initialLength = entry.value.length;
          entry.value.removeWhere((site) => site.id == siteId);

          if (entry.value.length != initialLength) {
            companyId = entry.key;
            break;
          }
        }

        if (companyId != null) {
          notifyListeners();
          _showSuccess('Site deleted successfully!');
        }
      } else {
        throw Exception('Failed to delete site: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting site: $e');
      _showError('Failed to delete site: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSite(Site updatedSite) async {
    try {
      _setLoading(true);
      
      // Create update data according to your API structure
      final updateData = {
        'name': updatedSite.name,
        'description': updatedSite.description ?? updatedSite.name,
        'budget': updatedSite.budget.toInt(), // Convert to int if API expects integer
        'workspace': int.parse(updatedSite.companyId), // Convert to int
        'start_date': updatedSite.startDate,
        'end_date': updatedSite.endDate,
        'status': updatedSite.status.toLowerCase(), // Ensure status is in correct format
        'created_by': _currentUserId ?? 10, // Use dynamic user ID
        if (updatedSite.latitude != null) 'latitude': updatedSite.latitude,
        if (updatedSite.longitude != null) 'longitude': updatedSite.longitude,
        if (updatedSite.address != null) 'address': updatedSite.address,
      };

      print('Updating site ${updatedSite.id} with data: $updateData');

      final response = await DioService.instance.dio.put(
        '/projects/${updatedSite.id}',
        data: updateData,
      );

      print('Update site response: ${response.statusCode}');
      print('Update site body: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['success'] != null) {
          // Find which company the site belongs to and update local storage
          String? companyId;
          int siteIndex = -1;

          for (var entry in _companySites.entries) {
            final index = entry.value.indexWhere((s) => s.id == updatedSite.id);

            if (index != -1) {
              companyId = entry.key;
              siteIndex = index;
              break;
            }
          }

          if (companyId != null && siteIndex != -1) {
            _companySites[companyId]![siteIndex] = updatedSite;
            notifyListeners();
            _showSuccess('Site "${updatedSite.name}" updated successfully!');
          }
        } else {
          throw Exception('Invalid response format: ${response.statusCode}');
        }
      } else {
        throw Exception('Failed to update site: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating site: $e');
      _showError('Failed to update site: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Company Management Methods
  Future<bool> addCompany({
    required String name,
    String status = 'active',
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? country,
    String? gstNumber,
    String? panNumber,
    String? cinNo,
    String? termsAndConditions,
    String? logoPath,
  }) async {
    try {
      // Check permission
      final hasPermission = await _hasPermission('workspace create');
      if (!hasPermission) {
        _showError('You do not have permission to create a workspace.');
        return false;
      }

      _setLoading(true);
      print('Creating new workspace: $name');

      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      String? actualUserId;
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (userData['user'] != null && userData['user']['id'] != null) {
          actualUserId = userData['user']['id'].toString();
        } else if (userData['id'] != null) {
          actualUserId = userData['id'].toString();
        }
      }

      // Build form data
      final formDataMap = <String, dynamic>{
        'name': name,
        'status': status,
        'created_by': actualUserId ?? _currentUserId?.toString() ?? '1',
      };
      if (contactPerson != null && contactPerson.isNotEmpty) formDataMap['contact_person'] = contactPerson;
      if (phone != null && phone.isNotEmpty) formDataMap['phone'] = phone;
      if (email != null && email.isNotEmpty) formDataMap['email'] = email;
      if (address != null && address.isNotEmpty) formDataMap['address'] = address;
      if (city != null && city.isNotEmpty) formDataMap['city'] = city;
      if (state != null && state.isNotEmpty) formDataMap['state'] = state;
      if (pincode != null && pincode.isNotEmpty) formDataMap['pincode'] = pincode;
      if (country != null && country.isNotEmpty) formDataMap['country'] = country;
      if (gstNumber != null && gstNumber.isNotEmpty) formDataMap['gst_number'] = gstNumber;
      if (panNumber != null && panNumber.isNotEmpty) formDataMap['pan_number'] = panNumber;
      if (cinNo != null && cinNo.isNotEmpty) formDataMap['cin_no'] = cinNo;
      if (termsAndConditions != null && termsAndConditions.isNotEmpty) formDataMap['terms_and_conditions'] = termsAndConditions;
      if (logoPath != null) {
        formDataMap['logo'] = await MultipartFile.fromFile(logoPath, filename: logoPath.split('/').last);
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await DioService.instance.dio.post(
        '/workspaces',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      print('Create workspace response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;

        if (data['success'] != null && data['workspace'] != null) {
          final workspace = data['workspace'];

          // Add to local lists
          _companies.add({
            'id': workspace['id'].toString(),
            'name': workspace['name'],
            'status': workspace['status'],
            'contact_person': workspace['contact_person'],
            'phone': workspace['phone'],
            'email': workspace['email'],
            'address': workspace['address'],
            'city': workspace['city'],
            'state': workspace['state'],
            'pincode': workspace['pincode'],
            'country': workspace['country'],
            'gst_number': workspace['gst_number'],
            'pan_number': workspace['pan_number'],
            'cin_no': workspace['cin_no'],
            'terms_and_conditions': workspace['terms_and_conditions'],
            'logo': workspace['logo'],
            'created_by': workspace['created_by'],
          });
          _companySites[workspace['id'].toString()] = [];

          notifyListeners();
          _showSuccess('Company "$name" added successfully!');
          return true;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to create workspace: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating workspace: $e');
      _showError('Failed to add company: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCompany(
    String oldCompanyId,
    String newCompanyName, {
    String status = 'active',
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? country,
    String? gstNumber,
    String? panNumber,
    String? cinNo,
    String? termsAndConditions,
    String? logoPath,
  }) async {
    try {
      // Check permission
      final hasPermission = await _hasPermission('workspace edit');
      if (!hasPermission) {
        _showError('You do not have permission to edit this workspace.');
        return false;
      }

      _setLoading(true);

      final companyIndex = _companies.indexWhere((c) => c['id'] == oldCompanyId);
      if (companyIndex == -1) {
        _showError('Company not found');
        return false;
      }

      final company = _companies[companyIndex];

      // Build form data
      final formDataMap = <String, dynamic>{
        'name': newCompanyName,
        'status': status,
        'created_by': company['created_by'],
      };
      if (contactPerson != null && contactPerson.isNotEmpty) formDataMap['contact_person'] = contactPerson;
      if (phone != null && phone.isNotEmpty) formDataMap['phone'] = phone;
      if (email != null && email.isNotEmpty) formDataMap['email'] = email;
      if (address != null && address.isNotEmpty) formDataMap['address'] = address;
      if (city != null && city.isNotEmpty) formDataMap['city'] = city;
      if (state != null && state.isNotEmpty) formDataMap['state'] = state;
      if (pincode != null && pincode.isNotEmpty) formDataMap['pincode'] = pincode;
      if (country != null && country.isNotEmpty) formDataMap['country'] = country;
      if (gstNumber != null && gstNumber.isNotEmpty) formDataMap['gst_number'] = gstNumber;
      if (panNumber != null && panNumber.isNotEmpty) formDataMap['pan_number'] = panNumber;
      if (cinNo != null && cinNo.isNotEmpty) formDataMap['cin_no'] = cinNo;
      if (termsAndConditions != null && termsAndConditions.isNotEmpty) formDataMap['terms_and_conditions'] = termsAndConditions;
      if (logoPath != null) {
        formDataMap['logo'] = await MultipartFile.fromFile(logoPath, filename: logoPath.split('/').last);
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await DioService.instance.dio.post(
        '/workspaces/$oldCompanyId',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        queryParameters: {'_method': 'PUT'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data['success'] != null) {
          // Update local data
          _companies[companyIndex]['name'] = newCompanyName;
          _companies[companyIndex]['status'] = status;
          if (contactPerson != null) _companies[companyIndex]['contact_person'] = contactPerson;
          if (phone != null) _companies[companyIndex]['phone'] = phone;
          if (email != null) _companies[companyIndex]['email'] = email;
          if (address != null) _companies[companyIndex]['address'] = address;
          if (city != null) _companies[companyIndex]['city'] = city;
          if (state != null) _companies[companyIndex]['state'] = state;
          if (pincode != null) _companies[companyIndex]['pincode'] = pincode;
          if (country != null) _companies[companyIndex]['country'] = country;
          if (gstNumber != null) _companies[companyIndex]['gst_number'] = gstNumber;
          if (panNumber != null) _companies[companyIndex]['pan_number'] = panNumber;
          if (cinNo != null) _companies[companyIndex]['cin_no'] = cinNo;
          if (termsAndConditions != null) _companies[companyIndex]['terms_and_conditions'] = termsAndConditions;

          // Update selected company name if it was the one being updated
          if (_selectedCompanyId == oldCompanyId) {
            _selectedCompanyName = newCompanyName;
          }

          notifyListeners();
          _showSuccess('Company updated to "$newCompanyName" successfully!');
          return true;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to update workspace: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating company: $e');
      _showError('Failed to update company: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<Site> get allSites {
    List<Site> allSites = [];
    _companySites.forEach((companyId, siteList) {
      allSites.addAll(siteList);
    });
    return allSites;
  }

  Future<bool> deleteCompany(String companyId) async {
  try {
    // Check permission
    final hasPermission = await _hasPermission('workspace delete');
    if (!hasPermission) {
      _showError('You do not have permission to delete this workspace.');
      return false;
    }

    _setLoading(true);
    
    // First, check if the company has any sites/projects
    final sitesCount = getSitesCount(companyId);
    if (sitesCount > 0) {
      _showError('Cannot delete company with $sitesCount active sites. Please delete all sites first.');
      return false;
    }

    final company = _getCompanyById(companyId);
    if (company == null) {
      _showError('Company not found');
      return false;
    }

    print('🔴 PERMANENT DELETE ATTEMPT: ${company['name']} (ID: $companyId)');

    // DON'T DELETE LOCALLY UNTIL API CONFIRMS PERMANENT DELETION
    final success = await _deleteFromApiPermanently(companyId, company);
    
    if (success) {
      // Only delete locally after API confirms permanent deletion
      _deleteCompanyLocally(companyId);
      _showSuccess('Company "${company['name']}" permanently deleted from server!');
      
      // Force reload to verify deletion
      await loadCompanies();
      return true;
    } else {
      _showError('Failed to delete company from server. Company still exists.');
      return false;
    }

  } catch (e) {
    print('Error deleting company: $e');
    _showError('Failed to delete company: $e');
    return false;
  } finally {
    _setLoading(false);
  }
}

Future<bool> _deleteFromApiPermanently(String companyId, Map<String, dynamic> company) async {
  // Method 1: Try DELETE method first (for permanent deletion)
  try {
    print('🔄 Attempting DELETE method for permanent deletion...');
    final deleteResponse = await DioService.instance.dio.delete(
      '/workspaces/$companyId',
    );

    print('DELETE Response Status: ${deleteResponse.statusCode}');
    print('DELETE Response Body: ${deleteResponse.data}');

    if (deleteResponse.statusCode == 200 || deleteResponse.statusCode == 204) {
      print('✅ DELETE method successful - Company permanently deleted');
      return true;
    } else {
      print('❌ DELETE method failed with status: ${deleteResponse.statusCode}');
    }
  } catch (e) {
    print('DELETE method error: $e');
  }

  // Method 2: If DELETE doesn't work, try different PUT approaches
  return await _tryForceDeleteMethods(companyId, company);
}

Future<bool> _tryForceDeleteMethods(String companyId, Map<String, dynamic> company) async {
  final forceDeleteMethods = [
    // Try different data structures that might force permanent deletion
    {
      'name': 'Force Delete with status=deleted',
      'data': {
        'status': 'deleted',
        'name': company['name'],
        'created_by': company['created_by'],
        'is_disable': 1,
      }
    },
    {
      'name': 'Force Delete with is_disable=1',
      'data': {
        'is_disable': 1,
        'status': 'deleted',
        'name': company['name'],
        'created_by': company['created_by'],
      }
    },
    {
      'name': 'Force Delete with empty data',
      'data': {
        '_method': 'DELETE', // Some APIs require this for override
        'name': company['name'],
      }
    },
    {
      'name': 'Force Delete with force flag',
      'data': {
        'force': true,
        'status': 'deleted',
        'name': company['name'],
        'created_by': company['created_by'],
      }
    },
  ];

  for (var method in forceDeleteMethods) {
    try {
      print('🔄 Trying: ${method['name']}');
      final response = await DioService.instance.dio.put(
        '/workspaces/$companyId',
        data: method['data'],
      );

      print('${method['name']} - Status: ${response.statusCode}');
      print('${method['name']} - Body: ${response.data}');

      if (response.statusCode == 200) {
        // Check if the response indicates actual deletion
        final data = response.data;
        if (data['workspace'] != null && 
            (data['workspace']['status'] == 'deleted' || 
             data['workspace']['is_disable'] == 1)) {
          print('✅ ${method['name']} successful - Company marked for deletion');
          return true;
        } else {
          print('⚠️ ${method['name']} returned 200 but may not have deleted');
        }
      }
    } catch (e) {
      print('${method['name']} failed: $e');
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Method 3: Try POST to delete endpoint if it exists
  try {
    print('🔄 Trying POST to delete endpoint...');
    final postResponse = await DioService.instance.dio.post(
      '/workspaces/$companyId/delete',
      data: {
        'force': true,
        'permanent': true,
      },
    );

    if (postResponse.statusCode == 200 || postResponse.statusCode == 204) {
      print('✅ POST delete method successful');
      return true;
    }
  } catch (e) {
    print('POST delete method failed: $e');
  }

  // Method 4: Final verification - check if company still exists in API
  return await _verifyPermanentDeletion(companyId, company['name']);
}

Future<bool> _verifyPermanentDeletion(String companyId, String companyName) async {
  try {
    print('🔄 Verifying permanent deletion...');
    
    // Wait a moment for API to process
    await Future.delayed(const Duration(seconds: 2));
    
    final verifyResponse = await DioService.instance.dio.get('/workspaces');

    if (verifyResponse.statusCode == 200) {
      final data = verifyResponse.data;
      final workspaces = data['workspaces'] as List;
      
      // Check if the company still exists in the API response
      final companyStillExists = workspaces.any((workspace) => 
          workspace['id'].toString() == companyId);
      
      if (!companyStillExists) {
        print('✅ VERIFIED: Company "$companyName" permanently deleted from API');
        return true;
      } else {
        print('❌ VERIFICATION FAILED: Company "$companyName" still exists in API');
        
        // Check if it's at least marked as inactive
        final companyData = workspaces.firstWhere(
          (workspace) => workspace['id'].toString() == companyId,
          orElse: () => null,
        );
        
        if (companyData != null && companyData['status'] == 'inactive') {
          print('⚠️ Company marked as inactive but not permanently deleted');
        }
        
        return false;
      }
    }
  } catch (e) {
    print('Verification error: $e');
  }
  
  return false;
}

void _deleteCompanyLocally(String companyId) {
  final company = _getCompanyById(companyId);
  final companyName = company?['name'] ?? 'Unknown Company';
  
  print('🗑️ Removing company locally: $companyName (ID: $companyId)');
  
  _companies.removeWhere((company) => company['id'] == companyId);
  _companySites.remove(companyId);
  
  // If the deleted company was selected, clear selection or select another
  if (_selectedCompanyId == companyId) {
    if (_companies.isNotEmpty) {
      _selectedCompanyId = _companies.first['id'].toString();
      _selectedCompanyName = _companies.first['name'];
      print('Selected new company: $_selectedCompanyName');
    } else {
      _selectedCompanyId = null;
      _selectedCompanyName = null;
      print('No companies left, selection cleared');
    }
  }
  
  print('Local deletion complete. Remaining companies: ${_companies.length}');
  notifyListeners();
}

  Future<void> refreshCompanies() async {
    try {
      _setLoading(true);
      print('Manual refresh triggered');
      
      // Clear current data
      _companies.clear();
      _companySites.clear();
      _selectedCompanyId = null;
      _selectedCompanyName = null;
      
      notifyListeners();
      
      // Reload from API
      await loadCompanies();
      
      _showSuccess('Companies refreshed successfully');
    } catch (e) {
      print('Error refreshing companies: $e');
      _showError('Failed to refresh companies: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  Map<String, dynamic>? _getCompanyById(String id) {
    try {
      return _companies.firstWhere((company) => company['id'] == id);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? getCompanyByName(String name) {
    try {
      return _companies.firstWhere((company) => company['name'] == name);
    } catch (e) {
      return null;
    }
  }

  String? getCompanyIdByName(String name) {
    final company = getCompanyByName(name);
    return company?['id']?.toString();
  }

  String? getCompanyNameById(String id) {
    final company = _getCompanyById(id);
    return company?['name'];
  }

  bool companyExists(String companyName) {
    return _companies.any((company) => company['name'] == companyName);
  }

  int getSitesCount(String companyId) {
    return _companySites[companyId]?.length ?? 0;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _showError(String message) {
    // This would typically show a SnackBar or dialog
    print('Error: $message');
  }

  void _showSuccess(String message) {
    // This would typically show a SnackBar
    print('Success: $message');
  }
}