import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPusherManager {
  static final AppPusherManager _instance = AppPusherManager._internal();
  factory AppPusherManager() => _instance;
  
  late PusherChannelsFlutter _pusher;
  final List<Function(PusherEvent)> _listeners = [];
  bool _isInitialized = false;
  String _currentUserId = '';
  String? _activeChatId; // Track the currently open chat ID
  
  AppPusherManager._internal();

  // Initialize once when the app starts or user logs in
  Future<void> initializeAppConnection() async {
    if (_isInitialized) {
      print("✅ AppPusherManager already initialized");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final userDataStr = prefs.getString('user_data');
    
    if (userDataStr == null || token.isEmpty) {
      print("❌ AppPusherManager: Missing token or user data");
      return;
    }

    final userData = json.decode(userDataStr);
    final userId = userData['id']?.toString();
    if (userId == null || userId.isEmpty) {
      print("❌ AppPusherManager: Invalid user ID");
      return;
    }
    
    _currentUserId = userId;
    _pusher = PusherChannelsFlutter.getInstance();

    try {
      print("🚀 AppPusherManager: Initializing global connection for user: $userId");
      
      await _pusher.init(
        apiKey: "6f2938d34182bd34f292",
        cluster: "ap2",
        onConnectionStateChange: (currentState, previousState) {
          print("🌐 App Pusher State: $previousState -> $currentState");
          if (currentState == 'CONNECTED') {
            print("✅ AppPusherManager: Connected to Pusher");
          } else if (currentState == 'DISCONNECTED') {
            print("❌ AppPusherManager: Disconnected from Pusher");
          }
        },
        onError: (message, code, error) {
          print("❌ AppPusherManager Error: $message");
        },
        onEvent: _handleGlobalEvent,
        onAuthorizer: (channelName, socketId, options) async {
          final prefs = await SharedPreferences.getInstance();
          final freshToken = prefs.getString('auth_token') ?? '';
          if (freshToken.isEmpty) {
             print("❌ AppPusherManager: Token missing during re-auth");
             return null;
          }
          return await _authorizeChannel(channelName, socketId, freshToken);
        },
      );

      await _pusher.connect();
      await _subscribeToAppChannels(userId);
      
      _isInitialized = true;
      print("✅ AppPusherManager: Global connection established");
      
    } catch (e) {
      print("❌ AppPusherManager Initialization Error: $e");
      _isInitialized = false;
    }
  }

  Future<dynamic> _authorizeChannel(String channelName, String socketId, String token) async {
    print("🔑 AppPusherManager Authorizing: $channelName");
    try {
      final response = await http.post(
        Uri.parse('https://app.ecoteamsolar.com/broadcasting/auth'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode({
          'socket_id': socketId,
          'channel_name': channelName,
        }),
      );

      print("🔑 AppPusherManager Auth Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("❌ AppPusherManager Auth Failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ AppPusherManager Auth Exception: $e");
      return null;
    }
  }

  Future<void> _subscribeToAppChannels(String userId) async {
    try {
      print("📡 AppPusherManager: Subscribing to channels...");
      await _pusher.subscribe(
        channelName: "private-chatify",
        onEvent: (event) {
          if (event is PusherEvent) {
            _handleGlobalEvent(event);
          }
        }
      );
      
      await _pusher.subscribe(
        channelName: "private-notifications.$userId",
        onEvent: (event) {
          if (event is PusherEvent) {
            _handleGlobalEvent(event);
          }
        }
      );
      
      print("✅ AppPusherManager: Subscribed to all channels");
    } catch (e) {
      print("❌ AppPusherManager Subscription Error: $e");
    }
  }

  void _handleGlobalEvent(PusherEvent event) {
    // Forward events to all registered listeners
    for (var listener in _listeners) {
      try {
        listener(event);
      } catch (e) {
        print("❌ AppPusherManager Listener Error: $e");
      }
    }
  }

  // Register a listener for global events
  void addListener(Function(PusherEvent) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  // Remove a listener
  void removeListener(Function(PusherEvent) listener) {
    _listeners.remove(listener);
  }

  // Set the currently active chat ID (to suppress notifications)
  void setActiveChatId(String? chatId) {
    _activeChatId = chatId;
    print("🎯 AppPusherManager: Active Chat ID set to: $chatId");
  }

  // Deprecated: Use addListener instead
  void setMessageHandler(Function(PusherEvent) handler) {
    addListener(handler);
  }

  // Deprecated: Use removeListener instead
  void removeMessageHandler() {
    // Note: This behavior is slightly different now, as it requires passing the specific handler to remove.
    // For backward compatibility, we might want to clear all, but that's dangerous.
    // Ideally, callers should be updated to use removeListener(handler).
    // For now, we'll incorrectly clear all for safety if this is called, 
    // BUT since we are updating ChatScreen, we will update it to use removeListener properly.
    // _listeners.clear(); // DANGEROUS - avoided.
    print("⚠️ removeMessageHandler called without argument - doing nothing. updates required.");
  }

  // Getters
  String get currentUserId => _currentUserId;
  bool get isConnected => _isInitialized;
  String? get activeChatId => _activeChatId;
  PusherChannelsFlutter get pusherInstance => _pusher;

  // Call this only when the user logs out or app fully closes
  Future<void> disconnect() async {
    if (_isInitialized) {
      print("🔌 AppPusherManager: Disconnecting...");
      try {
        await _pusher.disconnect();
        _isInitialized = false;
        _listeners.clear();
        _activeChatId = null;
        print("✅ AppPusherManager: Disconnected successfully");
      } catch (e) {
        print("❌ AppPusherManager Disconnect Error: $e");
      }
    }
  }

  // Update when user data changes
  Future<void> updateUserConnection() async {
    print("🔄 AppPusherManager: Updating user connection...");
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await initializeAppConnection();
  }
}