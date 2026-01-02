import 'dart:convert';
import 'package:ecoteam_app/contractor/models/chat_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String _baseUrl = 'https://sitepilot.easy2it.in/api/chat';
  
  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch messages for a conversation - FIXED VERSION
 // Fetch messages for a conversation - UPDATED VERSION
Future<List<ChatMessage>> fetchMessages(String conversationId) async {
  try {
    // Get current user ID and name first
    String currentUserId = '';
    String currentUserName = 'You';
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      final userData = json.decode(userDataStr);
      currentUserId = userData['id']?.toString() ?? '';
      currentUserName = userData['name']?.toString() ?? 'You';
    }

    final headers = await _headers;
    
    // Construct URL with query parameters
    final url = '$_baseUrl/fetch/$conversationId?from_id=$currentUserId&to_id=$conversationId';
    print('DEBUG: Fetching messages URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      print('DEBUG: New API Response received');
      final data = json.decode(response.body);

      // Debug: Print first message structure
      if (data['messages'] is List && (data['messages'] as List).isNotEmpty) {
        print('DEBUG: First message structure:');
        print(jsonEncode(data['messages'][0]));
      }

      // 1. Try JSON list (New API)
      if (data['messages'] is List && (data['messages'] as List).isNotEmpty) {
        final List<dynamic> messagesJson = data['messages'];
        print('DEBUG: Parsing ${messagesJson.length} messages from New API'); 
        
        return messagesJson.map((jsonItem) {
          final jsonMap = Map<String, dynamic>.from(jsonItem);
          
          // DEBUG: Print all keys in the message
          print('DEBUG: Message keys: ${jsonMap.keys.toList()}');
          
          // Map API fields to Model fields
          jsonMap['message'] = jsonMap['body'] ?? jsonMap['message'] ?? '';
          jsonMap['sender_id'] = jsonMap['from_id']?.toString() ?? jsonMap['sender_id']?.toString();
          
          // Extract sender name - Check multiple possible fields
          String senderName = 'Unknown';
          
          // Priority 1: Check if there's a 'user' object
          if (jsonMap['user'] is Map) {
            final userData = Map<String, dynamic>.from(jsonMap['user']);
            senderName = userData['name']?.toString() ?? 
                        userData['username']?.toString() ?? 
                        userData['full_name']?.toString() ?? 
                        'Unknown';
            print('DEBUG: Found sender name from user object: $senderName');
          }
          // Priority 2: Check direct fields
          else if (jsonMap['from_name'] != null) {
            senderName = jsonMap['from_name'].toString();
            print('DEBUG: Found sender name from from_name: $senderName');
          }
          else if (jsonMap['sender_name'] != null) {
            senderName = jsonMap['sender_name'].toString();
            print('DEBUG: Found sender name from sender_name: $senderName');
          }
          else if (jsonMap['name'] != null) {
            senderName = jsonMap['name'].toString();
            print('DEBUG: Found sender name from name: $senderName');
          }
          else if (jsonMap['username'] != null) {
            senderName = jsonMap['username'].toString();
            print('DEBUG: Found sender name from username: $senderName');
          }
          
          jsonMap['sender_name'] = senderName;

          // Handle Attachment - CORRECT DOMAIN NAME
          if (jsonMap['attachment'] != null && jsonMap['attachment'].toString().isNotEmpty) {
            try {
              String attachmentStr = jsonMap['attachment'].toString();
              print('DEBUG: Raw attachment: $attachmentStr');
              
              // Check if it's JSON string (Old format)
              if (attachmentStr.startsWith('{')) {
                final attachmentData = json.decode(attachmentStr);
                final newName = attachmentData['new_name']?.toString();
                final oldName = attachmentData['old_name']?.toString();
                
                if (newName != null && newName.isNotEmpty) {
                  // Construct URL with CORRECT DOMAIN
                  String fileUrl;
                  if (newName.contains('/')) {
                    fileUrl = 'https://sitepilot.easy2it.in/$newName';
                  } else {
                    fileUrl = 'https://sitepilot.easy2it.in/uploads/attachments/$newName';
                  }
                  
                  // Preserve caption
                  final caption = jsonMap['message']?.toString();
                  if (caption != null && caption.isNotEmpty && caption != 'null') {
                    jsonMap['metadata'] = {
                      'caption': caption,
                      'filename': oldName ?? 'attachment',
                      'is_attachment': true,
                    };
                  } else {
                    jsonMap['metadata'] = {
                      'filename': oldName ?? 'attachment',
                      'is_attachment': true,
                    };
                  }

                  // Determine file type
                  final extension = newName.split('.').last.toLowerCase();
                  
                  // Set message type based on extension
                  if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
                    jsonMap['message_type'] = 'image';
                    jsonMap['message'] = fileUrl;
                  } else if (['pdf'].contains(extension)) {
                    jsonMap['message_type'] = 'document';
                    jsonMap['message'] = fileUrl;
                    jsonMap['document_type'] = 'pdf';
                  } else {
                    jsonMap['message_type'] = 'document';
                    jsonMap['message'] = fileUrl;
                  }
                }
              } 
              // Check if it's List string (New format ["filename.pdf"])
              else if (attachmentStr.startsWith('[')) {
                try {
                  List<dynamic> list = json.decode(attachmentStr);
                  if (list.isNotEmpty) {
                    final filename = list[0].toString();
                    if (filename.isNotEmpty && filename != 'null') {
                      String fileUrl = 'https://sitepilot.easy2it.in/uploads/attachments/$filename';
                      
                      // Preserve caption
                      final caption = jsonMap['message']?.toString();
                      if (caption != null && caption.isNotEmpty && caption != 'null') {
                        jsonMap['metadata'] = {
                          'caption': caption,
                          'filename': filename,
                          'is_attachment': true,
                        };
                      } else {
                        jsonMap['metadata'] = {
                          'filename': filename,
                          'is_attachment': true,
                        };
                      }

                      // Determine file type
                      final extension = filename.split('.').last.toLowerCase();
                      
                      if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
                        jsonMap['message_type'] = 'image';
                        jsonMap['message'] = fileUrl;
                      } else if (['pdf'].contains(extension)) {
                        jsonMap['message_type'] = 'document';
                        jsonMap['message'] = fileUrl;
                        jsonMap['document_type'] = 'pdf';
                      } else {
                        jsonMap['message_type'] = 'document';
                        jsonMap['message'] = fileUrl;
                      }
                      
                      print('DEBUG: Parsed attachment list URL: $fileUrl');
                    }
                  }
                } catch (e) {
                  print('Error parsing attachment list: $e');
                }
              } else if (attachmentStr.contains('http')) {
                // Direct URL - check and fix typos
                String fixedUrl = attachmentStr
                    .replaceAll('sitepliot.', 'sitepilot.')
                    .replaceAll('easy2lt.', 'easy2it.');
                
                jsonMap['message'] = fixedUrl;
                jsonMap['message_type'] = 'image';
                jsonMap['metadata'] = {
                  'filename': 'attachment',
                  'is_attachment': true,
                  'url': fixedUrl,
                };
                print('DEBUG: Fixed URL from direct: $fixedUrl');
              } else {
                // Not a URL, might be just text
                jsonMap['message'] = attachmentStr;
                jsonMap['message_type'] = 'text';
              }
            } catch (e) {
              print('Error parsing attachment: $e');
              jsonMap['message'] = jsonMap['attachment'];
              jsonMap['message_type'] = 'text';
            }
          } else {
            // No attachment - text message
            jsonMap['message_type'] = 'text';
          }

          // Auto-detect if message is from current user
          if (currentUserId.isNotEmpty && jsonMap['sender_id'] != null) {
            jsonMap['is_from_current_user'] = jsonMap['sender_id'].toString() == currentUserId;
            
            // If it's from current user, set sender name to user's actual name
            if (jsonMap['is_from_current_user'] == true) {
              jsonMap['sender_name'] = currentUserName;
              print('DEBUG: Message from current user: ${currentUserName}');
            }
          }

          // Handle timestamp
          if (jsonMap['timestamp'] == null && jsonMap['created_at'] != null) {
            jsonMap['timestamp'] = jsonMap['created_at'];
          }

          // Ensure required fields
          jsonMap['id'] = jsonMap['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          jsonMap['conversation_id'] = conversationId;
          
          // Ensure sender_name has a value
          jsonMap['sender_name'] = jsonMap['sender_name'] ?? 'Unknown';
          
          // DEBUG: Print final message data
          print('DEBUG: Final message data - Sender: ${jsonMap['sender_name']}, Message: ${jsonMap['message']}');

          return ChatMessage.fromJson(jsonMap);
        }).toList();
      }
    }

    // 2. Fallback to Legacy API
    print('DEBUG: New API empty, trying fallback fetch1...');
    final fallbackResponse = await http.get(
      Uri.parse('$_baseUrl/fetch1?conversation_id=$conversationId'),
      headers: headers,
    );

    if (fallbackResponse.statusCode == 200) {
      final data = json.decode(fallbackResponse.body);
      if (data['count'] != null && data['count'] > 0) {
        final htmlContent = data['message']?.toString() ?? data['messages']?.toString() ?? '';
        return _parseMessagesFromHtml(htmlContent);
      }
    }
    return [];
  } catch (e) {
    print('ERROR in fetchMessages: $e');
    throw Exception('Failed to fetch messages: $e');
  }
}
  // Send a message
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String message,
    required String type,
    int? id,
  }) async {
    try {
      final body = {
        'id': id ?? conversationId,
        'type': type,
        'message': message,
      };

      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/send'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == 0) {
          return {
            'success': true,
            'messageId': data['tempID']?.toString(),
            'html': data['message']?.toString(),
          };
        } else {
          throw Exception(data['error_meg']?.toString() ?? 'Failed to send message');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Send attachment
  // Send attachment - UPDATED VERSION
Future<Map<String, dynamic>> sendAttachment({
  required String conversationId,
  required String filePath,
  required String type, // 'image', 'video', 'document', 'pdf', etc.
  String? message,
}) async {
  try {
    // Get current user ID
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    final userData = userDataStr != null ? json.decode(userDataStr) : null;
    final fromId = userData?['id']?.toString() ?? '';

    final headers = await _headers;
    final uri = Uri.parse('$_baseUrl/send');
    
    var request = http.MultipartRequest('POST', uri);
    
    // Add headers
    headers.forEach((key, value) {
      if (key != 'Content-Type') {
        request.headers[key] = value;
      }
    });

    // DEBUG: Print what we're sending
    print('DEBUG SEND ATTACHMENT:');
    print('  - File path: $filePath');
    print('  - File name: ${filePath.split('/').last}');
    print('  - Conversation ID: $conversationId');
    print('  - Message: $message');
    print('  - Type: $type');
    
    // Add fields - MATCH THE API EXPECTATION FROM YOUR IMAGE
    request.fields['id'] = conversationId; // This is the "to_id" (receiver ID)
    request.fields['type'] = type == 'group' ? 'group' : 'user';
    request.fields['message'] = message ?? '';
    
    // For testing: Also try sending from_id if API needs it
    request.fields['from_id'] = fromId;
    
    // Add file
    try {
      // CHANGED: Use 'file' as key to match Postman screenshot
      var file = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(file);
      
      // DEBUG: Check file info
      print('  - File size: ${await file.length} bytes');
    } catch (e) {
      print('ERROR creating multipart file: $e');
      throw Exception('Failed to prepare file: $e');
    }

    print('DEBUG: Final request fields: ${request.fields}');
    print('DEBUG: Request files count: ${request.files.length}');

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('DEBUG: Upload response status: ${response.statusCode}');
    print('DEBUG: Upload response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('DEBUG: Parsed response data: $data');
      
      if (data['error'] == 0) {
        // Extract real message ID from response
        String? realMessageId;
        
        // Check various possible locations for message ID
        if (data['message'] != null && data['message'] is Map) {
          realMessageId = data['message']['id']?.toString();
        } else if (data['tempID'] != null) {
          realMessageId = data['tempID']?.toString();
        } else if (data['id'] != null) {
          realMessageId = data['id']?.toString();
        }
        
        return {
          'success': true,
          'messageId': realMessageId,
          'tempId': data['tempID']?.toString(),
          'html': data['message']?.toString(),
          'rawResponse': data,
        };
      } else {
        throw Exception(data['error_meg']?.toString() ?? 'Failed to upload attachment');
      }
    } else {
      print('ERROR: HTTP ${response.statusCode}: ${response.body}');
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('ERROR in sendAttachment: $e');
    throw Exception('Failed to send attachment: $e');
  }
}
  // Mark message as seen
  Future<bool> markAsSeen(String messageId) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/seen'),
        headers: headers,
        body: json.encode({'id': messageId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 1;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to mark as seen: $e');
    }
  }

  // Delete conversation
  Future<int> deleteConversation(String conversationId) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/deleteConversation'),
        headers: headers,
        body: json.encode({'conversation_id': conversationId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['deleted'] is int ? data['deleted'] : 0;
      }
      return 0;
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Update contact item
  Future<Map<String, dynamic>> updateContactItem(String userId) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/updateContactItem'),
        headers: headers,
        body: json.encode({'user_id': int.tryParse(userId) ?? 0}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'contactItem': data['contactItem']?.toString() ?? '',
          'messengerCount': data['messengerCount'] is int ? data['messengerCount'] : 0,
        };
      }
      return {'contactItem': '', 'messengerCount': 0};
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  // Search chat
  Future<Map<String, dynamic>> searchChat(String query) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$_baseUrl/search'),
        headers: headers,
        body: json.encode({'input': query}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'records': data['records']?.toString() ?? '',
          'addData': data['addData']?.toString() ?? 'html',
        };
      }
      return {'records': '', 'addData': 'html'};
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // Get contacts - separate chats and all contacts
  Future<Map<String, List<ChatContact>>> getContacts({String? siteId, String? workspaceId}) async {
    try {
      final headers = await _headers;
      
      // Get user data for workspace_id and user_id
      final prefs = await SharedPreferences.getInstance();
      String userId = '';
      String storedWorkspaceId = '';
      
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userData = json.decode(userDataStr);
        userId = userData['id']?.toString() ?? '';
        storedWorkspaceId = userData['workspace_id']?.toString() ?? '';
      }
      
      // Prioritize passed workspaceId
      final finalWorkspaceId = (workspaceId != null && workspaceId.isNotEmpty) 
          ? workspaceId 
          : storedWorkspaceId;
      
      // Build query parameters
      String queryParams = 'user_id=$userId';
      if (finalWorkspaceId.isNotEmpty) {
        queryParams += '&workspace_id=$finalWorkspaceId';
      }
      if (siteId != null && siteId.isNotEmpty) {
        queryParams += '&site_id=$siteId';
      }
      
      print('DEBUG: Fetching contacts with params: $queryParams');

      final response = await http.get(
        Uri.parse('$_baseUrl/contacts?$queryParams'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<ChatContact> recentChats = [];
        final List<ChatContact> allContacts = [];
        
        // Parse 'contacts' (Recent Chats)
        if (data['contacts'] is List) {
          for (var item in data['contacts']) {
             if (item is Map) {
               try {
                 recentChats.add(ChatContact.fromJson(Map<String, dynamic>.from(item)));
               } catch (e) {
                 print('Error parsing recent chat contact: $e');
               }
             }
          }
        }

        // Parse 'allUsers' (All Contacts)
        // Check for 'allUsers' or 'allusers'
        var allUsersList = data['allUsers'] ?? data['allusers'];
        if (allUsersList is List) {
          for (var item in allUsersList) {
             if (item is Map) {
               try {
                 allContacts.add(ChatContact.fromJson(Map<String, dynamic>.from(item)));
               } catch (e) {
                 print('Error parsing all contact: $e');
               }
             }
          }
        }
        
        return {
          'chats': recentChats,
          'contacts': allContacts,
        };
      } else {
        throw Exception('Failed to fetch contacts: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch contacts: $e');
    }
  }

  // Get favorites
  Future<List<ChatFavorite>> getFavorites() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$_baseUrl/favorites'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['favorites'] is String) {
          return _parseFavoritesFromHtml(data['favorites']);
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch favorites: $e');
    }
  }

  // Helper method to parse HTML response for messages
  // Helper method to parse HTML response for messages
List<ChatMessage> _parseMessagesFromHtml(String html) {
  final List<ChatMessage> messages = [];
  
  // Enhanced regex to capture sender name
  final regex = RegExp(
    r'class="message-card[^>]*>.*?<div[^>]*class="[^"]*sender-name[^"]*"[^>]*>(.*?)</div>.*?<p>(.*?)</p>.*?data-id="(\d+)"',
    dotAll: true,
  );
  
  final matches = regex.allMatches(html);
  for (final match in matches) {
    if (match.groupCount >= 3) {
      final senderName = match.group(1)?.trim() ?? 'Unknown';
      final messageText = match.group(2)?.trim() ?? '';
      final messageId = match.group(3) ?? '';
      
      messages.add(ChatMessage(
        id: messageId,
        conversationId: '',
        senderId: '',
        senderName: senderName,
        message: messageText,
        timestamp: DateTime.now(),
        isFromCurrentUser: false,
        messageType: MessageType.text,
      ));
    }
  }

  // Fallback regex if above doesn't match
  if (messages.isEmpty) {
    final fallbackRegex = RegExp(
      r'class="message-card[^>]*>.*?<p>(.*?)</p>.*?data-id="(\d+)"',
      dotAll: true,
    );
    
    final fallbackMatches = fallbackRegex.allMatches(html);
    for (final match in fallbackMatches) {
      if (match.groupCount >= 2) {
        final messageText = match.group(1)?.trim() ?? '';
        final messageId = match.group(2) ?? '';
        
        messages.add(ChatMessage(
          id: messageId,
          conversationId: '',
          senderId: '',
          senderName: 'Unknown', // Default fallback
          message: messageText,
          timestamp: DateTime.now(),
          isFromCurrentUser: false,
          messageType: MessageType.text,
        ));
      }
    }
  }

  return messages;
}

  // Helper method to parse HTML response for favorites
  List<ChatFavorite> _parseFavoritesFromHtml(String html) {
    final List<ChatFavorite> favorites = [];
    
    final regex = RegExp(
      r'data-id="(\d+)".*?url\(([^)]+)\).*?<p>([^<]+)</p>',
      dotAll: true,
    );
    
    final matches = regex.allMatches(html);
    for (final match in matches) {
      if (match.groupCount >= 3) {
        final userId = match.group(1) ?? '';
        final avatarUrl = match.group(2)?.replaceAll("'", '') ?? '';
        final name = match.group(3) ?? 'Unknown';
        
        favorites.add(ChatFavorite(
          userId: int.tryParse(userId) ?? 0,
          name: name,
          avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
        ));
      }
    }
    
    return favorites;
  }
}