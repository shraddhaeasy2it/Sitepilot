import 'dart:math';
import 'dart:async';

import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/admin/models/purchase_model.dart';
import 'package:ecoteam_app/admin/services/Allsupplier_service.dart';
import 'package:ecoteam_app/admin/services/purchase_services.dart';
import 'package:ecoteam_app/admin/models/purchase_order_model.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/add_purchase_order_bottom_sheet.dart';
import 'package:ecoteam_app/admin/models/indent_model.dart';
import 'package:ecoteam_app/admin/services/indent_service.dart';
import 'package:ecoteam_app/admin/models/grn_model.dart';
import 'package:ecoteam_app/admin/services/grn_service.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/view_grn_bottom_sheet.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/add_grn_bottom_sheet.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/StockTab.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/all_material_page.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/consumptionLog_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/material_category_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/add_indent_bottom_sheet.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/payment.dart'
    hide PaymentFormBottomSheet;
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/unit_management_page.dart';
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ecoteam_app/admin/services/payment_services.dart';
import 'package:ecoteam_app/admin/models/payment_model.dart' as pm;
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/paymentScreen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Material/transfer_material.dart';

import '../../../models/site_model.dart';
import 'package:ecoteam_app/global.dart';

class MaterialScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final int? workspaceId;
  final String? currentCompany;
  final int? userId;

  const MaterialScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    this.workspaceId,
    this.currentCompany,
    this.userId,
  });

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen>
    with TickerProviderStateMixin, RouteAware {
  late TabController _mainTabController;
  final ValueNotifier<int> _resetNotifier = ValueNotifier<int>(0);
  Timer? _permissionTimer;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPermissions();
      MaterialApiService.initToken();
    });

    // Auto-refresh permissions every 10 seconds
    _permissionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _refreshPermissions();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    // This is called when the top route has been popped off, and the current route (MaterialScreen) shows up.
    setState(() {
      _mainTabController.animateTo(0);
      _resetNotifier.value++; // Increment to signal sub-tabs to reset
    });
  }

  void _refreshPermissions() {
    Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    ).refreshPermissions();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _mainTabController.dispose();
    _resetNotifier.dispose();
    _permissionTimer?.cancel();
    super.dispose();
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

  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color primaryDark = Color(0xFF2a43a0);
  static const Color backgroundColor = Color(0xFFf8f9fa);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Material Management',
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
        toolbarHeight: 74.h,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryColor, Color(0xFF3a53b0), primaryDark],
            ),
          ),
        ),
        actions: [
          ...buildNotificationActions(
            context: context,
            selectedSiteId: widget.selectedSiteId,
            sites: widget.sites,
            currentCompany: widget.currentCompany,
            workspaceId: widget.workspaceId,
          ),
          GestureDetector(
            onTap: () {
              _showMaterialOptionsBottomSheet(context);
            },
            child: Icon(Icons.more_vert),
          ),
          SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(45.h),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            color: Colors.transparent,
            child: TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              labelPadding: EdgeInsets.symmetric(horizontal: 2.w),
              controller: _mainTabController,
              tabs: const [
                Tab(text: 'Procurement'),
                Tab(text: 'Inventory'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          // Procurement Tab
          ProcurementTab(
            selectedSiteId: widget.selectedSiteId,
            selectedSiteName: _getCurrentSiteName(),
            onSiteChanged: widget.onSiteChanged,
            sites: widget.sites,
            workspaceId: widget.workspaceId,
            currentCompany: widget.currentCompany,
            userId: widget.userId,
            resetNotifier: _resetNotifier,
          ),
          // Inventory Tab
          InventoryTab(
            selectedSiteId: widget.selectedSiteId,
            selectedSiteName: _getCurrentSiteName(),
            onSiteChanged: widget.onSiteChanged,
            sites: widget.sites,
            workspaceId: widget.workspaceId,
            currentCompany: widget.currentCompany,
            userId: widget.userId,
            resetNotifier: _resetNotifier,
          ),
        ],
      ),
    );
  }

  void _showMaterialOptionsBottomSheet(BuildContext context) {
    // Refresh permissions to ensure latest access rights are applied
    Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    ).refreshPermissions();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Consumer<CompanySiteProvider>(
                builder: (context, provider, child) {
                  // Check for 'material manage' permission
                  // Note: Permission names are often case-sensitive/specific, user said "material manage"
                  // Assuming exact string match based on CompanySiteProvider logic
                  if (!provider.hasPermission('material manage')) {
                    return const SizedBox.shrink();
                  }

                  return _buildOptionItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: 'All Material',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminAllMaterialPage(
                            userId: widget.userId,
                            workspaceId: widget.workspaceId,
                            siteId: int.tryParse(widget.selectedSiteId ?? ''),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              Consumer<CompanySiteProvider>(
                builder: (context, provider, child) {
                  if (!provider.hasPermission('material-categories manage')) {
                    return const SizedBox.shrink();
                  }
                  return _buildOptionItem(
                    context,
                    icon: Icons.category_outlined,
                    title: 'Material Category',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MaterialCategoryScreen(
                            userId: widget.userId,
                            workspaceId: widget.workspaceId,
                            siteId: int.tryParse(widget.selectedSiteId ?? ''),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              Consumer<CompanySiteProvider>(
                builder: (context, provider, child) {
                  if (!provider.hasPermission('material-unit manage')) {
                    return const SizedBox.shrink();
                  }

                  return _buildOptionItem(
                    context,
                    icon: Icons.straighten_outlined,
                    title: 'Unit',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UnitManagementPage(
                            userId: widget.userId,
                            workspaceId: widget.workspaceId,
                            siteId: int.tryParse(widget.selectedSiteId ?? ''),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF4a63c0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF4a63c0), size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 24.sp),
          ],
        ),
      ),
    );
  }
}

class InventoryTab extends StatefulWidget {
  final String? selectedSiteId;
  final String selectedSiteName;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final int? workspaceId;
  final String? currentCompany;
  final int? userId;
  final ValueNotifier<int>? resetNotifier;

  const InventoryTab({
    super.key,
    required this.selectedSiteId,
    required this.selectedSiteName,
    required this.onSiteChanged,
    required this.sites,
    this.workspaceId,
    this.currentCompany,
    this.userId,
    this.resetNotifier,
  });

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab>
    with TickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: _getTabLength(), vsync: this);
    widget.resetNotifier?.addListener(_handleReset);
  }

  int _getTabLength() {
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);
    int length = 0;
    if (provider.hasPermission('stock-report manage')) length++;
    if (provider.hasPermission('consumption-log manage')) length++;
    length += 2; // Material Issue and Returns
    return length == 0 ? 1 : length;
  }

  void _handleReset() {
    if (mounted) {
      _subTabController.animateTo(0);
    }
  }

  @override
  void dispose() {
    widget.resetNotifier?.removeListener(_handleReset);
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CompanySiteProvider>(context);
    print('DEBUG: Building InventoryTab');
    print('DEBUG: Provider Permissions: ${provider.permissions}');

    List<Widget> tabs = [];
    List<Widget> tabViews = [];

    // 1. Purchase Invoice Tab
    // Removed from InventoryTab as it is now moved to ProcurementTab

    // 2. Stock Tab
    if (provider.hasPermission('stock-report manage')) {
      print('DEBUG: Adding Stock Tab');
      tabs.add(const Tab(text: 'Stock'));
      tabViews.add(
        StockTab(
          selectedSiteId: widget.selectedSiteId,
          selectedSiteName: widget.selectedSiteName,
          onSiteChanged: widget.onSiteChanged,
          sites: widget.sites,
        ),
      );
    }

    // 3. Consumption Log Tab
    if (provider.hasPermission('consumption-log manage')) {
      print('DEBUG: Adding Consumption Tab');
      tabs.add(const Tab(text: 'Consumption'));
      tabViews.add(
        ConsumptionLogPage(
          isEmbedded: true,
          selectedSiteId: widget.selectedSiteId,
          userId: widget.userId,
        ),
      );
    }

    // 4. Material Issue
    // Assuming permissions/availability
    print('DEBUG: Adding Material Issue Tab');
    tabs.add(const Tab(text: 'Material Issue'));
    tabViews.add(
      MaterialTransferScreen(
        selectedSiteId: int.tryParse(widget.selectedSiteId ?? ''),
        selectedSiteName: widget.selectedSiteName,
        isEmbedded: true,
      ),
    );

    // 5. Material Returns
    print('DEBUG: Adding Material Returns Tab');
    tabs.add(const Tab(text: 'Material Returns'));
    tabViews.add(
      MaterialTransferScreen(
        selectedSiteId: int.tryParse(widget.selectedSiteId ?? ''),
        selectedSiteName: widget.selectedSiteName,
        isEmbedded: true,
      ),
    );

    if (tabs.isEmpty) {
      return Center(child: Text("No accessible inventory modules"));
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: TabBar(
            controller: _subTabController,
            isScrollable: true,
            indicatorColor: Color(0xFF4a63c0),
            labelColor: Color(0xFF4a63c0),
            unselectedLabelColor: Colors.black54,
            tabs: tabs,
          ),
        ),
        Expanded(
          child: TabBarView(controller: _subTabController, children: tabViews),
        ),
      ],
    );
  }
}

class ProcurementTab extends StatefulWidget {
  final String? selectedSiteId;
  final String selectedSiteName;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final int? workspaceId;
  final String? currentCompany;
  final int? userId;
  final ValueNotifier<int>? resetNotifier;

  const ProcurementTab({
    super.key,
    required this.selectedSiteId,
    required this.selectedSiteName,
    required this.onSiteChanged,
    required this.sites,
    this.workspaceId,
    this.currentCompany,
    this.userId,
    this.resetNotifier,
  });

  @override
  State<ProcurementTab> createState() => _ProcurementTabState();
}

class _ProcurementTabState extends State<ProcurementTab>
    with TickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    // Use a small delay to ensure provider is available if needed, or better, calculate length here.
    _subTabController = TabController(length: _getTabLength(), vsync: this);
    widget.resetNotifier?.addListener(_handleReset);
  }

  int _getTabLength() {
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);
    int length = 3; // Indent, Deliveries, GRN
    if (provider.hasPermission('purchase-invoices manage')) length++;
    return length;
  }

  void _handleReset() {
    if (mounted) {
      _subTabController.animateTo(0);
    }
  }

  @override
  void dispose() {
    widget.resetNotifier?.removeListener(_handleReset);
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CompanySiteProvider>(context);

    List<Widget> tabs = [];
    List<Widget> tabViews = [];

    // 1. Indent Tab
    tabs.add(const Tab(text: 'Indent'));
    tabViews.add(
      IndentTabContent(
        selectedSiteId: widget.selectedSiteId,
        workspaceId: widget.workspaceId,
        sites: widget.sites,
        userId: widget.userId,
      ),
    );

    // 2. Deliveries Tab
    tabs.add(const Tab(text: 'Deliveries/PO'));
    tabViews.add(
      DeliveriesTabContent(
        selectedSiteId: widget.selectedSiteId,
        workspaceId: widget.workspaceId,
        userId: widget.userId,
        sites: widget.sites,
      ),
    );

    // 3. GRN Tab
    tabs.add(const Tab(text: 'GRN'));
    tabViews.add(
      GRNTabContent(
        selectedSiteId: widget.selectedSiteId,
        workspaceId: widget.workspaceId,
        userId: widget.userId,
        sites: widget.sites,
      ),
    );

    // 4. Purchase Tab (Moved from Inventory)
    if (provider.hasPermission('purchase-invoices manage')) {
      tabs.add(const Tab(text: 'Purchase Invoices'));
      tabViews.add(
        PurchaseInvoiceTab(
          selectedSiteId: widget.selectedSiteId,
          onSiteChanged: widget.onSiteChanged,
          sites: widget.sites,
          workspaceId: widget.workspaceId,
          currentCompany: widget.currentCompany,
          userId: widget.userId,
        ),
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: TabBar(
            controller: _subTabController,
            isScrollable: true,
            indicatorColor: const Color(0xFF4a63c0),
            labelColor: const Color(0xFF4a63c0),
            unselectedLabelColor: Colors.black54,
            tabs: tabs,
          ),
        ),
        Expanded(
          child: TabBarView(controller: _subTabController, children: tabViews),
        ),
      ],
    );
  }
}

