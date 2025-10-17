import 'package:ecoteam_app/admin/Screens/Allmachinery_screen.dart';
import 'package:ecoteam_app/admin/Screens/Project-site_screen.dart';
import 'package:ecoteam_app/admin/Screens/all_material_page.dart';

import 'package:ecoteam_app/admin/Screens/machineryCategory_screen.dart';
import 'package:ecoteam_app/admin/Screens/role_management_page.dart';
import 'package:ecoteam_app/admin/Screens/admin_user_management_page.dart';
import 'package:ecoteam_app/admin/Screens/material_category_screen.dart';
import 'package:ecoteam_app/admin/Screens/supplier_categary_screen.dart';
import 'package:ecoteam_app/admin/Screens/tools_screen.dart';
import 'package:ecoteam_app/admin/Screens/unit_management_page.dart';
import 'package:ecoteam_app/admin/Screens/all_supplier_page.dart';
import 'package:ecoteam_app/main.dart';
import 'package:ecoteam_app/contractor/models/birthday_model.dart';
import 'package:ecoteam_app/contractor/models/dashboard_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/services/api_ser.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/attendance_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/more/machinary.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/more/material_screen.dart';

import 'package:ecoteam_app/contractor/view/contractor_dashboard/more/more_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/more/supplier.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/more/tools_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/worker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

// Activity Update Model
class ActivityUpdate {
  final int quantityCompleted;
  final DateTime date;

  ActivityUpdate({required this.quantityCompleted, required this.date});
}

// Activity Model
class Activity {
  final String id;
  String title;
  String scope;
  int quantity;
  String unit;
  int completedQuantity;
  String priority;
  String status;
  DateTime createdAt;
  List<ActivityUpdate> updates;

  int get balanceQuantity => quantity - completedQuantity;

  Activity({
    required this.id,
    required this.title,
    required this.scope,
    required this.quantity,
    required this.unit,
    required this.completedQuantity,
    required this.priority,
    required this.status,
    required this.createdAt,
    List<ActivityUpdate>? updates,
  }) : updates = updates ?? [];

  Activity copyWith({
    String? id,
    String? title,
    String? scope,
    int? quantity,
    String? unit,
    int? completedQuantity,
    String? priority,
    String? status,
    DateTime? createdAt,
    List<ActivityUpdate>? updates,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      scope: scope ?? this.scope,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      completedQuantity: completedQuantity ?? this.completedQuantity,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updates: updates ?? this.updates,
    );
  }
}

