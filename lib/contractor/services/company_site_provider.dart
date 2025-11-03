import 'package:flutter/material.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ecoteam_app/contractor/services/api_service_login.dart';

class CompanySiteProvider extends ChangeNotifier {
  String? _selectedCompanyId;
  String? _selectedCompanyName;
  List<Map<String, dynamic>> _companies = [];
  final Map<String, List<Site>> _companySites = {};
  
  // API Configuration
  final String _baseUrl = 'http://sitepilot.easy2it.in';
  bool _isLoading = false;

  String? get selectedCompanyId => _selectedCompanyId;
  String? get selectedCompanyName => _selectedCompanyName;
  List<String> get companyNames => _companies.map((c) => c['name'] as String).toList();
  List<Map<String, dynamic>> get companies => _companies;
  bool get isLoading => _isLoading;

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

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> loadCompanies() async {
    try {
      _setLoading(true);
      print('Loading companies from API...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/workspaces'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final workspaces = data['workspaces'] as List;
        
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
        
        // Select first company if available
        if (_companies.isNotEmpty) {
          _selectedCompanyId = _companies.first['id'].toString();
          _selectedCompanyName = _companies.first['name'];
          print('Selected company: $_selectedCompanyName (ID: $_selectedCompanyId)');
          
          // FIX: Check if _selectedCompanyId is not null before calling
          if (_selectedCompanyId != null) {
            await loadSitesForCompany(_selectedCompanyId!);
          } else {
            print('Warning: _selectedCompanyId is null after selection');
          }
        } else {
          // No active companies
          _selectedCompanyId = null;
          _selectedCompanyName = null;
          print('No active companies found');
        }
        
        notifyListeners();
      } else {
        throw Exception('Failed to load workspaces: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading workspaces: $e');
      _showError('Failed to load companies: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSitesForCompany(String companyId) async {
    try {
      _setLoading(true);
      final company = _getCompanyById(companyId);
      print('Loading sites for company: ${company?['name']} (ID: $companyId)');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('Sites API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final projects = data['projects'] as List? ?? [];
        
        // Clear existing sites for this company
        _companySites[companyId] = [];
        
        // Filter projects by workspace ID and add as sites
        int sitesCount = 0;
        for (var project in projects) {
          final projectWorkspaceId = project['workspace']?.toString();
          if (projectWorkspaceId == companyId) {
            try {
              final site = Site.fromJson(project);
              _companySites[companyId]!.add(site);
              sitesCount++;
            } catch (e) {
              print('Error parsing site: $e');
            }
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
      
      // FIX: Safe call to loadSitesForCompany
      if (_selectedCompanyId != null) {
        loadSitesForCompany(_selectedCompanyId!);
      }
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
        'created_by': await ApiService.getCurrentUserId(), // Use dynamic user ID
      };

      print('Site data: $siteData');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(siteData),
      ).timeout(const Duration(seconds: 30));

      print('Add site response: ${response.statusCode}');
      print('Add site body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        
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

        // Add to local storage
        if (!_companySites.containsKey(_selectedCompanyId)) {
          _companySites[_selectedCompanyId!] = [];
        }
        _companySites[_selectedCompanyId!]!.add(newSite);
        notifyListeners();
        
        _showSuccess('Site "${site.name}" added successfully!');
      } else {
        throw Exception('Failed to add site: ${response.statusCode} - ${response.body}');
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
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/projects/$siteId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

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
        'created_by': await ApiService.getCurrentUserId(), // Use dynamic user ID
      };

      print('Updating site ${updatedSite.id} with data: $updateData');

      final response = await http.put(
        Uri.parse('$_baseUrl/api/projects/${updatedSite.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(updateData),
      ).timeout(const Duration(seconds: 30));

      print('Update site response: ${response.statusCode}');
      print('Update site body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
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
          throw Exception('Invalid response format: ${response.body}');
        }
      } else {
        final errorBody = response.body;
        throw Exception('Failed to update site: ${response.statusCode} - $errorBody');
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
  Future<bool> addCompany(String companyName) async {
    try {
      _setLoading(true);
      print('Creating new workspace: $companyName');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/workspaces'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': companyName,
          'created_by': await ApiService.getCurrentUserId(),
        }),
      ).timeout(const Duration(seconds: 30));

      print('Create workspace response: ${response.statusCode}');
      print('Create workspace body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] != null && data['workspace'] != null) {
          final workspace = data['workspace'];
          
          // Add to local lists
          _companies.add({
            'id': workspace['id'].toString(),
            'name': workspace['name'],
            'created_by': workspace['created_by'],
          });
          _companySites[workspace['id'].toString()] = [];
          
          notifyListeners();
          _showSuccess('Company "$companyName" added successfully!');
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

  Future<bool> updateCompany(String oldCompanyId, String newCompanyName) async {
    try {
      _setLoading(true);
      
      final companyIndex = _companies.indexWhere((c) => c['id'] == oldCompanyId);
      if (companyIndex == -1) {
        _showError('Company not found');
        return false;
      }

      final company = _companies[companyIndex];
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/workspaces/$oldCompanyId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': newCompanyName,
          'created_by': company['created_by'],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] != null) {
          // Update local data
          _companies[companyIndex]['name'] = newCompanyName;
          
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
    final deleteResponse = await http.delete(
      Uri.parse('$_baseUrl/api/workspaces/$companyId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));

    print('DELETE Response Status: ${deleteResponse.statusCode}');
    print('DELETE Response Body: ${deleteResponse.body}');

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
       'created_by': await ApiService.getCurrentUserId(),
       'is_disable': 1,
     }
    },
    {
      'name': 'Force Delete with is_disable=1',
      'data': {
        'is_disable': 1,
        'status': 'deleted',
        'name': company['name'],
        'created_by': await ApiService.getCurrentUserId(),
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
        'created_by': await ApiService.getCurrentUserId(),
      }
    },
  ];

  for (var method in forceDeleteMethods) {
    try {
      print('🔄 Trying: ${method['name']}');
      final response = await http.put(
        Uri.parse('$_baseUrl/api/workspaces/$companyId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(method['data']),
      ).timeout(const Duration(seconds: 15));

      print('${method['name']} - Status: ${response.statusCode}');
      print('${method['name']} - Body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if the response indicates actual deletion
        final data = json.decode(response.body);
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
    final postResponse = await http.post(
      Uri.parse('$_baseUrl/api/workspaces/$companyId/delete'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'force': true,
        'permanent': true,
      }),
    ).timeout(const Duration(seconds: 15));

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
    
    final verifyResponse = await http.get(
      Uri.parse('$_baseUrl/api/workspaces'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (verifyResponse.statusCode == 200) {
      final data = json.decode(verifyResponse.body);
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