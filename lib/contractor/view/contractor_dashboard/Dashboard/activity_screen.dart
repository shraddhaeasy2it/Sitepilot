import 'dart:convert';
import 'dart:async';
import 'package:ecoteam_app/contractor/provider/activity_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Machinery/add_edit_dpr_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/profilepage.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/mancount.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/material_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Machinery/machineryCategory_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/consumptionLog_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/add_progress_page.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/activity_details_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

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
  Timer? _permissionTimer;
  bool _isLoading = false;
  List<Workspace> _workspaces = [];
  List<ApiSite> _apiSites = [];
  List<String> _priorities = [];
  Map<String, String> _users = {};

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
      _refreshPermissions();
    });

    _permissionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _refreshPermissions();
      }
    });
  }

  @override
  void didUpdateWidget(ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId ||
        widget.workspaceId != oldWidget.workspaceId) {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _permissionTimer?.cancel();
    super.dispose();
  }

  void _refreshPermissions() {
    Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    ).refreshPermissions();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      // Fetch activities
      await _activityProvider.fetchActivities(
        siteId: int.tryParse(widget.selectedSiteId ?? '') ?? 0,
        workspaceId: widget.workspaceId,
      );

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
          _users = Map<String, String>.from(createData['users'] ?? {});
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
          actions: buildNotificationActions(
            context: context,
            selectedSiteId: widget.selectedSiteId,
            sites: widget.sites,
            currentCompany: widget.currentCompany,
            workspaceId: widget.workspaceId,
          ),
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
        floatingActionButton:
            Provider.of<CompanySiteProvider>(
              context,
            ).hasPermission('activities create')
            ? FloatingActionButton(
                onPressed: () => _showAddActivityBottomSheet(context),
                backgroundColor: const Color.fromRGBO(42, 67, 160, 1),
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Add Activity',
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: Colors.black12.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      tooltip: 'Generate Report',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _showReportBottomSheet,
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        size: 24,
                        color: Color.fromARGB(255, 29, 29, 29),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : TabBarView(
                      children: [
                        _buildActivityList(pending: true),
                        _buildActivityList(pending: false),
                      ],
                    ),
            ),
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
                    await activityProvider.fetchActivities(
                      siteId: int.tryParse(widget.selectedSiteId ?? '') ?? 0,
                      workspaceId: widget.workspaceId,
                    );
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
            await activityProvider.fetchActivities(
              siteId: int.tryParse(widget.selectedSiteId ?? '') ?? 0,
              workspaceId: widget.workspaceId,
            );
          },
          color: const Color(0xFF4a63c0),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            itemCount: activities.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
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
    final companyProvider = Provider.of<CompanySiteProvider>(context);
    final hasShowPermission = companyProvider.hasPermission('activities show');
    final hasEditPermission = companyProvider.hasPermission('activities edit');
    final hasDeletePermission = companyProvider.hasPermission(
      'activities delete',
    );
    final showOptions =
        hasShowPermission || hasEditPermission || hasDeletePermission;

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
     onTap: hasShowPermission
    ? () => _showActivityDetailsBottomSheet(context, activity)
    : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 253, 254, 255),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 45, 79, 153).withOpacity(0.1),
              blurRadius: 5.r,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: const Color.fromARGB(255, 238, 237, 245),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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

                  SizedBox(width: 10.w),

                  // Title
                  Expanded(
                    child: Text(
                      activity.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        color: const Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Options Button
                  if (showOptions)
                    IconButton(
                      onPressed: () =>
                          _showOptionsBottomSheet(context, activity),
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 18.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minHeight: 24,
                        minWidth: 24,
                      ),
                    ),
                ],
              ),

              SizedBox(height: 6.h), // minimized gap
              // Progress and Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress Section
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _showActivityDetailsBottomSheet(context, activity),
                        child: Container(
                          width: 40.w,
                          height: 40.w,
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
                                width: 35.w,
                                height: 35.w,
                                child: CircularProgressIndicator(
                                  value: activity.progressPercentage,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    getColorForActivity(),
                                  ),
                                  strokeWidth: 2.w,
                                ),
                              ),
                              Text(
                                '${(activity.progressPercentage * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: getColorForActivity(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // Quantity Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${activity.completedQuantity}/${activity.quantity} ${activity.unit}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 64, 77, 95),
                            ),
                          ),
                          Text(
                            '${activity.balanceQuantity} ${activity.unit} remaining',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Update Button
                  ElevatedButton(
                    onPressed: !completed
                        ? () => _showAddProgressBottomSheet(context, activity)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4a63c0),
                      elevation: 0,
                      minimumSize: Size(0, 28.h),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        side: const BorderSide(
                          color: Color(0xFF4a63c0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color.fromARGB(255, 38, 66, 165),
                      ),
                    ),
                  ),
                ],
              ),

              // Latest Completion Info
              if (activity.completions.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final latest = activity.completions.reduce((a, b) =>
                        a.createdAt.isAfter(b.createdAt) ? a : b);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       
                        if (latest.creator != null) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 14.sp, color: Colors.grey[600]),
                              SizedBox(width: 4.w),
                              Text(
                                'Created By: ${latest.creator!['name']}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, Activity activity) {
    final companyProvider = Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    );
    final hasShowPermission = companyProvider.hasPermission('activities show');
    final hasEditPermission = companyProvider.hasPermission('activities edit');
    final hasDeletePermission = companyProvider.hasPermission(
      'activities delete',
    );

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
           
            if (hasEditPermission)
              _buildOptionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Activity',
                Iconcolor: Colors.blue,
                backgroundColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _showAddActivityBottomSheet(
                    context,
                    existingActivity: activity,
                  );
                },
              ),
            if (hasDeletePermission)
              _buildOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Activity',
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailsPage(
          activity: activity,
          onGenerateReport: () => _generateActivityReport(activity),
        ),
      ),
    );
  }

  Future<void> _generateActivityReport(Activity activity) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.nunitoRegular();

    // Calculate remaining quantities
    List<Map<String, dynamic>> processedCompletions = [];
    if (activity.completions.isNotEmpty) {
      var sorted = List<ActivityUpdate>.from(activity.completions);
      sorted.sort((a, b) {
        int dateComp = a.createdAt.compareTo(b.createdAt);
        if (dateComp != 0) return dateComp;
        return a.id.compareTo(b.id);
      });

      int cumulative = 0;
      for (var comp in sorted) {
        cumulative += comp.completedQuantity;
        int remaining = activity.quantity - cumulative;
        processedCompletions.add({'data': comp, 'remaining': remaining});
      }
      // Reverse for display (Newest first)
      processedCompletions = processedCompletions.reversed.toList();
    }

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Activity Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Title: ${activity.title}',
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.Text(
                'Scope: ${activity.scope}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Status: ${activity.isCompleted ? "Completed" : "Pending"}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Created Date: ${DateFormat('yyyy-MM-dd').format(activity.createdAt)}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Progress: ${activity.completedQuantity} / ${activity.quantity} ${activity.unit}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Completed Records',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>[
                    'Date',
                    'Total Quantity',
                    'Completed Quantity',
                    'Remaining Quantity',
                  ],
                  ...processedCompletions.map((item) {
                    final completion = item['data'] as ActivityUpdate;
                    final remaining = item['remaining'] as int;
                    return [
                      DateFormat('yyyy-MM-dd').format(completion.createdAt),
                      '${activity.quantity} ${activity.unit}',
                      '${completion.completedQuantity} ${activity.unit}',
                      '$remaining ${activity.unit}',
                    ];
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/activity_report_${activity.id}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  // ==================== PDF REPORT FUNCTIONALITY ====================

  DateTime _reportStartDate = DateTime.now();
  DateTime _reportEndDate = DateTime.now();
  List<Activity> _reportActivities = [];
  int _reportTotalActivities = 0;

  void _showReportBottomSheet() {
    _reportStartDate = DateTime.now();
    _reportEndDate = DateTime.now();
    _updateReportData();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReportSheet(),
    );
  }

  void _updateReportData() {
    final activities = _activityProvider.activities;

    // Filter activities
    _reportActivities = activities.where((activity) {
      final activityDate = DateTime(
        activity.createdAt.year,
        activity.createdAt.month,
        activity.createdAt.day,
      );
      final startDate = DateTime(
        _reportStartDate.year,
        _reportStartDate.month,
        _reportStartDate.day,
      );
      final endDate = DateTime(
        _reportEndDate.year,
        _reportEndDate.month,
        _reportEndDate.day,
      );

      final createdInRange =
          (!activityDate.isBefore(startDate) && !activityDate.isAfter(endDate));

      final hasCompletionInRange = activity.completions.any((completion) {
        final completionDate = DateTime(
          completion.createdAt.year,
          completion.createdAt.month,
          completion.createdAt.day,
        );
        return (!completionDate.isBefore(startDate) &&
            !completionDate.isAfter(endDate));
      });

      return createdInRange || hasCompletionInRange;
    }).toList();

    _reportTotalActivities = _reportActivities.length;
  }

  Widget _buildReportSheet() {
    final screenHeight = MediaQuery.of(context).size.height;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          height: screenHeight * 0.45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activity Report',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2a43a0),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF2a43a0)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: 12.h),

              const Text(
                'Select Date Range:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a43a0),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _reportStartDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _reportStartDate = picked;
                            if (_reportStartDate.isAfter(_reportEndDate)) {
                              _reportEndDate = _reportStartDate;
                            }
                            _updateReportData();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(_reportStartDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('to', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _reportEndDate,
                          firstDate: _reportStartDate,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _reportEndDate = picked;
                            _updateReportData();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(_reportEndDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4a63c0), Color(0xFF2a43a0)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Activities:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '$_reportTotalActivities',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _generatePdf();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 50, 160, 47),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text(
                      'View PDF',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // Ensure fresh data
    _updateReportData();

    if (_reportActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No activities found for this date range'),
        ),
      );
      return;
    }

    final font = await PdfGoogleFonts.nunitoRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return [
            _buildPdfHeader(),
            pw.SizedBox(height: 20),
            _buildPdfTable(_reportActivities),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Generated on: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName =
        'activity_report_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  pw.Widget _buildPdfHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Activity Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Date Range: ${DateFormat('dd MMM yyyy').format(_reportStartDate)} to ${DateFormat('dd MMM yyyy').format(_reportEndDate)}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.Text(
          'Site: ${_getCurrentSiteName()}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildPdfTable(List<Activity> activities) {
    return pw.Table.fromTextArray(
      headers: [
        'Title',
        'Scope',
        'Quantity',
        'Completed',
        'Unit',
        'Status',
        'Priority',
      ],
      data: activities.map((activity) {
        return [
          activity.title,
          activity.scope,
          activity.quantity.toString(),
          activity.completedQuantity.toString(),
          activity.unit,
          activity.isCompleted ? 'Completed' : 'Pending',
          activity.priority.toUpperCase(),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }

  void _showActivityDetailsBottomSheetOld(
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
                                    'Activity Information',
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
                                          'Completed Records',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Spacer(),
                                        IconButton(
                                          icon: Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.red,
                                            size: 24.sp,
                                          ),
                                          onPressed: () {
                                            _generateActivityReport(activity);
                                          },
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
      text: (existingActivity != null && existingActivity.completedQuantity > 0)
          ? existingActivity.completedQuantity.toString()
          : '',
    );

    DateTime selectedDate = existingActivity?.date ?? DateTime.now();
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(selectedDate),
    );

    String? selectedPriority = existingActivity?.priority;
    int? selectedWorkspaceId =
        existingActivity?.workspaceId ?? widget.workspaceId;
    int? selectedSiteId =
        existingActivity?.siteId ??
        (widget.selectedSiteId != null
            ? int.tryParse(widget.selectedSiteId!)
            : null);

    final initialAssignTo = existingActivity?.assignTo ?? [];
    List<String> selectedAssignTo = List<String>.from(initialAssignTo);
    File? _pickedReferenceFile;

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
          minChildSize: isKeyboardOpen ? 0.9 : (isSmallScreen ? 0.9 : 0.6),
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
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        top: 24.h,
                        bottom: 24.h + MediaQuery.of(context).viewInsets.bottom,
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
                                          color: Color.fromARGB(
                                            255,
                                            214,
                                            215,
                                            216,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            189,
                                            190,
                                            197,
                                          ), // Different color when focused
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

                                  StatefulBuilder(
                                    builder: (context, setDateState) {
                                      return TextField(
                                        controller: dateController,
                                        readOnly: true,
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: selectedDate,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            selectedDate = picked;
                                            dateController.text = DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(selectedDate);
                                            setDateState(() {});
                                          }
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Date',
                                          hintText: 'yyyy-mm-dd',
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
                                              color: Color.fromARGB(
                                                255,
                                                214,
                                                215,
                                                216,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                255,
                                                189,
                                                190,
                                                197,
                                              ),
                                              width: 1.0,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.calendar_today,
                                            color: Color(0xFF4a63c0),
                                            size: 20.sp,
                                          ),
                                        ),
                                      );
                                    },
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
                                          color: Color.fromARGB(
                                            255,
                                            214,
                                            215,
                                            216,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            189,
                                            190,
                                            197,
                                          ), // Different color when focused
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
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                  255,
                                                  214,
                                                  215,
                                                  216,
                                                ),
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                  255,
                                                  189,
                                                  190,
                                                  197,
                                                ), // Different color when focused
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
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                  255,
                                                  214,
                                                  215,
                                                  216,
                                                ),
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                  255,
                                                  189,
                                                  190,
                                                  197,
                                                ), // Different color when focused
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
                                      hintText:
                                          'e.g. 85(should be Greater than 0)',
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
                                          color: Color.fromARGB(
                                            255,
                                            214,
                                            215,
                                            216,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            189,
                                            190,
                                            197,
                                          ), // Different color when focused
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

                                  // Reference File Picker
                                  StatefulBuilder(
                                    builder: (context, setPickerState) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Reference File (Optional)',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          InkWell(
                                            onTap: () async {
                                              final ImagePicker picker = ImagePicker();
                                              final XFile? image = await showModalBottomSheet<XFile?>(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return SafeArea(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: <Widget>[
                                                        ListTile(
                                                          leading: const Icon(Icons.photo_library),
                                                          title: const Text('Gallery'),
                                                          onTap: () async {
                                                            final XFile? img = await picker.pickImage(source: ImageSource.gallery);
                                                            Navigator.pop(context, img);
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: const Icon(Icons.photo_camera),
                                                          title: const Text('Camera'),
                                                          onTap: () async {
                                                            final XFile? img = await picker.pickImage(source: ImageSource.camera);
                                                            Navigator.pop(context, img);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );

                                              if (image != null) {
                                                setPickerState(() {
                                                  _pickedReferenceFile = File(image.path);
                                                });
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.shade300),
                                                borderRadius: BorderRadius.circular(12.r),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.image, color: Color(0xFF4a63c0), size: 24.sp),
                                                  SizedBox(width: 12.w),
                                                  Expanded(
                                                    child: Text(
                                                      _pickedReferenceFile != null
                                                          ? p.basename(_pickedReferenceFile!.path)
                                                          : (existingActivity?.referenceFile != null
                                                              ? p.basename(existingActivity!.referenceFile!)
                                                              : 'Tap to pick an image'),
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        color: _pickedReferenceFile != null || existingActivity?.referenceFile != null
                                                            ? Colors.black87
                                                            : Colors.grey,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (_pickedReferenceFile != null)
                                                    IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        setPickerState(() {
                                                          _pickedReferenceFile = null;
                                                        });
                                                      },
                                                      icon: const Icon(Icons.close, size: 20),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (_pickedReferenceFile != null) ...[
                                            SizedBox(height: 12.h),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12.r),
                                              child: Image.file(
                                                _pickedReferenceFile!,
                                                height: 150.h,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ] else if (existingActivity?.referenceFile != null) ...[
                                            SizedBox(height: 12.h),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12.r),
                                              child: Image.network(
                                                existingActivity!.referenceFile!.startsWith('http')
                                                    ? existingActivity!.referenceFile!
                                                    : 'https://app.ecoteamsolar.com/${existingActivity!.referenceFile}',
                                                height: 150.h,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                              ),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: 16.h),

                                  StatefulBuilder(
                                    builder: (context, setAssignState) {
                                      final selectedNames = selectedAssignTo
                                          .map((id) => _users[id] ?? 'Unknown')
                                          .join(', ');
                                      return TextField(
                                        readOnly: true,
                                        controller: TextEditingController(
                                          text: selectedNames.isEmpty
                                              ? 'Select Users'
                                              : selectedNames,
                                        ),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return StatefulBuilder(
                                                builder: (context, setDialogState) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      'Assign To',
                                                    ),
                                                    content: SizedBox(
                                                      width: double.maxFinite,
                                                      child: ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount:
                                                            _users.length,
                                                        itemBuilder: (context, index) {
                                                          final userId = _users
                                                              .keys
                                                              .elementAt(index);
                                                          final userName =
                                                              _users[userId] ??
                                                              'Unknown';
                                                          final isSelected =
                                                              selectedAssignTo
                                                                  .contains(
                                                                    userId,
                                                                  );
                                                          return CheckboxListTile(
                                                            title: Text(
                                                              userName,
                                                            ),
                                                            value: isSelected,
                                                            onChanged: (bool? value) {
                                                              setDialogState(() {
                                                                if (value ==
                                                                    true) {
                                                                  selectedAssignTo
                                                                      .add(
                                                                        userId,
                                                                      );
                                                                } else {
                                                                  selectedAssignTo
                                                                      .remove(
                                                                        userId,
                                                                      );
                                                                }
                                                              });
                                                              setAssignState(
                                                                () {},
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          'Done',
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Assign To',
                                          hintText: 'Select Users',
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
                                              color: Color.fromARGB(
                                                255,
                                                214,
                                                215,
                                                216,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                255,
                                                189,
                                                190,
                                                197,
                                              ),
                                              width: 1.0,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.person_add,
                                            color: Color(0xFF4a63c0),
                                            size: 20.sp,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  SizedBox(height: 16.h),

                                  // Priority Dropdown
                                  DropdownButtonFormField<String>(
                                    value: selectedPriority,
                                    hint: Text(
                                      'Select Priority',
                                      style: TextStyle(color: Colors.grey),
                                    ),
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
                                          color: Color.fromARGB(
                                            255,
                                            214,
                                            215,
                                            216,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            189,
                                            190,
                                            197,
                                          ), // Different color when focused
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
                                          assignTo: selectedAssignTo,
                                          date: selectedDate,
                                          createdAt:
                                              existingActivity?.createdAt ??
                                              DateTime.now(),
                                          completions:
                                              existingActivity?.completions,
                                          updatedAt: DateTime.now(),
                                          referenceFile: existingActivity?.referenceFile,
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

                                        if (isEditing) {
                                          final result =
                                              await activityProvider
                                                  .updateActivity(activity, file: _pickedReferenceFile);
                                          print('Update Activity Response: $result');
                                          if (mounted) {
                                            Navigator.pop(context);
                                            
                                            // Auto refresh the entire page
                                            setState(() {
                                              _isLoading = true;
                                            });
                                            await _loadInitialData();

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  result['message'],
                                                ),
                                                backgroundColor:
                                                    result['success']
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            );
                                          }
                                        } else {
                                          final result =
                                              await activityProvider
                                                  .addActivity(activity, file: _pickedReferenceFile);
                                          print('Add Activity Response: $result');
                                          if (mounted) {
                                            Navigator.pop(context);
                                            
                                            // Auto refresh the entire page
                                            setState(() {
                                              _isLoading = true;
                                            });
                                            await _loadInitialData();

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  result['message'],
                                                ),
                                                backgroundColor:
                                                    result['success']
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            );
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

  Future<void> _showAddProgressBottomSheet(
    BuildContext context,
    Activity activity,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProgressPage(
          activity: activity,
          selectedSiteId: widget.selectedSiteId,
          sites: widget.sites,
          userId: widget.userId,
          workspaceId: widget.workspaceId,
          token: widget.token,
          currentCompany: widget.currentCompany,
          onSiteChanged: widget.onSiteChanged,
        ),
      ),
    );

    // Refresh data when the page pops after saving progress
    if (result == true && mounted) {
      setState(() {
        _isLoading = true;
      });
      await _loadInitialData();
    }
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

  Widget _buildAdditionalDetailRow(
    String title,
    IconData icon,
    VoidCallback onAdd,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4a63c0), size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: Icon(
              Icons.add_circle_outline,
              color: const Color(0xFF4a63c0),
              size: 25.sp,
            ),
          ),
        ],
      ),
    );
  }
}