// Activity Provider
class ActivityProvider with ChangeNotifier {
  final List<Activity> _activities = [
    Activity(
      id: '1',
      title: 'Foundation Progress',
      scope: 'Foundation work',
      quantity: 100,
      unit: 'sq ft',
      completedQuantity: 85,
      priority: 'high',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Activity(
      id: '2',
      title: 'Material Delivery',
      scope: 'Steel beams delivery',
      quantity: 50,
      unit: 'tons',
      completedQuantity: 50,
      priority: 'medium',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),

    Activity(
      id: '3',
      title: 'Team Meeting',
      scope: 'Weekly coordination meeting',
      quantity: 1,
      unit: 'meeting',
      completedQuantity: 1,
      priority: 'low',
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  List<Activity> get activities => _activities;

  List<Activity> get pendingActivities =>
      _activities.where((activity) => activity.status == 'pending').toList();

  List<Activity> get completedActivities =>
      _activities.where((activity) => activity.status == 'completed').toList();

  void addActivity(Activity activity) {
    _activities.insert(0, activity);
    notifyListeners();
  }

  void updateActivity(String id, Activity updatedActivity) {
    final index = _activities.indexWhere((activity) => activity.id == id);
    if (index != -1) {
      _activities[index] = updatedActivity;
      notifyListeners();
    }
  }

  void markComplete(String id) {
    final index = _activities.indexWhere((activity) => activity.id == id);
    if (index != -1) {
      _activities[index] = _activities[index].copyWith(
        status: 'completed',
        completedQuantity: _activities[index].quantity,
      );
      notifyListeners();
    }
  }

  void markPending(String id) {
    final index = _activities.indexWhere((activity) => activity.id == id);
    if (index != -1) {
      _activities[index] = _activities[index].copyWith(status: 'pending');
      notifyListeners();
    }
  }

  void deleteActivity(String id) {
    _activities.removeWhere((activity) => activity.id == id);
    notifyListeners();
  }
}

class AdmindashboardScreen extends StatefulWidget {
  final Site? selectedSite;
  final String? companyName;
  const AdmindashboardScreen({super.key, this.selectedSite, this.companyName});

  @override
  State<AdmindashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<AdmindashboardScreen> {
  int _currentIndex = 0;
  String? _selectedSiteId;
  List<Site> _sites = [];
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _searchQuery;
  List<Widget> _screens = [];

  bool _isDashboardExpanded = false;
  bool _isUserManagementExpanded = false;
  bool _isMasterExpanded = false;
  bool _isMaterialExpanded = false;
  bool _isSupplierExpanded = false;
  bool _isAssetsExpanded = false;
  bool _isTransactionExpanded = false;
  bool _isProjectSitesExpanded = false;
  bool _isHRMExpanded = false;
  bool _isAttendanceExpanded = false;
  bool _isReportExpanded = false;
  bool _isSettingsExpanded = false;
  bool _isDailyTransactionExpanded = false;
  bool _isDailyConsumptionExpanded = false;
  bool _isMaterialTransferExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedSite != null) {
      _selectedSiteId = widget.selectedSite!.id;
    }
    _initializeScreens();
    _loadData();
  }

  void _initializeScreens() {
    _screens = [
      const Center(child: CircularProgressIndicator()),
      const Center(child: CircularProgressIndicator()),
      const Center(child: CircularProgressIndicator()),
      const Center(child: CircularProgressIndicator()),
      const Center(child: CircularProgressIndicator()),
    ];
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      print('Loading dashboard data...');
      final companyProvider = Provider.of<CompanySiteProvider>(
        context,
        listen: false,
      );
      _dashboardData = await ApiService()
          .fetchDashboardData(companyId: companyProvider.selectedCompanyId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Loading timeout - please check your connection');
            },
          );
      print(
        'Dashboard data loaded: \n  sites: ${_dashboardData?.sites.length}, selectedSiteId: ${_dashboardData?.selectedSiteId}',
      );
      _sites = companyProvider.sites;
      if (widget.selectedSite != null) {
        _selectedSiteId = widget.selectedSite!.id;
      } else if (_sites.isNotEmpty) {
        _selectedSiteId = _sites.first.id;
      } else {
        _selectedSiteId = null;
      }
      _screens = [
        DashboardContent(
          key: ValueKey('dashboard-${DateTime.now().millisecondsSinceEpoch}'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
          onSitesUpdated: _onSitesUpdated,
          dashboardData: _dashboardData,
        ),
        MaterialScreen(
          key: const PageStorageKey('materials'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
        MachineryScreen(
          key: const PageStorageKey('machinery'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
        MoreScreen(
          key: const PageStorageKey('more'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
      ];
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
      _screens = [
        DashboardContent(
          key: const PageStorageKey('dashboard'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
          onSitesUpdated: _onSitesUpdated,
          dashboardData: _dashboardData,
        ),
        MaterialScreen(
          key: const PageStorageKey('materials'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
        MachineryScreen(
          key: const PageStorageKey('machinery'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
        MoreScreen(
          key: const PageStorageKey('more'),
          selectedSiteId: _selectedSiteId,
          onSiteChanged: _onSiteChanged,
          sites: _sites,
        ),
      ];
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
                            !site.address.toLowerCase().contains(
                              _searchQuery!.toLowerCase(),
                            )) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          title: Text(
                            site.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(site.address),
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

    if (_dashboardData == null || _screens.isEmpty) {
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentIndex == 0
          ? AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              toolbarHeight: 80.h,
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
                children: [
                  if (widget.companyName != null) const SizedBox(height: 8),
                  if (widget.companyName != null)
                    Text(
                      widget.companyName!,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(239, 255, 255, 255),
                      ),
                    ),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: _sites.isEmpty ? null : _showSiteSelectorBottomSheet,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _sites.isEmpty
                              ? 'No Sites'
                              : (_selectedSiteId == null
                                    ? 'Select Site'
                                    : _sites
                                          .firstWhere(
                                            (site) =>
                                                site.id == _selectedSiteId,
                                            orElse: () => Site(
                                              id: '',
                                              name: 'Unknown Site',
                                              address: '',
                                            ),
                                          )
                                          .name),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (_sites.isNotEmpty) const SizedBox(width: 8),
                        if (_sites.isNotEmpty)
                          const Icon(
                            Icons.keyboard_arrow_down_outlined,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              centerTitle: false,
            )
          : null,
      drawer: _currentIndex == 0 ? _buildNavigationDrawer() : null,
      body: IndexedStack(index: _currentIndex, children: _screens),
      
    );
  }

  Widget _buildNavigationDrawer() {
  return Drawer(
    child: Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header section remains the same
          Container(
            padding: EdgeInsets.only(top: 50.h, bottom: 20.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AdminColors.primary, AdminColors.primaryLight],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Dashboard Section
                _buildExpandableDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isExpanded: _isDashboardExpanded,
                  onTap: () {
                    setState(() {
                      _isDashboardExpanded = !_isDashboardExpanded;
                    });
                  },
                ),
                if (_isDashboardExpanded) ...[
                  _buildSubDrawerItem(
                    icon: Icons.business_center,
                    title: 'Project/Site Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildSubDrawerItem(
                    icon: Icons.people_alt,
                    title: 'HRM Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('HRM Dashboard coming soon');
                    },
                  ),
                ],

                // User Management Section
                _buildExpandableDrawerItem(
                  icon: Icons.people,
                  title: 'User Management',
                  isExpanded: _isUserManagementExpanded,
                  onTap: () {
                    setState(() {
                      _isUserManagementExpanded = !_isUserManagementExpanded;
                    });
                  },
                ),
                if (_isUserManagementExpanded) ...[
                  _buildSubDrawerItem(
                    icon: Icons.person,
                    title: 'User',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminUserManagementPage(),
                        ),
                      );
                    },
                  ),
                  _buildSubDrawerItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Role',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminRoleManagementPage(),
                        ),
                      );
                    },
                  ),
                ],

                // Master Section
                _buildExpandableDrawerItem(
                  icon: Icons.inventory,
                  title: 'Master',
                  isExpanded: _isMasterExpanded,
                  onTap: () {
                    setState(() {
                      _isMasterExpanded = !_isMasterExpanded;
                    });
                  },
                ),
                if (_isMasterExpanded) ...[
                  // Material Sub-section
                  _buildExpandableSubDrawerItem(
                    icon: Icons.inventory_2,
                    title: 'Material',
                    isExpanded: _isMaterialExpanded,
                    onTap: () {
                      setState(() {
                        _isMaterialExpanded = !_isMaterialExpanded;
                      });
                    },
                  ),
                  if (_isMaterialExpanded) ...[
                    _buildNestedSubDrawerItem(
                      icon: Icons.list,
                      title: 'All Material',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAllMaterialPage(),
                          ),
                        );
                      },
                    ),
                    _buildNestedSubDrawerItem(
                      icon: Icons.category,
                      title: 'Material Category',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MaterialCategoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildNestedSubDrawerItem(
                      icon: Icons.straighten,
                      title: 'Unit',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UnitManagementPage(),
                          ),
                        );
                      },
                    ),
                  ],

                  // Supplier Sub-section
                  _buildExpandableSubDrawerItem(
                    icon: Icons.business_center,
                    title: 'Supplier',
                    isExpanded: _isSupplierExpanded,
                    onTap: () {
                      setState(() {
                        _isSupplierExpanded = !_isSupplierExpanded;
                      });
                    },
                  ),
                  if (_isSupplierExpanded) ...[
                    _buildNestedSubDrawerItem(
                      icon: Icons.list,
                      title: 'All Supplier',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllSupplierPage(),
                          ),
                        );
                      },
                    ),
                    _buildNestedSubDrawerItem(
                      icon: Icons.category,
                      title: 'Supplier Category',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SupplierCategoriesScreen(),
                          ),
                        );
                      },
                    ),
                  ],

                  // Assets Sub-section
                  _buildExpandableSubDrawerItem(
                    icon: Icons.devices,
                    title: 'Assets',
                    isExpanded: _isAssetsExpanded,
                    onTap: () {
                      setState(() {
                        _isAssetsExpanded = !_isAssetsExpanded;
                      });
                    },
                  ),
                  if (_isAssetsExpanded) ...[
                    _buildNestedSubDrawerItem(
                      icon: Icons.build,
                      title: 'All machinery',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAllMachineryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildNestedSubDrawerItem(
                      icon: Icons.category,
                      title: 'machinery Category',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MachineryCategoriesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildNestedSubDrawerItem(
                      icon: Icons.handyman,
                      title: 'tools & equipment',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  ToolsEquipmentPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ],

                // Transaction Section
                _buildExpandableDrawerItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Transaction',
                  isExpanded: _isTransactionExpanded,
                  onTap: () {
                    setState(() {
                      _isTransactionExpanded = !_isTransactionExpanded;
                    });
                  },
                ),
                if (_isTransactionExpanded) ...[
                  _buildExpandableSubDrawerItem(
                    icon: Icons.business_center,
                    title: 'Daily Transaction',
                    isExpanded: _isDailyTransactionExpanded,
                    onTap: () {
                      setState(() {
                        _isDailyTransactionExpanded = !_isDailyTransactionExpanded;
                      });
                    },
                  ),
                  if (_isDailyTransactionExpanded) ...[
                    _buildNestedSubDrawerItem(
                      icon: Icons.list,
                      title: 'Purchase Invoice',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar('Purchase Invoice coming soon');
                      },
                    ),
                  ],
                  _buildExpandableSubDrawerItem(
                    icon: Icons.business_center,
                    title: 'Daily Consumption',
                    isExpanded: _isDailyConsumptionExpanded,
                    onTap: () {
                      setState(() {
                        _isDailyConsumptionExpanded = !_isDailyConsumptionExpanded;
                      });
                    },
                  ),
                  if (_isDailyConsumptionExpanded) ...[
                    _buildNestedSubDrawerItem(
                      icon: Icons.list,
                      title: 'machinery Rental',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar('Machinery Rental coming soon');
                      },
                    ),
                    _buildNestedSubDrawerItem(
                      icon: Icons.list,
                      title: 'machinery Fuel',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar('Machinery Fuel coming soon');
                      },
                    ),
                    _buildNestedSubDrawerItem(
                      icon: Icons.list,
                      title: 'manpower',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar('Manpower coming soon');
                      },
                    ),
                  ],
                  _buildSubDrawerItem(
                    icon: Icons.swap_horiz,
                    title: 'Material Transfer',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Material Transfer coming soon');
                    },
                  ),
                ],

                // Project/Sites Section
                _buildExpandableDrawerItem(
                  icon: Icons.business,
                  title: 'Project/Sites',
                  isExpanded: _isProjectSitesExpanded,
                  onTap: () {
                    setState(() {
                      _isProjectSitesExpanded = !_isProjectSitesExpanded;
                    });
                  },
                ),
                if (_isProjectSitesExpanded) ...[
                  _buildSubDrawerItem(
                    icon: Icons.list,
                    title: 'All Project/Site',
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectSitePage(),
                          ),
                        );
                    },
                  ),
                  _buildSubDrawerItem(
                    icon: Icons.assessment,
                    title: 'Project/Site Report',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Project/Site Report coming soon');
                    },
                  ),
                ],

                // HRM Section
                _buildExpandableDrawerItem(
                  icon: Icons.group,
                  title: 'HRM',
                  isExpanded: _isHRMExpanded,
                  onTap: () {
                    setState(() {
                      _isHRMExpanded = !_isHRMExpanded;
                    });
                  },
                ),
                if (_isHRMExpanded) ...[
                  _buildSubDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Employee',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Employee management coming soon');
                    },
                  ),
                  _buildExpandableSubDrawerItem(
                    icon: Icons.fact_check,
                    title: 'Attendance',
                    isExpanded: _isAttendanceExpanded,
                    onTap: () {
                      setState(() {
                        _isAttendanceExpanded = !_isAttendanceExpanded;
                      });
                    },
                  ),
                  if (_isAttendanceExpanded) ...[
                    _buildNestedSubDrawerItem(
                      icon: Icons.check_circle,
                      title: 'Mark Attendance',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar('Mark Attendance coming soon');
                      },
                    ),
                    _buildNestedSubDrawerItem(
                      icon: Icons.group_add,
                      title: 'Bulk Attendance',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar('Bulk Attendance coming soon');
                      },
                    ),
                  ],
                  _buildSubDrawerItem(
                    icon: Icons.calendar_today,
                    title: 'Manage Leave',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Leave management coming soon');
                    },
                  ),
                  _buildSubDrawerItem(
                    icon: Icons.description,
                    title: 'Document',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('HR Document management coming soon');
                    },
                  ),
                  _buildExpandableSubDrawerItem(
                    icon: Icons.bar_chart,
                    title: 'Report',
                    isExpanded: _isReportExpanded,
                    onTap: () {
                      setState(() {
                        _isReportExpanded = !_isReportExpanded;
                      });
                    },
                  ),
                  if (_isReportExpanded) ...[
                    _buildNestedSubDrawerItem(
                      icon: Icons.calendar_view_month,
                      title: 'Monthly Attendance',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar('Monthly Attendance coming soon');
                      },
                    ),
                    _buildNestedSubDrawerItem(
                      icon: Icons.leave_bags_at_home,
                      title: 'Leave Report',
                      onTap: () {
                        Navigator.pop(context);
                        _showSnackBar('Leave Report coming soon');
                      },
                    ),
                  ],
                ],

                // Chat
                _buildDrawerItem(
                  icon: Icons.chat,
                  title: 'Chat',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Chat functionality coming soon');
                  },
                ),

                // Settings
                _buildExpandableDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  isExpanded: _isSettingsExpanded,
                  onTap: () {
                    setState(() {
                      _isSettingsExpanded = !_isSettingsExpanded;
                    });
                  },
                ),
                if (_isSettingsExpanded) ...[
                  _buildSubDrawerItem(
                    icon: Icons.settings_applications,
                    title: 'System settings',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('System settings coming soon');
                    },
                  ),
                ],

                const Divider(),

                // Logout
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Logout functionality coming soon');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AdminColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: AdminColors.textPrimary,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  Widget _buildExpandableDrawerItem({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AdminColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: AdminColors.textPrimary,
        ),
      ),
      trailing: Icon(
        isExpanded ? Icons.expand_less : Icons.expand_more,
        color: AdminColors.primary,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  Widget _buildSubDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 16.w),
      child: ListTile(
        leading: Icon(icon, color: AdminColors.primary.withOpacity(0.7), size: 20.sp),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AdminColors.textPrimary.withOpacity(0.8),
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      ),
    );
  }

  Widget _buildExpandableSubDrawerItem({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 16.w),
      child: ListTile(
        leading: Icon(icon, color: AdminColors.primary.withOpacity(0.7), size: 20.sp),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AdminColors.textPrimary.withOpacity(0.8),
          ),
        ),
        trailing: Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: AdminColors.primary.withOpacity(0.7),
          size: 18.sp,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      ),
    );
  }

  Widget _buildNestedSubDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 32.w),
      child: ListTile(
        leading: Icon(icon, color: AdminColors.primary.withOpacity(0.6), size: 18.sp),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: AdminColors.textPrimary.withOpacity(0.7),
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.r),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
        dense: true,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
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
        address: _siteAddressController.text.trim(),
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
                              site.address,
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

