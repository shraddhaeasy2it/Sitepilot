// activity_screen.dart
import 'dart:convert';
import 'package:ecoteam_app/contractor/provider/activity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/profilepage.dart';

class ActivityScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final int userId;
  final int workspaceId;
  final String token;
  final String? currentCompany;

  const ActivityScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    required this.userId,
    required this.workspaceId,
    required this.token,
    this.currentCompany,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late ActivityProvider _activityProvider;
  bool _isLoading = false;
  List<Workspace> _workspaces = [];
  List<ApiSite> _apiSites = [];
  List<String> _priorities = [];

  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color backgroundColor = Color.fromARGB(255, 249, 249, 253);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      // Fetch activities
      await _activityProvider.fetchActivities();

      // Fetch create form data
      final createData = await ActivityApiService.fetchCreateData({
        'site_id': int.tryParse(widget.selectedSiteId ?? '') ?? 0,
        'workspace_id': widget.workspaceId,
        'created_by': widget.userId,
      });

      if (createData['success'] == true) {
        setState(() {
          _workspaces = (createData['workspaces'] as List)
              .map((json) => Workspace.fromJson(json))
              .toList();
          _apiSites = (createData['sites'] as List)
              .map((json) => ApiSite.fromJson(json))
              .toList();
          _priorities = (createData['priorities'] as List).cast<String>();
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh data'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCurrentSiteName() {
    if (widget.selectedSiteId == null) {
      return 'All Sites';
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () => Site(id: '', name: 'Unknown Site', companyId: ''),
    );
    return site.name;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 74.h,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Activity Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Site: ${_getCurrentSiteName()}",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen()),
                );
              },
              child: const FaIcon(FontAwesomeIcons.bell, size: 20),
            ),
            const SizedBox(width: 5),
            IconButton(
              tooltip: 'Chat',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      selectedSiteId: widget.selectedSiteId,
                      onSiteChanged: (String siteId) {
                        debugPrint('Site changed to: $siteId');
                      },
                      sites: widget.sites,
                      currentCompany: widget.currentCompany,
                      workspaceId: widget.workspaceId,
                    ),
                  ),
                );
              },
              icon: const FaIcon(FontAwesomeIcons.commentDots, size: 20),
              color: Colors.white,
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
            ),
            tabs: const [
              Tab(text: "Pending"),
              Tab(text: "Completed"),
            ],
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddActivityBottomSheet(context),
          backgroundColor: const Color.fromRGBO(42, 67, 160, 1),
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Add Activity',
        ),
        body: _isLoading
            ? _buildLoadingState()
            : TabBarView(
                children: [
                  _buildActivityList(pending: true),
                  _buildActivityList(pending: false),
                ],
              ),
      ),
    );
  }

  Widget _buildActivityList({required bool pending}) {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        if (activityProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFF4a63c0)),
          );
        }

        if (activityProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                SizedBox(height: 8.h),
                Text(
                  'Error loading activities',
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () async {
                    await activityProvider.fetchActivities();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4a63c0),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final activities = pending
            ? activityProvider.pendingActivities
            : activityProvider.completedActivities;

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  pending ? Icons.check_circle_outline : Icons.task_alt,
                  color: Colors.grey,
                  size: 48.sp,
                ),
                SizedBox(height: 16.h),
                Text(
                  pending
                      ? 'No pending activities'
                      : 'No completed activities yet',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Tap + button to add new activity',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await activityProvider.fetchActivities();
          },
          color: const Color(0xFF4a63c0),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            itemCount: activities.length,
            separatorBuilder: (context, index) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityCard(activity, !pending);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4a63c0)),
          SizedBox(height: 16.h),
          Text('Loading activities...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity, bool completed) {
    IconData getIconForActivity() {
      switch (activity.priority) {
        case 'high':
          return Icons.warning;
        case 'medium':
          return Icons.timeline;
        case 'low':
          return Icons.low_priority;
        default:
          return Icons.task;
      }
    }

    Color getColorForActivity() {
      switch (activity.priority) {
        case 'high':
          return Colors.red;
        case 'medium':
          return Colors.orange;
        case 'low':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12.r,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: Colors.grey.shade50, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: getColorForActivity().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      getIconForActivity(),
                      color: getColorForActivity(),
                      size: 17.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Title and Scope
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.sp,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  IconButton(
                    onPressed: () => _showOptionsBottomSheet(context, activity),
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Progress and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _showQuickQuantityEditDialog(context, activity),
                        child: Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                getColorForActivity().withOpacity(0.15),
                                getColorForActivity().withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 40.w,
                                height: 40.w,
                                child: CircularProgressIndicator(
                                  value: activity.progressPercentage,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    getColorForActivity(),
                                  ),
                                  strokeWidth: 3.w,
                                ),
                              ),
                              Text(
                                '${(activity.progressPercentage * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: getColorForActivity(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${activity.completedQuantity}/${activity.quantity} ${activity.unit}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 64, 77, 95),
                            ),
                          ),
                          Text(
                            '${activity.balanceQuantity} ${activity.unit} remaining',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, Activity activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.visibility_outlined,
              title: 'View Full Details',
              Iconcolor: const Color.fromARGB(255, 37, 49, 158),
              backgroundColor: const Color.fromARGB(
                255,
                37,
                49,
                158,
              ).withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                _showActivityDetailsBottomSheet(context, activity);
              },
            ),

            _buildOptionTile(
              icon: Icons.edit_outlined,
              title: 'Edit Machinery',
              Iconcolor: Colors.blue,
              backgroundColor: Colors.blue.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                _showAddActivityBottomSheet(context);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline,
              title: 'Delete Machinery',
              color: Colors.red,
              Iconcolor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 200), () {
                  _showDeleteConfirmationDialog(context, activity);
                });
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color Iconcolor,
    required String title,
    Color? backgroundColor,
    required VoidCallback onTap,
    Color color = textPrimary,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Iconcolor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showActivityDetailsBottomSheet(
    BuildContext context,
    Activity activity,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600 || screenWidth < 400;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * (isSmallScreen ? 0.85 : 0.75),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: isSmallScreen ? 0.85 : 0.65,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 25.r,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.blue.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32.r),
                        ),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8.r,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.task,
                                  color: Colors.blue,
                                  size: 32.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.title,
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: activity.isCompleted
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Text(
                                        activity.isCompleted
                                            ? 'COMPLETED'
                                            : 'PENDING',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                          color: activity.isCompleted
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 20.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Progress Section
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        color: Colors.blue,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Progress',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  Row(
                                    children: [
                                      Container(
                                        width: 60.w,
                                        height: 60.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade100,
                                              Colors.blue.shade50,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 50.w,
                                              height: 50.h,
                                              child: CircularProgressIndicator(
                                                value:
                                                    activity.progressPercentage,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.blue),
                                                strokeWidth: 3.w,
                                              ),
                                            ),
                                            Text(
                                              '${(activity.progressPercentage * 100).round()}%',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${activity.completedQuantity}/${activity.quantity} ${activity.unit}',
                                              style: TextStyle(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              '${activity.balanceQuantity} ${activity.unit} remaining',
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
                                ],
                              ),
                            ),

                            SizedBox(height: 20.h),

                            // Details Section
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 8.r,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Details',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  _buildDetailRow('Scope:', activity.scope),
                                  _buildDetailRow(
                                    'Priority:',
                                    activity.priority.toUpperCase(),
                                  ),
                                  _buildDetailRow(
                                    'Status:',
                                    activity.isCompleted
                                        ? 'Completed'
                                        : 'Pending',
                                  ),
                                  _buildDetailRow(
                                    'Created:',
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(activity.createdAt),
                                  ),
                                  _buildDetailRow(
                                    'Last Updated:',
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(activity.updatedAt),
                                  ),
                                ],
                              ),
                            ),

                            if (activity.completions.isNotEmpty) ...[
                              SizedBox(height: 20.h),
                              Container(
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade100,
                                      blurRadius: 8.r,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.history,
                                          color: Colors.grey[600],
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Update History',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                    ...activity.completions
                                        .map(
                                          (completion) => Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 12.h,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 16.sp,
                                                ),
                                                SizedBox(width: 12.w),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${completion.completedQuantity} ${activity.unit} completed',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Text(
                                                        DateFormat(
                                                          'MMM dd, yyyy',
                                                        ).format(
                                                          completion.createdAt,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 12.sp,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddActivityBottomSheet(
    BuildContext context, {
    Activity? existingActivity,
  }) {
    final isEditing = existingActivity != null;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final isSmallScreen = screenHeight < 600 || screenWidth < 400;

    final titleController = TextEditingController(
      text: existingActivity?.title ?? '',
    );
    final scopeController = TextEditingController(
      text: existingActivity?.scope ?? '',
    );
    final quantityController = TextEditingController(
      text: existingActivity?.quantity.toString() ?? '',
    );
    final unitController = TextEditingController(
      text: existingActivity?.unit ?? '',
    );
    final completedQuantityController = TextEditingController(
      text: existingActivity?.completedQuantity.toString() ?? '0',
    );

    String? selectedPriority =
        existingActivity?.priority ?? _priorities.firstOrNull;
    int? selectedWorkspaceId =
        existingActivity?.workspaceId ?? widget.workspaceId;
    int? selectedSiteId =
        existingActivity?.siteId ??
        (widget.selectedSiteId != null
            ? int.tryParse(widget.selectedSiteId!)
            : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight:
              screenHeight *
              (isKeyboardOpen ? 0.98 : (isSmallScreen ? 0.75 : 0.85)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: isKeyboardOpen ? 0.95 : (isSmallScreen ? 0.9 : 0.7),
          minChildSize: isKeyboardOpen ? 0.9 : (isSmallScreen ? 0.9 : 0.8),
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20.r,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 24.h,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Icon(
                                isEditing ? Icons.edit : Icons.add_task,
                                color: Color(0xFF4a63c0),
                                size: 28.sp,
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Text(
                                  isEditing
                                      ? 'Edit Activity'
                                      : 'Add New Activity',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32.h),
                          Flexible(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: titleController,
                                    decoration: InputDecoration(
                                      labelText: 'Activity Title',
                                      hintText: 'e.g. Foundation Work',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 214, 215, 216),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 189, 190, 197), // Different color when focused
                                          width: 1.0,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.title,
                                        color: Color(0xFF4a63c0),
                                        size: 20.sp,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),

                                  TextField(
                                    controller: scopeController,
                                    decoration: InputDecoration(
                                      labelText: 'Scope',
                                      hintText:
                                          'e.g. Foundation work for building A',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                       enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 214, 215, 216),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 189, 190, 197), // Different color when focused
                                          width: 1.0,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.description,
                                        color: Color(0xFF4a63c0),
                                        size: 20.sp,
                                      ),
                                    ),
                                    maxLines: 2,
                                  ),
                                  SizedBox(height: 12.h),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: quantityController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Quantity',
                                            hintText: 'e.g. 100',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 2,
                                                ),
                                                 enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 214, 215, 216),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 189, 190, 197), // Different color when focused
                                          width: 1.0,
                                        ),
                                      ),
                                            prefixIcon: Icon(
                                              Icons.numbers,
                                              color: Color(0xFF4a63c0),
                                              size: 20.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: TextField(
                                          controller: unitController,
                                          decoration: InputDecoration(
                                            labelText: 'Unit',
                                            hintText: 'e.g. sq ft, tons',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 2,
                                                ),
                                                 enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 214, 215, 216),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 189, 190, 197), // Different color when focused
                                          width: 1.0,
                                        ),
                                      ),
                                            prefixIcon: Icon(
                                              Icons.straighten,
                                              color: Color(0xFF4a63c0),
                                              size: 20.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),

                                  TextField(
                                    controller: completedQuantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Completed Quantity',
                                      hintText: 'e.g. 85',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                       enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 214, 215, 216),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 189, 190, 197), // Different color when focused
                                          width: 1.0,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF4a63c0),
                                        size: 20.sp,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),

                                  StatefulBuilder(
                                    builder: (context, setBalanceState) {
                                      final quantity =
                                          int.tryParse(
                                            quantityController.text,
                                          ) ??
                                          0;
                                      final completed =
                                          int.tryParse(
                                            completedQuantityController.text,
                                          ) ??
                                          0;
                                      final balance = quantity - completed;
                                      return Text(
                                        'Balance Quantity: $balance',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: balance >= 0
                                              ? const Color.fromARGB(
                                                  255,
                                                  62,
                                                  150,
                                                  65,
                                                )
                                              : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 16.h),

                                  // Priority Dropdown
                                  DropdownButtonFormField<String>(
                                    value: selectedPriority,
                                    decoration: InputDecoration(
                                      labelText: 'Priority',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                       enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 214, 215, 216),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(255, 189, 190, 197), // Different color when focused
                                          width: 1.0,
                                        ),
                                      ),
                                      prefixIcon: Icon(Icons.flag, size: 20.sp),
                                    ),
                                    items: _priorities.map((priority) {
                                      return DropdownMenuItem<String>(
                                        value: priority,
                                        child: Text(priority.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setSheetState(
                                          () => selectedPriority = value,
                                        );
                                      }
                                    },
                                    validator: (value) => value == null
                                        ? 'Please select a priority'
                                        : null,
                                  ),
                                  SizedBox(height: 24.h),

                                  Container(
                                    height: 56.h,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6f88e2),
                                          Color(0xFF4a63c0),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(
                                            0xFF4a63c0,
                                          ).withOpacity(0.3),
                                          blurRadius: 12.r,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                        ),
                                      ),
                                      icon: Icon(
                                        isEditing ? Icons.update : Icons.add,
                                        color: Colors.white,
                                        size: 22.sp,
                                      ),
                                      label: Text(
                                        isEditing
                                            ? 'Update Activity'
                                            : 'Add Activity',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: () async {
                                        // Validate required fields
                                        if (titleController.text
                                                .trim()
                                                .isEmpty ||
                                            scopeController.text
                                                .trim()
                                                .isEmpty ||
                                            quantityController.text
                                                .trim()
                                                .isEmpty ||
                                            unitController.text
                                                .trim()
                                                .isEmpty ||
                                            selectedPriority == null ||
                                            selectedWorkspaceId == null ||
                                            selectedSiteId == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Please fill all required fields',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        final quantity =
                                            int.tryParse(
                                              quantityController.text,
                                            ) ??
                                            0;
                                        final completedQuantity =
                                            int.tryParse(
                                              completedQuantityController.text,
                                            ) ??
                                            0;

                                        final activity = Activity(
                                          id: existingActivity?.id ?? 0,
                                          title: titleController.text.trim(),
                                          scope: scopeController.text.trim(),
                                          quantity: quantity,
                                          unit: unitController.text.trim(),
                                          completedQuantity: completedQuantity,
                                          priority: selectedPriority!,
                                          status: existingActivity?.status ?? 0,
                                          createdBy: widget.userId,
                                          workspaceId: selectedWorkspaceId!,
                                          siteId: selectedSiteId!,
                                          createdAt:
                                              existingActivity?.createdAt ??
                                              DateTime.now(),
                                          completions:
                                              existingActivity?.completions,
                                          updatedAt: DateTime.now(),
                                        );

                                        final activityProvider =
                                            Provider.of<ActivityProvider>(
                                              context,
                                              listen: false,
                                            );

                                        // Show loading indicator
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.green,
                                            content: Row(
                                              children: [
                                                Text(
                                                  isEditing
                                                      ? 'Updating activity...'
                                                      : 'Adding activity...',
                                                ),
                                              ],
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );

                                        try {
                                          final result = isEditing
                                              ? await activityProvider
                                                    .updateActivity(activity)
                                              : await activityProvider
                                                    .addActivity(activity);

                                          Navigator.pop(context);

                                          // Auto refresh the entire page
                                          setState(() {
                                            _isLoading =
                                                true; // Show loading indicator
                                          });

                                          // Refresh all data
                                          await _loadInitialData();

                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  result['message'],
                                                ),
                                                backgroundColor:
                                                    result['success']
                                                    ? Colors.green
                                                    : Colors.red,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                        } catch (e) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _isLoading =
                                                  false; // Hide loading indicator
                                            });
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showQuickQuantityEditDialog(BuildContext context, Activity activity) {
    final remainingQuantity = activity.balanceQuantity;
    final TextEditingController quantityController = TextEditingController(
      text: remainingQuantity > 0 ? remainingQuantity.toString() : '0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Mark Progress',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${activity.title}\nRemaining: ${remainingQuantity} ${activity.unit}',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity to Complete',
                hintText: 'Enter amount to mark complete',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                suffixText: activity.unit,
              ),
            ),
            SizedBox(height: 8.h),
            StatefulBuilder(
              builder: (context, setState) {
                final enteredQuantity =
                    int.tryParse(quantityController.text) ?? 0;
                final isValid =
                    enteredQuantity >= 0 &&
                    enteredQuantity <= remainingQuantity;
                return Column(
                  children: [
                    Text(
                      'New Remaining: ${remainingQuantity - enteredQuantity} ${activity.unit}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: (remainingQuantity - enteredQuantity) >= 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isValid)
                      Text(
                        enteredQuantity > remainingQuantity
                            ? 'Cannot exceed remaining quantity'
                            : 'Must be non-negative',
                        style: TextStyle(fontSize: 12.sp, color: Colors.red),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantityToComplete =
                  int.tryParse(quantityController.text) ?? 0;
              if (quantityToComplete >= 0 &&
                  quantityToComplete <= remainingQuantity) {
                final activityProvider = Provider.of<ActivityProvider>(
                  context,
                  listen: false,
                );

                try {
                  final result = await activityProvider.markComplete(
                    activity.id,
                    quantityToComplete,
                  );

                  Navigator.pop(context);

                  // Auto refresh the entire page
                  setState(() {
                    _isLoading = true;
                  });

                  // Refresh all data
                  await _loadInitialData();

                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: result['success']
                            ? Colors.green
                            : Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4a63c0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Activity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 28.sp),
            SizedBox(width: 12.w),
            Text(
              'Delete Activity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${activity.title}"?',
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final activityProvider = Provider.of<ActivityProvider>(
                context,
                listen: false,
              );

              try {
                final result = await activityProvider.deleteActivity(
                  activity.id,
                );

                Navigator.pop(context);

                // Auto refresh the entire page
                setState(() {
                  _isLoading = true;
                });

                // Refresh all data
                await _loadInitialData();

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['success']
                          ? Colors.green
                          : Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
