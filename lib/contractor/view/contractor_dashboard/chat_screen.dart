import 'dart:convert';
import 'dart:async';
import 'package:ecoteam_app/contractor/models/chat_model.dart';
import 'package:ecoteam_app/contractor/services/chat_service.dart';
import 'package:ecoteam_app/contractor/services/pusher_services.dart';
import 'package:ecoteam_app/contractor/services/app_pusher_services.dart'; // Add this import
import 'package:ecoteam_app/contractor/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<dynamic> sites;
  final String? currentCompany;
  final int? workspaceId;
  
  const ChatScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    required this.currentCompany,
    this.workspaceId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late String _selectedSiteId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  
  bool _isInChat = false;
  bool _isGroupChat = false;
  String? _currentGroupName;
  List<ChatContact> _contacts = [];
  List<ChatContact> _allContacts = [];
  List<ChatFavorite> _favorites = [];
  List<ChatMessage> _messages = [];
  ChatContact? _currentContact;
  dynamic _currentGroup;
  bool _isLoading = false;
  String? _searchQuery;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;
  bool _pusherConnected = false;
  
  // Attachment state
  File? _selectedAttachment;
  String? _selectedAttachmentType; // 'image', 'document'

  // Color theme
  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color backgroundColor = Color(0xFFF8F9FC);
  static const Color chatBubbleColor = Color(0xFFE7EFFD);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);

  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedSiteId = widget.selectedSiteId ?? '';
    _chatService = ChatService();
    _loadInitialData();
    
    // Register as observer for app lifecycle
    WidgetsBinding.instance.addObserver(this);
    
    // Create handlers
    _setupPusherHandler();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("📱 App Lifecycle State: $state");
    
    if (state == AppLifecycleState.resumed) {
      // App came to foreground
      _checkPusherConnection();
    } else if (state == AppLifecycleState.paused) {
      // App went to background - we keep Pusher connected
      print("📱 App backgrounded - keeping Pusher connection alive");
    }
  }

  void _setupPusherHandler() {
    // Register listener via AppPusherManager
    AppPusherManager().addListener(_handlePusherEvent);
  }

  Future<void> _checkPusherConnection() async {
    if (!AppPusherManager().isConnected) {
      print("⚠️ Pusher not connected, attempting to reconnect...");
      await AppPusherManager().initializeAppConnection();
      
      if (mounted) {
        setState(() {
          _pusherConnected = AppPusherManager().isConnected;
        });
        
        if (AppPusherManager().isConnected) {
          _showSuccess("Chat reconnected");
        } else {
          _showError("Failed to reconnect chat");
        }
      }
    } else {
      setState(() {
        _pusherConnected = true;
      });
    }
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _selectedSiteId = widget.selectedSiteId ?? '';
      _isInChat = false;
      _loadContacts();
    }
  }

  // ==================== HTML PARSING HELPER ====================
  Map<String, dynamic> _parseHtmlMessage(String html, Map<String, dynamic> originalData) {
    try {
      final document = html_parser.parse(html);
      final result = <String, dynamic>{};
      
      // Extract message text from <p> tag
      final pTags = document.getElementsByTagName('p');
      if (pTags.isNotEmpty) {
        String messageText = pTags.first.text.trim();
        
        // Remove timestamp subtext if present
        final subTags = pTags.first.getElementsByTagName('sub');
        if (subTags.isNotEmpty) {
          messageText = messageText.replaceAll(subTags.first.text, '').trim();
        }
        
        result['message'] = messageText;
      }
      
      // Extract message ID from data-id attribute
      final messageDiv = document.querySelector('.message-card');
      if (messageDiv != null) {
        final messageId = messageDiv.attributes['data-id'];
        if (messageId != null && messageId.isNotEmpty) {
          result['id'] = messageId;
        }
      }
      
      // Extract timestamp from <sub> tag
      final subTags = document.getElementsByTagName('sub');
      if (subTags.isNotEmpty) {
        final timestamp = subTags.first.attributes['title'];
        if (timestamp != null) {
          try {
            result['created_at'] = timestamp;
          } catch (e) {
            print("⚠️ Could not parse timestamp: $e");
          }
        }
      }
      
      return result;
      
    } catch (e) {
      print("❌ HTML parsing error: $e");
      return {'message': 'Message from web'};
    }
  }

  // ==================== FIXED PUSHER EVENT HANDLER ====================
  bool _isProcessingEvent = false;
  void _handlePusherEvent(PusherEvent event) {
    print("\n📨 PUSHER EVENT RECEIVED:");
    print("Channel: ${event.channelName}");
    print("Event: ${event.eventName}");
    print("Data: ${event.data}");
    
    // Prevent duplicate processing
    if (_isProcessingEvent) {
      print("⚠️ Event already being processed, skipping...");
      return;
    }
    
    _isProcessingEvent = true;
    
    try {
      // Only handle events from chatify channel
      if (event.channelName == 'private-chatify') {
        
        if (event.eventName == 'messaging' || 
            event.eventName.contains('MessageSent') ||
            event.eventName == 'new-message') {
          
          final Map<String, dynamic> data = json.decode(event.data);
          
          // Extract message data (could be direct or nested)
          Map<String, dynamic> messageData;
          
          if (data['message'] != null && data['message'] is Map) {
            messageData = Map<String, dynamic>.from(data['message']);
          } else {
            messageData = Map<String, dynamic>.from(data);
          }
          
          print("📦 Raw message data keys: ${messageData.keys.join(', ')}");
          
          // Check if message contains HTML (from web Chatify)
          if (messageData['message'] != null && 
              messageData['message'] is String &&
              (messageData['message'] as String).contains('<div')) {
            
            print("🔄 Message contains HTML, parsing...");
            final parsedMessage = _parseHtmlMessage(
              messageData['message'] as String,
              messageData
            );
            
            // Merge parsed data with original
            messageData.addAll(parsedMessage);
            print("✅ HTML parsed to: ${messageData['message']}");
          }
          
          // Check if message is for current user
          final String? fromId = messageData['from_id']?.toString();
          final String? toId = messageData['to_id']?.toString();
          
          bool isForCurrentUser = false;
          
          if (toId == _currentUserId) {
            // Message sent TO current user
            isForCurrentUser = true;
            print("✅ Message TO current user from: $fromId");
          } else if (fromId == _currentUserId) {
            // Message sent FROM current user
            isForCurrentUser = true;
            print("✅ Message FROM current user to: $toId");
          } else {
            print("⚠️ Message not for current user (to: $toId, from: $fromId)");
          }
          
          if (isForCurrentUser) {
            _processIncomingMessage(messageData);
          }
        }
      } else if (event.channelName == 'private-notifications.$_currentUserId') {
        // Handle notification events
        print("🔔 Notification received for current user");
        _handleNotificationEvent(event);
      } else if (event.eventName == 'pusher:subscription_succeeded') {
        print("✅ Subscribed to channel: ${event.channelName}");
      }
    } catch (e) {
      print("❌ Error processing pusher event: $e");
    } finally {
      _isProcessingEvent = false;
    }
  }

  
  void _handleNotificationEvent(PusherEvent event) {
    try {
      final Map<String, dynamic> data = json.decode(event.data);
      print("🔔 Notification data: $data");
      
      // Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("New notification received"),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print("❌ Error processing notification: $e");
    }
  }
  
  void _processIncomingMessage(Map<String, dynamic> messageData) {
    final String? fromId = messageData['from_id']?.toString();
    final String? toId = messageData['to_id']?.toString();
    
    // Check if message is for current chat
    bool isForCurrentChat = false;
    
    if (_isGroupChat && _currentGroup != null) {
      isForCurrentChat = messageData['conversation_id']?.toString() == _currentGroup.id;
    } else if (!_isGroupChat && _currentContact != null) {
      final contactId = _currentContact!.userId?.toString();
      isForCurrentChat = (fromId == contactId && toId == _currentUserId) ||
                        (fromId == _currentUserId && toId == contactId);
    }
    
    if (_isInChat && isForCurrentChat) {
      print("💬 Message is for current chat, adding to UI...");
      _addMessageToChat(messageData);
    } else {
      print("📱 Message is not for current chat, ignoring (handled by Global Listener)...");
      // _showNotificationForOtherChat(messageData); // REMOVED: Handled by Global Listener
    }
  }

  void _addMessageToChat(Map<String, dynamic> messageData) {
    try {
      // Prepare data for ChatMessage
      final Map<String, dynamic> preparedData = Map.from(messageData);
      
      // Ensure required fields
      if (preparedData['sender_id'] == null && preparedData['from_id'] != null) {
        preparedData['sender_id'] = preparedData['from_id'].toString();
      }
      
      if (preparedData['message'] == null && preparedData['body'] != null) {
        preparedData['message'] = preparedData['body'].toString();
      }
      
      // Determine sender name
      if (preparedData['sender_name'] == null) {
        if (preparedData['from_name'] != null) {
          preparedData['sender_name'] = preparedData['from_name'];
        } else if (preparedData['sender_id']?.toString() == _currentUserId) {
          preparedData['sender_name'] = _currentUserName ?? 'You';
        } else if (_currentContact != null) {
          preparedData['sender_name'] = _currentContact!.name;
        } else {
          preparedData['sender_name'] = 'Unknown';
        }
      }
      
      // Determine if message is from current user
      final String? senderId = preparedData['sender_id']?.toString();
      preparedData['is_from_current_user'] = senderId == _currentUserId;
      
      // Add conversation ID if missing
      if (preparedData['conversation_id'] == null && !_isGroupChat) {
        preparedData['conversation_id'] = senderId == _currentUserId ? 
            messageData['to_id']?.toString() : senderId;
      }
      
      // Handle timestamp
      if (preparedData['timestamp'] == null && preparedData['created_at'] != null) {
        preparedData['timestamp'] = preparedData['created_at'];
      }
      
      // Handle Attachment Response (List format)
      if (preparedData['attachment'] is List && (preparedData['attachment'] as List).isNotEmpty) {
        final attachmentList = preparedData['attachment'] as List;
        final attachmentName = attachmentList[0]?.toString(); // First element is filename
        
        if (attachmentName != null && attachmentName.isNotEmpty) {
          final extension = attachmentName.split('.').last.toLowerCase();
          final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
          final isPdf = ['pdf'].contains(extension);
          
          // Construct URL
          final fileUrl = 'https://sitepilot.easy2it.in/uploads/attachments/$attachmentName';
          
          // Preserve caption
          final caption = preparedData['message']?.toString();
          if (caption != null && caption.isNotEmpty) {
             preparedData['metadata'] = {
               ...(preparedData['metadata'] ?? {}),
               'caption': caption,
               'filename': attachmentName, // Store filename for PDF display
             };
          } else {
             preparedData['metadata'] = {
               ...(preparedData['metadata'] ?? {}),
               'filename': attachmentName,
             };
          }

          // Override message with URL for display
          preparedData['message'] = fileUrl;
          
          // Set message type
          preparedData['message_type'] = isImage ? 'image' : (isPdf ? 'document' : 'file');
          if (isPdf) preparedData['document_type'] = 'pdf';
        }
      }
      
      // Create ChatMessage
      final newMessage = ChatMessage.fromJson(preparedData);
      
      print("✅ Adding message to chat:");
      print("   ID: ${newMessage.id}");
      print("   Type: ${newMessage.messageType}");
      print("   Message/URL: ${newMessage.message}");
      if (newMessage.metadata?['caption'] != null) {
        print("   Caption: ${newMessage.metadata!['caption']}");
      }
      print("   Sender: ${newMessage.senderName}");
      print("   Message: ${newMessage.message}");
      print("   Is from current user: ${newMessage.isFromCurrentUser}");
      
      if (mounted) {
        setState(() {
          // Check for duplicates
          if (!_messages.any((m) => m.id == newMessage.id)) {
            // Improved deduplication logic
            final int tempIndex = _messages.indexWhere((m) {
              if (!m.id.startsWith('temp_')) return false;
              if (m.isFromCurrentUser != newMessage.isFromCurrentUser) return false;
              
              // 1. Try matching by caption if matches
              if (m.metadata?['caption'] != null && newMessage.metadata?['caption'] != null) {
                if (m.metadata!['caption'] == newMessage.metadata!['caption']) return true;
              }
              
              // 2. Try matching by filename (if server preserved it)
              if (m.metadata?['filename'] != null && newMessage.metadata?['filename'] != null) {
                 if (m.metadata!['filename'] == newMessage.metadata!['filename']) return true;
              }
              
              // 3. Try matching by local path vs URL (heuristic)
              // If both are same type and we have a temp message of this type, assume it's the one
              if (m.messageType == newMessage.messageType) {
                 return true; // Match the first pending temp message of same type
              }
              
              // 4. Default: Match by message content (for text)
              return m.message == newMessage.message;
            });
            
            if (tempIndex != -1) {
              print("🔄 Replacing temp message with real ID: ${newMessage.id}");
              _messages[tempIndex] = newMessage;
            } else {
              _messages.add(newMessage);
            }
            
            _scrollToBottom();
          }
        });
        
        // Mark as seen if not from current user
        if (!newMessage.isFromCurrentUser) {
          _markAsSeen(newMessage.id);
        }
      }
    } catch (e) {
      print("❌ Error creating ChatMessage: $e");
      // Fallback: reload messages
      final String? loadId = _isGroupChat 
          ? _currentGroup?.id 
          : _currentContact?.userId?.toString();
      if (loadId != null) _loadMessages(loadId);
    }
  }
  
  void _showNotificationForOtherChat(Map<String, dynamic> messageData) {
    print("🎯 Showing notification for other chat...");
    
    // Get sender name
    final String senderName = messageData['from_name']?.toString() ?? 
                            messageData['sender_name']?.toString() ?? 
                            'Someone';
    final String messageText = messageData['message']?.toString() ?? 
                             'New message';
    
    print("🔔 Notification: New message from $senderName: $messageText");
    
    // Show notification toast
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("💬 $senderName: $messageText"),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: const Color.fromARGB(255, 20, 30, 121),
              onPressed: () {
                // Try to find and switch to this conversation
                _switchToConversation(
                  messageData['from_id']?.toString(),
                  messageData
                );
              },
            ),
          )
        );
      });
      
      // Also show system notification
      Fluttertoast.showToast(
        msg: "💬 $senderName: $messageText",
        backgroundColor: primaryColor,
        textColor: Colors.white,
        fontSize: 14.0,
        gravity: ToastGravity.TOP,
        toastLength: Toast.LENGTH_LONG,
      );
    }
    
    // Refresh contacts list silently
    _loadContacts(silent: true);
  }

  void _switchToConversation(String? senderId, Map<String, dynamic> data) {
    if (senderId == null) return;
    
    // Find the contact
    ChatContact? contact;
    
    contact = _allContacts.firstWhere(
      (c) => c.userId?.toString() == senderId,
      orElse: () => ChatContact(
        userId: senderId,
        name: data['from_name']?.toString() ?? 
              data['sender_name']?.toString() ?? 
              'Unknown',
        email: '',
      ),
    );
    
    // Start chat with this contact
    _startChatWithContact(contact);
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    await _loadContacts();
    await _loadFavorites();
    await _checkPusherConnection(); // Check instead of initialize
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr);
        setState(() {
          _currentUserId = userData['id']?.toString();
          _currentUserName = userData['name'];
          _currentUserAvatar = userData['avatar_url'];
        });
        print("✅ Loaded user data: $_currentUserName (ID: $_currentUserId)");
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadContacts({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final String? siteId = _selectedSiteId.isNotEmpty ? _selectedSiteId : null;
      final String? workspaceIdStr = widget.workspaceId?.toString();
      
      final contactsData = await _chatService.getContacts(
        siteId: siteId,
        workspaceId: workspaceIdStr,
      );
      
      if (mounted) {
        setState(() {
          _contacts = contactsData['chats'] ?? [];
          _allContacts = contactsData['contacts'] ?? [];
        });
      }
    } catch (e) {
      if (!silent) _showError('Failed to load contacts: $e');
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFavorites() async {
    try {
      _favorites = await _chatService.getFavorites();
      setState(() {});
    } catch (e) {
      _showError('Failed to load favorites: $e');
    }
  }

  @override
  void dispose() {
    _stopPolling();
    
    // Unregister listener and clear active chat
    AppPusherManager().removeListener(_handlePusherEvent);
    AppPusherManager().setActiveChatId(null);
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isInChat && (_currentContact != null || _currentGroup != null)) {
        final conversationId = _isGroupChat 
            ? _currentGroup?.id 
            : _currentContact?.userId?.toString();
        
        if (conversationId != null) {
          _loadMessages(conversationId, isPolling: true);
        }
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _loadMessages(String? conversationId, {bool isPolling = false}) async {
    if (conversationId == null) return;

    if (!isPolling) {
      setState(() => _isLoading = true);
    }
    
    try {
      final newMessages = await _chatService.fetchMessages(conversationId);
      
      if (mounted) {
        setState(() {
          _messages = newMessages;
        });
        
        for (var message in newMessages) {
          if (!message.isFromCurrentUser && message.status != MessageStatus.seen) {
            _markAsSeen(message.id);
          }
        }
        
        if (!isPolling) {
          _scrollToBottom();
        }
      }
      
      // DO NOT subscribe to other users' channels here
      // Pusher is already listening on private-chatify channel
      
    } catch (e) {
      if (!isPolling) _showError('Failed to load messages: $e');
    } finally {
      if (!isPolling && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    
    // Check if we have content to send (text OR attachment)
    if (messageText.isEmpty && _selectedAttachment == null) return;

    // Handle attachment send
    if (_selectedAttachment != null) {
      final file = _selectedAttachment!;
      final type = _selectedAttachmentType!;
      
      // Clear selection FIRST to update UI immediately
      setState(() {
        _selectedAttachment = null;
        _selectedAttachmentType = null;
        _messageController.clear();
      });
      
      _uploadAttachment(file.path, type, message: messageText);
      return;
    }

    _messageController.clear();

    final tempMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _currentGroup?.id ?? _currentContact?.userId?.toString() ?? '',
      senderId: _currentUserId ?? 'current_user',
      senderName: _currentUserName ?? 'You',
      message: messageText,
      timestamp: DateTime.now(),
      isFromCurrentUser: true,
      messageType: MessageType.text,
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        conversationId: _currentGroup?.id ?? _currentContact?.userId?.toString() ?? '',
        message: messageText,
        type: _isGroupChat ? 'group' : 'user',
      );

      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            id: response['messageId']?.toString() ?? tempMessage.id,
            status: MessageStatus.sent,
          );
        }
      });
    } catch (e) {
      _showError('Failed to send message: $e');
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            status: MessageStatus.failed,
          );
        }
      });
    }
  }

  // ==================== ATTACHMENT METHODS ====================

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Content',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.pink,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  icon: Icons.description,
                  label: 'Document',
                  color: Colors.blue,
                  onTap: () => _pickDocument(),
                ),
              ],
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, // Optimize size
      );

      if (image != null) {
        setState(() {
          _selectedAttachment = File(image.path);
          _selectedAttachmentType = 'image';
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAttachment = File(result.files.single.path!);
          _selectedAttachmentType = 'document';
        });
      }
    } catch (e) {
      _showError('Failed to pick document: $e');
    }
  }

  Future<void> _uploadAttachment(String filePath, String type, {String? message}) async {
  final conversationId = _isGroupChat 
      ? _currentGroup?.id 
      : _currentContact?.userId?.toString();
  
  if (conversationId == null) return;

  // Create temp message for UI
  final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
  final tempMessage = ChatMessage(
    id: tempId,
    conversationId: conversationId,
    senderId: _currentUserId ?? 'current_user',
    senderName: _currentUserName ?? 'You',
    message: filePath, // For local display
    timestamp: DateTime.now(),
    isFromCurrentUser: true,
    messageType: type == 'image' ? MessageType.image : MessageType.document,
    status: MessageStatus.sending,
    metadata: {
      if (message != null && message.trim().isNotEmpty) 'caption': message,
      'filename': filePath.split('/').last,
      'local_path': filePath,
    },
  );

  setState(() {
    _messages.add(tempMessage);
  });
  _scrollToBottom();

  try {
    // IMPORTANT: Determine the correct type to send to API
    String apiType = _isGroupChat ? 'group' : 'user';
    
    final response = await _chatService.sendAttachment(
      conversationId: conversationId,
      filePath: filePath,
      type: apiType, // Send 'user' or 'group', not 'image'/'document'
      message: message, // Optional text message
    );

    print('DEBUG: Attachment upload response: $response');
    
    setState(() {
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        // If we got a real message ID from response, use it
        if (response['messageId'] != null) {
          _messages[index] = _messages[index].copyWith(
            id: response['messageId']?.toString() ?? tempId,
            status: MessageStatus.sent,
          );
        } else {
          // Keep temp ID but mark as sent
          _messages[index] = _messages[index].copyWith(
            status: MessageStatus.sent,
          );
        }
      }
    });
    
    // Refresh messages to get the real server URL
    // Use a small delay to ensure server has processed the upload
    await Future.delayed(const Duration(seconds: 1));
    await _loadMessages(conversationId, isPolling: true);
    
  } catch (e) {
    print('Upload error: $e');
    setState(() {
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: MessageStatus.failed,
        );
      }
    });
    _showError('Failed to upload attachment: $e');
  }
}
  Future<void> _markAsSeen(String messageId) async {
    try {
      await _chatService.markAsSeen(messageId);
      setState(() {
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].id == messageId && !_messages[i].isFromCurrentUser) {
            _messages[i] = _messages[i].copyWith(status: MessageStatus.seen);
          }
        }
      });
    } catch (e) {
      print('Failed to mark as seen: $e');
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      final result = await _chatService.deleteConversation(conversationId);
      if (result > 0) {
        if (_isGroupChat && _currentGroup?.id == conversationId) {
          _exitChat();
        } else if (!_isGroupChat &&
            _currentContact?.userId?.toString() == conversationId) {
          _exitChat();
        }
        _showSuccess('Conversation deleted');
      }
    } catch (e) {
      _showError('Failed to delete conversation: $e');
    }
  }

  Future<void> _updateContactItem(String userId) async {
    try {
      final result = await _chatService.updateContactItem(userId);
      if (result['contactItem'].isNotEmpty) {
        _showSuccess('Contact updated');
        _loadContacts();
      }
    } catch (e) {
      _showError('Failed to update contact: $e');
    }
  }

  void _startChatWithContact(ChatContact contact) {
    setState(() {
      _isInChat = true;
      _isGroupChat = false;
      _currentContact = contact;
      _currentGroup = null;
      _currentGroupName = null;
    });
    
    // Set active chat ID for global listener suppression
    AppPusherManager().setActiveChatId(contact.userId?.toString());
    
    _loadMessages(contact.userId?.toString());
    
    // DO NOT subscribe to other user's channels
    // Pusher is already listening on private-chatify channel
  }

  void _startChatWithGroup(dynamic group) {
    setState(() {
      _isInChat = true;
      _isGroupChat = true;
      _currentGroup = group;
      _currentGroupName = group.name;
      _currentContact = null;
    });
    
    // Set active chat ID for global listener suppression
    AppPusherManager().setActiveChatId(group.id);
    
    _loadMessages(group.id);
    
    // DO NOT subscribe to group channels
    // Pusher is already listening on private-chatify channel
  }

  void _exitChat() {
    // Clear active chat ID
    AppPusherManager().setActiveChatId(null);
    
    // DO NOT unsubscribe from channels
    // Keep Pusher connected to receive all messages
    
    setState(() {
      _isInChat = false;
      _currentContact = null;
      _currentGroup = null;
      _messages.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Test notification method
  void _testNotification() {
    print("🧪 Testing notification...");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("💬 Test User: This is a test message"),
          duration: const Duration(seconds: 4),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              print("Test notification viewed");
            },
          ),
        )
      );
      
      Fluttertoast.showToast(
        msg: "💬 Test User: This is a test message",
        backgroundColor: primaryColor,
        textColor: Colors.white,
        fontSize: 14.0,
        gravity: ToastGravity.TOP,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 80.h,
        title: _isInChat
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isGroupChat
                        ? (_currentGroupName ?? 'Group')
                        : (_currentContact?.name ?? 'Unknown'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 22.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _isGroupChat
                        ? 'Group chat'
                        : (_currentContact?.email ?? ''),
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              )
            : Text(
                'Chats',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 22.sp,
                ),
              ),
        iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.r)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4a63c0),
                  Color(0xFF3a53b0),
                  Color(0xFF2a43a0),
                ],
              ),
            ),
          ),
        ),
        bottom: _isInChat ? null : _buildTabBar(),
        actions: _buildAppBarActions(),
        leading: _isInChat ? _buildBackButton() : null,
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isInChat
          ? Column(
              children: [
                // Always show connection status when in chat
                //_buildConnectionStatus(),
                Expanded(child: _buildChatList()),
                _buildMessageInput(),
              ],
            )
          : Column(
              children: [
                // Show connection status on main chat screen too
               // _buildConnectionStatus(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChatsTab(),
                      _buildContactsTab(),
                      _buildFavoritesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(50.h),
      child: Container(
        decoration: BoxDecoration(
          border: const Border(
            bottom: BorderSide(color: Colors.white24, width: 0.5),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.white),
            insets: EdgeInsets.symmetric(horizontal: 40.0),
          ),
          indicatorWeight: 3.0,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Contacts'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isInChat) {
      return [
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () => _startCall(false),
          tooltip: 'Voice Call',
        ),
        if (_isGroupChat)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGroupInfo,
            tooltip: 'Group Info',
          ),
        if (!_isGroupChat)
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: const Text('Delete Conversation'),
              ),
              PopupMenuItem(
                value: 'clear',
                child: const Text('Clear Chat'),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _deleteConversation(_currentContact?.userId?.toString() ?? '');
              } else if (value == 'clear') {
                setState(() {
                  _messages.clear();
                });
              }
            },
          ),
      ];
    }
    return [
      IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: _showFilterOptions,
        tooltip: 'Filter',
      ),
    ];
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back), 
      onPressed: _exitChat
    );
  }

  Widget _buildChatsTab() {
    // Sort contacts by last message time
    final recentContacts = List<ChatContact>.from(_contacts);
    recentContacts.sort((a, b) {
      if (a.lastMessageTime != null && b.lastMessageTime != null) {
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      } else if (a.lastMessageTime != null) {
        return -1;
      } else if (b.lastMessageTime != null) {
        return 1;
      }
      return 0;
    });

    if (recentContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No recent chats',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () {
                _tabController.animateTo(1);
              },
              child: const Text('Start a conversation'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: recentContacts.length,
      itemBuilder: (context, index) {
        final contact = recentContacts[index];
        return _buildContactCard(contact, true);
      },
    );
  }

  Widget _buildContactCard(ChatContact contact, [bool showActions = false]) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAvatarColor(contact.name),
          backgroundImage: contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty
              ? CachedNetworkImageProvider(contact.avatarUrl!)
              : null,
          child: contact.avatarUrl == null || contact.avatarUrl!.isEmpty
              ? Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.email ?? '',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            if (showActions) SizedBox(height: 8.h),
            if (showActions)
              Row(
                children: [
                  _buildActionButton(
                    Icons.message,
                    primaryColor,
                    () => _startChatWithContact(contact),
                  ),
                  SizedBox(width: 8.w),
                  _buildActionButton(
                    Icons.call,
                    Colors.green,
                    () => _startCall(false, contact),
                  ),
                ],
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (contact.lastMessageTime != null)
              Text(
                _formatTime(contact.lastMessageTime!),
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            if (contact.isOnline ?? false)
              Container(
                width: 10.w,
                height: 10.h,
                margin: EdgeInsets.only(top: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () => _startChatWithContact(contact),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20.sp, color: color),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      primaryColor,
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.teal.shade700,
    ];
    if (name.isEmpty) return primaryColor;
    final index = name.length % colors.length;
    return colors[index];
  }

  Widget _buildContactsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: Icon(Icons.search, color: primaryColor, size: 20.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 16.w),
            itemCount: _allContacts.length,
            itemBuilder: (context, index) {
              final contact = _allContacts[index];
              if (_searchQuery != null &&
                  _searchQuery!.isNotEmpty &&
                  !contact.name.toLowerCase().contains(_searchQuery!.toLowerCase()) &&
                  !(contact.email?.toLowerCase().contains(_searchQuery!.toLowerCase()) ?? false)) {
                return const SizedBox.shrink();
              }
              return _buildContactCard(contact, false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 60.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No favorites yet',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final favorite = _favorites[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primaryColor,
            backgroundImage: favorite.avatarUrl != null
                ? CachedNetworkImageProvider(favorite.avatarUrl!)
                : null,
            child: favorite.avatarUrl == null
                ? Text(
                    favorite.name.isNotEmpty ? favorite.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          title: Text(
            favorite.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          ),
          subtitle: Text(favorite.company ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            onPressed: () => _updateContactItem(favorite.userId.toString()),
          ),
          onTap: () => _startChatWithContact(
            ChatContact(
              userId: favorite.userId.toString(),
              name: favorite.name,
              email: favorite.company,
              avatarUrl: favorite.avatarUrl,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatList() {
    return RefreshIndicator(
      onRefresh: () async {
        if (_isInChat) {
          final conversationId = _isGroupChat 
              ? _currentGroup?.id 
              : _currentContact?.userId?.toString();
          if (conversationId != null) {
            await _loadMessages(conversationId);
          }
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16.w),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          if (index == 0 ||
              _messages[index - 1].timestamp.day != message.timestamp.day) {
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDate(message.timestamp),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 8.h),
                _buildMessageBubble(message),
              ],
            );
          }
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isCurrentUser = message.isFromCurrentUser;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) SizedBox(width: 8.w),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isCurrentUser ? primaryColor : chatBubbleColor,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 
                  
                  message.messageType == MessageType.image
                      ? GestureDetector(
                          onTap: () {
                            if (message.message.startsWith('http')) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    backgroundColor: Colors.black,
                                    appBar: AppBar(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      iconTheme: const IconThemeData(color: Colors.white),
                                    ),
                                    body: Center(
                                      child: Hero(
                                        tag: message.id,
                                        child: CachedNetworkImage(
                                          imageUrl: message.message,
                                          placeholder: (context, url) => const CircularProgressIndicator(),
                                          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Hero(
                            tag: message.id,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: message.message.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: message.message,
                                      width: 200.w,
                                      placeholder: (context, url) => Container(
                                        width: 200.w,
                                        height: 200.w,
                                        color: Colors.grey[300],
                                        child: const Center(child: CircularProgressIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    )
                                  : Image.file(
                                      File(message.message),
                                      width: 200.w,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        )
                      : message.messageType == MessageType.document
                          ? InkWell(
                              onTap: () async {
                                final url = message.message;
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                } else {
                                  // Try direct open if local
                                  if (!url.startsWith('http')) {
                                    OpenFile.open(url);
                                  }
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 32.sp),
                                    SizedBox(width: 8.w),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.metadata?['filename'] ?? 'Document.pdf',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.sp,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Tap to open',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Text(
                              message.message,
                              style: TextStyle(
                                color: isCurrentUser ? Colors.white : Colors.black,
                                fontSize: 16.sp,
                              ),
                            ),
                  if ((message.messageType == MessageType.image || message.messageType == MessageType.document || message.messageType == MessageType.video) &&
                      message.metadata?['caption'] != null &&
                      message.metadata!['caption'].toString().trim().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        message.metadata!['caption'],
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.black87,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (isCurrentUser) SizedBox(width: 4.w),
                      if (isCurrentUser)
                        Icon(
                          _getMessageStatusIcon(message.status),
                          size: 12.sp,
                          color: _getMessageStatusColor(message.status),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) SizedBox(width: 8.w),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedAttachment != null) _buildAttachmentPreview(),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file, color: primaryColor, size: 24.sp),
                onPressed: _showAttachmentOptions,
                tooltip: 'Attach File',
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              SizedBox(width: 8.w),
              CircleAvatar(
                backgroundColor: primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              image: _selectedAttachmentType == 'image' && _selectedAttachment != null
                  ? DecorationImage(
                      image: FileImage(_selectedAttachment!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _selectedAttachmentType == 'document'
                ? Icon(Icons.picture_as_pdf, color: Colors.red, size: 24.sp)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedAttachmentType == 'image' ? 'Image Selected' : 'PDF Document',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
                if (_selectedAttachment != null)
                  Text(
                    _selectedAttachment!.path.split('/').last,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              setState(() {
                _selectedAttachment = null;
                _selectedAttachmentType = null;
              });
            },
          ),
        ],
      ),
    );
  }

  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.seen:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  Color _getMessageStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.grey;
      case MessageStatus.seen:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    if (timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day) {
      return 'Today';
    } else if (timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // ==================== OTHER METHODS ====================
  
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Filter Contacts',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.online_prediction, color: Colors.green),
              title: const Text('Online Only'),
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha, color: Colors.blue),
              title: const Text('Sort A-Z'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Show Favorites First'),
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupInfo() {
    if (_currentGroup == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0.w),
              child: Text(
                'Group Info',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            Expanded(
              child: _currentGroup.participants != null
                  ? ListView.builder(
                      itemCount: _currentGroup.participants.length,
                      itemBuilder: (context, index) {
                        final participant = _currentGroup.participants[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor,
                            child: Text(
                              participant.name.isNotEmpty
                                  ? participant.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(participant.name),
                          subtitle: Text(participant.company ?? ''),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'No participants',
                        style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCall(bool isVideoCall, [ChatContact? contact]) async {
    if (isVideoCall) {
      _showError('Video calls are not supported yet');
      return;
    }

    final targetContact = contact ?? _currentContact;
    final phoneNumber = targetContact?.mobileNumber;
    
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      try {
        var status = await Permission.phone.status;
        if (!status.isGranted) {
          status = await Permission.phone.request();
        }

        if (status.isGranted) {
          bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
          if (res != true) {
            _launchDialer(phoneNumber);
          }
        } else {
          _launchDialer(phoneNumber);
        }
      } catch (e) {
        print('Error making direct call: $e');
        _launchDialer(phoneNumber);
      }
    } else {
      _showError('No phone number available for ${targetContact?.name ?? 'this contact'}');
    }
  }

  Future<void> _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showError('Could not launch dialer for $phoneNumber');
    }
  }




  Future<void> _pickVideo(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: source);
      
      if (video != null) {
        _uploadFile(video.path, 'video');
      }
    } catch (e) {
      _showError('Error picking video: $e');
    }
  }


  Future<void> _uploadFile(String filePath, String type) async {
    final tempMessage = ChatMessage(
      id: 'temp_att_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _currentGroup?.id ?? _currentContact?.userId?.toString() ?? '',
      senderId: _currentUserId ?? 'current_user',
      senderName: _currentUserName ?? 'You',
      message: 'Sending ${type}...',
      timestamp: DateTime.now(),
      isFromCurrentUser: true,
      messageType: MessageType.text,
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      final conversationId = _isGroupChat 
         ? _currentGroup?.id 
         : _currentContact?.userId?.toString();
       
      if (conversationId == null) throw Exception('No conversation selected');

      await _chatService.sendAttachment(
        conversationId: conversationId,
        filePath: filePath,
        type: type,
        message: '',
      );
      
      _loadMessages(conversationId);
      
    } catch (e) {
      _showError('Failed to send attachment: $e');
      setState(() {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });
    }
  }
}