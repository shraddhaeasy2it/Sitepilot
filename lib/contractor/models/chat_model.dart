import 'dart:convert';

class ChatContact {
  final String? userId;
  final String name;
  final String? email;
  final String? company;
  final String? avatarUrl;
  final String? mobileNumber; // Add this field
  final bool? isOnline;
  final DateTime? lastSeen;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int? unreadCount;

  ChatContact({
    this.userId,
    required this.name,
    this.email,
    this.company,
    this.avatarUrl,
    this.mobileNumber,
    this.isOnline,
    this.lastSeen,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      userId: json['id']?.toString(),
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
      company: json['company']?.toString(),
      avatarUrl: json['avatar'] != null && json['avatar'].toString().isNotEmpty
          ? (json['avatar'].toString().startsWith('http')
              ? json['avatar'].toString()
              : 'https://sitepilot.easy2it.in/${json['avatar']}')
          : null,
      mobileNumber: json['mobile_no']?.toString(), // Parse from API
      isOnline: json['is_active'] == true || json['is_active'] == 1,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'].toString())
          : null,
      lastMessage: json['last_message']?.toString(),
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'].toString())
          : null,
      unreadCount: json['unread_count'] != null
          ? int.tryParse(json['unread_count'].toString())
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'name': name,
      'email': email,
      'company': company,
      'avatar': avatarUrl,
      'is_active': isOnline ?? false,
      'last_seen': lastSeen?.toIso8601String(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
    };
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isFromCurrentUser;
  final MessageType messageType;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;
  final String? documentType; // Add this field
  final String? fileSize; // Add this field

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isFromCurrentUser,
    this.messageType = MessageType.text,
    this.status = MessageStatus.sent,
    this.metadata,
    this.documentType,
    this.fileSize,
  });

  // Update fromJson method
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Determine message type
    MessageType type = MessageType.text;
    if (json['message_type'] != null) {
      final typeStr = json['message_type'].toString().toLowerCase();
      type = MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => MessageType.text,
      );
    }
    
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'Unknown',
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isFromCurrentUser: json['is_from_current_user'] ?? false,
      messageType: type,
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status']?.toString() ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      documentType: json['document_type']?.toString(),
      fileSize: json['file_size']?.toString(),
    );
  }

  // Update copyWith method
  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? message,
    DateTime? timestamp,
    bool? isFromCurrentUser,
    MessageType? messageType,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
    String? documentType,
    String? fileSize,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      documentType: documentType ?? this.documentType,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}

class ChatGroup {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final List<ChatParticipant>? participants;
  final DateTime? createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  ChatGroup({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.participants,
    this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    return ChatGroup(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Group',
      description: json['description']?.toString(),
      avatarUrl: json['avatar_url'] != null && json['avatar_url'].toString().isNotEmpty
          ? (json['avatar_url'].toString().startsWith('http')
              ? json['avatar_url'].toString()
              : 'https://sitepilot.easy2it.in/${json['avatar_url']}')
          : null,
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => ChatParticipant.fromJson(p))
              .toList()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      lastMessage: json['last_message']?.toString(),
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'participants': participants?.map((p) => p.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
    };
  }
}

class ChatParticipant {
  final String id;
  final String name;
  final String? company;
  final String? avatarUrl;
  final bool isOnline;

  ChatParticipant({
    required this.id,
    required this.name,
    this.company,
    this.avatarUrl,
    this.isOnline = false,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      company: json['company']?.toString(),
      avatarUrl: json['avatar_url'] != null && json['avatar_url'].toString().isNotEmpty
          ? (json['avatar_url'].toString().startsWith('http')
              ? json['avatar_url'].toString()
              : 'https://sitepilot.easy2it.in/${json['avatar_url']}')
          : null,
      isOnline: json['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
    };
  }
}

class ChatFavorite {
  final int userId;
  final String name;
  final String? company;
  final String? avatarUrl;

  ChatFavorite({
    required this.userId,
    required this.name,
    this.company,
    this.avatarUrl,
  });

  factory ChatFavorite.fromJson(Map<String, dynamic> json) {
    return ChatFavorite(
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      company: json['company']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'company': company,
      'avatar_url': avatarUrl,
    };
  }
}

enum MessageType {
  text,
  image,
  video,
  document,
  audio,
  location,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  seen,
  failed,
}

class ChatResponse {
  final bool success;
  final dynamic data;
  final String? error;

  ChatResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      success: json['success'] ?? false,
      data: json['data'],
      error: json['error']?.toString(),
    );
  }
}