import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/models/birthday_model.dart';
import 'package:ecoteam_app/models/meeting_model.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late MeetingProvider _meetingProvider;
  // Computed property to determine if it's a small mobile device
  bool get isSmallMobile => MediaQuery.of(context).size.width < 360;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addBirthdayNotifications();
      _addMeetingNotifications();
    });
  }

  void _addBirthdayNotifications() {
    final birthdayProvider = Provider.of<BirthdayProvider>(
      context,
      listen: false,
    );
    final todaysBirthdays = birthdayProvider.todaysBirthdays;
    final upcomingBirthdays = birthdayProvider.upcomingBirthdays;

    // Add today's birthdays
    for (var birthday in todaysBirthdays) {
      notifications.add({
        'title': 'Happy Birthday ${birthday.name}!',
        'subtitle':
            'Today is ${birthday.name}\'s birthday. Don\'t forget to wish them!',
        'time': 'Today',
        'isRead': false,
        'type': 'birthday',
        'icon': Icons.cake,
      });
    }

    // Add upcoming birthdays
    for (var birthday in upcomingBirthdays) {
      notifications.add({
        'title': 'Birthday Reminder: ${birthday.name}',
        'subtitle':
            'Birthday on ${DateFormat('MMM dd').format(birthday.date)} (${birthday.daysUntilBirthday} days left)',
        'time': '${birthday.daysUntilBirthday} days left',
        'isRead': false,
        'type': 'birthday',
        'icon': Icons.cake,
      });
    }

    setState(() {});
  }

  void _addMeetingNotifications() {
    final meetingProvider = Provider.of<MeetingProvider>(
      context,
      listen: false,
    );
    final upcomingMeetings = meetingProvider.upcomingMeetings;

    // Add upcoming meetings
    for (var meeting in upcomingMeetings) {
      notifications.add({
        'title': 'Meeting Reminder',
        'subtitle':
            '${meeting.organizerCompany} wants a meeting with ${meeting.invitedWorkerCompanies}\n${meeting.title} – Scheduled at ${DateFormat('MMM dd, yyyy hh:mm a').format(meeting.dateTime)}',
        'time': _formatMeetingTime(meeting.dateTime),
        'isRead': false,
        'type': 'meeting',
        'icon': Icons.calendar_today,
      });
    }

    setState(() {});
  }

  String _formatMeetingTime(DateTime meetingTime) {
    final now = DateTime.now();
    final difference = meetingTime.difference(now);

    if (difference.isNegative) {
      return 'Past due';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes left';
    } else {
      return 'Now';
    }
  }

  // Notification filter options
  final List<String> filterOptions = [
    'All',
    'Unread',
    'Meeting',
    'Birthday',
    'Documents',
    
    
  ];
  String selectedFilter = 'All';

  // Sample notifications data
  List<Map<String, dynamic>> notifications = [
    {
      'title': 'New Document Added',
      'subtitle': 'A new document has been added to Project Alpha',
      'time': '2 min ago',
      'isRead': false,
      'type': 'document',
      'icon': Icons.edit_document,
    },
    {
      'title': 'Folder Created',
      'subtitle': 'You created a new folder "Design Documents"',
      'time': '1 hour ago',
      'isRead': true,
      'type': 'folder',
      'icon': Icons.folder,
    },
    {
      'title': 'Document Shared',
      'subtitle': 'John shared a document with you',
      'time': '3 hours ago',
      'isRead': true,
      'type': 'share',
      'icon': Icons.share,
    },

    {
      'title': 'New Comment',
      'subtitle': 'Sarah commented on your design proposal',
      'time': '5 min ago',
      'isRead': false,
      'type': 'comment',
      'icon': Icons.message_sharp,
    },
  ];

  // Filter notifications based on selected filter
  List<Map<String, dynamic>> get filteredNotifications {
    if (selectedFilter == 'All') return notifications;
    if (selectedFilter == 'Unread') {
      return notifications.where((n) => !n['isRead']).toList();
    }
    return notifications
        .where((n) => n['type'] == selectedFilter.toLowerCase())
        .toList();
  }

  // Mark all notifications as read
  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification['isRead'] = true;
      }
    });

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Clear all notifications
  void _clearAllNotifications() {
    setState(() {
      notifications.clear();
    });

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications cleared'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateMeetingNotifications(MeetingProvider meetingProvider) {
    // Remove existing meeting notifications
    notifications.removeWhere((n) => n['type'] == 'meeting');

    // Add current meeting notifications
    final upcomingMeetings = meetingProvider.upcomingMeetings;
    for (var meeting in upcomingMeetings) {
      final timeUntil = meeting.dateTime.difference(DateTime.now());
      String timeText;
      if (timeUntil.inDays > 0) {
        timeText = '${timeUntil.inDays} days left';
      } else if (timeUntil.inHours > 0) {
        timeText = '${timeUntil.inHours} hours left';
      } else {
        timeText = '${timeUntil.inMinutes} minutes left';
      }

      String invitedText;
      if (meeting.invitedWorkerNames.length == 1) {
        invitedText =
            '${meeting.invitedWorkerNames.first} (${meeting.invitedWorkerCompanies.first})';
      } else {
        // Group workers by company
        Map<String, int> companyWorkerCount = {};
        for (int i = 0; i < meeting.invitedWorkerCompanies.length; i++) {
          String company = meeting.invitedWorkerCompanies[i];
          companyWorkerCount[company] = (companyWorkerCount[company] ?? 0) + 1;
        }

        if (companyWorkerCount.length == 1) {
          // All workers from same company
          String company = companyWorkerCount.keys.first;
          int workerCount = companyWorkerCount[company]!;
          invitedText = '$company wants meeting with $workerCount workers';
        } else {
          // Workers from multiple companies
          invitedText =
              '${meeting.invitedWorkerNames.length} workers from ${companyWorkerCount.length} companies';
        }
      }

      notifications.add({
        'title': 'New Meeting Scheduled',
        'subtitle':
            '${meeting.organizerCompany} wants a meeting with ${meeting.invitedCompany} at ${meeting.siteName}\n${meeting.title} – Scheduled at ${DateFormat('MMM dd, yyyy hh:mm a').format(meeting.dateTime)}',
        'time': timeText,
        'isRead': false,
        'type': 'meeting',
        'icon': Icons.calendar_today,
        'meeting': meeting,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
          if (notifications.isNotEmpty &&
              notifications.any((n) => !n['isRead']))
            IconButton(
              icon: Badge(
                smallSize: 8,
                backgroundColor: Colors.amber,
                child: Icon(Icons.mark_chat_read, color: Colors.white),
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          if (notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_rounded, color: Colors.white),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear all notifications',
            ),
        ],
      ),
      body: Consumer<MeetingProvider>(
        builder: (context, meetingProvider, child) {
          _updateMeetingNotifications(meetingProvider);
          return Container(
            color: isDarkMode
                ? Color(0xFF121212)
                : Color.fromARGB(255, 254, 254, 255),
            child: Column(
              children: [
                // Filter chips
                if (notifications.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filterOptions.map((filter) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(filter),
                              selected: selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() {
                                  selectedFilter = selected ? filter : 'All';
                                });
                              },
                              backgroundColor: isDarkMode
                                  ? Color(0xFF2A2A2A)
                                  : Color(0xFFf1f3f5),
                              selectedColor: Color(0xFF4a63c0).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: selectedFilter == filter
                                    ? Color(0xFF4a63c0)
                                    : isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                              checkmarkColor: Color(0xFF4a63c0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Notifications list or empty state
                Expanded(
                  child: notifications.isEmpty
                      ? _buildEmptyState(isDarkMode)
                      : filteredNotifications.isEmpty
                      ? _buildNoFilterResults(isDarkMode)
                      : ListView.builder(
                          padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            return _buildNotificationCard(
                              notification,
                              isDarkMode,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    bool isDarkMode,
  ) {
    return Dismissible(
      key: Key(notification['title']),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (direction) {
        setState(() {
          notifications.remove(notification);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification removed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallMobile ? 10 : 12),
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
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 16 : 20,
            vertical: isSmallMobile ? 12 : 16,
          ),
          leading: Container(
            width: isSmallMobile ? 40 : 48,
            height: isSmallMobile ? 40 : 48,
            decoration: BoxDecoration(
              color: notification['isRead']
                  ? Color(0xFF4a63c0).withOpacity(0.1)
                  : Color(0xFF4a63c0).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification['icon'],
              color: notification['isRead']
                  ? Color(0xFF4a63c0)
                  : Color(0xFF3a53b0),
              size: isSmallMobile ? 20 : 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallMobile ? 14 : 16,
                    color: isDarkMode ? Colors.white : Color(0xFF2A2A2A),
                  ),
                ),
              ),
              if (!notification['isRead'])
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF4a63c0),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                notification['subtitle'],
                style: TextStyle(
                  fontSize: isSmallMobile ? 12 : 14,
                  color: isDarkMode ? Colors.white70 : Color(0xFF6C757D),
                ),
              ),
              SizedBox(height: 8),
              Text(
                notification['time'],
                style: TextStyle(
                  fontSize: isSmallMobile ? 10 : 12,
                  color: isDarkMode ? Colors.white54 : Color(0xFFADB5BD),
                ),
              ),
            ],
          ),
          onTap: () {
            // Mark as read when tapped
            setState(() {
              notification['isRead'] = true;
            });
          },
          onLongPress: () {
            // Show options on long press
            showModalBottomSheet(
              context: context,
              backgroundColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                return Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(
                          notification['isRead']
                              ? Icons.remove_red_eye
                              : Icons.remove_red_eye_outlined,
                          color: Color(0xFF4a63c0),
                        ),
                        title: Text(
                          notification['isRead']
                              ? 'Mark as unread'
                              : 'Mark as read',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            notification['isRead'] = !notification['isRead'];
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          setState(() {
                            notifications.remove(notification);
                          });
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Notification removed'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
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
              Icons.notifications,
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
          SizedBox(height: isSmallMobile ? 6 : 8),
          Text(
            "You're all caught up! Check back later for updates",
            style: TextStyle(
              fontSize: isSmallMobile ? 12 : 14,
              color: isDarkMode ? Colors.white70 : Color(0xFF6C757D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResults(bool isDarkMode) {
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
              Icons.search,
              size: isSmallMobile ? 40 : 48,
              color: Color(0xFF4a63c0),
            ),
          ),
          SizedBox(height: isSmallMobile ? 20 : 24),
          Text(
            "No Matching Notifications",
            style: TextStyle(
              fontSize: isSmallMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Color(0xFF2A2A2A),
            ),
          ),
          SizedBox(height: isSmallMobile ? 6 : 8),
          Text(
            "Try changing your filter settings to see more notifications",
            style: TextStyle(
              fontSize: isSmallMobile ? 12 : 14,
              color: isDarkMode ? Colors.white70 : Color(0xFF6C757D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
