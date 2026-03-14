import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Import jwt_decoder

import 'package:ecoteam_app/global.dart';
import 'package:ecoteam_app/contractor/services/api_service_login.dart';
import 'package:ecoteam_app/contractor/view/auth/login_selector.dart';

class DioService {
  static final DioService _instance = DioService._internal();
  static DioService get instance => _instance;

  late Dio dio;
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;
  Timer? _refreshTimer; // Timer for proactive refresh

  // Base URL
  final String baseUrl = 'https://app.ecoteamsolar.com/api';

  DioService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // Add Authorization header
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (DioException e, handler) async {
            if (e.response?.statusCode == 401) {
              // Create a localized definition of the refresh logic to keep things clean
              
              // 1. Check if this request was already a retry. If so, fail to avoid infinite loops.
              if (e.requestOptions.extra['is_retry'] == true) {
                print('🔴 401 on RETRY request. Giving up.');
                return handler.next(e);
              }

              final prefs = await SharedPreferences.getInstance();
              final currentToken = prefs.getString('auth_token');
              
              // Extract the token used in the failed request
              final requestTokenHeader = e.requestOptions.headers['Authorization'];
              final requestToken = (requestTokenHeader is String && requestTokenHeader.startsWith('Bearer '))
                  ? requestTokenHeader.substring(7)
                  : null;

              // 2. Check if the token has changed since this request was made.
              // This happens if another request triggered a refresh while this one was in flight.
              if (currentToken != null && requestToken != null && currentToken != requestToken) {
                print('🟠 Token already refreshed by another request. Retrying immediately.');
                return _retryRequest(e, handler);
              }

              // 3. Handle Concurrent Refreshes using a Completer lock
              if (_isRefreshing) {
                print('🟠 Refresh already in progress. Waiting for completion...');
                if (_refreshCompleter != null) {
                  try {
                    await _refreshCompleter!.future;
                    print('🟢 Previous refresh completed. Retrying request.');
                    return _retryRequest(e, handler);
                  } catch (err) {
                    print('🔴 Previous refresh failed. Rejecting request.');
                    return handler.next(e);
                  }
                }
              }

              // 4. Start the Refresh Flow
              _isRefreshing = true;
              _refreshCompleter = Completer<void>();

              try {
                print('🟡 STARTING/TRIGGERING REFRESH FLOW...');
                final refreshSuccess = await ApiService.refreshToken();

                if (refreshSuccess) {
                  print('🟢 Refresh API Success. Resuming pending requests.');
                  _isRefreshing = false;
                  _refreshCompleter?.complete();
                  _refreshCompleter = null;
                  
                  // Re-schedule the next refresh based on the NEW token
                  final prefs = await SharedPreferences.getInstance();
                  final newToken = prefs.getString('auth_token');
                  if (newToken != null) {
                    scheduleTokenRefresh(newToken);
                  }

                  return _retryRequest(e, handler);
                } else {
                  print('🔴 Refresh API returned false/failed.');
                  throw Exception('Refresh returned false');
                }
              } catch (refreshError) {
                print('🔴 Session Expired/Refresh Failed: $refreshError');
                _isRefreshing = false;
                _refreshCompleter?.completeError(refreshError);
                _refreshCompleter = null;
                
                // Only logout if it's a genuine refresh failure, not a network hiccup? 
                // For security, usually 401 on refresh means game over.
                await _performInternalLogout();
                return handler.next(e);
              }
            }
            // For non-401 errors, just pass them through
            return handler.next(e);
          },
        ),
      );
  }

  // --- Proactive Refresh Logic ---

  void scheduleTokenRefresh(String token) {
    _refreshTimer?.cancel(); // Cancel any existing timer

    try {
      if (JwtDecoder.isExpired(token)) {
        print('⚠️ Token is already expired during schedule check. Calling refresh immediately.');
        _triggerScheduledRefresh();
        return;
      }

      DateTime expirationDate = JwtDecoder.getExpirationDate(token);
      DateTime now = DateTime.now();

      Duration timeUntilExpiry = expirationDate.difference(now);
      Duration refreshDelay = timeUntilExpiry - const Duration(minutes: 3);

      if (refreshDelay.isNegative) {
        print('⚠️ Less than 3 mins to expiry (or expired). Scheduling refresh ASAP (10s delay).');
        // Add a small buffer to avoid spamming if called in a tight loop,
        // but effectively immediate.
        refreshDelay = const Duration(seconds: 10);
      }

      print(
          '🕒 Token expires at $expirationDate. Scheduling refresh in ${refreshDelay.inMinutes} minutes (${refreshDelay.inSeconds} seconds).');

      _refreshTimer = Timer(refreshDelay, () {
        print('⏰ Timer triggered: Proactively refreshing token...');
        _triggerScheduledRefresh();
      });
    } catch (e) {
      print('ℹ️ Token is not a JWT or is invalid ($e). Skipping proactive refresh scheduling.');
    }
  }

  Future<void> _triggerScheduledRefresh() async {
    // If a refresh is already happening (e.g. via 401 interceptor), don't double up via timer
    if (_isRefreshing) {
      print('Existing refresh in progress. Timer task skipped.');
      return;
    }

    // Set refreshing flag so 401 interceptor knows we are busy
    // (Though ApiService.refreshToken doesn't use the interceptor-dio instance, so it is fine)
    
    try {
      final success = await ApiService.refreshToken();
      if (success) {
        print('✅ Scheduled refresh successful.');
        final prefs = await SharedPreferences.getInstance();
        final newToken = prefs.getString('auth_token');
        if (newToken != null) {
          scheduleTokenRefresh(newToken); // Reschedule for next time
        }
      } else {
        print('❌ Scheduled refresh failed. Will rely on 401 interceptor or next app start.');
        // Optionally retry? For now, let's leave it. If next request 401s, interceptor catches it.
      }
    } catch (e) {
      print('❌ Error during scheduled refresh: $e');
    }
  }


  Future<void> _performInternalLogout() async {
    try {
      print('⚠️ Performing Internal Logout...');
      _refreshTimer?.cancel(); // Cancel timer on logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginSelectorPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<void> _retryRequest(
      DioException e, ErrorInterceptorHandler handler) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newToken = prefs.getString('auth_token');

      if (newToken == null) {
        return handler.next(e);
      }

      print('🟢 RETRYING with new token: $newToken');

      final options = e.requestOptions;
      options.headers['Authorization'] = 'Bearer $newToken';
      options.extra['is_retry'] = true;

      final retryResponse = await dio.fetch(options);
      return handler.resolve(retryResponse);
    } catch (retryError) {
      if (retryError is DioException) {
        return handler.next(retryError);
      }
      return handler.next(e);
    }
  }
}