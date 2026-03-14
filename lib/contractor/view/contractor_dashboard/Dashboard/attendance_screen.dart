import 'dart:io';
import 'dart:convert';
import 'package:ecoteam_app/contractor/models/attendance_model.dart';
import 'package:ecoteam_app/contractor/services/attendance_service.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/site_model.dart';
import 'package:ecoteam_app/admin/services/employee_services.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:open_file/open_file.dart'; // Keep if used, otherwise remove
import 'package:path_provider/path_provider.dart';
import 'package:ecoteam_app/admin/models/employee_model.dart' as AdminEmployee;
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/employee_screen.dart'
    show EmployeeBottomSheet;
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Employee Model
class Employee {
  String id;
  String name;
  String position;
  String employeeId;
  String siteId;
  File? image;
  String status;
  String? timeIn;
  String? timeOut;
  double hours;
  double overtime;
  double latitude;
  double longitude;
  DateTime date;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.employeeId,
    required this.siteId,
    this.image,
    this.status = 'Absent',
    this.timeIn,
    this.timeOut,
    this.hours = 0.0,
    this.overtime = 0.0,
    required this.latitude,
    required this.longitude,
    required this.date,
  });
}

// Provider
class EmployeeProvider extends ChangeNotifier {
  List<Employee> _employees = [];
  List<Site> _sites = [];
  String _selectedSiteId = '';

  List<Employee> get employees => _employees;
  List<Site> get sites => _sites;
  String get selectedSiteId => _selectedSiteId;
  // Location logic removed as requested.

  EmployeeProvider() {
    _initializeData();
  }

  void _initializeData() {
    // Initialize sites (Mock data kept for safety, but usually set via setSites)
    _sites = [];
    _selectedSiteId = '';
    _employees = [];
  }

  void setSelectedSite(String siteId) {
    _selectedSiteId = siteId;
    notifyListeners();
  }

  // Set sites from parent
  void setSites(List<Site> sites) {
    _sites = sites;
    if (_selectedSiteId.isEmpty && _sites.isNotEmpty) {
      // _selectedSiteId = _sites.first.id;
    }
    notifyListeners();
  }

  // Get site name by ID
  String getSiteName(String siteId) {
    if (siteId.isEmpty) return 'Unknown Site';
    try {
      final site = _sites.firstWhere(
        (s) => s.id == siteId,
        orElse: () => Site(id: '', name: 'Unknown Site', companyId: ''),
      );
      return site.name;
    } catch (e) {
      return 'Unknown Site';
    }
  }

  Future<void> refreshLocation() async {
    // No-op
  }
}

class AttendanceScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const AttendanceScreen({
    Key? key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  }) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize provider and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      provider.setSites(widget.sites);
      if (widget.selectedSiteId != null) {
        provider.setSelectedSite(widget.selectedSiteId!);
      }
      _fetchEmployeeNames();
      _loadAttendance();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final provider = Provider.of<EmployeeProvider>(context, listen: false);

    if (widget.sites != oldWidget.sites) {
      provider.setSites(widget.sites);
    }

    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      if (widget.selectedSiteId != null) {
        provider.setSelectedSite(widget.selectedSiteId!);
      } else {
        provider.setSelectedSite('');
      }
      // Reload attendance when site changes
      _fetchEmployeeNames();
      _loadAttendance();
    }
  }

  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'monthly';
  List<AttendanceData> _attendanceList = [];
  List<Map<String, dynamic>> _flattenedAttendanceList = [];
  Map<int, String> _employeeNames = {};
  int? _selectedEmployeeId;
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _parseId(dynamic id) {
    if (id == null) return 0;
    if (id is int) return id;
    if (id is String && id.isNotEmpty) {
      final numericId = id.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(numericId) ?? 0;
    }
    return 0;
  }

  Future<void> _fetchEmployeeNames() async {
    final companyProvider = Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    );
    final workspaceId = companyProvider.selectedCompanyId;
    final siteId = widget.selectedSiteId;
    final userId = companyProvider.currentUserId;

    if (workspaceId == null || userId == null) return;

    // Get created_by from workspace
    int createdBy = userId; // Fallback
    try {
      final workspace = companyProvider.companies.firstWhere(
        (c) => c['id'].toString() == workspaceId,
      );
      createdBy = int.tryParse(workspace['created_by'].toString()) ?? userId;
    } catch (_) {}

    try {
      final employees = await AttendanceService.instance.fetchDropdownEmployees(
        workspaceId: _parseId(workspaceId),
        siteId: _parseId(siteId),
        createdBy: createdBy,
        userId: userId,
      );

      setState(() {
        _employeeNames = {for (var e in employees) e.id: e.name};
      });
    } catch (e) {
      debugPrint('Error fetching employee names: $e');
    }
  }

  Future<void> _loadAttendance({bool silent = false}) async {
    final companyProvider = Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    );
    final userId = companyProvider.currentUserId;
    final workspaceId = companyProvider.selectedCompanyId;
    final siteId = widget.selectedSiteId;

    if (userId == null || workspaceId == null) return;

    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await AttendanceService.instance.fetchAttendanceHistory(
        userId: _selectedEmployeeId ?? 0,
        workspaceId: _parseId(workspaceId),
        siteId: _parseId(siteId),
        month: _selectedDate.month.toString(),
        year: _selectedDate.year.toString(),
        type: _selectedType,
      );

      var historyList = response.data ?? [];

      if (_selectedType == 'daily') {
        final selectedDateString = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDate);
        historyList = historyList
            .where((item) => item.date == selectedDateString)
            .toList();
      }

      setState(() {
        _attendanceList = historyList;
        _flattenedAttendanceList = [];
        for (var data in _attendanceList) {
          for (var historyItem in data.history) {
            // Filter by employee if one is selected
            if (_selectedEmployeeId != null &&
                historyItem.employeeId != _selectedEmployeeId) {
              continue;
            }
            _flattenedAttendanceList.add({
              'date': data.date,
              'item': historyItem,
            });
          }
        }
        // Sort by date descending
        _flattenedAttendanceList.sort((a, b) => b['date'].compareTo(a['date']));
      });
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAttendanceReport() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    final companyProvider = Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    );
    final employeeProvider = Provider.of<EmployeeProvider>(
      context,
      listen: false,
    );
    final siteName =
        widget.selectedSiteId == null || widget.selectedSiteId!.isEmpty
        ? 'All Sites'
        : employeeProvider.getSiteName(widget.selectedSiteId!);

    String reportDate;
    if (_selectedType == 'daily') {
      reportDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    } else {
      reportDate = DateFormat('MMMM yyyy').format(_selectedDate);
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Site: $siteName',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Period: $reportDate',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>[
                  'Date',
                  'Employee',
                  'Clock In',
                  'Clock Out',
                  'Total',
                  'Status',
                ],
                ..._flattenedAttendanceList.map((entry) {
                  final item = entry['item'] as HistoryItem;
                  final date = entry['date'] as String;
                  String employeeName = item.employeeName;
                  if (employeeName.isEmpty ||
                      employeeName == 'null' ||
                      employeeName == 'null (null)') {
                    employeeName =
                        _employeeNames[item.employeeId] ??
                        'Employee #${item.employeeId}';
                  } else if (employeeName.contains('null')) {
                    // Try to fix corrupted names if possible, or fallback to lookup
                    employeeName =
                        _employeeNames[item.employeeId] ?? employeeName;
                  }

                  return [
                    date,
                    '$employeeName',
                    item.clockIn,
                    item.clockOut,
                    item.total,
                    item.status,
                  ];
                }),
              ],
            ),
            if (_flattenedAttendanceList.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Center(
                  child: pw.Text("No records found for this period."),
                ),
              ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      "${output.path}/attendance_report_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<void> _selectDate(BuildContext context) async {
    final bool isDaily = _selectedType == 'daily';
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: isDaily ? DatePickerMode.day : DatePickerMode.year,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance History',
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.w400,
                fontSize: 17.sp,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    widget.selectedSiteId == null ||
                            widget.selectedSiteId!.isEmpty
                        ? 'All Sites'
                        : employeeProvider.getSiteName(widget.selectedSiteId!),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
        ),
        actions: [
          ...buildNotificationActions(
            context: context,
            selectedSiteId: widget.selectedSiteId,
            sites: widget.sites,
            currentCompany:
                Provider.of<CompanySiteProvider>(
                  context,
                  listen: false,
                ).selectedCompanyName ??
                '',
            workspaceId: int.tryParse(
              Provider.of<CompanySiteProvider>(
                    context,
                    listen: false,
                  ).selectedCompanyId ??
                  '0',
            ),
          ),
          // IconButton(
          //   icon: Icon(Icons.refresh, color: Colors.white, size: 24.sp),
          //   onPressed: () => _loadAttendance(),
          //   tooltip: 'Refresh History',
          // ),
        ],
        toolbarHeight: 80.h,
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
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4a63c0).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAttendanceBottomSheet(),
        backgroundColor: const Color(0xFF4a63c0),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Column(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Row(
              children: [
                // Date Picker Field
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: _selectedType == 'daily'
                            ? 'Select Date'
                            : 'Select Month',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: Color(0xFF4a63c0),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ), // Reduced padding
                      ),
                      child: Text(
                        _selectedType == 'daily'
                            ? DateFormat('dd MMM yyyy').format(_selectedDate)
                            : DateFormat('MMMM yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Type Dropdown
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 5.h,
                    ), // Adjusted padding
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        icon: Icon(Icons.filter_list, color: Color(0xFF4a63c0)),
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedType = newValue;
                            });
                          }
                        },
                        items: <String>['monthly', 'daily']
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value[0].toUpperCase() + value.substring(1),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Employee...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4a63c0)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          Row(
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
                  onPressed: _generateAttendanceReport,
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    size: 24,
                    color: Color.fromARGB(255, 29, 29, 29),
                  ),
                ),
              ),
            ],
      
          ),
         
         
          Expanded(child: _buildHistoryTab()),
        ],
      ),
    );
  }

  Widget _buildSimpleTimeItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleTimeDivider() {
    return Container(
      height: 12.h,
      width: 1.w,
      color: Colors.grey[300],
      margin: EdgeInsets.symmetric(horizontal: 12.w),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4a63c0)),
      );
    }

    if (_flattenedAttendanceList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60.sp, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              _selectedType == 'daily'
                  ? 'No history found for this date'
                  : 'No history found for this month',
              style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(10.h),
      itemCount: _flattenedAttendanceList.length,
      itemBuilder: (context, index) {
        final entry = _flattenedAttendanceList[index];
        final item = entry['item'] as HistoryItem;
        final date = entry['date'] as String;

        String employeeName = item.employeeName;
        // Logic to fix name display
        if (employeeName.isEmpty ||
            employeeName == 'null' ||
            employeeName == 'null (null)') {
          employeeName =
              _employeeNames[item.employeeId] ?? 'Employee #${item.employeeId}';
        } else if (employeeName.contains('null')) {
          employeeName = _employeeNames[item.employeeId] ?? employeeName;
        }

        if (_searchQuery.isNotEmpty &&
            !employeeName.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: EdgeInsets.only(bottom: 10.h),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$employeeName',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            DateFormat(
                              'EEEE, MMM d, yyyy',
                            ).format(DateTime.parse(date)),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: const Color(0xFF4a63c0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: item.status == 'Present'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: item.status == 'Present'
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: () =>
                          _showAddAttendanceBottomSheet(item: item, date: date),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16.sp,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 9.h),
                Row(
                  children: [
                    _buildSimpleTimeItem(
                      Icons.login,
                      item.clockIn,
                      Colors.green,
                    ),
                    _buildSimpleTimeDivider(),
                    _buildSimpleTimeItem(
                      Icons.logout,
                      item.clockOut,
                      Colors.red,
                    ),
                    _buildSimpleTimeDivider(),
                    _buildSimpleTimeItem(
                      Icons.access_time,
                      item.total,
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddAttendanceBottomSheet({HistoryItem? item, String? date}) {
    final companyProvider = Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    );

    // Parse Workspace ID safely
    final workspaceId = _parseId(companyProvider.selectedCompanyId);

    // Parse Site ID safely
    final siteId = widget.selectedSiteId != null
        ? _parseId(widget.selectedSiteId!)
        : 0;

    // Only blocking logic if site selection is mandatory and we want to enforce it for new items.
    // However, if siteId is 0 (All Sites), we might want to allow it depending on business logic,
    // but usually creating attendance requires a specific site.
    if (siteId == 0 && item == null) {
      // If "All Sites" is selected (id 0), we prompt user to select a site, but since we don't have a picker in bottom sheet yet,
      // we show the validation message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a specific site to add attendance'),
        ),
      );
      return;
    }

    // Get Names
    final workspaceName =
        companyProvider.selectedCompanyName ?? 'Unknown Workspace';
    final employeeProvider = Provider.of<EmployeeProvider>(
      context,
      listen: false,
    );
    final siteName = widget.selectedSiteId != null
        ? employeeProvider.getSiteName(widget.selectedSiteId!)
        : 'All Sites';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAttendanceBottomSheet(
        workspaceId: workspaceId,
        siteId: siteId,
        workspaceName: workspaceName,
        siteName: siteName,
        editItem: item,
        date: date,
        onSuccess: (DateTime submittedDate) {
          // Update selected date to show the new entry
          setState(() {
            _selectedDate = submittedDate;
          });
          _loadAttendance(silent: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                item == null
                    ? 'Attendance added successfully'
                    : 'Attendance updated successfully',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddAttendanceBottomSheet extends StatefulWidget {
  final int workspaceId;
  final int? siteId;
  final String workspaceName;
  final String siteName;
  final Function(DateTime) onSuccess;
  final HistoryItem? editItem;
  final String? date;

  const _AddAttendanceBottomSheet({
    required this.workspaceId,
    this.siteId,
    required this.workspaceName,
    required this.siteName,
    required this.onSuccess,
    this.editItem,
    this.date,
  });

  @override
  State<_AddAttendanceBottomSheet> createState() =>
      _AddAttendanceBottomSheetState();
}

class _AddAttendanceBottomSheetState extends State<_AddAttendanceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _clockInController;
  late TextEditingController _clockOutController;

  DropdownEmployee? _selectedEmployee;
  List<DropdownEmployee> _employees = [];
  bool _isLoadingEmployees = true;
  bool _isSubmitting = false;

  @override
  @override
  void initState() {
    super.initState();
    if (widget.editItem != null && widget.date != null) {
      _dateController = TextEditingController(text: widget.date!);

      // Helper to strip seconds if present (HH:mm:ss -> HH:mm)
      String cleanTime(String time) {
        if (time.isEmpty) return '';
        final parts = time.split(':');
        // Ensure 2 digits for hours/minutes if needed, but splitting is usually enough if data is standard
        if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
        return time;
      }

      _clockInController = TextEditingController(
        text: cleanTime(widget.editItem!.clockIn),
      );
      _clockOutController = TextEditingController(
        text: cleanTime(widget.editItem!.clockOut),
      );
    } else {
      _dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );
      _clockInController = TextEditingController(text: '09:00');
      _clockOutController = TextEditingController(text: '17:00');
    }
    _loadEmployees();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _clockInController.dispose();
    _clockOutController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      int userId = 0;
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (userData['user'] != null && userData['user']['id'] != null) {
          userId = userData['user']['id'];
        } else if (userData['id'] != null) {
          userId = userData['id'];
        }
      }

      // Get created_by from workspace list via provider
      // (We don't have direct access to provider inside initState async comfortably without context,
      // but we are in State so we can use context safely in post-frame or just read from provider in _loadEmployees if mounted)

      int createdBy = userId; // Default fallback
      if (mounted) {
        final companyProvider = Provider.of<CompanySiteProvider>(
          context,
          listen: false,
        );
        final workspace = companyProvider.companies.firstWhere(
          (c) => c['id'].toString() == widget.workspaceId.toString(),
          orElse: () => {'created_by': userId},
        );
        createdBy = int.tryParse(workspace['created_by'].toString()) ?? userId;
      }

      final employees = await AttendanceService.instance.fetchDropdownEmployees(
        workspaceId: widget.workspaceId,
        siteId: widget.siteId ?? 0,
        createdBy: createdBy,
        userId: userId,
      );

      if (mounted) {
        setState(() {
          _employees = employees;
          _isLoadingEmployees = false;
          // Pre-select employee if editing
          if (widget.editItem != null) {
            try {
              _selectedEmployee = _employees.firstWhere(
                (e) => e.id == widget.editItem!.employeeId,
              );
            } catch (e) {
              // Employee might be inactive or not in the list anymore
              debugPrint(
                'Employee not found in list: ${widget.editItem!.employeeId}',
              );
              // Optionally create a placeholder if needed, or leave null
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEmployees = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // We only have id (employeeId) and name.
      // We assume id from dropdown is employeeId.
      // We need userId for insertAttendance. We will use the same ID if userId is unavailable,
      // but typically API should return userId if it's different.
      // For now, we use the ID we have.
      final startEmployeeId = _selectedEmployee!.id;

      // user_id is the logged in user
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      int userId = 0;
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (userData['user'] != null && userData['user']['id'] != null) {
          userId = userData['user']['id'];
        } else if (userData['id'] != null) {
          userId = userData['id'];
        }
      }

      // created_by is the workspace creator
      int createdBy = userId;
      if (mounted) {
        final companyProvider = Provider.of<CompanySiteProvider>(
          context,
          listen: false,
        );
        final workspace = companyProvider.companies.firstWhere(
          (c) => c['id'].toString() == widget.workspaceId.toString(),
          orElse: () => {'created_by': userId},
        );
        createdBy = int.tryParse(workspace['created_by'].toString()) ?? userId;
      }

      bool success;
      if (widget.editItem != null) {
        success = await AttendanceService.instance.updateAttendance(
          id: widget.editItem!.id,
          clockIn: _clockInController.text,
          clockOut: _clockOutController.text,
          date: _dateController.text,
          siteId: widget.siteId ?? 0,
          workspaceId: widget.workspaceId,
          employeeId: startEmployeeId,
          userId: userId,
          createdBy: createdBy,
        );
      } else {
        success = await AttendanceService.instance.insertAttendance(
          clockIn: _clockInController.text,
          clockOut: _clockOutController.text,
          date: _dateController.text,
          siteId: widget.siteId ?? 0,
          workspaceId: widget.workspaceId,
          employeeId: startEmployeeId,
          userId: userId,
          createdBy: createdBy,
        );
      }

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess(DateTime.parse(_dateController.text));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit attendance (Unknown error)'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      controller.text = DateFormat('HH:mm').format(dt);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20.h),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            children: [
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
              SizedBox(height: 20.h),
              Text(
                widget.editItem != null ? 'Edit Attendance' : 'Add Attendance',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16.sp,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Workspace: ${widget.workspaceName}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16.sp,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Site: ${widget.siteName}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              DropdownButtonFormField<DropdownEmployee>(
                decoration: InputDecoration(
                  labelText: 'Select Employee',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                value: _selectedEmployee, // Ensure this is bound
                items: _employees
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          '${e.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedEmployee = val),
                validator: (val) => val == null ? 'Required' : null,
                icon: _isLoadingEmployees
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.arrow_drop_down),
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clockInController,
                      readOnly: true,
                      onTap: () => _selectTime(_clockInController),
                      decoration: InputDecoration(
                        labelText: 'Clock In',
                        suffixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: TextFormField(
                      controller: _clockOutController,
                      readOnly: true,
                      onTap: () => _selectTime(_clockOutController),
                      decoration: InputDecoration(
                        labelText: 'Clock Out',
                        suffixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4a63c0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.editItem != null
                              ? 'Update Attendance'
                              : 'Submit Attendance',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
