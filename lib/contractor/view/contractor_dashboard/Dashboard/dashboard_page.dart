import 'dart:async';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/dashboard_page.dart'
    as _companyProvider;
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/docstorage.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/transfer_reports_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Machinery/machinary.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/material_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Supplier/supplier.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/HR_Admin/hr_admin_page.dart';
import 'dart:convert';

import 'package:ecoteam_app/contractor/provider/activity_provider.dart';

import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/activity_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/employee_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/mancount.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/paymentScreen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/profilepage.dart';
import 'package:ecoteam_app/main.dart';
import 'package:ecoteam_app/contractor/models/birthday_model.dart';
import 'package:ecoteam_app/contractor/models/dashboard_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/services/api_ser.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/attendance_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/tools_screen.dart';
import 'package:ecoteam_app/contractor/widgets/bottom_navbar.dart';
import 'package:ecoteam_app/admin/services/DPR_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/reports_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/summary_screen.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DashboardScreen extends StatefulWidget {
  final Site? selectedSite;
  final String? companyName;
  const DashboardScreen({super.key, this.selectedSite, this.companyName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

List<Map<String, dynamic>> get companies => _companyProvider.companies;
String? currentCompanyId;
String? currentCompanyName;

class _DashboardScreenState extends State<DashboardScreen> {
  late CompanySiteProvider _companyProvider;
  int _currentIndex = 0;
  String? _selectedSiteId;
  List<Site> _sites = [];
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _searchQuery;

  String? _authToken;
  Map<String, dynamic>? _userData;
  int? _userId;
  int? _workspaceId;
  int? _employeeId;

  bool _isDashboardExpanded = false;
  bool _isUserManagementExpanded = false;
  bool _isMasterExpanded = false;
  bool _isMaterialExpanded = false;
  bool _isSupplierExpanded = false;
  bool _isAssetsExpanded = false;
  bool _isTransactionExpanded = false;
  bool _isPaymentExpanded = false;
  bool _isProjectSitesExpanded = false;
  bool _isHRMExpanded = false;
  bool _isAttendanceExpanded = false;
  bool _isReportExpanded = false;
  bool _isSettingsExpanded = false;
  bool _isDailyTransactionExpanded = false;
  bool _isDailyConsumptionExpanded = false;
  bool _isMaterialTransferExpanded = false;
  bool _isDPRreportExpanded = false;
  bool _showSummary = false; // Added for Summary Screen embedding
  Timer? _permissionTimer;

  @override
  void initState() {
    super.initState();
    if (widget.selectedSite != null) {
      _selectedSiteId = widget.selectedSite!.id;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _refreshPermissions();
    });

    _permissionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _refreshPermissions();
      }
    });
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      print('Loading dashboard data...');
      final companyProvider = Provider.of<CompanySiteProvider>(
        context,
        listen: false,
      );

      // Always refresh permissions to ensure latest access rights
      companyProvider.refreshPermissions().catchError((e) {
        print('Error refreshing permissions: $e');
      });

      // Fetch notification count
      companyProvider.fetchUnreadNotificationCount().catchError((e) {
        print('Error fetching notification count: $e');
      });

      // Fetch chat count
      companyProvider.fetchUnreadChatCount().catchError((e) {
        print('Error fetching chat count: $e');
      });

      // _hasMachineryAccess = companyProvider.hasPermission('machinery manage');

      _dashboardData = await ApiService()
          .fetchDashboardData(companyId: companyProvider.selectedCompanyId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Loading timeout - please check your connection');
            },
          );

      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        _userData = jsonDecode(userDataStr);

        // Handle nested user object structure
        if (_userData?['user'] != null &&
            _userData?['user'] is Map &&
            _userData?['user']['id'] != null) {
          _userId = _userData?['user']['id'];
        } else {
          _userId = _userData?['id'];
        }

        // Prefer parsing as int, handle String case
        if (_userId == null && _userData?['id'] is String) {
          _userId = int.tryParse(_userData?['id']);
        }

        _workspaceId = _userData?['workspace_id'];
        if (_workspaceId == null &&
            _userData?['user'] != null &&
            _userData?['user'] is Map) {
          _workspaceId = _userData?['user']['workspace_id'];
        }
        _workspaceId ??= 1;
      }

      final employeeDataStr = prefs.getString('employee_data');
      if (employeeDataStr != null) {
        final employeeData = jsonDecode(employeeDataStr);
        if (employeeData['id'] != null) {
          _employeeId = int.tryParse(employeeData['id'].toString());
        } else if (employeeData['employee_id'] != null) {
          _employeeId = int.tryParse(employeeData['employee_id'].toString());
        }
      }

      _sites = companyProvider.sites;
      if (widget.selectedSite != null) {
        _selectedSiteId = widget.selectedSite!.id;
      } else if (_sites.isNotEmpty) {
        _selectedSiteId = _sites.first.id;
      } else {
        _selectedSiteId = null;
      }

      // No need to update _screens manually anymore
    } catch (e) {
      print('Error loading dashboard data: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${e.toString()}'),
            backgroundColor: const Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: const Color(0xFF6366F1),
              onPressed: _loadData,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSiteChanged(String siteId) {
    setState(() {
      _selectedSiteId = siteId;
    });
  }

  void _onSitesUpdated(List<Site> updatedSites) {
    setState(() {
      _sites = updatedSites;
    });
  }

  void _showSiteSelectorBottomSheet() {
    setState(() {
      _searchQuery = '';
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Site',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search sites...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _sites.length,
                      itemBuilder: (context, index) {
                        final site = _sites[index];
                        if (_searchQuery != null &&
                            _searchQuery!.isNotEmpty &&
                            !site.name.toLowerCase().contains(
                              _searchQuery!.toLowerCase(),
                            ) &&
                            !(site.description ?? '').toLowerCase().contains(
                              _searchQuery!.toLowerCase(),
                            )) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          title: Text(
                            site.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(site.description ?? 'No description'),
                          onTap: () {
                            _onSiteChanged(site.id);
                            Navigator.pop(context);
                          },
                          trailing: _selectedSiteId == site.id
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4a63c0),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 130,
                child: Lottie.asset(
                  'assets/landing3.json',
                  repeat: true,
                  animate: true,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Preparing your dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4a63c0),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please wait while we load your data...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Listen to provider for permission changes
    final companyProvider = Provider.of<CompanySiteProvider>(context);
    final hasMachineryAccess = companyProvider.hasPermission(
      'machinery manage',
    );
    final hasActivityAccess = companyProvider.hasPermission(
      'activities manage',
    );
    print(
      'DEBUG: Dashboard Build - hasMachineryAccess: $hasMachineryAccess, hasActivityAccess: $hasActivityAccess',
    ); // Added Log

    // Dynamically build screens based on permissions
    final screens = _buildScreensList(hasMachineryAccess, hasActivityAccess);

    // Safeguard index if permission revoked while on that tab
    final effectiveIndex = _currentIndex >= screens.length ? 0 : _currentIndex;
    // Note: This effectiveIndex is for display of BODY.
    // The bottom nav bar handles its own visual index.
    // We need to sync them using _handleNavigation logic later.

    // However, _currentIndex is "Application Logic Index" or "Visual Index"?
    // Usually it is Visual Index for BottomNavBar.
    // If Machinery is hidden, Profile is Visual Index 3.
    // If Machinery is shown, Profile is Visual Index 4.
    // We should treat _currentIndex as the VISUAL index.

    // So screens list should match visual index.
    // _buildScreensList should return: [Dash, Tasks, Materials, Machinery?, Profile]
    // If Machinery hidden: [Dash, Tasks, Materials, Profile] (Length 4)
    // Profile is at index 3. Perfect.

    if (_dashboardData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4a63c0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4a63c0).withOpacity(0.3),
                    ),
                  ),
                  child: Lottie.asset(
                    'assets/error.json',
                    width: 100,
                    height: 100,
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load dashboard',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please check your internet connection and try again',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4a63c0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFF4a63c0).withOpacity(0.3),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_showSummary,
      onPopInvokedWithResult: (didPop, result) async {
         if (didPop) return;
         if (_showSummary) {
            setState(() => _showSummary = false);
         }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: (_currentIndex == 0 && !_showSummary)
          ? AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              toolbarHeight: 74.h,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.companyName ?? 'Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (_selectedSiteId != null &&
                            widget.selectedSite != null &&
                            widget.selectedSite!.id == _selectedSiteId)
                        ? 'Site: ${widget.selectedSite!.name}'
                        : (_sites.isEmpty
                              ? 'No Sites'
                              : (_selectedSiteId == null
                                    ? 'Select Site'
                                    : 'Site: ${_sites.firstWhere(
                                        (site) => site.id == _selectedSiteId,
                                        orElse: () => Site(id: '', name: 'Unknown Site', companyId: ''),
                                      ).name}')),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final provider = Provider.of<CompanySiteProvider>(
                          context,
                          listen: false,
                        );
                        final workspaceId =
                            int.tryParse(provider.selectedCompanyId ?? '') ??
                            _workspaceId ??
                            3;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationScreen(
                              siteId: _selectedSiteId,
                              workspaceId: workspaceId,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const FaIcon(FontAwesomeIcons.bell, size: 22),
                          Consumer<CompanySiteProvider>(
                            builder: (context, provider, child) {
                              if (provider.unreadNotificationCount > 0) {
                                return Positioned(
                                  right: -5,
                                  top: -12,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 15,
                                      minHeight: 15,
                                    ),
                                    child: Center(
                                      child: Text(
                                        provider.unreadNotificationCount > 99
                                            ? '99+'
                                            : '${provider.unreadNotificationCount}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          height: 1, // Ensure text is vertically centered
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    IconButton(
                      tooltip: 'Chat',
                      onPressed: _navigateToChatScreen,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.commentDots,
                            size: 22,
                          ),
                          Consumer<CompanySiteProvider>(
                            builder: (context, provider, child) {
                              if (provider.unreadChatCount > 0) {
                                return Positioned(
                                  right: -5,
                                  top: -12,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 17,
                                      minHeight: 17,
                                    ),
                                    child: Center(
                                      child: Text(
                                        provider.unreadChatCount > 99
                                            ? '99+'
                                            : '${provider.unreadChatCount}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
              centerTitle: false,
            )
          : null,
      //drawer: _currentIndex == 0 ? _buildNavigationDrawer() : null,
      body: _showSummary
          ? SummaryScreen(
              selectedSiteId: _selectedSiteId,
              onSiteChanged: _onSiteChanged,
              sites: _sites,
              workspaceId:
                  int.tryParse(
                    Provider.of<CompanySiteProvider>(
                          context,
                          listen: false,
                        ).selectedCompanyId ??
                        '',
                  ) ??
                  _workspaceId ??
                  3,
              token: _authToken ?? '',
              createdBy: _userId ?? 0,
              currentCompany: currentCompanyName,
            )
          : screens[effectiveIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _showSummary ? 0 : effectiveIndex,
        onTap: _handleNavigation,
        showMachinery: hasMachineryAccess,
        showActivity: hasActivityAccess,
      ),
    )); // Closing Scaffold and PopScope
  }

  List<Widget> _buildScreensList(
    bool hasMachineryAccess,
    bool hasActivityAccess,
  ) {
    return [
      DashboardContent(
        key: const PageStorageKey('dashboard_content'),
        selectedSiteId: _selectedSiteId,
        onSiteChanged: _onSiteChanged,
        sites: _sites,
        onSitesUpdated: _onSitesUpdated,
        dashboardData: _dashboardData,
        userId: _userId ?? 0,
        employeeId: _employeeId ?? 0,
        workspaceId:
            int.tryParse(
              Provider.of<CompanySiteProvider>(
                    context,
                    listen: false,
                  ).selectedCompanyId ??
                  '',
            ) ??
            _workspaceId ??
            3,
        token: _authToken ?? '',
        currentCompany: currentCompanyName,
        onSummaryTap: () {
          setState(() {
            _showSummary = true;
          });
        },
      ),
      if (hasActivityAccess)
        ChangeNotifierProvider(
          create: (_) => ActivityProvider(),
          child: ActivityScreen(
            selectedSiteId: _selectedSiteId,
            onSiteChanged: _onSiteChanged,
            sites: _sites,
            userId: _userId ?? 0,
            workspaceId:
                int.tryParse(
                  Provider.of<CompanySiteProvider>(
                        context,
                        listen: false,
                      ).selectedCompanyId ??
                      '',
                ) ??
                _workspaceId ??
                3,
            token: _authToken ?? '',
          ),
        ),
      MaterialScreen(
        key: const PageStorageKey('materials'),
        selectedSiteId: _selectedSiteId,
        onSiteChanged: _onSiteChanged,
        sites: _sites,
        workspaceId:
            int.tryParse(
              Provider.of<CompanySiteProvider>(
                    context,
                    listen: false,
                  ).selectedCompanyId ??
                  '',
            ) ??
            _workspaceId ??
            3,
        currentCompany: currentCompanyName,
        userId: _userId,
      ),
      if (hasMachineryAccess)
        AllMachineryScreen(
          key: const PageStorageKey('machinery'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
          workspaceId:
              int.tryParse(
                Provider.of<CompanySiteProvider>(
                      context,
                      listen: false,
                    ).selectedCompanyId ??
                    '',
              ) ??
              _workspaceId ??
              3,
          currentCompany: currentCompanyName,
          userId: _userId,
        ),
      ProfileScreen(
        key: const PageStorageKey('profile'),
        passedUserId: _userId,
        passedWorkspaceId:
            int.tryParse(
              Provider.of<CompanySiteProvider>(
                    context,
                    listen: false,
                  ).selectedCompanyId ??
                  '',
            ) ??
            _workspaceId ??
            3,
      ),
    ];
  }

  void _handleNavigation(int index) {
    if (index == 0 && _showSummary) {
      setState(() {
         _showSummary = false;
         _currentIndex = 0;
      });
      return;
    }

    if (index == _currentIndex) {
      _scrollToTop();
      return;
    }
    setState(() {
      _currentIndex = index;
      _showSummary = false; 
    });
  }

  void _scrollToTop() {
    if (_currentIndex == 0) {
      // Implement scroll to top for dashboard if needed
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  Future<void> _navigateToChatScreen() async {
    final siteList = _sites;
    // Prefer provider workspace ID if selected, otherwise stored _workspaceId, fallback to 1
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);
    final effectiveWorkspaceId =
        int.tryParse(provider.selectedCompanyId ?? '') ?? _workspaceId ?? 1;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          selectedSiteId: siteList.isNotEmpty ? siteList.first.id : null,
          onSiteChanged: (String siteId) {
            debugPrint('Site changed to: $siteId');
          },
          sites: siteList,
          currentCompany: currentCompanyName,
          workspaceId: effectiveWorkspaceId,
        ),
      ),
    );

    // Refresh chat count on return
    if (mounted) {
      provider.fetchUnreadChatCount();
    }
  }
}

class SitesManagementModal extends StatefulWidget {
  final List<Site> sites;
  final Function(List<Site>) onSitesUpdated;
  const SitesManagementModal({
    super.key,
    required this.sites,
    required this.onSitesUpdated,
  });

  @override
  State<SitesManagementModal> createState() => _SitesManagementModalState();
}

class _SitesManagementModalState extends State<SitesManagementModal> {
  final TextEditingController _siteNameController = TextEditingController();
  final TextEditingController _siteAddressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _siteNameController.dispose();
    _siteAddressController.dispose();
    super.dispose();
  }

  void _addNewSite() async {
    if (_formKey.currentState!.validate()) {
      final existingIds = widget.sites
          .map((site) => int.tryParse(site.id.replaceAll('site', '')) ?? 0)
          .toList();
      final nextId = existingIds.isEmpty
          ? 1
          : existingIds.reduce((a, b) => a > b ? a : b) + 1;
      final newSite = Site(
        id: 'site$nextId',
        name: _siteNameController.text.trim(),
        companyId: '',
        description: _siteAddressController.text.trim(),
      );
      final success = await ApiService().addSite(newSite);
      if (success) {
        final updatedSites = ApiService.sites;
        widget.onSitesUpdated(updatedSites);
        _siteNameController.clear();
        _siteAddressController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Site "${newSite.name}" added successfully!'),
            backgroundColor: const Color(0xFF4a63c0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add site "${newSite.name}"!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _deleteSite(Site site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Site',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${site.name}"?\n\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ApiService().deleteSite(site.id);
              if (success) {
                final updatedSites = ApiService.sites;
                widget.onSitesUpdated(updatedSites);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Site "${site.name}" deleted successfully!'),
                    backgroundColor: const Color(0xFF4a63c0),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete site "${site.name}"!'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Sites',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add and manage construction sites',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4a63c0).withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Site',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _siteNameController,
                      style: const TextStyle(color: Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        labelText: 'Site Name',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Color(0xFF4a63c0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4a63c0),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter site name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _siteAddressController,
                      style: const TextStyle(color: Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        labelText: 'Site Address',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        prefixIcon: const Icon(
                          Icons.home,
                          color: Color(0xFF4a63c0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4a63c0),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter site address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addNewSite,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4a63c0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Add Site',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Existing Sites',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4a63c0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.sites.length}',
                          style: const TextStyle(
                            color: Color(0xFF4a63c0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.sites.length,
                      itemBuilder: (context, index) {
                        final site = widget.sites[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4a63c0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFF4a63c0),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              site.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            subtitle: Text(
                              site.description ?? 'No description',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 24,
                              ),
                              onPressed: () => _deleteSite(site),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final Function(List<Site>)? onSitesUpdated;
  final DashboardData? dashboardData;
  final int userId;
  final int employeeId;
  final int workspaceId;
  final String token;
  final String? currentCompany;
  final VoidCallback onSummaryTap; // Added callback

  const DashboardContent({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    this.onSitesUpdated,
    required this.dashboardData,
    required this.userId,
    required this.employeeId,
    required this.workspaceId,
    required this.token,
    this.currentCompany,
    required this.onSummaryTap,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _isLoadingLocation = false;
  bool _isClockingIn = false;
  bool _isClockedIn = false;
  String? _currentAttendanceId;
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAttendanceStatus();
  }

  Future<void> _loadAttendanceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _currentAttendanceId = prefs.getString('current_attendance_id');

    // Load persisted image if clocked in
    String? imagePath = prefs.getString('current_attendance_image_path');
    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) {
        _capturedImage = file;
      }
    }

    // You can also check with API to verify current status
    setState(() {
      _isClockedIn = _currentAttendanceId != null;
    });
  }

  Future<void> _checkPermissionAndClockInOut(String type) async {
    setState(() => _isLoadingLocation = true);

    try {
      // 1. Check Permissions
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
        if (!status.isGranted) {
          _showSnackBar(
            'Location permission is required to $type',
            isError: true,
          );
          return;
        }
      }

      // 2. Check Service
      Location location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _showSnackBar('Location service is disabled', isError: true);
          return;
        }
      }

      // 3. Get Location
      final locationData = await location.getLocation();

      // 4. Retrieve stored attendanceId if clocking out
      String? attendanceId;
      final prefs = await SharedPreferences.getInstance();
      if (type == 'clockout') {
        attendanceId = _currentAttendanceId;
        if (attendanceId == null) {
          _showSnackBar(
            'No active attendance found. Please clock in first.',
            isError: true,
          );
          return;
        }
      }

      // 5. Call API
      if (!mounted) return;
      setState(() => _isClockingIn = true);

      // Determine Site ID
      String? siteId = widget.selectedSiteId;
      if (siteId == null && widget.sites.isNotEmpty) {
        siteId = widget.sites.first.id;
      }

      if (siteId == null) {
        _showSnackBar('Please select a site first.', isError: true);
        setState(() {
          _isLoadingLocation = false;
          _isClockingIn = false;
        });
        return;
      }

      final result = await ApiService().clockInOut(
        type: type, // 'clockin' or 'clockout'
        userId: widget.userId.toString(),
        employeeId: widget.employeeId.toString(),
        workspaceId: widget.workspaceId.toString(),
        siteId: siteId,
        latitude: locationData.latitude.toString(),
        longitude: locationData.longitude.toString(),
        attendanceId: attendanceId,
        imageFile: _capturedImage,
      );

      print('DEBUG: Clock In/Out API Response: $result');

      if (!mounted) return;

      if (result['success']) {
        final msg =
            result['data']['message'] ??
            'Successfully ${type == 'clockin' ? 'Clocked In' : 'Clocked Out'}';
        _showSnackBar(msg, isError: false);

        // Update local state
        if (type == 'clockin') {
          if (result['data']['data'] != null) {
            final data = result['data']['data'];
            if (data['attendence_id'] != null) {
              _currentAttendanceId = data['attendence_id'].toString();
              await prefs.setString(
                'current_attendance_id',
                _currentAttendanceId!,
              );
            }
          }
          // Persist image on clock in
          if (_capturedImage != null) {
            final directory = await getApplicationDocumentsDirectory();
            final fileName =
                'clockin_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final savedImage = await _capturedImage!.copy(
              '${directory.path}/$fileName',
            );
            await prefs.setString(
              'current_attendance_image_path',
              savedImage.path,
            );
            _capturedImage = savedImage; // Update reference to persisted file
          }

          setState(() {
            _isClockedIn = true;
            // Do NOT clear image on clock in, keep it displayed
          });
        } else if (type == 'clockout') {
          _currentAttendanceId = null;
          await prefs.remove('current_attendance_id');
          await prefs.remove(
            'current_attendance_image_path',
          ); // Remove persisted image path

          setState(() {
            _isClockedIn = false;
            _capturedImage = null; // Clear image after clock out
          });
        }
      } else {
        _showSnackBar(result['message'] ?? 'Failed to $type', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _isClockingIn = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF4a63c0),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Compress image
        maxWidth: 800,
      );

      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardData = widget.dashboardData;
    if (dashboardData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh permissions which will trigger parent update via didChangeDependencies
        await Provider.of<CompanySiteProvider>(
          context,
          listen: false,
        ).refreshPermissions();
        // Also could reload dashboard data if we had the method, but permissions is the key here.
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryGrid(dashboardData),
            SizedBox(height: 24.h),

            // Clock In/Out Section - Updated with single toggle button
            if (widget.employeeId != 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F2937).withOpacity(0.06),
                      blurRadius: 24.r,
                      spreadRadius: -8,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF1F2937).withOpacity(0.04),
                      blurRadius: 4.r,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 16.sp,
                                  color: const Color(0xFF4a63c0),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'DAILY ATTENDANCE',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF4a63c0),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "Mark your presence for today",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Main card content
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(
                          color: const Color(0xFFF1F5F9),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Left side - Camera/Profile section
                          Container(
                            width: 100.w,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4a63c0).withOpacity(0.08),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20.r),
                                bottomLeft: Radius.circular(20.r),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _showImageSourceDialog,
                                  child: _capturedImage != null
                                      ? Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(
                                                12.r,
                                              ),
                                              child: Image.file(
                                                _capturedImage!,
                                                width: 80.w,
                                                height: 80.w,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _capturedImage = null;
                                                });
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.camera_alt_rounded,
                                              size: 24.sp,
                                              color: const Color(0xFF4a63c0),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              'Capture',
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: const Color(0xFF4a63c0),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),

                          // Right side - Clock in/out section
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Status indicator
                                  SizedBox(height: 12.h),

                                  // Toggle button
                                  _buildToggleAttendanceButton(),

                                  SizedBox(height: 12.h),

                                  // Start time display (if clocked in)
                                  if (_isClockedIn &&
                                      _currentAttendanceId != null)
                                    Text(
                                      'Clock Started at: ${DateFormat('hh:mm a').format(DateTime.now())}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color.fromARGB(
                                          255,
                                          39,
                                          39,
                                          39,
                                        ),
                                      ),
                                    )
                                  else
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 14.sp,
                                          color: const Color(0xFF4a63c0),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'Ready to clock in',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF4a63c0),
                                          ),
                                        ),
                                      ],
                                    ),

                                  SizedBox(height: 16.h),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Helper methods
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleAttendanceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_isLoadingLocation || _isClockingIn) return;

          if (_isClockedIn) {
            // Clock Out
            _checkPermissionAndClockInOut('clockout');
          } else {
            // Clock In
            _checkPermissionAndClockInOut('clockin');
          }
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: 140,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12),
          decoration: BoxDecoration(
            gradient: _isClockedIn
                ? LinearGradient(
                    colors: [Colors.red.shade500, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.green.shade500, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: (_isClockedIn ? Colors.red : Colors.green).withOpacity(
                  0.3,
                ),
                blurRadius: 12.r,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or loading indicator
              Container(
                height: 20.h,
                child: _isLoadingLocation || _isClockingIn
                    ? SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      )
                    : Icon(
                        _isClockedIn
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                        size: 18.sp,
                        color: Colors.white,
                      ),
              ),

              SizedBox(width: 10.w),

              // Text
              Text(
                _isClockedIn ? 'CLOCK OUT' : 'CLOCK IN',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method for camera/image handling

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required Color iconColor,
    required bool isLoading,
    required VoidCallback onTap,
    required bool isFirst,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(20.r) : Radius.zero,
          bottom: !isFirst ? Radius.circular(20.r) : Radius.zero,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          child: Row(
            children: [
              // Icon container with gradient
              Container(
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      )
                    : Icon(icon, size: 22.sp, color: iconColor),
              ),
              SizedBox(width: 16.w),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(DashboardData data) {
    // Check permissions
    final companyProvider = Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    );
    final hasSupplierAccess = companyProvider.hasPermission('supplier manage');
    final hasToolsAccess = companyProvider.hasPermission(
      'tools-and-equipment manage',
    );
    final hasManpowerAccess = companyProvider.hasPermission('manpower manage');
    final hasPaymentAccess = companyProvider.hasPermission(
      'manage-payment manage',
    );
    final hasDPRAccess = companyProvider.hasPermission('machinery-dpr manage');
    final hasEmployeeAccess = companyProvider.hasPermission('employee manage');
    final hasDocumentAccess = companyProvider.hasPermission('document manage');

    final List<Map<String, dynamic>> summaryItems = [
      if (hasEmployeeAccess)
        {
          'icon': Icons.person,
          'title': 'Employees',
          'value': data.totalWorkers.toString(),
          'color': const Color.fromARGB(
            255,
            241,
            189,
            208,
          ), // Darker Pastel Pink
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeePage(
                  selectedSiteId: widget.selectedSiteId,
                  onSiteChanged: widget.onSiteChanged,
                  sites: widget.sites,
                  workspaceId:
                      int.tryParse(
                        Provider.of<CompanySiteProvider>(
                              context,
                              listen: false,
                            ).selectedCompanyId ??
                            '',
                      ) ??
                      widget.workspaceId ??
                      3,
                ),
              ),
            );
          },
        },
      if (hasManpowerAccess)
        {
          'icon': Icons.engineering,
          'title': 'Manpower',
          'value': data.totalInspection.toString(),
          'color': const Color.fromARGB(
            255,
            196,
            208,
            241,
          ), // Darker Pastel Blue
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManpowerCountScreen(
                  selectedSiteId: widget.selectedSiteId,
                  onSiteChanged: widget.onSiteChanged,
                  sites: widget.sites,
                  workspaceId: widget.workspaceId,
                  currentCompany: widget.currentCompany,
                  userId: widget.userId,
                ),
              ),
            );
          },
        },
      {
        'icon': Icons.calendar_today,
        'title': 'Attendance',
        'value': data.totalPicking.toString(),
        'color': const Color.fromARGB(255, 211, 189, 233), // Darker Lavender
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceScreen(
                selectedSiteId: widget.selectedSiteId,
                onSiteChanged: widget.onSiteChanged,
                sites: widget.sites,
              ),
            ),
          );
        },
      },
      if (hasSupplierAccess)
        {
          'icon': Icons.local_shipping,
          'title': 'Supplier',
          'value': data.totalPicking.toString(),
          'color': const Color.fromARGB(255, 199, 236, 220), // Darker Mint
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SupplierLedger(
                  selectedSiteId: widget.selectedSiteId,
                  onSiteChanged: widget.onSiteChanged,
                  sites: widget.sites,
                  workspaceId: widget.workspaceId,
                  currentCompany: widget.currentCompany,
                  userId: widget.userId,
                ),
              ),
            );
          },
        },
      if (hasToolsAccess)
        {
          'icon': Icons.build,
          'title': 'Assets',
          'value': data.totalInspection.toString(),
          'color': const Color.fromARGB(255, 235, 184, 184), // Darker Peach
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ToolsScreen(
                  selectedSiteId: widget.selectedSiteId,
                  onSiteChanged: widget.onSiteChanged,
                  sites: widget.sites,
                ),
              ),
            );
          },
        },
      if (hasPaymentAccess)
        {
          'icon': Icons.payment,
          'title': 'Payment',
          'value': data.totalInspection.toString(),
          'color': const Color.fromARGB(255, 240, 230, 177), // Darker Mauve
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentsDetailScreen(
                  selectedSiteId: widget.selectedSiteId != null
                      ? int.tryParse(widget.selectedSiteId!)
                      : null,
                  selectedSiteName:
                      widget.selectedSiteId != null &&
                          widget.sites.any(
                            (s) => s.id.toString() == widget.selectedSiteId,
                          )
                      ? widget.sites
                            .firstWhere(
                              (s) => s.id.toString() == widget.selectedSiteId,
                            )
                            .name
                      : null,
                  workspaceId:
                      widget.selectedSiteId != null &&
                          widget.sites.any(
                            (s) => s.id.toString() == widget.selectedSiteId,
                          )
                      ? int.tryParse(
                          widget.sites
                              .firstWhere(
                                (s) => s.id.toString() == widget.selectedSiteId,
                              )
                              .companyId,
                        )
                      : widget.workspaceId,
                  userId: widget.userId,
                ),
              ),
            );
          },
        },
      if (hasDocumentAccess)
        {
          'icon': Icons.folder,
          'title': 'Documents',
          'value': data.totalInspection.toString(),
          'color': const Color.fromARGB(
            255,
            200,
            205,
            235,
          ), // Darker Periwinkle
          'onTap': () {
            final String effectiveSiteId =
                widget.selectedSiteId ??
                (widget.sites.isNotEmpty ? widget.sites.first.id : '');
            final String effectiveSiteName =
                widget.selectedSiteId != null &&
                    widget.sites.any((s) => s.id == widget.selectedSiteId)
                ? widget.sites
                      .firstWhere((s) => s.id == widget.selectedSiteId)
                      .name
                : (widget.sites.isNotEmpty ? widget.sites.first.name : '');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentStorageScreen(
                  selectedSiteId: effectiveSiteId,
                  siteId: effectiveSiteId,
                  siteName: effectiveSiteName,
                  onSiteChanged: widget.onSiteChanged,
                  sites: widget.sites,
                  selectedSite:
                      widget.selectedSiteId != null &&
                          widget.sites.any((s) => s.id == widget.selectedSiteId)
                      ? widget.sites.firstWhere(
                          (s) => s.id == widget.selectedSiteId,
                        )
                      : (widget.sites.isNotEmpty ? widget.sites.first : null),
                ),
              ),
            );
          },
        },
      
      {
        'icon': Icons.admin_panel_settings,
        'title': 'HR Admin',
        'value': data.totalInspection.toString(),
        'color': const Color.fromARGB(255, 175, 219, 245), // Light Orange
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HrAdminPage(
                selectedSiteId: widget.selectedSiteId,
                onSiteChanged: widget.onSiteChanged,
                sites: widget.sites,
                currentCompany: widget.currentCompany,
                workspaceId: widget.workspaceId,
                userId: widget.userId,
              ),
            ),
          );
        },
      },
      // {
      //   'icon': Icons.assignment,
      //   'title': 'Report',
      //   'value': data.totalInspection.toString(),
      //   'color': const Color.fromARGB(255, 255, 224, 178), // Light Orange
      //   'onTap': () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => ReportsScreen(
      //           selectedSiteId: widget.selectedSiteId,
      //           onSiteChanged: widget.onSiteChanged,
      //           sites: widget.sites,
      //           workspaceId: widget.workspaceId,
      //           token: widget.token,
      //           createdBy: widget.userId,
      //           currentCompany: widget.currentCompany,
      //         ),
      //       ),
      //     );
      //   },
      // },
      {
        'icon': Icons.summarize,
        'title': 'Report',
        'value': data.totalInspection.toString(), // You might want to change this value if needed
        'color': const Color.fromARGB(255, 250, 208, 188), // Light Deep Purple
        'onTap': widget.onSummaryTap,
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.0,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: summaryItems.length,
      itemBuilder: (context, index) {
        final item = summaryItems[index];
        final color = item['color'] as Color;

        final int targetValue = int.tryParse(item['value'] as String) ?? 0;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.95, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: item['onTap'] as VoidCallback,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned(
                          top: -25,
                          right: -25,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                255,
                                131,
                                131,
                                131,
                              ).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.all(
                            Responsive.isSmall(context)
                                ? 14
                                : Responsive.isLarge(context)
                                ? 18
                                : 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row with icon
                              Icon(
                                item['icon'] as IconData,
                                color: const Color.fromARGB(255, 36, 36, 36),
                                size: 34.sp,
                              ),

                              SizedBox(height: 8),

                              // Value with animation
                              // TweenAnimationBuilder<int>(
                              //   tween: IntTween(begin: 0, end: targetValue),
                              //   duration: const Duration(seconds: 1),
                              //   curve: Curves.easeOut,
                              //   builder: (context, value, child) {
                              //     return Text(
                              //       value.toString(),
                              //       style: TextStyle(
                              //         fontSize: 24,
                              //         fontWeight: FontWeight.bold,
                              //         color: Colors.white,
                              //         height: 1,
                              //       ),
                              //     );
                              //   },
                              // ),
                              SizedBox(height: 6),

                              // Title
                              Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 36, 36, 36),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
