
class UserNotificationResponse {
  final String status;
  final NotificationDataPagination data;

  UserNotificationResponse({required this.status, required this.data});

  factory UserNotificationResponse.fromJson(Map<String, dynamic> json) {
    return UserNotificationResponse(
      status: json['status'],
      data: NotificationDataPagination.fromJson(json['data']),
    );
  }
}

class NotificationDataPagination {
  final int currentPage;
  final List<UserNotification> data;

  NotificationDataPagination({required this.currentPage, required this.data});

  factory NotificationDataPagination.fromJson(Map<String, dynamic> json) {
    return NotificationDataPagination(
      currentPage: json['current_page'],
      data: (json['data'] as List)
          .map((i) => UserNotification.fromJson(i))
          .toList(),
    );
  }
}

class UserNotification {
  final int id;
  final int notificationId;
  final int userId;
  final String? readAt;
  final String createdAt;
  final NotificationDetails notification;

  UserNotification({
    required this.id,
    required this.notificationId,
    required this.userId,
    this.readAt,
    required this.createdAt,
    required this.notification,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      notificationId: json['notification_id'],
      userId: json['user_id'],
      readAt: json['read_at'],
      createdAt: json['created_at'],
      notification: NotificationDetails.fromJson(json['notification']),
    );
  }
  
  // Helper to check if read
  bool get isRead => readAt != null;
}

class NotificationDetails {
  final int id;
  final int? workspaceId;
  final int? projectId;
  final String type;
  final String title;
  final String message;
  final String iconType;
  final int? relatedId;
  final String? relatedType;
  final String? actionUrl;
  final String createdAt;

  NotificationDetails({
    required this.id,
    this.workspaceId,
    this.projectId,
    required this.type,
    required this.title,
    required this.message,
    required this.iconType,
    this.relatedId,
    this.relatedType,
    this.actionUrl,
    required this.createdAt,
  });

  factory NotificationDetails.fromJson(Map<String, dynamic> json) {
    String messageContent = '';
    
    // Parse message_arr first as requested
    if (json['message_arr'] != null) {
      try {
        final messageArr = json['message_arr'];
        if (messageArr is Map) {
          final buffer = StringBuffer();
          final sortedKeys = messageArr.keys.toList()..sort();
          
          for (var key in sortedKeys) {
            final item = messageArr[key];
            if (item is Map) {
              final name = item['material_name'] ?? 'Material';
              final qty = item['total_qty'] ?? 0;
              final reorder = item['reorder_level'] ?? 0;
              buffer.writeln('$name: Qty $qty (Reorder: $reorder)');
            }
          }
          messageContent = buffer.toString().trim();
        } else if (messageArr is List) {
           final buffer = StringBuffer();
           for (var item in messageArr) {
             if (item is Map) {
                final name = item['material_name'] ?? 'Material';
                final qty = item['total_qty'] ?? 0;
                final reorder = item['reorder_level'] ?? 0;
                buffer.writeln('$name: Qty $qty (Reorder: $reorder)');
             }
           }
           messageContent = buffer.toString().trim();
        }
      } catch (e) {
        print('Error parsing message_arr: $e');
      }
    }

    // Fallback to 'message' if message_arr was missing or empty
    if (messageContent.isEmpty) {
      messageContent = json['message'] ?? '';
    }

    return NotificationDetails(
      id: json['id'],
      workspaceId: json['workspace_id'],
      projectId: json['project_id'],
      type: json['type'] ?? 'info',
      title: json['title'] ?? 'Notification',
      message: messageContent,
      iconType: json['icon_type'] ?? 'info',
      relatedId: json['related_id'],
      relatedType: json['related_type'],
      actionUrl: json['action_url'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
