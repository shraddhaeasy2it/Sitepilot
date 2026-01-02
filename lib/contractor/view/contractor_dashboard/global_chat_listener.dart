import 'dart:convert';
import 'package:ecoteam_app/contractor/services/chat_service.dart';

import 'package:ecoteam_app/contractor/services/app_pusher_services.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class GlobalChatListener extends StatefulWidget {
  final Widget child;

  const GlobalChatListener({super.key, required this.child});

  @override
  State<GlobalChatListener> createState() => _GlobalChatListenerState();
}

class _GlobalChatListenerState extends State<GlobalChatListener> {
  final Map<String, String> _contactNames = {};

  @override
  void initState() {
    super.initState();
    // Register global listener
    AppPusherManager().addListener(_handleGlobalPusherEvent);
    
    // Load contact names for lookups
    _loadContactNames();
  }

  Future<void> _loadContactNames() async {
    try {
      final data = await ChatService().getContacts();
      
      // Helper to add contacts to map
      void addContacts(List<dynamic>? contacts) {
        if (contacts != null) {
          for (var contact in contacts) {
            // Try different ID fields as API might return 'id' or 'userId'
            final String? id = contact.userId?.toString() ?? contact.id?.toString();
            if (id != null && contact.name != null) {
              _contactNames[id] = contact.name;
            }
          }
        }
      }

      addContacts(data['chats']);
      addContacts(data['contacts']);
      
      print("✅ GlobalChatListener cached ${_contactNames.length} contact names");
    } catch (e) {
      print("⚠️ GlobalChatListener failed to load contacts: $e");
    }
  }

  // Fetch individual contact info if missing
  Future<void> _fetchAndCacheContact(String userId) async {
    try {
      final info = await ChatService().updateContactItem(userId);
      // Note: updateContactItem returns HTML or partial data, might not give clean name directly 
      // depending on API. Let's try to extract from 'contactItem' HTML if needed or just trust the side effect.
      // Actually, let's refresh all contacts to be safe, but debounced.
      
      // Better approach: re-fetch all contacts silently
      _loadContactNames();
    } catch (e) {
      print("⚠️ GlobalChatListener failed to fetch missing contact: $e");
    }
  }

  @override
  void dispose() {
    // Unregister listener
    AppPusherManager().removeListener(_handleGlobalPusherEvent);
    super.dispose();
  }

  void _handleGlobalPusherEvent(PusherEvent event) {
    try {
      if (event.channelName == 'private-chatify' &&
          (event.eventName == 'messaging' ||
              event.eventName.contains('MessageSent') ||
              event.eventName == 'new-message')) {
        final Map<String, dynamic> data = json.decode(event.data);
        
        // Extract message data
        Map<String, dynamic> messageData;
        if (data['message'] != null && data['message'] is Map) {
          messageData = Map<String, dynamic>.from(data['message']);
        } else {
          messageData = Map<String, dynamic>.from(data);
        }

        // Check if message is for current user (sent TO me)
        final String? toId = messageData['to_id']?.toString();
        final currentUserId = AppPusherManager().currentUserId;

        if (toId == currentUserId) {
          final String? conversationId = 
              messageData['conversation_id']?.toString() ?? 
              messageData['from_id']?.toString();
          
          final String? activeChatId = AppPusherManager().activeChatId;

          // Only show notification if NOT in this chat
          if (conversationId != activeChatId) {
             _showNotification(messageData);
          }
        }
      }
    } catch (e) {
      print("❌ GlobalChatListener Error: $e");
    }
  }

  void _showNotification(Map<String, dynamic> messageData) {
    String senderName = messageData['from_name']?.toString() ?? 
                        messageData['sender_name']?.toString() ?? 
                        '';
    
    // If name is found in payload, use it
    if (senderName.isEmpty || senderName == 'Someone' || senderName == 'Unknown') {
      final String? fromId = messageData['from_id']?.toString() ?? 
                            messageData['sender_id']?.toString();
                            
      if (fromId != null && _contactNames.containsKey(fromId)) {
        senderName = _contactNames[fromId]!;
      } else {
        // Fallback: If not in cache, try to fetch it dynamically (async but best effort for next time)
        if (fromId != null) {
          _fetchAndCacheContact(fromId);
        }
        senderName = 'Someone';
      }
    }
    String messageText = messageData['message']?.toString() ?? 'New message';

    // Parse HTML if needed
    if (messageText.contains('<div')) {
      try {
        final document = html_parser.parse(messageText);
        final pTags = document.getElementsByTagName('p');
        if (pTags.isNotEmpty) {
          messageText = pTags.first.text.trim();
          final subTags = pTags.first.getElementsByTagName('sub');
          if (subTags.isNotEmpty) {
            messageText = messageText.replaceAll(subTags.first.text, '').trim();
          }
        }
      } catch (e) {
        // keep original text if parse fails
      }
    }

    // Show persistent notification
    Fluttertoast.showToast(
      msg: "💬 $senderName: $messageText",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 4,
      backgroundColor: Colors.white,
      textColor: const Color(0xFF1565C0), // Blue color
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
