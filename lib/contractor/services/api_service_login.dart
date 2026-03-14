import 'dart:convert';
import 'dart:io';

import 'package:ecoteam_app/contractor/models/dashboard_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';

import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ApiService {
  static const String baseUrl = 'https://app.ecoteamsolar.com/api';

  static var sites;

  // Login method
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      // ---------------- DEVICE & APP INFO ----------------
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        print('Error fetching FCM token: $e');
      }

      String deviceName = 'Unknown';
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceName = androidInfo.model;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceName = iosInfo.utsname.machine;
        }
      } catch (e) {
        print('Error fetching device info: $e');
        deviceName = 'Unknown Device';
      }

      String appVersion = '1.0.0';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;
      } catch (e) {
        print('Error fetching package info: $e');
      }
      // ---------------------------------------------------

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => true,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      final response = await dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
          'fcm_token': fcmToken,
          'device_name': deviceName,
          'app_version': appVersion,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.data is String &&
          response.data.toString().trim().startsWith('<!DOCTYPE')) {
        return {
          'success': false,
          'error': 'Server returned HTML instead of JSON. Check API endpoint.',
        };
      }

      final responseData = response.data; // Dio parses JSON automatically

      if (response.statusCode == 200) {
        if (responseData is! Map) {
          print('DEBUG: Expected Map response, got ${responseData.runtimeType}');
          return {
            'success': false,
            'error': 'Unexpected response format from server.',
          };
        }

        print(
            'DEBUG: Login Response Keys: ${responseData.keys.toList()}');

        // Handle nested data structure
        Map<String, dynamic> dataToSave = Map<String, dynamic>.from(responseData);

        if (responseData['data'] != null && responseData['data'] is Map) {
          dataToSave = Map<String, dynamic>.from(responseData['data']);
        }

        if (dataToSave['token'] == null)
          print('DEBUG: Token is NULL in parsed data!');

        // --- NEW: Fetch Role Permissions Explicitly ---

        if (dataToSave['token'] != null) {
          try {
            print('DEBUG: Fetching separate role permissions...');
            final permResponse =
                await fetchRolePermissions(dataToSave['token']);
            if (permResponse['status'] == 1 &&
                permResponse['data'] != null &&
                permResponse['data'] is Map) {
              final permData = permResponse['data'] as Map<String, dynamic>;
              print('DEBUG: Role permissions fetched successfully.');

              // ALWAYS overwrite/set roles from this endpoint
              if (permData['roles'] != null) {
                dataToSave['roles'] = permData['roles'];
                if (permData['roles'] is List) {
                  print(
                      'DEBUG: Set ${(permData['roles'] as List).length} roles from /role-permissions');
                }
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
        
        if (fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', fcmToken);
          print('DEBUG: FCM token saved locally.');
        }
        
        await saveUserData(dataToSave);
        
        // Start the proactive token refresh timer
        if (dataToSave['token'] != null) {
          DioService.instance.scheduleTokenRefresh(dataToSave['token']);
        }

        return {'success': true, 'data': responseData};
      } else {
        String errorMsg = 'Login failed (Status ${response.statusCode})';
        if (responseData is Map && responseData['message'] != null) {
          errorMsg = responseData['message'];
        } else if (responseData is String) {
          errorMsg = responseData;
        }
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      print('Login Exception details: $e');
       if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout || 
            e.type == DioExceptionType.sendTimeout) {
           return {
            'success': false,
            'error': 'Connection timed out. Please check your internet.',
          };
        } else if (e.type == DioExceptionType.connectionError) {
           return {
            'success': false,
            'error': 'Connection error. Please check your internet.',
          };
        }
      }
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
      };
    }
  }


  // Change Password method
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final dio = Dio();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      print('Changing password...');

      final response = await dio.post(
        '$baseUrl/change-password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => true,
        ),
      );

      print('Change Password Status: ${response.statusCode}');
      print('Change Password Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['status'] == 1) {
          return {'success': true, 'message': data['message'] ?? 'Password updated successfully'};
        } else {
           return {'success': false, 'message': data['message'] ?? 'Failed to update password'};
        }
      } else {
         final data = response.data;
         String msg = 'Failed to update password';
         if (data is Map && data['message'] != null) {
           msg = data['message'];
         }
         return {'success': false, 'message': msg};
      }
    } catch (e) {
      print('Change Password Exception: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Forgot Password method
  // Forgot Password method
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final dio = Dio();
      
      // Try to get token just in case the API requires it (even if it shouldn't for this flow)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final Map<String, dynamic> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest', // Helps identifying AJAX requests
      };

      if (token != null) {
        print('Forgot Password: Found potential token, attaching to request.');
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await dio.post(
        '$baseUrl/forgot-password',
        data: {'email': email},
        options: Options(
          headers: headers,
          validateStatus: (status) => true,
        ),
      );

      print('Forgot Password Status: ${response.statusCode}');
      print('Forgot Password Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['status'] == 1) {
           return {'success': true, 'message': data['message'] ?? 'Reset link sent to your email.'};
        } else {
           String msg = 'Failed to send reset link';
           if (data is Map && data['message'] != null) msg = data['message'];
           return {'success': false, 'message': msg};
        }
      } else {
        // Try to parse error message from server
        String errorMsg = 'Request failed with status: ${response.statusCode}';
        if (response.data is Map && response.data['message'] != null) {
          errorMsg = response.data['message'];
        }
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      print('Forgot Password Error: $e');
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // Fetch permissions from dedicated endpoint
  static Future<Map<String, dynamic>> fetchRolePermissions(String token) async {
      try {
        final dio = Dio();
        final response = await dio.get(
          '$baseUrl/role-permissions',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            validateStatus: (status) => true,
          ),
        );
        
        print('fetchRolePermissions status: ${response.statusCode}');
        if (response.statusCode == 200) {
          var responseData = response.data;
          if (responseData is String) {
             final dataString = responseData.trim();
             if (dataString.startsWith('<')) {
               print('fetchRolePermissions: Received HTML instead of JSON. Ignoring.');
               return {'status': 0, 'message': 'Invalid server response'};
             }
             try {
                responseData = jsonDecode(dataString);
             } catch (e) {
                print('fetchRolePermissions: JSON decode error: $e');
                return {'status': 0, 'message': 'Invalid JSON format'};
             }
          }
          
          if (responseData is Map) {
            return Map<String, dynamic>.from(responseData);
          } else {
            print('fetchRolePermissions: Expected Map, got ${responseData.runtimeType}');
            return {'status': 0, 'message': 'Unexpected response format'};
          }
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

    // NEW: Save 'employee' data if present (contains full profile info)
    if (data['employee'] != null) {
      print('DEBUG: Saving full employee data to storage');
      await prefs.setString('employee_data', jsonEncode(data['employee']));
    } else {
      print('DEBUG: No employee data found, clearing existing employee_data');
      await prefs.remove('employee_data');
    }

    
    // Save Workspaces from Login Response
    if (data['workspaces'] != null) {
      print('DEBUG: Saving ${data['workspaces'].length} workspaces to storage');
      await prefs.setString('stored_workspaces', jsonEncode(data['workspaces']));
    } else {
       print('DEBUG: No workspaces found in login response to save');
    }

    // Save Sites from Login Response
    if (data['sites'] != null) {
      print('DEBUG: Saving ${(data['sites'] as List).length} sites to storage');
      await prefs.setString('stored_sites', jsonEncode(data['sites']));
    } else {
      print('DEBUG: No sites found in login response to save');
    }
  }

  static Future<bool> refreshUserProfile() async {
    try {
      print('refreshUserProfile: Starting...');
      final result = await getData();
      print('refreshUserProfile: getData success: ${result['success']}');
      
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
                 print('refreshUserProfile: Fetching extra permissions...');
                 final permResponse = await fetchRolePermissions(token);
                 print('refreshUserProfile: Perms status: ${permResponse['status']}');
                 if (permResponse['status'] == 1 && 
                     permResponse['data'] != null && 
                     permResponse['data'] is Map) {
                    final permData = permResponse['data'] as Map<String, dynamic>;
                    if (permData['roles'] != null) {
                        data['roles'] = permData['roles'];
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
        print('refreshUserProfile: User data saved.');
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

      // If we don't have a token to refresh, we can't proceed
      if (token == null) {
        print('refreshToken: 🔴 No token found in storage.');
        return false;
      }

      print('refreshToken: Calling API with token: ${token.substring(0, 10)}...');
      
      // Use a fresh Dio instance to avoid our main interceptor (which might trigger loops)
      final dio = Dio();
      final response = await dio.post(
        '$baseUrl/auth/refresh',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => true, // Handle all statuses manually
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      print('refreshToken: API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Validate response structure as per screenshot:
        // { "status": 1, "data": { "token": "...", ... } }
        if (responseData is Map && responseData['status'] == 1) {
          final dataObj = responseData['data'];
          if (dataObj != null && dataObj['token'] != null) {
            final newToken = dataObj['token'];
            
            print('refreshToken: 🟢 Success! New token received.');
            
            // Print Expiry Time from API Response
            if (dataObj['expires_in'] != null) {
              final int expiresIn = dataObj['expires_in'];
              final DateTime expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
              print('⏳ New Token Expires in $expiresIn seconds (at $expiryTime)');
            }

            // Save immediately
            await prefs.setString('auth_token', newToken);

            // Optional: Update permissions if the refresh response includes it (or trigger a fetch)
            // Ideally, we should do this quietly so we don't block the retry
            try {
               _updatePermissionsQuietly(newToken, dataObj);
            } catch (e) {
               print('refreshToken: Permission update logic warning: $e');
            }
            
            return true;
          }
        }
        
        print('refreshToken: 🔴 Response OK but invalid structure: $responseData');
        return false;
      } else {
        print('refreshToken: 🔴 Failed with status ${response.statusCode}');
        // 401 here means the refresh token itself is expired or invalid -> Logout
        return false;
      }
    } catch (e) {
      print('refreshToken: 🔴 Exception: $e');
      return false;
    }
  }

  // Helper to update permissions without blocking the main flow too much
  static Future<void> _updatePermissionsQuietly(String newToken, Map<String, dynamic> refreshData) async {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Try to get roles/permissions from the refresh response itself if available
      // The screenshot shows "user" object inside data, maybe roles are there?
      Map<String, dynamic> dataToSave = {};
      
      // If refresh returned user data, use it
      if (refreshData['user'] != null) {
         // dataToSave['user'] = refreshData['user']; // optional, depends if we want to update profile
      }

      // 2. Fetch fresh permissions from endpoint
      print('refreshToken: Fetching fresh permissions in background...');
      final permResponse = await fetchRolePermissions(newToken);
      
      if (permResponse['status'] == 1 && 
          permResponse['data'] != null && 
          permResponse['data'] is Map) {
          final permData = permResponse['data'] as Map<String, dynamic>;
          if (permData['roles'] != null) {
              dataToSave['roles'] = permData['roles'];
          }
          if (permData['permissions'] != null) {
              dataToSave['permissions'] = permData['permissions'];
          }
      }
      
      // 3. Save whatever we found
      if (dataToSave.isNotEmpty) {
          // We need to merge with existing user_data to not lose other fields
          final String? existingDataStr = prefs.getString('user_data');
          Map<String, dynamic> finalUserData = {};
          
          if (existingDataStr != null) {
              try {
                finalUserData = jsonDecode(existingDataStr);
              } catch (_) {}
          }
          
          // Merge
          dataToSave.forEach((key, value) {
             finalUserData[key] = value;
          });
          
          await prefs.setString('user_data', jsonEncode(finalUserData));
          print('refreshToken: Permissions/User data updated in background.');
      }
  }

  // Get all items
  static Future<Map<String, dynamic>> getData() async {
    try {
      print('getData: Fetching from /user');

      final response = await DioService.instance.dio.get('/user');
      
      print('getData Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Dio parses JSON automatically
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to fetch data',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Fetch user by ID
  static Future<Map<String, dynamic>> fetchUserById(String id) async {
    try {
      final endpoints = [
        '/employee/$id',
        '/user/$id', // Fallback 1
        '/user',     // Fallback 2 (Sanctum me)
      ];

      for (var url in endpoints) {
        print('fetchUserById: Trying $url');
        try {
          final response = await DioService.instance.dio.get(url);

          if (response.statusCode == 200) {
             final data = response.data;
             
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




}