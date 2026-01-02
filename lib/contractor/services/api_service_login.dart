import 'dart:convert';
import 'package:ecoteam_app/contractor/models/dashboard_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://sitepilot.easy2it.in/api';

  static var sites;

  // Login method
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');


      if (response.body.trim().startsWith('<!DOCTYPE')) {
        return {
          'success': false,
          'error': 'Server returned HTML instead of JSON. Check API endpoint.',
        };
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('DEBUG: Login Response Keys: ${responseData.keys.toList()}');
        
        // Handle nested data structure
        Map<String, dynamic> dataToSave = responseData;
        if (responseData['data'] != null && responseData['data'] is Map) {
           dataToSave = Map<String, dynamic>.from(responseData['data']);
        }

        if (dataToSave['token'] == null) print('DEBUG: Token is NULL in parsed data!');
        
        // --- NEW: Fetch Role Permissions Explicitly ---
        // User requested to REMOVE all permission usage from login API and use ONLY this.
        if (dataToSave['token'] != null) {
           try {
             print('DEBUG: Fetching separate role permissions...');
             final permResponse = await fetchRolePermissions(dataToSave['token']);
             if (permResponse['status'] == 1 && permResponse['data'] != null) {
                final permData = permResponse['data'];
                print('DEBUG: Role permissions fetched successfully.');
                
                // ALWAYS overwrite/set roles from this endpoint
                if (permData['roles'] != null) {
                   dataToSave['roles'] = permData['roles'];
                   print('DEBUG: Set ${permData['roles'].length} roles from /role-permissions');
                }
                
                // Also overwrite permissions if present
                 if (permData['permissions'] != null) {
                   dataToSave['permissions'] = permData['permissions'];
                }
             }
           } catch (e) {
             print('DEBUG: Failed to fetch role permissions: $e');
           }
        }
        // ----------------------------------------------
        
        await saveUserData(dataToSave);
        return {'success': true, 'data': responseData};
      } else {
        final errorMsg =
            responseData['message'] ??
            'Login failed (Status ${response.statusCode})';
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {
        'success': false,
        'error':
            'Network error: ${e.toString().replaceAll('FormatException: ', '')}',
      };
    }
  }


  // Fetch permissions from dedicated endpoint
  static Future<Map<String, dynamic>> fetchRolePermissions(String token) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/role-permissions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print('fetchRolePermissions status: ${response.statusCode}');
        // print('fetchRolePermissions body: ${response.body}');
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
      } catch (e) {
        print('Error in fetchRolePermissions: $e');
      }
      return {'status': 0, 'message': 'Failed'};
  }

  static Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data['token'] != null) {
      await prefs.setString('auth_token', data['token']);
    }
    if (data['user'] != null) {
      Map<String, dynamic> userToSave = Map<String, dynamic>.from(data['user']);
      
      // CRITICAL: We now ONLY save roles/permissions that are explicitly passed in 'data'
      // (which comes from fetchRolePermissions in login flow).
      // We do NOT extract them from the 'user' object if they happen to be there from the login API
      // unless we want to fallback (but user said "remove all those").
      
      // Check if 'roles' is at the root of 'data' (where we put it in login())
      if (data['roles'] != null) {
         userToSave['roles'] = data['roles'];
      }
      
      // Check if 'permissions' is at the root of 'data'
      if (data['permissions'] != null) {
         userToSave['permissions'] = data['permissions'];
      }
      
      await prefs.setString('user_data', jsonEncode(userToSave));
    }
    
    // Save Workspaces from Login Response
    if (data['workspaces'] != null) {
      print('DEBUG: Saving ${data['workspaces'].length} workspaces to storage');
      await prefs.setString('stored_workspaces', jsonEncode(data['workspaces']));
    } else {
       print('DEBUG: No workspaces found in login response to save');
    }
  }

  static Future<bool> refreshUserProfile() async {
    try {
      final result = await getData();
      if (result['success'] == true) {
        var data = result['data'];
        
        // Handle nested data structure like in login method
        if (data['data'] != null && data['data'] is Map) {
           data = Map<String, dynamic>.from(data['data']);
        }
        
        // --- NEW: Fetch permissions on refresh ---
        try {
            final prefs = await SharedPreferences.getInstance();
            var token = prefs.getString('auth_token');
            if (token != null) {
                 final permResponse = await fetchRolePermissions(token);
                 if (permResponse['status'] == 1 && permResponse['data'] != null) {
                    if (permResponse['data']['roles'] != null) {
                        data['roles'] = permResponse['data']['roles'];
                        print('refreshUserProfile: Merged roles from permissions endpoint.');
                    }
                 }
            }
        } catch (e) {
            print('refreshUserProfile: Failed to fetch extra permissions: $e');
        }
        // -----------------------------------------
        
        if (data['user'] != null) {
          // You could add validation here if needed, but logging is removed.
        }
        
        await saveUserData(data);
        return true;
      }
    } catch (e) {
      print('Error refreshing user profile: $e');
    }
    return false;
  }

  // Refresh Token
  static Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Check for status 1 as per screenshot
        if (responseData['status'] == 1 &&
            responseData['data'] != null &&
            responseData['data']['token'] != null) {
          final newToken = responseData['data']['token'];
          await prefs.setString('auth_token', newToken);

          // ALWAYS fetch permissions with the new token
          try {
             print('refreshToken: Fetching permissions with new token...');
             final permResponse = await fetchRolePermissions(newToken);
             
             Map<String, dynamic> dataToSave = {};
             
             // If refresh returned user data, use it as base
             if (responseData['data'] is Map) {
                 dataToSave = Map<String, dynamic>.from(responseData['data']);
             }
             
             // Merge permissions/roles from API
             if (permResponse['status'] == 1 && permResponse['data'] != null) {
                  print('refreshToken: Permissions fetched successfully.');
                  if (permResponse['data']['roles'] != null) {
                      dataToSave['roles'] = permResponse['data']['roles'];
                  }
                  if (permResponse['data']['permissions'] != null) {
                      dataToSave['permissions'] = permResponse['data']['permissions'];
                  }
             }
             
             // Ensure we have something to save. If 'user' is missing from refresh response,
             // we might be in trouble if we overwrite. 
             // BUT, usually refresh returns the user. If not, we should probably fetch it.
             // For now, let's assume if we got roles we are good to update those.
             // If dataToSave has no 'user' key, saveUserData might skip it or fail?
             // saveUserData checks `if (data['user'] != null)`.
             
             // If refresh didn't return user, we should probably keep existing user data but update roles?
             // That's complex. Let's see if we can just trigger a user profile refresh too?
             // Or better: If 'user' is missing, try to fetch it via getData()? 
             
             if (dataToSave['user'] == null) {
                 print('refreshToken: User object missing in refresh response. Fetching profile...');
                 // Reuse refreshUserProfile logic basically, but we are inside refreshToken.
                 // let's just try to get user data
                 final userRes = await getData();
                 if (userRes['success'] == true && userRes['data']['data'] != null) {
                     dataToSave['user'] = userRes['data']['data']['user'];
                 }
             }

             if (dataToSave['user'] != null) {
                  await saveUserData(dataToSave);
             }

          } catch (e) {
             print('refreshToken: Error updating permissions: $e');
          }

          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  // Get all items
  static Future<Map<String, dynamic>> getData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('auth_token');
      
      print('getData: Fetching from $baseUrl/user');

      var response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('getData Response Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        if (await refreshToken()) {
          token = prefs.getString('auth_token');
          response = await http.get(
            Uri.parse('$baseUrl/user'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        if (response.body.startsWith('<!DOCTYPE')) {
           print('getData returned HTML. Endpoint likely incorrect/method not allowed.');
           return {'success': false, 'error': 'Server returned HTML'};
        }
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to fetch data',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Fetch user by ID
  static Future<Map<String, dynamic>> fetchUserById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('auth_token');
      
      final endpoints = [
        '$baseUrl/employee/$id',
        '$baseUrl/user/$id', // Fallback 1
        '$baseUrl/user',     // Fallback 2 (Sanctum me)
      ];

      for (var url in endpoints) {
        print('fetchUserById: Trying $url');
        try {
          var response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 401 && await refreshToken()) {
            token = prefs.getString('auth_token');
            response = await http.get(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            );
          }

          if (response.statusCode == 200 && !response.body.startsWith('<!DOCTYPE')) {
             final data = jsonDecode(response.body);
             
             // Helper to check for permissions deep inside
             bool checkPermissions(dynamic obj) {
               if (obj is Map) {
                 if (obj['permissions'] is List && (obj['permissions'] as List).isNotEmpty) return true;
                 if (obj['roles'] is List) {
                    for (var role in obj['roles']) {
                       if (role is Map && role['permissions'] is List) return true;
                    }
                 }
                 if (obj['role'] is Map && obj['role']['permissions'] is List) return true;
                 
                 // Recursive search in common keys
                 if (obj['data'] != null && checkPermissions(obj['data'])) return true;
                 if (obj['user'] != null && checkPermissions(obj['user'])) return true;
                 if (obj['employee'] != null && checkPermissions(obj['employee'])) return true;
               }
               return false;
             }
             
             if (checkPermissions(data)) {
                print('fetchUserById: Success with DEEP permissions found at $url');
                return {'success': true, 'data': data};
             } else {
                print('fetchUserById: $url returned 200 but NO permissions list found. Trying next...');
             }
          } else {
             print('fetchUserById: $url failed with status ${response.statusCode}');
          }
        } catch (e) {
          print('fetchUserById: Error fetching $url: $e');
        }
      }
      
      return {'success': false, 'error': 'Could not fetch user data with permissions from any endpoint.'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Get all items
  static Future<Map<String, dynamic>> createItem(
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('auth_token');

      var response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 401) {
        if (await refreshToken()) {
          token = prefs.getString('auth_token');
          response = await http.post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(data),
          );
        }
      }

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to create item',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Update item
  static Future<Map<String, dynamic>> updateItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('auth_token');

      var response = await http.put(
        Uri.parse('$baseUrl/login/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 401) {
        if (await refreshToken()) {
          token = prefs.getString('auth_token');
          response = await http.put(
            Uri.parse('$baseUrl/login/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(data),
          );
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to update item',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Delete item
  static Future<Map<String, dynamic>> deleteItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('auth_token');

      var response = await http.delete(
        Uri.parse('$baseUrl/items/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        if (await refreshToken()) {
          token = prefs.getString('auth_token');
          response = await http.delete(
            Uri.parse('$baseUrl/items/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        }
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to delete item',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future deleteSite(String id) async {}

  Future addSite(Site newSite) async {}

  Future<DashboardData?> fetchDashboardData() async {
    return null;
  }
}