class IndentTabContent extends StatefulWidget {
  final String? selectedSiteId;
  final int? workspaceId;
  final List<Site>? sites;
  final int? userId;

  const IndentTabContent({
    super.key,
    this.selectedSiteId,
    this.workspaceId,
    this.sites,
    this.userId,
  });

  @override
  State<IndentTabContent> createState() => _IndentTabContentState();
}

class _IndentTabContentState extends State<IndentTabContent> {
  final IndentService _indentService = IndentService();
  List<IndentModel> _indents = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // ==================== PDF REPORT STATE ====================
  DateTime _reportStartDate = DateTime.now();
  DateTime _reportEndDate = DateTime.now();
  List<IndentModel> _reportRecords = [];
  int _reportTotalIndents = 0;

  @override
  void initState() {
    super.initState();
    _loadIndents();
  }

  @override
  void didUpdateWidget(IndentTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSiteId != widget.selectedSiteId ||
        oldWidget.workspaceId != widget.workspaceId) {
      _loadIndents();
    }
  }

  Future<void> _loadIndents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final indents = await _indentService.getIndents(
        siteId: widget.selectedSiteId,
        workspaceId: widget.workspaceId,
      );
      if (mounted) {
        setState(() {
          _indents = indents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ==================== PDF REPORT FUNCTIONALITY ====================

  Future<void> _generateReport() async {
    // Initialize report with default values (today's date)
    _reportStartDate = DateTime.now();
    _reportEndDate = DateTime.now();

    // Calculate initial report data
    _updateReportData();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReportSheet(),
    );
  }

  void _updateReportData() {
    // Filter records by date range
    _reportRecords = _indents.where((indent) {
      if (indent.indentDate == null) return false;
      try {
        final indentDate = DateTime.parse(indent.indentDate!);
        return (indentDate.isAtSameMomentAs(_reportStartDate) ||
                indentDate.isAfter(_reportStartDate)) &&
            (indentDate.isAtSameMomentAs(_reportEndDate) ||
                indentDate.isBefore(
                  _reportEndDate.add(const Duration(days: 1)),
                ));
      } catch (e) {
        return false;
      }
    }).toList();

    _reportTotalIndents = _reportRecords.length;
  }

  Widget _buildReportSheet() {
    final screenHeight = MediaQuery.of(context).size.height;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          height: screenHeight * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Indent Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4a63c0),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              /// DATE PICKERS
              Row(
                children: [
                  Expanded(
                    child: _buildDateButton(
                      label: "From Date",
                      date: _reportStartDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _reportStartDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            _reportStartDate = picked;
                            _updateReportData();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateButton(
                      label: "To Date",
                      date: _reportEndDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _reportEndDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            _reportEndDate = picked;
                            _updateReportData();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// SUMMARY SECTION
              _buildReportSummary(),

              const SizedBox(height: 24),

              const Text(
                'Indents per Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              /// DATE-WISE LIST
              Expanded(
                child: _reportRecords.isEmpty
                    ? const Center(
                        child: Text("No records found for this range."),
                      )
                    : ListView.builder(
                        itemCount: _reportRecords.length,
                        itemBuilder: (context, index) {
                          final indent = _reportRecords[index];
                          final dateStr = indent.indentDate != null
                              ? DateFormat(
                                  'dd MMM yyyy',
                                ).format(DateTime.parse(indent.indentDate!))
                              : 'N/A';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(indent.indentNumber ?? 'N/A'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${indent.creator?.name ?? "Unknown"} | $dateStr",
                                ),
                                if (indent.items != null &&
                                    indent.items!.isNotEmpty)
                                  Text(
                                    "Materials: ${indent.items!.map((i) => i.material?.name ?? 'N/A').join(', ')}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            trailing: Text(
                              indent.status ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              /// ACTIONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewPDF(() => Navigator.pop(context)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4a63c0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View PDF'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF4a63c0),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy-MM-dd').format(date),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportSummary() {
    String siteName = 'All Sites';
    if (widget.selectedSiteId != null && widget.sites != null) {
      try {
        final site = widget.sites!.firstWhere(
          (s) => s.id == widget.selectedSiteId,
        );
        siteName = site.name;
      } catch (_) {}
    }

    return Container(
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
          _buildReportItem(
            'Date Range',
            '${DateFormat('yyyy-MM-dd').format(_reportStartDate)} to ${DateFormat('yyyy-MM-dd').format(_reportEndDate)}',
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem('Site', siteName, Colors.white70, Colors.white),
          _buildReportItem(
            'Total Indents',
            _reportTotalIndents.toString(),
            Colors.white70,
            Colors.white,
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white30),
          const SizedBox(height: 10),
          _buildReportItem(
            'Report Generated',
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
            Colors.white70,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewPDF([VoidCallback? onSuccess]) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfBytes = await _generatePdfBytes();
      final directory = await getTemporaryDirectory();

      String siteName = 'All_Sites';
      if (widget.selectedSiteId != null && widget.sites != null) {
        try {
          final site = widget.sites!.firstWhere(
            (s) => s.id == widget.selectedSiteId,
          );
          siteName = site.name.replaceAll(' ', '_');
        } catch (_) {}
      }

      final fileName =
          'indent_report_${siteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes);

      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      if (onSuccess != null) {
        onSuccess();
      }

      await OpenFile.open(file.path);
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to view PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    String siteName = 'All Sites';
    if (widget.selectedSiteId != null && widget.sites != null) {
      try {
        final site = widget.sites!.firstWhere(
          (s) => s.id == widget.selectedSiteId,
        );
        siteName = site.name;
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Indent Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Site: $siteName'),
                    pw.Text(
                      'Period: ${DateFormat('yyyy-MM-dd').format(_reportStartDate)} to ${DateFormat('yyyy-MM-dd').format(_reportEndDate)}',
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // Summary Table
            pw.Table.fromTextArray(
              headers: [
                'Date',
                'Indent No',
                'Materials',
                'Created By',
                'Delivery Date',
                'Status',
              ],
              data: _reportRecords.map((indent) {
                final materials =
                    indent.items
                        ?.map((item) {
                          return "${item.material?.name ?? 'N/A'} (${item.quantity ?? '0'} ${item.unit ?? ''})";
                        })
                        .join('\n') ??
                    'N/A';

                return [
                  indent.indentDate != null
                      ? DateFormat(
                          'yyyy-MM-dd',
                        ).format(DateTime.parse(indent.indentDate!))
                      : 'N/A',
                  indent.indentNumber ?? 'N/A',
                  materials,
                  indent.creator?.name ?? 'N/A',
                  indent.deliveryDate != null
                      ? DateFormat(
                          'yyyy-MM-dd',
                        ).format(DateTime.parse(indent.deliveryDate!))
                      : 'N/A',
                  indent.status ?? 'N/A',
                ];
              }).toList(),

              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10, // header size
              ),

              cellStyle: pw.TextStyle(
                fontSize: 9, // smaller content text
              ),

              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),

              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddIndentBottomSheet(
              sites: widget.sites ?? [],
              preselectedSiteId: int.tryParse(widget.selectedSiteId ?? ''),
              workspaceId: widget.workspaceId,
              userId: widget.userId,
              onIndentSaved: (newIndent) {
                _loadIndents();
                _showViewIndentBottomSheet(newIndent);
              },
            ),
          );
        },
        backgroundColor: const Color(0xFF4a63c0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4a63c0)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadIndents, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 35.h,
              width: 35.h,
              decoration: BoxDecoration(
                color: Colors.black12.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: IconButton(
                tooltip: 'Generate Report',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _generateReport,
                icon: Icon(
                  Icons.picture_as_pdf,
                  size: 24.sp,
                  color: const Color.fromARGB(255, 29, 29, 29),
                ),
              ),
            ),
            SizedBox(width: 16.w),
          ],
        ),
        Expanded(
          child: _indents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      const Text(
                        'No Indents Found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadIndents,
                  color: const Color(0xFF4a63c0),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: 80,
                    ),
                    itemCount: _indents.length,
                    itemBuilder: (context, index) {
                      final indent = _indents[index];
                      return _buildIndentCard(indent);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildIndentCard(IndentModel indent) {
    final dateStr = indent.indentDate != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.tryParse(indent.indentDate!) ?? DateTime.now())
        : 'N/A';

    final deliveryDateStr = indent.deliveryDate != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.tryParse(indent.deliveryDate!) ?? DateTime.now())
        : 'Not Set';

    return InkWell(
      onTap: () => _showViewIndentBottomSheet(indent),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  Expanded(
                    child: Text(
                      indent.indentNumber ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(indent.status),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      indent.status ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => _showOptionsBottomSheet(indent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LEFT SIDE — CREATED BY
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Created By",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 133, 133, 133),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          "${indent.creator?.name ?? "Unknown"} | $dateStr",
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// RIGHT SIDE — DELIVERY DATE
                  if (indent.deliveryDate != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Expected Delivery",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 133, 133, 133),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              deliveryDateStr,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),

              /// MATERIAL ITEMS
              if (indent.items != null && indent.items!.isNotEmpty) ...[
                const Text(
                  "Material Items",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 107, 107, 107),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 4),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indent.items!
                          .map((item) => item.material?.name ?? "Unknown")
                          .join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'open':
        return Color.fromARGB(255, 47, 84, 219);
      case 'closed':
        return Colors.green;
      case 'short close':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  void _showOptionsBottomSheet(IndentModel indent) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              _buildOptionItem(
                context,
                icon: Icons.edit_outlined,
                title: 'Edit Indent',
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddIndentBottomSheet(
                      sites: widget.sites ?? [],
                      preselectedSiteId: int.tryParse(
                        widget.selectedSiteId ?? '',
                      ),
                      workspaceId: widget.workspaceId,
                      userId: widget.userId,
                      onIndentSaved: (newIndent) => _loadIndents(),
                      indentToEdit: indent,
                    ),
                  );
                },
              ),
              _buildOptionItem(
                context,
                icon: Icons.delete_outline,
                title: 'Delete Indent',
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Indent'),
                      content: const Text(
                        'Are you sure you want to delete this indent?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF4a63c0),
                                  ),
                                ),
                              );
                              final success = await _indentService.deleteIndent(
                                indent.id,
                              );
                              if (mounted) {
                                Navigator.pop(context); // Close loading dialog
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Indent deleted successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _loadIndents();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to delete indent'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context); // Close loading dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? const Color(0xFF4a63c0);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 24.sp),
          ],
        ),
      ),
    );
  }

  void _showViewIndentBottomSheet(IndentModel indent) {
    final dateStr = indent.indentDate != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.tryParse(indent.indentDate!) ?? DateTime.now())
        : 'N/A';

    final deliveryDateStr = indent.deliveryDate != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.tryParse(indent.deliveryDate!) ?? DateTime.now())
        : 'Not Set';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xffF7F8FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),

              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),

              child: Column(
                children: [
                  /// HANDLE
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Indent Details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            indent.status,
                          ).withOpacity(.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          indent.status ?? "Unknown",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(indent.status),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  /// CONTENT
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        /// BASIC INFO CARD
                        _infoCard([
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  'Indent Number',
                                  indent.indentNumber ?? 'N/A',
                                  Icons.tag,
                                ),
                              ),

                              Expanded(
                                child: _buildDetailRow(
                                  'Date',
                                  dateStr,
                                  Icons.calendar_today,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  'Created By',
                                  indent.creator?.name ?? 'N/A',
                                  Icons.person,
                                ),
                              ),

                              if (indent.assignedUsers != null &&
                                  indent.assignedUsers!.isNotEmpty)
                                Expanded(
                                  child: _buildDetailRow(
                                    'Assigned To',
                                    indent.assignedUsers!
                                        .map((u) => u.name ?? 'Unknown')
                                        .join(', '),
                                    Icons.group,
                                  ),
                                ),
                            ],
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  'Total Amount',
                                  '₹${indent.totalAmount ?? '0.00'}',
                                  Icons.account_balance_wallet,
                                ),
                              ),

                              if (indent.deliveryDate != null)
                                Expanded(
                                  child: _buildDetailRow(
                                    'Delivery Date',
                                    deliveryDateStr,
                                    Icons.local_shipping,
                                  ),
                                ),
                            ],
                          ),

                          if (indent.description != null &&
                              indent.description!.isNotEmpty)
                            _buildDetailRow(
                              'Description',
                              indent.description!,
                              Icons.description,
                            ),

                          if (indent.rejectionReason != null &&
                              indent.rejectionReason!.isNotEmpty)
                            _buildDetailRow(
                              'Rejection Reason',
                              indent.rejectionReason!,
                              Icons.warning,
                              color: Colors.red,
                            ),
                        ]),

                        const SizedBox(height: 16),

                        /// FILE CARD
                        if (indent.referenceFile != null &&
                            indent.referenceFile!.isNotEmpty)
                          _infoCard([
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  color: Colors.blue[700],
                                ),

                                const SizedBox(width: 10),

                                const Text(
                                  "Reference File",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            InkWell(
                              onTap: () async {
                                final url =
                                    'https://app.ecoteamsolar.com/${indent.referenceFile}';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              child: Text(
                                "View / Download File",
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ]),

                        const SizedBox(height: 10),

                        /// MATERIAL HEADER
                        const Text(
                          "Materials",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// ITEMS
                        if (indent.items == null || indent.items!.isEmpty)
                          const Text(
                            "No items found",
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ...indent.items!.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),

                              padding: const EdgeInsets.all(14),

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.material?.name ?? "Unknown Material",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Qty : ${item.quantity ?? '0'} ${item.unit ?? ''}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),

                                      Text(
                                        "Price : ₹${item.price ?? '0'}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Subtotal",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      Text(
                                        "₹${item.subtotal ?? '0'}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (item.remarks != null &&
                                      item.remarks!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        "Remarks : ${item.remarks}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// CLOSE BUTTON
                  /// ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xff4A63C0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Close",
                            style: TextStyle(color: Color(0xff4A63C0)),
                          ),
                        ),
                      ),
                      if (indent.status == 'Open' ||
                          indent.status == 'Partially Closed') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    AddEditPurchaseOrderBottomSheet(
                                      sites: widget.sites ?? [],
                                      preselectedSiteId: int.tryParse(
                                        widget.selectedSiteId ?? '',
                                      ),
                                      workspaceId: widget.workspaceId,
                                      userId: widget.userId,
                                      onPOSaved: _loadIndents,
                                      preselectedIndentId: indent.id,
                                    ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff4A63C0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Create PO",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (e) =>
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: e),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Color(0xFF2a43a0)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveriesTabContent extends StatefulWidget {
  final String? selectedSiteId;
  final int? workspaceId;
  final int? userId;
  final List<Site>? sites;

  const DeliveriesTabContent({
    super.key,
    this.selectedSiteId,
    this.workspaceId,
    this.userId,
    this.sites,
  });

  @override
  State<DeliveriesTabContent> createState() => _DeliveriesTabContentState();
}

class _DeliveriesTabContentState extends State<DeliveriesTabContent> {
  List<PurchaseOrderModel> _purchaseOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPurchaseOrders();
  }

  @override
  void didUpdateWidget(DeliveriesTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSiteId != widget.selectedSiteId ||
        oldWidget.workspaceId != widget.workspaceId) {
      _loadPurchaseOrders();
    }
  }

  Future<void> _loadPurchaseOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final orders = await ApiServicePurchaseInvoice.getPurchaseOrders(
        siteId: widget.selectedSiteId != null
            ? int.tryParse(widget.selectedSiteId!)
            : null,
        workspaceId: widget.workspaceId,
      );
      if (mounted) {
        setState(() {
          _purchaseOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _viewPOFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No PDF file available for this PO'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final url = 'https://app.ecoteamsolar.com/$filePath';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
      case 'pending':
        return Colors.orange;
      case 'approved':
        return const Color.fromARGB(255, 59, 158, 62);
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddEditPurchaseOrderBottomSheet(
              sites: widget.sites ?? [],
              preselectedSiteId: int.tryParse(widget.selectedSiteId ?? ''),
              workspaceId: widget.workspaceId,
              userId: widget.userId,
              onPOSaved: _loadPurchaseOrders,
            ),
          );
        },
        backgroundColor: const Color(0xFF4a63c0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4a63c0)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPurchaseOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_purchaseOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Purchase Orders Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No incoming deliveries currently scheduled.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPurchaseOrders,
      color: const Color(0xFF4a63c0),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _purchaseOrders.length,
        itemBuilder: (context, index) {
          final po = _purchaseOrders[index];
          return _buildPOCard(po);
        },
      ),
    );
  }

  Widget _buildPOCard(PurchaseOrderModel po) {
    final poDateStr = po.poDate != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.tryParse(po.poDate!) ?? DateTime.now())
        : 'N/A';

    final deliveryDateStr = po.deliveryDate != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.tryParse(po.deliveryDate!) ?? DateTime.now())
        : 'Not Set';

    return InkWell(
      onTap: () => _showViewPOBottomSheet(po),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      po.poNumber ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(po.status),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      po.status ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => _showPOOptionsBottomSheet(po),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Created By",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${po.creator?.name ?? "Unknown"} | $poDateStr",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (po.deliveryDate != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Expected Delivery",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              deliveryDateStr,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
              if (po.supplier?.name != null) ...[
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Vendor",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.business_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  po.supplier?.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${po.grandTotal ?? '0'}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4a63c0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPOOptionsBottomSheet(PurchaseOrderModel po) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // _buildOptionItem(
              //   context,
              //   icon: Icons.visibility_outlined,
              //   title: 'View PO',
              //   onTap: () {
              //     Navigator.pop(context);
              //     _showViewPOBottomSheet(po);
              //   },
              // ),
              _buildOptionItem(
                context,
                icon: Icons.picture_as_pdf_outlined,
                iconColor: const Color.fromARGB(255, 50, 184, 55),
                title: 'Export PDF',
                onTap: () {
                  Navigator.pop(context);
                  _viewPOFile(po.poPdf);
                },
              ),
              _buildOptionItem(
                context,
                icon: Icons.edit_outlined,
                title: 'Edit PO',
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddEditPurchaseOrderBottomSheet(
                      sites: widget.sites ?? [],
                      preselectedSiteId: int.tryParse(
                        widget.selectedSiteId ?? '',
                      ),
                      workspaceId: widget.workspaceId,
                      userId: widget.userId,
                      onPOSaved: _loadPurchaseOrders,
                      poToEdit: po,
                    ),
                  );
                },
              ),
              if (po.status?.toLowerCase() == 'pending' ||
                  po.status?.toLowerCase() == 'draft') ...[
                _buildOptionItem(
                  context,
                  icon: Icons.check_circle_outline,
                  title: 'Approve PO',
                  iconColor: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _updatePOStatus(po, 'Approved');
                  },
                ),
                // _buildOptionItem(
                //   context,
                //   icon: Icons.cancel_outlined,
                //   title: 'Reject PO',
                //   iconColor: Colors.red,
                //   onTap: () {
                //     Navigator.pop(context);
                //     _updatePOStatus(po, 'Rejected');
                //   },
                // ),
              ],
              // if (po.status?.toLowerCase() == 'approved') ...[
              //   _buildOptionItem(
              //     context,
              //     icon: Icons.done_all,
              //     title: 'Complete PO',
              //     iconColor: Colors.blue,
              //     onTap: () {
              //       Navigator.pop(context);
              //       _updatePOStatus(po, 'Completed');
              //     },
              //   ),
              // ],
              _buildOptionItem(
                context,
                icon: Icons.delete_outline,
                title: 'Delete PO',
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(po);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(PurchaseOrderModel po) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Purchase Order'),
        content: const Text(
          'Are you sure you want to delete this purchase order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4a63c0)),
                  ),
                );
                await ApiServicePurchaseInvoice.deletePurchaseOrder(po.id);
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Purchase Order deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadPurchaseOrders();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _updatePOStatus(PurchaseOrderModel po, String newStatus) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4a63c0)),
        ),
      );
      final updatedPO = await ApiServicePurchaseInvoice.updatePurchaseOrderStatus(
        po.id,
        newStatus,
      );
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase Order $newStatus successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPurchaseOrders();
        if (newStatus.toLowerCase() == 'approved') {
          _showViewPOBottomSheet(updatedPO);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? const Color(0xFF4a63c0);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 24.sp),
          ],
        ),
      ),
    );
  }

  void _showViewPOBottomSheet(PurchaseOrderModel po) {
    final poDateStr = po.poDate != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.tryParse(po.poDate!) ?? DateTime.now())
        : 'N/A';

    final deliveryDateStr = po.deliveryDate != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.tryParse(po.deliveryDate!) ?? DateTime.now())
        : 'Not Set';

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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Purchase Order Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(po.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          po.status ?? 'Unknown',
                          style: TextStyle(
                            color: _getStatusColor(po.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (po.poPdf != null && po.poPdf!.isNotEmpty)
                        Container(
                          height: 35,
                          width: 35,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              31,
                              44,
                              44,
                              44,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              size: 24,
                              color: Colors.red,
                            ),
                            onPressed: () => _viewPOFile(po.poPdf),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailRow(
                                'PO Number',
                                po.poNumber ?? 'N/A',
                                Icons.tag,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailRow(
                                'Date',
                                poDateStr,
                                Icons.calendar_today,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        if (po.supplier?.name != null)
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  'Supplier',
                                  po.supplier!.name!,
                                  Icons.business,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDetailRow(
                                  'Created By',
                                  po.creator?.name ?? 'N/A',
                                  Icons.person,
                                ),
                              ),
                            ],
                          ),

                        Row(
                          children: [
                            if (po.deliveryDate != null)
                              Expanded(
                                child: _buildDetailRow(
                                  'Delivery Date',
                                  deliveryDateStr,
                                  Icons.local_shipping,
                                ),
                              ),
                            const SizedBox(width: 12),
                            if (po.indent?.indentNumber != null)
                              Expanded(
                                child: _buildDetailRow(
                                  'Linked Indent',
                                  po.indent!.indentNumber!,
                                  Icons.link,
                                ),
                              ),
                          ],
                        ),
                        _buildDetailRow(
                          'Grand Total',
                          '₹${po.grandTotal ?? '0.00'}',
                          Icons.attach_money,
                        ),
                        if (po.description != null &&
                            po.description!.isNotEmpty)
                          _buildDetailRow(
                            'Description',
                            po.description!,
                            Icons.description,
                          ),
                        if (po.rejectionReason != null &&
                            po.rejectionReason!.isNotEmpty)
                          _buildDetailRow(
                            'Rejection Reason',
                            po.rejectionReason!,
                            Icons.warning,
                            color: Colors.red,
                          ),
                        if (po.deliveryTermsConditions != null &&
                            po.deliveryTermsConditions!.isNotEmpty)
                          _buildDetailRow(
                            'Delivery Terms',
                            po.deliveryTermsConditions!,
                            Icons.gavel_outlined,
                          ),
                        if (po.paymentTermsConditions != null &&
                            po.paymentTermsConditions!.isNotEmpty)
                          _buildDetailRow(
                            'Payment Terms',
                            po.paymentTermsConditions!,
                            Icons.payments_outlined,
                          ),
                        const SizedBox(height: 24),
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (po.items != null && po.items!.isNotEmpty)
                          ...po.items!.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.material?.name ?? 'Unknown Material',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Qty: ${item.quantity} ${item.unit}',
                                        ),
                                        Text('Price: ₹${item.price}'),
                                      ],
                                    ),
                                    const Divider(),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Subtotal: ₹${item.subtotal}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4a63c0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (po.status?.toLowerCase() == 'approved')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => AddGRNBottomSheet(
                                sites: widget.sites ?? [],
                                selectedSiteId: widget.selectedSiteId,
                                workspaceId: widget.workspaceId,
                                userId: widget.userId,
                                initialPO: po,
                                onGRNSaved: _loadPurchaseOrders,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart,
                              color: Colors.white),
                          label: const Text(
                            'Create GRN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4a63c0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
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

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PurchaseInvoiceTab extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final int? workspaceId;
  final String? currentCompany;
  final int? userId;

  const PurchaseInvoiceTab({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    this.workspaceId,
    this.currentCompany,
    this.userId,
  });

  @override
  State<PurchaseInvoiceTab> createState() => _PurchaseInvoiceTabState();
}