class DashboardContent extends StatelessWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final Function(List<Site>)? onSitesUpdated;
  final DashboardData? dashboardData;
  const DashboardContent({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    this.onSitesUpdated,
    required this.dashboardData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Expanded(
        child: dashboardData == null
            ? _buildEmptyState()
            : _buildDashboardContent(context),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      color: const Color(0xFF4a63c0),
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                _buildSummaryGrid(dashboardData!),
                const SizedBox(height: 24),
                
                _buildBirthdayReminders(),
                const SizedBox(height: 120), // Space for FABs
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(DashboardData data) {
    final summaryItems = [
      
      {
        'icon': Icons.fact_check_outlined,
        'title': 'Machinary',
        'value': data.totalInspection.toString(),
        'subtitle': 'Total Count',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.badge_outlined,
        'title': 'Projects/Sites',
        'value': data.totalPicking.toString(),
        'subtitle': 'This month',
        'color': const Color.fromARGB(255, 238, 105, 43),
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'title': 'Material',
        'value': data.totalPicking.toString(),
        'subtitle': 'Total Items',
        'color': const Color.fromARGB(255, 55, 140, 189),
      },
      
      {
        'icon': Icons.build_outlined,
        'title': 'All Users',
        'value': data.totalInspection.toString(),
        'subtitle': 'Total Items',
        'color': const Color(0xFF00ACC1),
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'title': 'Supplier',
        'value': data.totalPicking.toString(),
        'subtitle': 'This month',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.handyman_outlined,
        'title': 'Assets/Tools',
        'value': data.totalInspection.toString(),
        'subtitle': 'Total Items',
        'color': const Color(0xFF10B981),
      },
    ];
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: summaryItems.length,
      itemBuilder: (context, index) {
        final item = summaryItems[index];
        final color = item['color'] as Color;
        final int targetValue = int.tryParse(item['value'] as String) ?? 0;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(seconds: 3),
          curve: Curves.easeOutBack,
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: () {
                  // Navigate to respective page based on index
                  switch (index) {
                    // case 0: // Inventory
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (context) =>
                    //         InventoryDetailScreen(selectedSiteId: selectedSiteId, onSiteChanged: onSiteChanged, sites: sites)
                    //     ),
                    //   );
                    //   break;
                    case 0: // Workers
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkersScreen(
                            selectedSiteId: selectedSiteId,
                            onSiteChanged: onSiteChanged,
                            sites: sites,
                          ),
                        ),
                      );
                      break;
                    case 1: // Machinary
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MachineryScreen(
                            selectedSiteId: selectedSiteId,
                            onSiteChanged: onSiteChanged,
                            sites: sites,
                          ),
                        ),
                      );
                      break;
                    case 2: // Attendance
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceScreen(
                            selectedSiteId: selectedSiteId,
                            onSiteChanged: onSiteChanged,
                            sites: sites,
                          ),
                        ),
                      );
                      break;
                    case 3: // Material
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MaterialScreen(
                            selectedSiteId: selectedSiteId,
                            onSiteChanged: onSiteChanged,
                            sites: sites,
                          ),
                        ),
                      );
                      break;
                    case 4: // Supplier
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupplierLedger(
                            selectedSiteId: selectedSiteId,
                            onSiteChanged: onSiteChanged,
                            sites: sites,
                          ),
                        ),
                      );
                      break;
                    case 5: // Assets/Tools
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ToolsScreen(
                            selectedSiteId: selectedSiteId,
                            onSiteChanged: onSiteChanged,
                            sites: sites,
                          ),
                        ),
                      );
                      break;
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withOpacity(0.20),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      Responsive.isSmall(context)
                          ? 6.w
                          : Responsive.isLarge(context)
                          ? 12.w
                          : 9.w,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: color,
                              size: 18.sp,
                            ),
                            TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 0, end: targetValue),
                              duration: const Duration(seconds: 1),
                              builder: (context, value, child) {
                                return Text(
                                  value.toString(),
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 13.h),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              item['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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

  Widget _buildBirthdaySection(
    String title,
    List<Birthday> birthdays, {
    required bool isToday,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: birthdays.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final birthday = birthdays[index];
            return _buildBirthdayCard(birthday, isToday: isToday);
          },
        ),
      ],
    );
  }

  Widget _buildBirthdayCard(Birthday birthday, {required bool isToday}) {
    return Consumer<BirthdayProvider>(
      builder: (context, birthdayProvider, child) {
        return Container(
          padding: EdgeInsets.all(10.h),
          decoration: BoxDecoration(
            color: isToday
                ? Colors.yellow.shade50
                : const Color.fromARGB(255, 248, 249, 252),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isToday ? Colors.yellow.shade200 : Colors.grey.shade100,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color.fromARGB(255, 255, 225, 181)
                      : Colors.pink.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isToday ? Icons.cake : Icons.card_giftcard,
                  color: isToday ? Colors.orange : Colors.pink,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      birthday.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14.sp,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          DateFormat('MMM dd, yyyy').format(birthday.date),
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (!isToday) ...[
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getDaysLeftColor(
                            birthday.daysUntilBirthday,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          birthday.daysUntilBirthday == 0
                              ? '🎉 Today!'
                              : '${birthday.daysUntilBirthday} ${birthday.daysUntilBirthday == 1 ? 'day' : 'days'} left',
                          style: TextStyle(
                            color: _getDaysLeftColor(
                              birthday.daysUntilBirthday,
                            ),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.red.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.5),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.celebration,
                              color: Colors.white,
                              size: 14.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "It's their birthday!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 18.sp, color: Colors.red),
                onPressed: () => birthdayProvider.deleteBirthday(birthday.id),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivities() {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final pendingActivities = activityProvider.pendingActivities;
        final completedActivities = activityProvider.completedActivities;

        return Column(
          children: [
            _buildActivitySection(
              "Pending Activities",
              pendingActivities,
              false,
            ),
            SizedBox(height: 20.h),
            if (completedActivities.isNotEmpty)
              _buildActivitySection(
                "Completed Activities",
                completedActivities,
                true,
              ),
          ],
        );
      },
    );
  }

  Widget _buildBirthdayReminders() {
    return Consumer<BirthdayProvider>(
      builder: (context, birthdayProvider, child) {
        final upcomingBirthdays = birthdayProvider.upcomingBirthdays;
        final todaysBirthdays = birthdayProvider.todaysBirthdays;

        if (upcomingBirthdays.isEmpty && todaysBirthdays.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Birthday Reminders',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 16.h),
            if (todaysBirthdays.isNotEmpty) ...[
              _buildBirthdaySection(
                "Today's Birthdays",
                todaysBirthdays,
                isToday: true,
              ),
              SizedBox(height: 20.h),
            ],
            if (upcomingBirthdays.isNotEmpty)
              _buildBirthdaySection(
                "Upcoming Birthdays",
                upcomingBirthdays,
                isToday: false,
              ),
          ],
        );
      },
    );
  }

  // Section builder
  Widget _buildActivitySection(
    String title,
    List<Activity> data,
    bool completed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 16.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final activity = data[index];
            return _buildActivityCard(activity, completed);
          },
        ),
      ],
    );
  }

  // Activity card with dynamic buttons
  Widget _buildActivityCard(Activity activity, bool completed) {
    IconData getIconForActivity() {
      switch (activity.priority) {
        case 'urgent':
          return Icons.assignment_late;
        case 'high':
          return Icons.update;
        case 'medium':
          return Icons.local_shipping;
        case 'low':
          return Icons.people;
        default:
          return Icons.task;
      }
    }

    Color getColorForActivity() {
      switch (activity.priority) {
        case 'urgent':
          return const Color(0xFFEF4444);
        case 'high':
          return const Color(0xFF10B981);
        case 'medium':
          return const Color(0xFFF59E0B);
        case 'low':
          return const Color(0xFF8B5CF6);
        default:
          return const Color(0xFF6B7280);
      }
    }

    String getTimeAgo(BuildContext context) {
      final now = DateTime.now();
      final difference = now.difference(activity.createdAt);
      final isSmall = Responsive.isSmall(context);

      if (difference.inDays >= 7) {
        // More than a week ago, show date
        final date = activity.createdAt;
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final activityDate = DateTime(date.year, date.month, date.day);

        if (activityDate == today) {
          return 'Today';
        } else if (activityDate == yesterday) {
          return 'Yesterday';
        } else {
          return isSmall
              ? '${date.day}/${date.month}'
              : '${date.day}/${date.month}/${date.year}';
        }
      } else if (difference.inDays > 0) {
        return isSmall
            ? '${difference.inDays}d ago'
            : '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Now';
      }
    }

    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final progressPercentage = activity.quantity > 0
            ? (activity.completedQuantity / activity.quantity)
            : 0.0;

        return Dismissible(
          key: ValueKey(activity.id),
          direction: DismissDirection.horizontal,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 10.w),
            color: Colors.blue.shade100,
            child: Icon(Icons.edit, color: Colors.blue.shade700, size: 28.sp),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20.w),
            color: Colors.red.shade100,
            child: Icon(Icons.delete, color: Colors.red.shade700, size: 28.sp),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Swipe right -> edit
              _showAddActivityBottomSheet(context, existingActivity: activity);
              return false;
            } else if (direction == DismissDirection.endToStart) {
              // Swipe left -> delete
              _showDeleteConfirmationDialog(
                context,
                activity,
                activityProvider,
              );
              return false;
            }
            return false;
          },
          child: InkWell(
            onTap: () => _showActivityDetailsBottomSheet(context, activity),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(color: Colors.grey.shade50, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  Responsive.isSmall(context) ? 12.h : 20.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Title and Time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Priority indicator
                        Container(
                          width: 3.w,
                          height: Responsive.isSmall(context) ? 30.h : 40.h,
                          decoration: BoxDecoration(
                            color: activity.priority == 'urgent'
                                ? const Color(0xFFEF4444)
                                : activity.priority == 'high'
                                ? const Color(0xFFF59E0B)
                                : activity.priority == 'medium'
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                        SizedBox(
                          width: Responsive.isSmall(context) ? 12.w : 16.w,
                        ),
                        // Priority Icon
                        Container(
                          padding: EdgeInsets.all(
                            Responsive.isSmall(context) ? 6.w : 7.w,
                          ),
                          decoration: BoxDecoration(
                            color: getColorForActivity().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            getIconForActivity(),
                            color: getColorForActivity(),
                            size: Responsive.isSmall(context) ? 16.sp : 18.sp,
                          ),
                        ),
                        SizedBox(
                          width: Responsive.isSmall(context) ? 8.w : 12.w,
                        ),
                        // Title and Scope in Expanded Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: Responsive.isSmall(context)
                                      ? 14.sp
                                      : 16.sp,
                                  color: const Color(0xFF1F2937),
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(
                                height: Responsive.isSmall(context) ? 4.h : 8.h,
                              ),
                              Text(
                                activity.scope,
                                style: TextStyle(
                                  color: const Color(0xFF6B7280),
                                  fontSize: Responsive.isSmall(context)
                                      ? 12.sp
                                      : 14.sp,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Time badge
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Responsive.isSmall(context) ? 60.w : 80.w,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.isSmall(context)
                                  ? 6.w
                                  : 10.w,
                              vertical: Responsive.isSmall(context) ? 2.h : 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              getTimeAgo(context),
                              style: TextStyle(
                                color: const Color(0xFF64748B),
                                fontSize: Responsive.isSmall(context)
                                    ? 9.sp
                                    : 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Responsive.isSmall(context) ? 6.h : 10.h),

                    // Progress and Mark Complete in Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Circular Progress and Progress Info
                        Row(
                          children: [
                            // Circular Progress
                            GestureDetector(
                              onTap: () => _showQuickQuantityEditDialog(
                                context,
                                activity,
                                activityProvider,
                              ),
                              child: Container(
                                width: Responsive.isSmall(context)
                                    ? 40.0
                                    : 50.0,
                                height: Responsive.isSmall(context)
                                    ? 40.0
                                    : 50.0,
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
                                      width: Responsive.isSmall(context)
                                          ? 32.0
                                          : 40.0,
                                      height: Responsive.isSmall(context)
                                          ? 32.0
                                          : 40.0,
                                      child: CircularProgressIndicator(
                                        value: progressPercentage,
                                        backgroundColor: Colors.grey.shade100,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              getColorForActivity(),
                                            ),
                                        strokeWidth: 2.w,
                                      ),
                                    ),
                                    Text(
                                      '${(progressPercentage * 100).round()}%',
                                      style: TextStyle(
                                        fontSize: Responsive.isSmall(context)
                                            ? 11.sp
                                            : 13.sp,
                                        fontWeight: FontWeight.w800,
                                        color: getColorForActivity(),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(
                              width: Responsive.isSmall(context) ? 6.w : 8.w,
                            ),

                            // Progress Info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${activity.completedQuantity}/${activity.quantity} ${activity.unit}',
                                  style: TextStyle(
                                    fontSize: Responsive.isSmall(context)
                                        ? 11.sp
                                        : 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Status Button
                        if (!completed)
                          InkWell(
                            onTap: () =>
                                activityProvider.markComplete(activity.id),
                            borderRadius: BorderRadius.circular(25.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.isSmall(context)
                                    ? 8.w
                                    : 12.w,
                                vertical: Responsive.isSmall(context)
                                    ? 6.h
                                    : 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green.shade600,
                                    size: Responsive.isSmall(context)
                                        ? 14.sp
                                        : 16.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    Responsive.isSmall(context)
                                        ? 'Complete'
                                        : 'Mark Complete',
                                    style: TextStyle(
                                      fontSize: Responsive.isSmall(context)
                                          ? 10.sp
                                          : 11.sp,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.isSmall(context)
                                  ? 8.w
                                  : 12.w,
                              vertical: Responsive.isSmall(context) ? 6.h : 8.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade50,
                                  Colors.orange.shade100,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.orange.shade200,
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () =>
                                  activityProvider.markPending(activity.id),
                              borderRadius: BorderRadius.circular(20.r),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.orange.shade600,
                                    size: Responsive.isSmall(context)
                                        ? 14.sp
                                        : 16.sp,
                                  ),
                                  SizedBox(
                                    width: Responsive.isSmall(context)
                                        ? 4.w
                                        : 6.w,
                                  ),
                                  Text(
                                    Responsive.isSmall(context)
                                        ? 'Reopen'
                                        : 'Reopen Task',
                                    style: TextStyle(
                                      fontSize: Responsive.isSmall(context)
                                          ? 10.sp
                                          : 11.sp,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    Activity activity,
    ActivityProvider activityProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 28),
            SizedBox(width: 12),
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
          'Are you sure you want to delete "${activity.title}"?\n\nThis action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              activityProvider.deleteActivity(activity.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Activity "${activity.title}" deleted successfully',
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showActivityDetailsBottomSheet(
    BuildContext context,
    Activity activity,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600 || screenWidth < 400;
    final progressPercentage = activity.quantity > 0
        ? (activity.completedQuantity / activity.quantity)
        : 0.0;

    IconData getIconForActivity() {
      switch (activity.priority) {
        case 'urgent':
          return Icons.assignment_late;
        case 'high':
          return Icons.update;
        case 'medium':
          return Icons.local_shipping;
        case 'low':
          return Icons.people;
        default:
          return Icons.task;
      }
    }

    Color getColorForActivity() {
      switch (activity.priority) {
        case 'urgent':
          return const Color(0xFFEF4444);
        case 'high':
          return const Color(0xFF10B981);
        case 'medium':
          return const Color(0xFFF59E0B);
        case 'low':
          return const Color(0xFF8B5CF6);
        default:
          return const Color(0xFF6B7280);
      }
    }

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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 25,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header with gradient
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            getColorForActivity().withOpacity(0.1),
                            getColorForActivity().withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Activity icon and title
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: getColorForActivity().withOpacity(
                                    0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: getColorForActivity().withOpacity(
                                      0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  getIconForActivity(),
                                  color: getColorForActivity(),
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
                                        color: const Color(0xFF1F2937),
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
                                        color: activity.status == 'completed'
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Text(
                                        activity.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                          color: activity.status == 'completed'
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
                                        color: getColorForActivity(),
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Progress',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  Row(
                                    children: [
                                      // Circular Progress
                                      Container(
                                        width: 60.w,
                                        height: 60.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              getColorForActivity().withOpacity(
                                                0.15,
                                              ),
                                              getColorForActivity().withOpacity(
                                                0.08,
                                              ),
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
                                                value: progressPercentage,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(getColorForActivity()),
                                                strokeWidth: 3.w,
                                              ),
                                            ),
                                            Text(
                                              '${(progressPercentage * 100).round()}%',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.bold,
                                                color: getColorForActivity(),
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
                                                color: const Color(0xFF1F2937),
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              '${activity.balanceQuantity} ${activity.unit} remaining',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: const Color(0xFF6B7280),
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

                            // Scope Section
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.description,
                                        color: const Color(0xFF6B7280),
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Scope',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    activity.scope,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF374151),
                                      height: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 20),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: const Color(0xFF6B7280),
                                            size: 20.sp,
                                          ),
                                          SizedBox(width: 4.w), // Added spacing
                                          Text(
                                            'Created',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: const Color(0xFF6B7280),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h), // Added spacing
                                      Row(
                                        children: [
                                          Text(
                                            DateFormat(
                                              'MMM dd, yyyy • hh:mm a',
                                            ).format(activity.createdAt),
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: const Color(0xFF1F2937),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (activity.updates.isNotEmpty) ...[
                              SizedBox(height: 20.h),

                              // Update History
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
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
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
                                          color: const Color(0xFF6B7280),
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Update History',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: activity.updates.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                            height: 16.h,
                                            color: Colors.grey.shade200,
                                          ),
                                      itemBuilder: (context, index) {
                                        final update = activity.updates[index];
                                        return Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8.w),
                                              decoration: BoxDecoration(
                                                color: getColorForActivity()
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                              child: Icon(
                                                Icons.check_circle,
                                                color: getColorForActivity(),
                                                size: 16.sp,
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${update.quantityCompleted} ${activity.unit} completed',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFF1F2937,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    DateFormat(
                                                      'MMM dd, yyyy • hh:mm a',
                                                    ).format(update.date),
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: const Color(
                                                        0xFF6B7280,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
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

  void _showAddActivityBottomSheet(
    BuildContext context, {
    Activity? existingActivity,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final isSmallScreen = screenHeight < 600 || screenWidth < 400;
    final isEditing = existingActivity != null;
    final titleController = TextEditingController(
      text: isEditing ? existingActivity.title : '',
    );
    final scopeController = TextEditingController(
      text: isEditing ? existingActivity.scope : '',
    );
    final quantityController = TextEditingController(
      text: isEditing ? existingActivity.quantity.toString() : '',
    );
    final unitController = TextEditingController(
      text: isEditing ? existingActivity.unit : '',
    );
    final completedQuantityController = TextEditingController(
      text: isEditing ? existingActivity.completedQuantity.toString() : '0',
    );
    String selectedPriority = isEditing ? existingActivity.priority : 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight:
              screenHeight *
              (isKeyboardOpen ? 0.98 : (isSmallScreen ? 0.85 : 0.9)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: isKeyboardOpen ? 0.95 : (isSmallScreen ? 0.9 : 0.7),
          minChildSize: isKeyboardOpen ? 0.8 : (isSmallScreen ? 0.7 : 0.5),
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
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
                                borderRadius: BorderRadius.circular(2),
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
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12.r),
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.title,
                                        color: Color.fromARGB(255, 46, 74, 179),
                                        size: 20.sp,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.h,
                                        horizontal: 12.w,
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
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12.r),
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.description,
                                        color: Color.fromARGB(255, 46, 74, 179),
                                        size: 20.sp,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.h,
                                        horizontal: 12.w,
                                      ),
                                    ),
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 12.h),
                                  TextField(
                                    controller: quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Quantity',
                                      hintText: 'e.g. 100',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12.r),
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.numbers,
                                        color: Color.fromARGB(255, 46, 74, 179),
                                        size: 20.sp,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.h,
                                        horizontal: 12.w,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  TextField(
                                    controller: unitController,
                                    decoration: InputDecoration(
                                      labelText: 'Unit',
                                      hintText: 'e.g. sq ft, tons',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12.r),
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.straighten,
                                        color: Color.fromARGB(255, 46, 74, 179),
                                        size: 20.sp,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.h,
                                        horizontal: 12.w,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  TextField(
                                    controller: completedQuantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Completed Quantity',
                                      hintText: 'e.g. 85',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12.r),
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.check_circle,
                                        color: Color.fromARGB(255, 46, 74, 179),
                                        size: 20.sp,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.h,
                                        horizontal: 12.w,
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
                                          fontSize: 12.sp,
                                          color: balance >= 0
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 16.h),
                                  DropdownButtonFormField<String>(
                                    value: selectedPriority,
                                    decoration: InputDecoration(
                                      labelText: 'Priority',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12.r),
                                        ),
                                      ),
                                      prefixIcon: Icon(Icons.flag, size: 20.sp),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.h,
                                        horizontal: 12.w,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'low',
                                        child: Text('Low Priority'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'medium',
                                        child: Text('Medium Priority'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'high',
                                        child: Text('High Priority'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'urgent',
                                        child: Text('Urgent'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setSheetState(
                                          () => selectedPriority = value,
                                        );
                                      }
                                    },
                                  ),
                                  SizedBox(height: 24.h),
                                  Container(
                                    height: 56.h,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
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
                                          color: const Color(
                                            0xFF4a63c0,
                                          ).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
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
                                      onPressed: () {
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
                                                .isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please fill all required fields',
                                              ),
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

                                        final activityProvider =
                                            Provider.of<ActivityProvider>(
                                              context,
                                              listen: false,
                                            );

                                        final activity = Activity(
                                          id: isEditing
                                              ? existingActivity!.id
                                              : DateTime.now()
                                                    .millisecondsSinceEpoch
                                                    .toString(),
                                          title: titleController.text.trim(),
                                          scope: scopeController.text.trim(),
                                          quantity: quantity,
                                          unit: unitController.text.trim(),
                                          completedQuantity: completedQuantity,
                                          priority: selectedPriority,
                                          status: isEditing
                                              ? existingActivity!.status
                                              : 'pending',
                                          createdAt: isEditing
                                              ? existingActivity!.createdAt
                                              : DateTime.now(),
                                        );

                                        if (isEditing) {
                                          activityProvider.updateActivity(
                                            activity.id,
                                            activity,
                                          );
                                        } else {
                                          activityProvider.addActivity(
                                            activity,
                                          );
                                        }
                                        Navigator.pop(context);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Activity "${activity.title}" ${isEditing ? 'updated' : 'added'} successfully',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4a63c0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.hourglass_empty,
                size: 48,
                color: Color(0xFF4a63c0),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data will appear here once available',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickQuantityEditDialog(
    BuildContext context,
    Activity activity,
    ActivityProvider activityProvider,
  ) {
    final remainingQuantity = activity.balanceQuantity;
    final TextEditingController quantityController = TextEditingController(
      text: remainingQuantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mark Progress',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${activity.title}\nRemaining: ${remainingQuantity} ${activity.unit}',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
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
                  borderRadius: BorderRadius.circular(12),
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
            onPressed: () {
              final quantityToComplete =
                  int.tryParse(quantityController.text) ?? 0;
              if (quantityToComplete >= 0 &&
                  quantityToComplete <= remainingQuantity) {
                // Update the current activity with the completed quantity
                final updatedActivity = activity.copyWith(
                  completedQuantity:
                      activity.completedQuantity + quantityToComplete,
                  status:
                      (activity.completedQuantity + quantityToComplete) >=
                          activity.quantity
                      ? 'completed'
                      : 'pending',
                  updates: [
                    ...activity.updates,
                    ActivityUpdate(
                      quantityCompleted: quantityToComplete,
                      date: DateTime.now(),
                    ),
                  ],
                );
                activityProvider.updateActivity(activity.id, updatedActivity);

                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4a63c0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getDaysLeftColor(int daysLeft) {
    if (daysLeft == 0) return Colors.red;
    if (daysLeft <= 3) return Colors.red.shade600;
    if (daysLeft <= 7) return Colors.orange.shade600;
    return Colors.green.shade600;
  }
}
