import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class SummaryScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final int workspaceId;
  final List<Site> sites;
  final String token;
  final int createdBy;
  final String? currentCompany;

  const SummaryScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.workspaceId,
    required this.sites,
    required this.token,
    required this.createdBy,
    this.currentCompany,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color primaryDark = Color(0xFF2a43a0);
  static const Color backgroundColor = Color(0xFFf8f9fa);
  Timer? _permissionTimer;

  // State Variables
  String _selectedReportType = 'Detailed';
  String _selectedDuration = 'Today';
  DateTime? _fromDate;
  DateTime? _toDate;

  // Checkbox States
  bool _taskUpdates = false;
  bool _issues = false;
  bool _inventory = false;
  bool _myTeam = false;
  bool _labourVendorResults = false;

  // Nested Checkbox States
  // Material Sub-items
  bool _material = false;
  bool _materialIndent = false;
  bool _materialGrn = false;
  bool _materialIssue = false;
  bool _materialTransferOrder = false;
  bool _materialPurchaseOrder = false;

  // Payables Sub-items
  bool _payables = false;
  bool _payablesPurchaseOrder = false;
  bool _payablesGrn = false;
  bool _payablesAttendance = false;
  bool _payablesManpower = false;

  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _permissionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        Provider.of<CompanySiteProvider>(
          context,
          listen: false,
        ).refreshPermissions();
      }
    });
  }

  @override
  void dispose() {
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

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Reporto Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              "Site: ${_getCurrentSiteName()}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 80.h,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate a New Report',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Report Type Selection
                  Row(
                    children: [
                      Expanded(
                        child: _buildReportTypeCard(
                          'Detailed Report',
                          true,
                          _selectedReportType == 'Detailed',
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildReportTypeCard(
                          'Summary Report',
                          false,
                          _selectedReportType == 'Summary',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Duration Selection
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildDurationChip('Today'),
                        SizedBox(width: 10.w),
                        _buildDurationChip('7 days'),
                        SizedBox(width: 10.w),
                        _buildDurationChip('15 days'),
                        SizedBox(width: 10.w),
                        _buildDurationChip('Specific'),
                      ],
                    ),
                  ),

                  // Date Pickers for Specific Duration
                  if (_selectedDuration == 'Specific') ...[
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(child: _buildDatePickerField('From', true)),
                        SizedBox(width: 16.w),
                        Expanded(child: _buildDatePickerField('To', false)),
                      ],
                    ),
                  ],

                  SizedBox(height: 24.h),

                  // Parts in the Report Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(
                        'Parts in the Report',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      childrenPadding: EdgeInsets.only(bottom: 16.h),
                      children: [
                        _buildCheckboxItem('Task Updates', _taskUpdates, (val) {
                          setState(() => _taskUpdates = val ?? false);
                        }),
                        _buildCheckboxItem('Issues', _issues, (val) {
                          setState(() => _issues = val ?? false);
                        }),
                        _buildCheckboxItem('Inventory', _inventory, (val) {
                          setState(() => _inventory = val ?? false);
                        }),
                        
                        // Material Expandable
                        _buildNestedCheckboxGroup(
                          'Material',
                          _material,
                          (val) {
                             setState(() {
                               _material = val ?? false;
                               _materialIndent = _material;
                               _materialGrn = _material;
                               _materialIssue = _material;
                               _materialTransferOrder = _material;
                               _materialPurchaseOrder = _material;
                             });
                          },
                          [
                            _buildCheckboxItem('Indent', _materialIndent, (v) => setState(() => _materialIndent = v ?? false), isNested: true),
                            _buildCheckboxItem('GRN', _materialGrn, (v) => setState(() => _materialGrn = v ?? false), isNested: true),
                            _buildCheckboxItem('Material Issue', _materialIssue, (v) => setState(() => _materialIssue = v ?? false), isNested: true),
                            _buildCheckboxItem('Transfer Order', _materialTransferOrder, (v) => setState(() => _materialTransferOrder = v ?? false), isNested: true),
                            _buildCheckboxItem('Purchase Order', _materialPurchaseOrder, (v) => setState(() => _materialPurchaseOrder = v ?? false), isNested: true),
                          ]
                        ),
                        
                        _buildCheckboxItem('My Team', _myTeam, (val) {
                          setState(() => _myTeam = val ?? false);
                        }),
                        _buildCheckboxItem('Labour & Vendor Labours', _labourVendorResults, (val) {
                          setState(() => _labourVendorResults = val ?? false);
                        }),
                        
                         // Payables Expandable
                        _buildNestedCheckboxGroup(
                          'Payables',
                          _payables,
                          (val) {
                             setState(() {
                               _payables = val ?? false;
                               _payablesPurchaseOrder = _payables;
                               _payablesGrn = _payables;
                               _payablesAttendance = _payables;
                               _payablesManpower = _payables;
                             });
                          },
                          [
                             _buildCheckboxItem('Purchase Order', _payablesPurchaseOrder, (v) => setState(() => _payablesPurchaseOrder = v ?? false), isNested: true),
                             _buildCheckboxItem('GRN', _payablesGrn, (v) => setState(() => _payablesGrn = v ?? false), isNested: true),
                             _buildCheckboxItem('Attendance', _payablesAttendance, (v) => setState(() => _payablesAttendance = v ?? false), isNested: true),
                             _buildCheckboxItem('Manpower', _payablesManpower, (v) => setState(() => _payablesManpower = v ?? false), isNested: true),
                          ]
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 80.h), // Space for bottom button
                ],
              ),
            ),
          ),
          
          // Create Report Button
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ]
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  // Handle Create Report Logic
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report generation started...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Create Report',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(String title, bool isNew, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedReportType = isNew ? 'Detailed' : 'Summary';
        });
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected
              ? Border.all(color: primaryColor, width: 2)
              : Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
           
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(String label) {
    final isSelected = _selectedDuration == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDuration = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: isSelected ? null : Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, bool isFrom) {
    final date = isFrom ? _fromDate : _toDate;
    final text = date != null ? DateFormat('dd MMM yyyy').format(date) : label;
    
    return GestureDetector(
      onTap: () => _selectDate(context, isFrom),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: date != null ? Colors.black87 : Colors.grey,
                fontSize: 14.sp,
              ),
            ),
            Icon(Icons.calendar_today, size: 16.sp, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxItem(String title, bool value, Function(bool?) onChanged, {bool isNested = false}) {
    return Padding(
      padding: EdgeInsets.only(left: isNested ? 32.w : 0),
      child: InkWell(
         onTap: () => onChanged(!value),
         child: Row(
          children: [
             Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
             Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isNested ? FontWeight.w400 : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
         ),
      ),
    );
  }
  
   Widget _buildNestedCheckboxGroup(String title, bool parentValue, Function(bool?) onParentChanged, List<Widget> children) {
    return Column(
      children: [
        _buildCheckboxItem(title, parentValue, onParentChanged),
        if (parentValue) ...children,
      ],
    );
  }

}