class _PurchaseInvoiceTabState extends State<PurchaseInvoiceTab> {
  late CompanySiteProvider _companyProvider;
  List<PurchaseInvoice> _invoices = [];
  List<Supplier> _suppliers = [];
  List<SiteModel> _sites = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // For report date range
  DateTime _reportStartDate = DateTime.now();
  DateTime _reportEndDate = DateTime.now();
  List<PurchaseInvoice> _reportRecords = [];
  double _reportTotalAmount = 0;
  int _reportTotalInvoices = 0;
  Map<String, double> _reportDateTotals = {};

  // UI Colors matching MaterialScreen
  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color primaryDark = Color(0xFF2a43a0);
  static const Color backgroundColor = Color(0xFFf8f9fa);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void didUpdateWidget(PurchaseInvoiceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSiteId != widget.selectedSiteId) {
      _loadAllData();
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

  // Get the current site ID
  String? get _currentSiteId {
    return widget.selectedSiteId;
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load suppliers and sites first
      final suppliers = await ApiServicePurchaseInvoice.getSuppliers();
      final sites = await ApiServicePurchaseInvoice.getSites(
        workspaceId: widget.workspaceId ?? 1,
      );

      // Load invoices filtered by selected site
      // Load invoices filtered by selected site and workspace
      List<PurchaseInvoice> invoices;

      final dynamicWorkspaceId = widget.workspaceId;
      final dynamicSiteId = _currentSiteId != null
          ? int.tryParse(_currentSiteId!)
          : null;

      print(
        'DEBUG: Loading Purchase Invoices - WorkspaceID: $dynamicWorkspaceId, SiteID: $dynamicSiteId',
      );

      invoices = await ApiServicePurchaseInvoice.getInvoices(
        workspaceId: dynamicWorkspaceId,
        siteId: dynamicSiteId,
      );

      setState(() {
        _invoices = invoices;
        _suppliers = suppliers;
        _sites = sites;
        _isLoading = false;
      });

      print(
        'Loaded ${_invoices.length} invoices for site ${_currentSiteId ?? "All Sites"}, ${_suppliers.length} suppliers, ${_sites.length} sites',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: Network Error';
        _isLoading = false;
      });
      print('Error loading all data: $e');
    }
  }

  List<PurchaseInvoice> get _filteredInvoices {
    if (_searchQuery.isEmpty) {
      return _invoices;
    }
    return _invoices.where((invoice) {
      return invoice.invoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          invoice.supplierInvoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          _getSupplierName(
            invoice.supplierId,
          ).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          _getSiteName(
            invoice.siteId,
          ).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showAddInvoiceBottomSheet() {
    // Pass the current site ID to the bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditInvoiceBottomSheet(
        suppliers: _suppliers,
        sites: _sites,
        preselectedSiteId: _currentSiteId != null
            ? int.parse(_currentSiteId!)
            : null,
        workspaceId: widget.workspaceId,
        userId: widget.userId,
        onInvoiceSaved: () {
          _loadAllData();
        },
        onSupplierCreated: _loadSuppliers,
      ),
    );
  }

  void _showEditInvoiceBottomSheet(PurchaseInvoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      //backgroundColor: Colors.transparent,
      builder: (context) => AddEditInvoiceBottomSheet(
        invoice: invoice,
        suppliers: _suppliers,
        sites: _sites,
        preselectedSiteId: _currentSiteId != null
            ? int.parse(_currentSiteId!)
            : null,
        workspaceId: widget.workspaceId,
        userId: widget.userId,
        onInvoiceSaved: _loadAllData,
        onSupplierCreated: _loadSuppliers,
      ),
    );
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await ApiServicePurchaseInvoice.getSuppliers();
      setState(() {
        _suppliers = suppliers;
      });
    } catch (e) {
      print('Error loading suppliers: $e');
    }
  }

  void _showDeleteInvoiceDialog(PurchaseInvoice invoice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Invoice',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete invoice ${invoice.invoiceNumber}?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ApiServicePurchaseInvoice.deleteInvoice(invoice.id);
                  setState(() {
                    _invoices.removeWhere((inv) => inv.id == invoice.id);
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Invoice ${invoice.invoiceNumber} deleted successfully',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete invoice'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _getSiteName(int siteId) {
    try {
      final site = _sites.firstWhere((site) => site.id == siteId);
      return site.name;
    } catch (e) {
      return 'Unknown Site';
    }
  }

  String _getSupplierName(int supplierId, [PurchaseInvoice? invoice]) {
    if (invoice?.supplier != null) {
      return invoice!.supplier.name;
    }
    // Fallback to searching in local list
    try {
      final supplier = _suppliers.firstWhere((s) => s.id == supplierId);
      return supplier.name;
    } catch (e) {
      return 'Supplier $supplierId';
    }
  }

  // ==================== PDF REPORT FUNCTIONALITY ====================

  Future<void> _generateReport() async {
    // Initialize report with default values (today's date)
    _reportStartDate = DateTime.now();
    _reportEndDate = DateTime.now();

    // Calculate initial report data
    _updateReportData();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReportSheet(),
    );
  }

  void _updateReportData() {
    // Filter records by date range
    _reportRecords = _invoices.where((invoice) {
      try {
        final invoiceDate = DateTime.parse(invoice.invoiceDate);
        return (invoiceDate.isAtSameMomentAs(_reportStartDate) ||
                invoiceDate.isAfter(_reportStartDate)) &&
            (invoiceDate.isAtSameMomentAs(_reportEndDate) ||
                invoiceDate.isBefore(
                  _reportEndDate.add(const Duration(days: 1)),
                ));
      } catch (e) {
        return false;
      }
    }).toList();

    // Calculate totals for the filtered records
    _reportTotalAmount = 0;
    _reportTotalInvoices = _reportRecords.length;
    _reportDateTotals.clear();

    for (var invoice in _reportRecords) {
      _reportTotalAmount += invoice.totalAmount;

      // Sum up by date
      final dateKey = invoice.invoiceDate;
      _reportDateTotals[dateKey] =
          (_reportDateTotals[dateKey] ?? 0) + invoice.totalAmount;
    }
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
          height: screenHeight * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Purchase Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a43a0),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF2a43a0)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date Range Selection
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

              const SizedBox(height: 16),

              // Report Summary
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildReportSummary(),
                      const SizedBox(height: 16),
                      _buildDateWiseSummary(),
                      const SizedBox(height: 16),
                      _buildRecordsList(),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _viewPDF(() => Navigator.pop(context)),
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
                  // ElevatedButton.icon(
                  //   onPressed: () => _downloadPDF(() => Navigator.pop(context)),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: const Color(0xFF4a63c0),
                  //     foregroundColor: Colors.white,
                  //     elevation: 4,
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 12,
                  //       vertical: 10,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //   ),
                  //   icon: const Icon(Icons.download, size: 16),
                  //   label: const Text(
                  //     'Download PDF',
                  //     style: TextStyle(fontSize: 12),
                  //   ),
                  // ),
                  // ElevatedButton(
                  //   onPressed: () => Navigator.pop(context),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.grey.shade300,
                  //     foregroundColor: Colors.black54,
                  //     elevation: 4,
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 16,
                  //       vertical: 10,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //   ),
                  //   child: const Text('Close', style: TextStyle(fontSize: 12)),
                  // ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _viewPDF([VoidCallback? onSuccess]) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfBytes = await _generatePdfBytes();
      final directory = await getTemporaryDirectory();
      final siteName = _getCurrentSiteName().replaceAll(' ', '_');
      final fileName =
          'dpr_report_${siteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes);

      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      if (onSuccess != null) {
        onSuccess();
      }

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${result.message}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to view PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildReportSummary() {
    return Container(
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
          _buildReportItem(
            'Date Range',
            '${DateFormat('yyyy-MM-dd').format(_reportStartDate)} to ${DateFormat('yyyy-MM-dd').format(_reportEndDate)}',
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem(
            'Site',
            _getCurrentSiteName(),
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem(
            'Total Invoices',
            _reportTotalInvoices.toString(),
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem(
            'Total Amount',
            'Rs ${_reportTotalAmount.toStringAsFixed(2)}',
            Colors.white70,
            Colors.white,
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white30),
          const SizedBox(height: 10),
          _buildReportItem(
            'Report Generated',
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
            Colors.white70,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: TextStyle(color: labelColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateWiseSummary() {
    if (_reportDateTotals.isEmpty) {
      return const Center(
        child: Text(
          'No data for selected date range',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Sort dates
    final sortedDates = _reportDateTotals.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            'Date-wise Expenditure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2a43a0),
            ),
          ),
          const SizedBox(height: 12),
          ...sortedDates.map(
            (date) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Rs ${_reportDateTotals[date]!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a43a0),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_reportRecords.isEmpty) {
      return Container();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            'Recent Invoices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2a43a0),
            ),
          ),
          const SizedBox(height: 12),
          ..._reportRecords
              .take(5)
              .map(
                (invoice) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.invoiceNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _getSupplierName(invoice.supplierId),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs ${invoice.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2a43a0),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          if (_reportRecords.length > 5)
            Text(
              '... and ${_reportRecords.length - 5} more invoices',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();

    // Use the already filtered records
    final filteredRecords = _reportRecords;

    // Group and calculate totals by date
    final Map<String, Map<String, double>> dailyStats = {};
    double totalAmount = 0;

    for (var invoice in filteredRecords) {
      totalAmount += invoice.totalAmount;

      if (!dailyStats.containsKey(invoice.invoiceDate)) {
        dailyStats[invoice.invoiceDate] = {'amount': 0.0, 'count': 0.0};
      }

      dailyStats[invoice.invoiceDate]!['amount'] =
          dailyStats[invoice.invoiceDate]!['amount']! + invoice.totalAmount;
      dailyStats[invoice.invoiceDate]!['count'] =
          dailyStats[invoice.invoiceDate]!['count']! + 1;
    }

    // Sort dates
    final sortedDates = dailyStats.keys.toList()..sort();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Material Purchase Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF2a43a0),
                    ),
                  ),
                  pw.Text(
                    'Site: ${_getCurrentSiteName()}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Report Details
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Report Period: ${DateFormat('dd MMM yyyy').format(_reportStartDate)} to ${DateFormat('dd MMM yyyy').format(_reportEndDate)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Total Invoices: ${filteredRecords.length}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Total Amount: Rs ${totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Suppliers Count: ${filteredRecords.map((e) => e.supplierId).toSet().length}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Dates with Data: ${sortedDates.length}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 25),

              // Date-wise Summary Table
              pw.Text(
                'Date-wise Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF2a43a0),
                ),
              ),
              pw.SizedBox(height: 10),

              if (sortedDates.isNotEmpty)
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5), // Date
                    1: const pw.FlexColumnWidth(1), // Day
                    2: const pw.FlexColumnWidth(1), // Count
                    3: const pw.FlexColumnWidth(1.5), // Amount
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF2a43a0),
                      ),
                      children: [
                        pw.Padding(
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            'Day',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            'Invoices',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                      ],
                    ),

                    // Data rows
                    ...sortedDates.map((dateStr) {
                      try {
                        final date = DateTime.parse(dateStr);
                        final formattedDate = DateFormat(
                          'dd-MMM-yyyy',
                        ).format(date);
                        final dayName = DateFormat('EEEE').format(date);
                        final stats = dailyStats[dateStr]!;

                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              child: pw.Text(
                                formattedDate,
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                dayName.substring(0, 3),
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                stats['count']!.toStringAsFixed(0),
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                'Rs ${stats['amount']!.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColor.fromInt(0xFF2a43a0),
                                ),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                          ],
                        );
                      } catch (e) {
                        return pw.TableRow(children: [pw.Text('Error')]);
                      }
                    }).toList(),

                    // Total row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF0F4FF),
                      ),
                      children: [
                        pw.Padding(
                          child: pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(''),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            filteredRecords.length.toString(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            'Rs ${totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: PdfColor.fromInt(0xFF2a43a0),
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                      ],
                    ),
                  ],
                )
              else
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No invoice data found for the selected date range',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                    ),
                  ),
                ),

              pw.SizedBox(height: 30),

              // DETAILED RECORDS SECTION
              if (filteredRecords.isNotEmpty) ...[
                pw.Text(
                  'Detailed Invoices',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF2a43a0),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Table for detailed records
                pw.Table(
                  border: pw.TableBorder.all(
                    width: 0.5,
                    color: PdfColors.grey300,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2), // Invoice #
                    1: const pw.FlexColumnWidth(1.2), // Date
                    2: const pw.FlexColumnWidth(2), // Supplier
                    3: const pw.FlexColumnWidth(1), // Status
                    4: const pw.FlexColumnWidth(1.2), // Amount
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF0F4FF),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Invoice #',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Supplier',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Status',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    // Rows
                    ...filteredRecords.map((invoice) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              invoice.invoiceNumber,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              invoice.invoiceDate,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              _getSupplierName(invoice.supplierId),
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              invoice.status,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color:
                                    invoice.status.toLowerCase() == 'approved'
                                    ? PdfColors.green
                                    : PdfColors.black,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Rs ${invoice.totalAmount.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 30),
              ],

              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                  color: PdfColor.fromInt(0xFFF8F9FA),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Generated on: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Site: ${_getCurrentSiteName()}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _downloadPDF([VoidCallback? onSuccess]) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      if (Platform.isAndroid) {
        await _requestStoragePermission();
      }

      final pdfBytes = await _generatePdfBytes();
      final directory = await _getDownloadDirectory();
      final siteName = _getCurrentSiteName().replaceAll(' ', '_');
      final fileName =
          'material_report_${siteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes);

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (onSuccess != null) {
        onSuccess();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded to ${file.path}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () async {
              final result = await OpenFile.open(file.path);
              if (result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open file: ${result.message}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.storage.status;
        if (status.isGranted) {
          Directory? downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            return downloadsDir;
          }
        }
      } catch (e) {
        debugPrint('Error accessing downloads directory: $e');
      }
    }

    return await getApplicationDocumentsDirectory();
  }

  // ==================== END PDF FUNCTIONALITY ====================

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search invoices...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        color: textSecondary,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cardColor,
                hintStyle: TextStyle(color: textSecondary, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long, size: 64, color: primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              _currentSiteId != null
                  ? 'No invoices for this site'
                  : 'No invoices found',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty && _invoices.isEmpty
                  ? (_currentSiteId != null
                        ? 'Start by adding an invoice for ${_getCurrentSiteName()}'
                        : 'Start by adding your first invoice')
                  : 'Try adjusting your search criteria',
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_currentSiteId != null) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _showAddInvoiceBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: Text(
                      'Add Invoice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.red;
      case 'paid':
        return Colors.blue;
      default:
        return primaryColor;
    }
  }

  void _showInvoiceOptionsBottomSheet(PurchaseInvoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final provider = Provider.of<CompanySiteProvider>(
          sheetContext,
          listen: false,
        );
        final hasShowPermission = provider.hasPermission(
          'purchase-invoices show',
        );
        final hasEditPermission = provider.hasPermission(
          'purchase-invoices edit',
        );
        final hasDeletePermission = provider.hasPermission(
          'purchase-invoices delete',
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // Header with invoice info
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.invoiceNumber,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getSupplierName(invoice.supplierId, invoice),
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Rs ${invoice.totalAmount.toStringAsFixed(2)} • ${_formatDate(invoice.invoiceDate)}',
                              style: TextStyle(
                                fontSize: 12, // Adjusted font size
                                color: textSecondary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 0, thickness: 1),

                // Options List
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Payment Request Option
                      _buildOptionTile(
                        icon: Icons.payment_outlined,
                        title: 'Payment Request',
                        Iconcolor: Colors.green,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        onTap: () async {
                          Navigator.pop(sheetContext); // Close the bottom sheet

                          // Show loading using OUTSIDE context
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          try {
                            final dropdownData =
                                await PaymentService.getDropdownData(
                                  workspaceId: widget.workspaceId ?? 3,
                                );

                            if (mounted) {
                              // Check if MaterialScreen is mounted
                              if (Navigator.of(
                                context,
                                rootNavigator: true,
                              ).canPop()) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop(); // Close loading dialog
                              }

                              showModalBottomSheet(
                                context: context, // Use outer context
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) {
                                  return PaymentFormBottomSheet(
                                    payment: pm.Payment(
                                      purchaseInvoiceId: invoice.id,
                                      supplierId: invoice.supplierId,
                                      siteId: invoice.siteId,
                                      paymentDate: DateTime.now().toString(),
                                      paymentNumber:
                                          dropdownData.nextPaymentNumber,
                                      paymentType:
                                          'against_invoice', // Auto-select 'against_invoice'
                                    ),
                                    hideSiteField: true,
                                    fixedSiteName: widget.sites
                                        .firstWhere(
                                          (s) =>
                                              s.id.toString() ==
                                              widget.selectedSiteId,
                                          orElse: () => widget.sites.first,
                                        )
                                        .name,
                                    dropdownData: dropdownData,

                                    onSave: (val) {
                                      _loadAllData();
                                    },
                                    workspaceId: widget.workspaceId,
                                    userId: widget.userId,
                                  );
                                },
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              if (Navigator.of(
                                context,
                                rootNavigator: true,
                              ).canPop()) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop(); // Close loading dialog
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),

                      // View Details Option
                      if (hasShowPermission)
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
                            Navigator.pop(sheetContext);
                            _showInvoiceDetailsBottomSheet(invoice);
                          },
                        ),

                      // Edit Option
                      if (hasEditPermission)
                        _buildOptionTile(
                          icon: Icons.edit_outlined,
                          title: 'Edit Invoice',
                          Iconcolor: Colors.blue,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          onTap: () {
                            Navigator.pop(context);
                            _showEditInvoiceBottomSheet(invoice);
                          },
                        ),
                      // Delete Option
                      if (hasDeletePermission)
                        _buildOptionTile(
                          icon: Icons.delete_outline,
                          title: 'Delete Invoice',
                          Iconcolor: Colors.red,
                          backgroundColor: Colors.red.withOpacity(0.1),
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteInvoiceDialog(invoice);
                          },
                        ),
                      // Download PDF Option
                      // ...
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  // Helper method to show invoice details
  void _showInvoiceDetailsBottomSheet(PurchaseInvoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Purchase Invoice',
                          style: TextStyle(fontSize: 14, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Details List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Invoice Number', invoice.invoiceNumber),
                    _buildDetailRow(
                      'Supplier Invoice',
                      invoice.supplierInvoiceNumber.isNotEmpty
                          ? invoice.supplierInvoiceNumber
                          : 'N/A',
                    ),
                    _buildDetailRow(
                      'Supplier',
                      _getSupplierName(invoice.supplierId, invoice),
                    ),

                    _buildDetailRow(
                      'Invoice Date',
                      _formatDate(invoice.invoiceDate),
                    ),
                    _buildDetailRow(
                      'Invoice Type',
                      _getInvoiceTypeDisplay(invoice.invoiceType),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Invoice Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Invoice File Section
                    if (invoice.invoiceFile != null &&
                        invoice.invoiceFile!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Invoice Document',
                              style: TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            InkWell(
                              onTap: () => _launchInvoiceUrl(invoice),
                              child: const Text(
                                'View File',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                    ],

                    // Total Amount
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Rs ${invoice.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 75, 172, 79),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Items Section (if available)
                    if (invoice.items != null && invoice.items!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...invoice.items!.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.material?.name ??
                                          'Material ${item.materialId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} ${item.unit} × Rs ${item.price}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rs ${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditInvoiceBottomSheet(invoice);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Edit Invoice'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for new options
  void _downloadInvoiceAsPDF(PurchaseInvoice invoice) {
    // TODO: Implement PDF download for single invoice
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading invoice ${invoice.invoiceNumber}...'),
        backgroundColor: primaryColor,
      ),
    );
  }

  Future<void> _launchInvoiceUrl(PurchaseInvoice invoice) async {
    if (invoice.invoiceFile == null || invoice.invoiceFile!.isEmpty) return;

    String url = invoice.invoiceFile!;
    const String baseUrl = 'https://app.ecoteamsolar.com';

    // Construct full URL if not already absolute
    if (!url.startsWith('http')) {
      // Remove leading slash if present to avoid double slashes
      if (url.startsWith('/')) {
        url = url.substring(1);
      }
      url = '$baseUrl/$url';
    }

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open file: $url')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  void _shareInvoice(PurchaseInvoice invoice) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing invoice ${invoice.invoiceNumber}...'),
        backgroundColor: primaryColor,
      ),
    );
  }

  void _updateInvoiceStatus(PurchaseInvoice invoice, String newStatus) {
    // TODO: Implement status update
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updating invoice status to $newStatus...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _duplicateInvoice(PurchaseInvoice invoice) {
    // TODO: Implement duplicate functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating duplicate of ${invoice.invoiceNumber}...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check permissions
    final provider = Provider.of<CompanySiteProvider>(context);
    final hasCreatePermission = provider.hasPermission(
      'purchase-invoices create',
    );
    final hasExportPermission = provider.hasPermission(
      'purchase-invoices export',
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: null,

      floatingActionButton: hasCreatePermission
          ? FloatingActionButton(
              heroTag: 'purchase_invoice_fab',
              onPressed: _showAddInvoiceBottomSheet,
              child: const Icon(Icons.add, color: Colors.white),
              backgroundColor: const Color.fromRGBO(
                42,
                67,
                160,
                1,
              ), // Any color you want
              tooltip: 'Add New Invoice',
            )
          : null, // Hide if no permission

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3,
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildSearchBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredInvoices.length} invoices',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Text(
                      //   'Total: \Rs ${_invoices.fold<double>(0, (sum, invoice) => sum + invoice.totalAmount).toStringAsFixed(2)}',
                      //   style: TextStyle(
                      //     color: primaryColor,
                      //     fontSize: 14,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                      // Export Button
                      if (hasExportPermission)
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
                            onPressed: _generateReport,
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
                const SizedBox(height: 8),
                Expanded(
                  child: _invoices.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 90,
                          ),
                          itemCount: _filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _filteredInvoices[index];
                            return _buildInvoiceCard(invoice);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildInvoiceCard(PurchaseInvoice invoice) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),

          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with invoice number and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.receipt,
                                  color: primaryColor,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  invoice.invoiceNumber,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.only(left: 44),
                            child: Text(
                              _getInvoiceTypeDisplay(invoice.invoiceType),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (Provider.of<CompanySiteProvider>(
                              context,
                            ).hasPermission('purchase-invoices show') ||
                            Provider.of<CompanySiteProvider>(
                              context,
                            ).hasPermission('purchase-invoices edit') ||
                            Provider.of<CompanySiteProvider>(
                              context,
                            ).hasPermission('purchase-invoices delete'))
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: textSecondary,
                            ),
                            onPressed: () =>
                                _showInvoiceOptionsBottomSheet(invoice),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getInvoiceTypeDisplay(String invoiceType) {
    switch (invoiceType) {
      case 'general_po':
        return 'General PO';
      case 'minor_misc_service':
        return 'Minor Miscellaneous Service';
      default:
        return StringExtension(invoiceType.replaceAll('_', ' ')).toTitleCase();
    }
  }
}

class AddEditInvoiceBottomSheet extends StatefulWidget {
  final PurchaseInvoice? invoice;
  final List<Supplier> suppliers;
  final List<SiteModel> sites;
  final int? preselectedSiteId;
  final int? workspaceId; // New parameter
  final int? userId;
  final VoidCallback? onInvoiceSaved;
  final VoidCallback? onSupplierCreated;

  const AddEditInvoiceBottomSheet({
    super.key,
    this.invoice,
    required this.suppliers,
    required this.sites,
    this.preselectedSiteId,
    this.workspaceId,
    this.userId,
    this.onInvoiceSaved,
    this.onSupplierCreated,
  });

  @override
  State<AddEditInvoiceBottomSheet> createState() =>
      _AddEditInvoiceBottomSheetState();
}

class _AddEditInvoiceBottomSheetState extends State<AddEditInvoiceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _supplierInvoiceNoController =
      TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();

  int? _selectedSiteId;
  int? _selectedSupplierId;
  final List<MaterialItem> _materialItems = [];
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedDate;
  bool _isSubmitting = false;
  List<MaterialModel> _materials = [];
  List<UnitModel> _units = [];
  bool _isLoadingMaterials = false;

  // Invoice type dropdown value
  String _selectedInvoiceType = 'general_po';
  final List<Map<String, String>> _invoiceTypeOptions = [
    {'value': 'general_po', 'label': 'General PO'},
    {
      'value': 'minor_misc_service',
      'label': 'Minor Miscellaneous Service Bills',
    },
  ];

  // Local suppliers list that can be updated
  List<Supplier> _localSuppliers = [];
  List<SiteModel> _fetchedSites = []; // Stores dynamically fetched sites

  // UI Colors
  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color primaryDark = Color(0xFF2a43a0);
  static const Color backgroundColor = Color(0xFFf8f9fa);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _localSuppliers = widget.suppliers;
    _fetchedSites = widget.sites;
    _loadMaterialsAndUnits();

    if (widget.invoice != null) {
      // Edit mode - populate fields
      _invoiceNoController.text = widget.invoice!.invoiceNumber;
      _supplierInvoiceNoController.text = widget.invoice!.supplierInvoiceNumber;

      _selectedSiteId = widget.invoice!.siteId;
      _selectedSupplierId = widget.invoice!.supplierId;
      _selectedInvoiceType = widget.invoice!.invoiceType;

      _invoiceDateController.text = _formatDateForDisplay(
        DateTime.parse(widget.invoice!.invoiceDate),
      );
      _selectedDate = DateTime.parse(widget.invoice!.invoiceDate);

      // Populate materials only if invoice type is general_po
      if (_selectedInvoiceType == 'general_po' &&
          widget.invoice!.items != null) {
        for (var item in widget.invoice!.items!) {
          String materialName = 'Material ${item.materialId}';
          String unitSymbol = item.unit;

          _materialItems.add(
            MaterialItem(
              materialId: item.materialId,
              materialName: materialName,
              quantity: item.quantity.toString(),
              unit: unitSymbol,
              price: item.price.toStringAsFixed(2),
              subtotal: item.subtotal.toStringAsFixed(2),
            ),
          );
        }
      }
    } else {
      // Add mode - set default values
      _invoiceNoController.text =
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      _invoiceDateController.text = _formatDateForDisplay(DateTime.now());
      _selectedDate = DateTime.now();
      _selectedSupplierId = _localSuppliers.isNotEmpty
          ? _localSuppliers.first.id
          : null;

      // Set selected site ID from preselected value or first site
      if (widget.preselectedSiteId != null) {
        _selectedSiteId = widget.preselectedSiteId;
      } else {
        _selectedSiteId = widget.sites.isNotEmpty
            ? widget.sites.first.id
            : null;
      }

      // Add one empty material item for add mode if invoice type is general_po
      if (_selectedInvoiceType == 'general_po') {
        _addMaterialItem();
      }
    }
  }

  Future<void> _refreshSuppliers() async {
    try {
      final suppliers = await ApiServicePurchaseInvoice.getSuppliers();
      setState(() {
        _localSuppliers = suppliers;
      });
    } catch (e) {
      print('Error refreshing suppliers: $e');
    }
  }

  Future<void> _loadMaterialsAndUnits() async {
    setState(() {
      _isLoadingMaterials = true;
    });

    try {
      final siteId = _selectedSiteId ?? widget.preselectedSiteId ?? 0;
      final workspaceId = widget.workspaceId ?? 1; // Default to 1 if null

      // Pass the selected siteId to fetch site-specific data if available
      // The API now expects siteId to be passed to get relevant stock/next invoice number
      final createData = await ApiServicePurchaseInvoice.getCreateData(
        siteId: siteId,
        workspaceId: workspaceId,
      );

      final materials = createData['materials'] as List<MaterialModel>;
      final units = await ApiServicePurchaseInvoice.getUnits();

      final suppliers = createData['suppliers'] as List<Supplier>?;
      final sites = createData['sites'] as List<SiteModel>?;
      final nextInvoiceNumber = createData['next_invoice_number'] as String?;

      if (mounted) {
        setState(() {
          _materials = materials;
          _units = units;
          if (suppliers != null && suppliers.isNotEmpty) {
            _localSuppliers = suppliers;
          }
          if (sites != null && sites.isNotEmpty) {
            _fetchedSites = sites;
          }

          // Auto-populate invoice number in Add mode
          if (widget.invoice == null &&
              nextInvoiceNumber != null &&
              nextInvoiceNumber.isNotEmpty) {
            _invoiceNoController.text = nextInvoiceNumber;
          }

          _isLoadingMaterials = false;
        });
      }

      // If in edit mode and we have materials, update the material names
      if (widget.invoice != null && _materials.isNotEmpty && mounted) {
        for (int i = 0; i < _materialItems.length; i++) {
          final item = _materialItems[i];
          try {
            final material = _materials.firstWhere(
              (m) => m.id == item.materialId || m.name == item.materialName,
              orElse: () =>
                  _materials.firstWhere((m) => m.id == item.materialId),
            );
            if (material.name != item.materialName) {
              setState(() {
                _materialItems[i] = _materialItems[i].copyWith(
                  materialName: material.name,
                );
              });
            }
          } catch (e) {
            print('Material not found for id: ${item.materialId}');
          }
        }
      }

      print('Loaded ${_materials.length} materials and ${_units.length} units');
    } catch (e) {
      print('Error loading materials or units: $e');
      if (mounted) {
        setState(() {
          _isLoadingMaterials = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load materials: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _invoiceDateController.text = _formatDateForDisplay(picked);
      });
    }
  }

  Future<void> _pickFile() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.attach_file, color: primaryColor),
                  title: const Text('Choose File (PDF/Image)'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                          );

                      if (result != null && result.files.single.path != null) {
                        setState(() {
                          _selectedFile = File(result.files.single.path!);
                        });
                      }
                    } catch (e) {
                      print('Error picking file: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error picking file: $e')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: primaryColor),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        setState(() {
                          _selectedFile = File(image.path);
                        });
                      }
                    } catch (e) {
                      print('Error taking photo: $e');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: const Text('Cancel'),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateSupplierBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateSupplierBottomSheet(
        onSupplierCreated: (newSupplierId) async {
          widget.onSupplierCreated?.call();

          await _refreshSuppliers();

          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            setState(() {
              _selectedSupplierId = newSupplierId;
            });
          }
        },
      ),
    );
  }

  void _addMaterialItem() {
    setState(() {
      _materialItems.add(MaterialItem());
    });
  }

  void _updateMaterialItem(int index, MaterialItem updatedItem) {
    setState(() {
      _materialItems[index] = updatedItem;
    });
  }

  void _removeMaterialItem(int index) {
    setState(() {
      _materialItems.removeAt(index);
    });
  }

  double get _totalAmount {
    if (_selectedInvoiceType == 'minor_misc_service') {
      return 0;
    }

    double total = 0;
    for (var item in _materialItems) {
      if (item.subtotal.isNotEmpty) {
        total += double.tryParse(item.subtotal) ?? 0;
      }
    }
    return total;
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool hasError = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        color: textPrimary,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 214, 215, 216),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
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
        contentPadding: EdgeInsets.symmetric(vertical: 2),
        prefixIcon: Icon(icon, color: Color(0xFF4a63c0), size: 20.sp),
        errorText: hasError ? 'Required' : null,
      ),
    );
  }

  Widget _buildEnhancedDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    bool hasError = false,
    bool isReadOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          errorText: hasError ? 'Required' : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          prefixIcon: Icon(
            icon,
            color: hasError ? Colors.red : textSecondary,
            size: 20,
          ),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color.fromARGB(255, 214, 215, 216),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color.fromARGB(255, 214, 215, 216),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color.fromARGB(255, 169, 171, 180),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: TextStyle(
            color: hasError ? Colors.red : textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        dropdownColor: cardColor,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        items: items,
        onChanged: (_isSubmitting || isReadOnly) ? null : onChanged,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInvoiceType == 'general_po' && _materialItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one material item for General PO'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSiteId == null || _selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select site and supplier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> invoiceData = {
        'invoice_number': _invoiceNoController.text,
        'invoice_date': _invoiceDateController.text,
        'supplier_invoice_number': _supplierInvoiceNoController.text,
        'supplier_id': _selectedSupplierId.toString(),
        'total_amount': _totalAmount.toStringAsFixed(2),
        'site_id': _selectedSiteId
            .toString(), // This will be the selected site ID
        'created_by': (widget.userId ?? 1).toString(),
        // Use the passed workspaceId or default to 1 (safe fallback)
        'workspace_id': widget.workspaceId,
        'invoice_type': _selectedInvoiceType,
        'invoice_file': _selectedFile,
      };

      // Add items only for general_po
      if (_selectedInvoiceType == 'general_po') {
        invoiceData['items'] = _materialItems
            .where((item) => item.materialId > 0)
            .map(
              (item) => {
                'material_id': item.materialId.toString(),
                'quantity': item.quantity,
                'unit': item.unit,
                'price': item.price,
                'subtotal': item.subtotal,
              },
            )
            .toList();
      }

      print('Submitting invoice data: $invoiceData');

      PurchaseInvoice result;
      if (widget.invoice != null) {
        result = await ApiServicePurchaseInvoice.updateInvoice(
          widget.invoice!.id,
          invoiceData,
        );
      } else {
        result = await ApiServicePurchaseInvoice.createInvoice(invoiceData);
      }

      print('Invoice saved successfully: ${result.invoiceNumber}');

      if (mounted) {
        Navigator.pop(context);
        widget.onInvoiceSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.invoice != null
                  ? 'Invoice ${result.invoiceNumber} updated successfully'
                  : 'Invoice ${result.invoiceNumber} created successfully',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error submitting form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save invoice'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.invoice != null;
    final bool isPreselectedSite = widget.preselectedSiteId != null && !isEdit;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: false,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEdit ? Icons.edit : Icons.add_circle,
                              color: primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit
                                      ? 'Edit Invoice'
                                      : 'Create Purchase Invoice',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  isEdit
                                      ? 'Update invoice details'
                                      : 'Enter invoice details below',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Invoice Number
                      const SizedBox(height: 8),
                      _buildEnhancedTextField(
                        controller: _invoiceNoController,
                        label: 'Invoice Number',
                        hint: 'Enter Invoice Number',
                        icon: Icons.receipt,
                        isRequired: true,
                      ),
                      const SizedBox(height: 10),

                      // Supplier Invoice Number
                      _buildEnhancedTextField(
                        controller: _supplierInvoiceNoController,
                        label: 'Supplier Invoice Number',
                        hint: 'Enter Supplier Invoice Number',

                        icon: Icons.receipt_long,
                      ),

                      // Project/Site
                      const SizedBox(height: 10),

                      // Invoice Type
                      const SizedBox(height: 10),
                      _buildEnhancedDropdown<String>(
                        value: _selectedInvoiceType,
                        label: 'Select Invoice Type',
                        icon: Icons.category,

                        items: _invoiceTypeOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option['value'],
                            child: Text(option['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedInvoiceType = value!;
                            if (value == 'general_po' &&
                                _materialItems.isEmpty) {
                              _addMaterialItem();
                            }
                          });
                        },
                      ),
                      SizedBox(height: 8.h),

                      // Invoice Materials Section - Only show for General PO
                      if (_selectedInvoiceType == 'general_po') ...[
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invoice Material',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18.sp,
                                color: textPrimary,
                              ),
                            ),
                            // You could add a small icon button here if you want
                            // Or leave it as just the text
                            IconButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : _addMaterialItem,
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF4A63C0),
                                      const Color(0xFF2A43A0),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Add New Material Item',
                            ),
                          ],
                        ),

                        SizedBox(height: 10.h),

                        if (_isLoadingMaterials) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Material Items List
                          if (_materialItems.isNotEmpty) ...[
                            ..._materialItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return MaterialItemRow(
                                item: item,
                                index: index,
                                materials: _materials,
                                units: _units,
                                onUpdate: (updatedItem) =>
                                    _updateMaterialItem(index, updatedItem),
                                onRemove: _isSubmitting
                                    ? null
                                    : () => _removeMaterialItem(index),
                              );
                            }),
                            const SizedBox(height: 16),
                          ] else ...[
                            MaterialItemRow(
                              item: MaterialItem(),
                              index: 0,
                              materials: _materials,
                              units: _units,
                              onUpdate: (updatedItem) =>
                                  _updateMaterialItem(0, updatedItem),
                              onRemove: null,
                            ),
                          ],

                          // Add Item Button - Moved here, outside the Row
                          const SizedBox(height: 13),
                        ],
                      ],

                      // Invoice Date
                      const SizedBox(height: 8),
                      _buildEnhancedTextField(
                        controller: _invoiceDateController,
                        label: 'Invoice Date',
                        hint: 'Select Date',
                        icon: Icons.calendar_today,
                        isRequired: true,
                        readOnly: true,
                        onTap: _isSubmitting
                            ? null
                            : () => _selectDate(context),
                      ),
                      const SizedBox(height: 10),

                      // Supplier
                      const SizedBox(height: 8),
                      _buildEnhancedDropdown<int>(
                        value:
                            _localSuppliers.any(
                              (s) => s.id == _selectedSupplierId,
                            )
                            ? _selectedSupplierId
                            : null,
                        label: 'Select Supplier',
                        icon: Icons.business_center,

                        items: _localSuppliers.map((supplier) {
                          return DropdownMenuItem<int>(
                            value: supplier.id,
                            child: Text(
                              supplier.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSupplierId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Create New Supplier Button
                      OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : _showCreateSupplierBottomSheet,
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text(
                          'Create New Supplier',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color.fromRGBO(74, 99, 192, 1),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(
                            vertical: 1, // Minimized vertical padding
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // Slightly smaller radius
                          ),
                          side: BorderSide(
                            color:
                                primaryColor, // Match border with background color
                          ),
                          minimumSize: const Size(
                            0,
                            30,
                          ), // Set minimum height to 30
                          tapTargetSize: MaterialTapTargetSize
                              .shrinkWrap, // Reduces tap target
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Invoice File Upload
                      const Text(
                        'Invoice File',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _pickFile,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.upload_file, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Choose File',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedFile != null
                                    ? _selectedFile!.path.split('/').last
                                    : 'No file chosen',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Allowed: pdf, jpg, jpeg, png, doc, docx',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Total Amount
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Rs ${_totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, primaryDark],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          isEdit
                                              ? 'Update Invoice'
                                              : 'Create Invoice',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreselectedSiteDisplay() {
    // Find the preselected site
    final preselectedSite = widget.sites.firstWhere(
      (site) => site.id == widget.preselectedSiteId,
      orElse: () => SiteModel(
        id: 0,
        name: 'Unknown Site',
        status: 'active', // Added
        description: '', // Added
        startDate: '', // Added
        endDate: '', // Added
        budget: 0.0, // Added
        isActive: 1, // Added
        type: '', // Added
        currency: 'USD', // Added
        profileProgress: '0', // Added
        progress: '0', // Added
        taskProgress: '0', // Added
        estimateSize: 0.0, // Added
        copylinksetting: '', // Added
        workspaceId: 1,
        createdBy: 0, // Added
        createdAt: '', // Added
        updatedAt: '', // Added
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

// Update CreateSupplierBottomSheet with MaterialScreen style
class CreateSupplierBottomSheet extends StatefulWidget {
  final Function(int)? onSupplierCreated;

  const CreateSupplierBottomSheet({super.key, this.onSupplierCreated});

  @override
  State<CreateSupplierBottomSheet> createState() =>
      _CreateSupplierBottomSheetState();
}

class _CreateSupplierBottomSheetState extends State<CreateSupplierBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _upiScreenshot1;
  final ImagePicker _picker = ImagePicker();

  int? _selectedCategoryId;
  List<SupplierCategory> _categories = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  // UI Colors
  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color primaryDark = Color(0xFF2a43a0);
  static const Color backgroundColor = Color(0xFFf8f9fa);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await SupplierApiService.getSupplierCategories();
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickUpiScreenshot1() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _upiScreenshot1 = File(image.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newSupplier = Supplier(
        name: _nameController.text,
        categoryId: _selectedCategoryId!,
        // Default/Dummy values for required fields not in form
        type: 'General',
        contactPerson:
            _nameController.text, // Use name as contact person default
        phone: _phoneController.text,
        siteId: 1, // Default from original code
        workspaceId: 1, // Default from original code
        createdBy: 1, // Default from original code
        isActive: 1,
        status: 'active',
      );

      final createdSupplier = await SupplierApiService.addSupplier(
        newSupplier,
        screenshot: _upiScreenshot1,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSupplierCreated?.call(createdSupplier.id ?? 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Supplier created successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error creating supplier: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create supplier: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool hasError = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 214, 215, 216),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
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
        contentPadding: EdgeInsets.symmetric(vertical: 2),
        prefixIcon: Icon(icon, color: Color(0xFF4a63c0), size: 20.sp),
        errorText: hasError ? 'Required' : null,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildEnhancedDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    bool hasError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          errorText: hasError ? 'Required' : null,
          prefixIcon: Icon(
            icon,
            color: hasError ? Colors.red : textSecondary,
            size: 20,
          ),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: TextStyle(
            color: hasError ? Colors.red : textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        dropdownColor: cardColor,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        items: items,
        onChanged: _isSubmitting ? null : onChanged,
        validator: (value) {
          if (hasError && value == null) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: false,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person_add,
                              color: primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create New Supplier',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Enter supplier details below',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Name
                      const Text(
                        'Name*',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEnhancedTextField(
                        controller: _nameController,
                        label: 'Supplier Name',
                        hint: 'Enter Supplier Name',
                        icon: Icons.person,
                        isRequired: true,
                      ),
                      const SizedBox(height: 20),

                      // Category
                      const Text(
                        'Category*',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            )
                          : _buildEnhancedDropdown<int>(
                              value: _selectedCategoryId,
                              label: 'Select Category',
                              icon: Icons.category,
                              items: _categories.map((category) {
                                return DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                              hasError: _selectedCategoryId == null,
                            ),
                      const SizedBox(height: 20),

                      // Phone
                      const Text(
                        'Phone',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEnhancedTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // UPI Screenshot
                      const Text(
                        'UPI Screenshot',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _pickUpiScreenshot1,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.upload_file, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Choose File',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _upiScreenshot1 != null
                                    ? _upiScreenshot1!.path.split('/').last
                                    : 'No file chosen',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Allowed: jpg, jpeg, png',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, primaryDark],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'Save Supplier',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Material Item Class
class MaterialItem {
  int materialId;
  String materialName;
  String quantity;
  String unit;
  String price;
  String subtotal;

  MaterialItem({
    this.materialId = 0,
    this.materialName = '',
    this.quantity = '',
    this.unit = '',
    this.price = '',
    this.subtotal = '0.00',
  });

  MaterialItem copyWith({
    int? materialId,
    String? materialName,
    String? quantity,
    String? unit,
    String? price,
    String? subtotal,
  }) {
    return MaterialItem(
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}

class MaterialItemRow extends StatefulWidget {
  final MaterialItem item;
  final int index;
  final List<MaterialModel> materials;
  final List<UnitModel> units;
  final Function(MaterialItem) onUpdate;
  final Function()? onRemove;

  const MaterialItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.materials,
    required this.units,
    required this.onUpdate,
    this.onRemove,
  });

  @override
  State<MaterialItemRow> createState() => _MaterialItemRowState();
}

class _MaterialItemRowState extends State<MaterialItemRow> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _subtotalController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  MaterialModel? _selectedMaterial;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(MaterialItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _quantityController.text = widget.item.quantity;
    _priceController.text = widget.item.price;
    _subtotalController.text = widget.item.subtotal;
    _unitController.text = widget.item.unit;

    if (widget.item.materialId > 0) {
      try {
        _selectedMaterial = widget.materials.firstWhere(
          (material) => material.id == widget.item.materialId,
        );
        if (_selectedMaterial?.unit != null) {
          _unitController.text = _selectedMaterial!.unit!.symbol;
        }
      } catch (e) {
        _selectedMaterial = null;
      }
    } else {
      _selectedMaterial = null;
    }
  }

  void _calculateSubtotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final subtotal = quantity * price;

    setState(() {
      _subtotalController.text = subtotal.toStringAsFixed(2);
    });

    widget.onUpdate(
      MaterialItem(
        materialId: _selectedMaterial?.id ?? 0,
        materialName: _selectedMaterial?.name ?? '',
        quantity: _quantityController.text,
        unit: _unitController.text,
        price: _priceController.text,
        subtotal: _subtotalController.text,
      ),
    );
  }

  List<MaterialModel> get _uniqueMaterials {
    final uniqueMaterials = <MaterialModel>[];
    final seenIds = <int>{};

    for (final material in widget.materials) {
      if (!seenIds.contains(material.id)) {
        seenIds.add(material.id);
        uniqueMaterials.add(material);
      }
    }
    return uniqueMaterials;
  }

  void _showMaterialSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Material',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _uniqueMaterials.length,
                    itemBuilder: (context, index) {
                      final material = _uniqueMaterials[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4a63c0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory,
                              color: Color(0xFF4a63c0),
                            ),
                          ),
                          title: Text(
                            material.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Price: \$${material.price.toStringAsFixed(2)}',
                            style: const TextStyle(color: Color(0xFF718096)),
                          ),
                          trailing: _selectedMaterial?.id == material.id
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedMaterial = material;
                              _priceController.text = material.price
                                  .toStringAsFixed(2);
                              if (material.unit != null) {
                                _unitController.text = material.unit!.symbol;
                              } else {
                                _unitController.text = '';
                              }
                              _calculateSubtotal();
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with remove button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${widget.index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF2D3748),
                ),
              ),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // First Row: Material + Quantity & Unit
          Row(
            children: [
              // Material Selection
              Expanded(flex: 2, child: _buildMaterialField()),
              const SizedBox(width: 8),

              // Quantity & Unit in one field
              Expanded(flex: 2, child: _buildQuantityUnitField()),
            ],
          ),
          const SizedBox(height: 8),

          // Second Row: Price + Subtotal
          Row(
            children: [
              // Price
              Expanded(
                child: _buildTextField(
                  label: 'Price',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  hint: '0.00',

                  onChanged: (value) => _calculateSubtotal(),
                ),
              ),
              const SizedBox(width: 8),

              // Subtotal
              Expanded(child: _buildSubtotalField()),
            ],
          ),
        ],
      ),
    );
  }

  // Material selection field
  Widget _buildMaterialField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Material',
          style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _showMaterialSelectionDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color.fromARGB(255, 214, 215, 216)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedMaterial?.name ?? 'Select Material',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedMaterial != null
                          ? const Color(0xFF2D3748)
                          : const Color.fromARGB(255, 88, 88, 88),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Quantity and Unit combined field
  Widget _buildQuantityUnitField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color.fromARGB(255, 214, 215, 216)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 87, 86, 86),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D3748),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _calculateSubtotal(),
                ),
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                  border: Border(
                    left: BorderSide(color: Color.fromARGB(255, 214, 215, 216)),
                  ),
                ),
                child: Text(
                  _unitController.text.isEmpty ? '-' : _unitController.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: _unitController.text.isEmpty
                        ? const Color.fromARGB(255, 100, 100, 100)
                        : const Color(0xFF2D3748),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Subtotal display field
  Widget _buildSubtotalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subtotal',
          style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            _subtotalController.text.isEmpty
                ? '0.00'
                : _subtotalController.text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Reusable text field widget for Price
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color.fromARGB(255, 214, 215, 216)),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 92, 92, 92),
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
            keyboardType: keyboardType,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _subtotalController.dispose();
    _unitController.dispose();
    super.dispose();
  }
}

class GRNTabContent extends StatefulWidget {
  final String? selectedSiteId;
  final int? workspaceId;
  final int? userId;
  final List<Site>? sites;

  const GRNTabContent({
    super.key,
    this.selectedSiteId,
    this.workspaceId,
    this.userId,
    this.sites,
  });

  @override
  State<GRNTabContent> createState() => _GRNTabContentState();
}

class _GRNTabContentState extends State<GRNTabContent> {
  final GRNService _grnService = GRNService();
  bool _isLoading = false;
  List<GRNModel> _grnRecords = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadGRNRecords();
  }

  @override
  void didUpdateWidget(GRNTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSiteId != widget.selectedSiteId ||
        oldWidget.workspaceId != widget.workspaceId) {
      _loadGRNRecords();
    }
  }

  Future<void> _loadGRNRecords() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final grns = await _grnService.getGRNs(
        siteId: widget.selectedSiteId,
        workspaceId: widget.workspaceId?.toString(),
      );
      if (mounted) {
        setState(() {
          _grnRecords = grns;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddGRNBottomSheet(
              sites: widget.sites ?? [],
              selectedSiteId: widget.selectedSiteId,
              workspaceId: widget.workspaceId,
              userId: widget.userId,
              onGRNSaved: _loadGRNRecords,
            ),
          );
        },
        backgroundColor: const Color(0xFF4a63c0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4a63c0)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGRNRecords,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_grnRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64.sp, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No GRN Records Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Goods Received Notes will appear here.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGRNRecords,
      color: const Color(0xFF4a63c0),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grnRecords.length,
        itemBuilder: (context, index) {
          final grn = _grnRecords[index];
          return _buildGRNCard(grn);
        },
      ),
    );
  }

  Widget _buildGRNCard(GRNModel grn) {
    final dateStr = grn.grnDate != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.tryParse(grn.grnDate!) ?? DateTime.now())
        : 'N/A';

    return InkWell(
      onTap: () {
        // Handle tap or show details bottom sheet if implemented later
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  Expanded(
                    child: Text(
                      grn.grnNumber ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(grn.status),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      grn.status ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => _showGRNOptionsBottomSheet(grn),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LEFT SIDE — CREATED BY & DATE
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Created By",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 133, 133, 133),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${grn.creator?.name ?? "Unknown"} | $dateStr",
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// RIGHT SIDE — SUPPLIER
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Vender",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 133, 133, 133),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          grn.supplier?.name ?? "Unknown",
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              /// MATERIALS
              if (grn.items != null && grn.items!.isNotEmpty) ...[
                const Text(
                  "Materials",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 107, 107, 107),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  grn.items!
                      .map((item) => item.material?.name ?? "Unknown")
                      .join(', '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showGRNOptionsBottomSheet(GRNModel grn) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              _buildOptionItem(
                context,
                icon: Icons.visibility_outlined,
                title: 'View GRN',
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ViewGRNBottomSheet(grn: grn),
                  );
                },
              ),
              _buildOptionItem(
                context,
                icon: Icons.edit_outlined,
                title: 'Edit GRN',
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddGRNBottomSheet(
                      sites: widget.sites ?? [],
                      selectedSiteId: widget.selectedSiteId,
                      workspaceId: widget.workspaceId,
                      userId: widget.userId,
                      grnToEdit: grn,
                      onGRNSaved: _loadGRNRecords,
                    ),
                  );
                },
              ),
              _buildOptionItem(
                context,
                icon: Icons.delete_outline,
                title: 'Delete GRN',
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete GRN'),
                      content: const Text(
                        'Are you sure you want to delete this GRN?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Delete GRN coming soon'),
                              ),
                            );
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? const Color(0xFF4a63c0);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 24.sp),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String toTitleCase() {
    return split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
