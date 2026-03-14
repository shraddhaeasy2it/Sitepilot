import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/models/user_notification_model.dart';
import 'package:ecoteam_app/contractor/services/api_ser.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:intl/intl.dart';

import '../../models/site_model.dart';

class NotificationScreen extends StatefulWidget {
  final String? siteId;
  final int? workspaceId;

  const NotificationScreen({
    super.key,
    this.siteId,
    this.workspaceId,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool get isSmallMobile => MediaQuery.of(context).size.width < 360;
  bool _isLoading = true;
  List<UserNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadApiNotifications();
  }

  Future<void> _loadApiNotifications() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<CompanySiteProvider>(context, listen: false);
      
      // Determine IDs to use
      final workspaceId = widget.workspaceId ?? int.tryParse(provider.selectedCompanyId ?? '3');
      final siteId = widget.siteId; // Can be null if generic workspace notifications

      final response = await ApiService().fetchUserNotifications(
        siteId: siteId,
        workspaceId: workspaceId,
      );
      
      if (response != null) {
        setState(() {
          _notifications = response.data.data;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatApiDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} min ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
         return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final success = await ApiService().markNotificationAsRead(notificationId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification marked as read')),
      );
      _loadApiNotifications(); // Refresh list
      // Refresh global count
      if (mounted) {
        Provider.of<CompanySiteProvider>(context, listen: false).fetchUnreadNotificationCount();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await ApiService().markAllNotificationsAsRead();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All notifications marked as read')),
      );
      _loadApiNotifications(); // Refresh list
      // Refresh global count
      if (mounted) {
        Provider.of<CompanySiteProvider>(context, listen: false).fetchUnreadNotificationCount();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all as read')),
      );
    }
  }

  void _showNotificationDetails(UserNotification userNotification, bool isDarkMode) {
    final notification = userNotification.notification;
    
    // Look up site name from provider if projectId is available
    String siteName = notification.title; // Fallback
    if (notification.projectId != null) {
      final provider = Provider.of<CompanySiteProvider>(context, listen: false);
      try {
        // Try to find site with matching ID (convert both to string to be safe)
        final site = provider.sites.firstWhere(
          (s) => s.id.toString() == notification.projectId.toString(),
          orElse: () => Site(id: '', name: '', companyId: ''),
        );
        if (site.name.isNotEmpty) {
           siteName = site.name;
        }
      } catch (e) {
        print('Error finding site name: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          child: Padding(
            padding: EdgeInsets.all(18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconForType(notification.type),
                        color: Color(0xFF4a63c0),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Color(0xFF2A2A2A),
                          ),
                        ),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey))
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  _buildDetailRow('Date',
                      _formatApiDate(userNotification.createdAt), isDarkMode),
                  SizedBox(height: 16),
                  Text(
                    'The following materials have reached their reorder level in project - $siteName:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black12 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: isDarkMode ? Colors.white : Color(0xFF2A2A2A),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (userNotification.readAt == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _markAsRead(userNotification.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4a63c0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('Mark as Read', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    if (type == 'event') return Icons.event;
    if (type == 'info') return Icons.info_outline;
    if (type == 'warning') return Icons.warning_amber_rounded;
    if (type == 'error') return Icons.error_outline;
    return Icons.notifications;
  }

  Widget _buildNotEmptyState() { // Not used but good to keep structure
    return SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isSmallMobile ? 70 : 80,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF4a63c0),
                    Color(0xFF3a53b0),
                    Color(0xFF2a43a0),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
              ),
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadApiNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        color: isDarkMode
            ? Color(0xFF121212)
            : Color.fromARGB(255, 254, 254, 255),
        child: Column(
          children: [
            if (!_isLoading && _notifications.any((n) => n.readAt == null))
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _markAllAsRead,
                      icon: Icon(Icons.done_all, size: 18, color: Color(0xFF4a63c0)),
                      label: Text('Mark all as read',
                          style: TextStyle(
                              color: Color(0xFF4a63c0),
                              fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Color(0xFF4a63c0).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? _buildEmptyState(isDarkMode)
                      : ListView.builder(
                          padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationCard(
                              _notifications[index],
                              isDarkMode,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    UserNotification userNotification,
    bool isDarkMode,
  ) {
    final notification = userNotification.notification;
    final isRead = userNotification.readAt != null;

    return GestureDetector(
      onTap: () => _showNotificationDetails(userNotification, isDarkMode),
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallMobile ? 10 : 12),
        padding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 12 : 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(isSmallMobile ? 12 : 14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
          border: isRead ? null : Border.all(color: Color.fromARGB(255, 165, 171, 194), width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF4a63c0).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForType(notification.type),
                    color: Color(0xFF4a63c0),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Color(0xFF2A2A2A),
                        ),
                      ),
                      Text(
                        notification.type,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  IconButton(
                    icon: Icon(Icons.mark_email_read, color: Color(0xFF4a63c0)),
                    tooltip: 'Mark as Read',
                    onPressed: () => _markAsRead(userNotification.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallMobile ? 20 : 24),
            decoration: BoxDecoration(
              color: Color(0xFF4a63c0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: isSmallMobile ? 40 : 48,
              color: Color(0xFF4a63c0),
            ),
          ),
          SizedBox(height: isSmallMobile ? 20 : 24),
          Text(
            "No Notifications",
            style: TextStyle(
              fontSize: isSmallMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Color(0xFF2A2A2A),
            ),
          ),
        ],
      ),
    );
  }
}
