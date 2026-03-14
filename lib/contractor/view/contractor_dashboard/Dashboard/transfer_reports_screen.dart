import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/contractor/services/api_ser.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';

class TransferReportsScreen extends StatefulWidget {
  final String? selectedSiteId;
  final int? workspaceId;
  final List<Site>? sites;
  
  const TransferReportsScreen({
    super.key, 
    this.selectedSiteId, 
    this.workspaceId,
    this.sites,
  });

  @override
  State<TransferReportsScreen> createState() => _TransferReportsScreenState();
}

class _TransferReportsScreenState extends State<TransferReportsScreen> {
  bool _isLoading = true;
  List<dynamic> _reports = [];
  String _selectedTransferType = 'machinery';

  // UI Colors matching DPRScreen
  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color primaryDark = Color(0xFF2a43a0);
  static const Color backgroundColor = Color(0xFFf8f9fa);

  final Map<String, String> _transferTypes = {
    'machinery': 'Machinery',
    'tool': 'Tools & Equipment',
    'employee': 'Employee',
  };

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  String _getCurrentSiteName() {
    if (widget.selectedSiteId == null || widget.sites == null) {
      return 'All Sites';
    }
    final site = widget.sites!.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () => Site(id: '', name: 'Unknown Site', companyId: ''),
    );
    return site.name;
  }

  Future<void> _fetchReports() async {
    if (widget.selectedSiteId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      setState(() => _isLoading = true);
      final reports = await ApiService().fetchGeneralTransfers(
        siteId: widget.selectedSiteId!,
        workspaceId: (widget.workspaceId ?? 3).toString(),
        transferType: _selectedTransferType,
      );
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error fetching reports: $e');
    }
  }

  Widget _buildFilterDropdown() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTransferType,
          isExpanded: true,
          icon: const Icon(Icons.filter_list, color: primaryColor),
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedTransferType) {
              setState(() {
                _selectedTransferType = newValue;
              });
              _fetchReports();
            }
          },
          items: _transferTypes.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getItemName(Map<String, dynamic> report) {
    if (report['employee'] != null) {
      return report['employee']['name'] ?? 'Employee #${report['employee_id'] ?? ''}';
    }
    if (report['machinery'] != null) {
      return report['machinery']['name'] ?? 'Machinery #${report['machinery_id'] ?? ''}';
    }
    if (report['tool'] != null) {
       return report['tool']['material']?['name'] ?? report['tool']['name'] ?? 'Tool #${report['tools_and_equipment_id'] ?? ''}';
    }
    
    // Fallback for flat structure if objects are missing
    if (report['transfer_type'] == 'employee' && report['employee_id'] != null) {
      return 'Employee #${report['employee_id']}';
    }
    if (report['transfer_type'] == 'machinery' && report['machinery_id'] != null) {
      return 'Machinery #${report['machinery_id']}';
    }
    if (report['transfer_type'] == 'tool' && report['tools_and_equipment_id'] != null) {
      return 'Tool #${report['tools_and_equipment_id']}';
    }

    return 'Unknown Item';
  }

  String _getItemImage(Map<String, dynamic> report) {
    if (report['employee'] != null) return report['employee']['avatar'] ?? '';
    if (report['machinery'] != null) return report['machinery']['image'] ?? '';
    return '';
  }

  IconData _getItemIcon(String type) {
    switch (type.toLowerCase()) {
      case 'machinery': return Icons.agriculture;
      case 'tool': return Icons.build;
      case 'employee': return Icons.person;
      default: return Icons.compare_arrows;
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
            Text(
              'Transfer Reports',
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
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterDropdown(),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64.sp, color: Colors.grey[400]),
                          SizedBox(height: 16.h),
                          Text(
                            'No reports found',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final report = _reports[index];
                        final fromSite = report['from_site'] ?? {};
                        final toSite = report['to_site'] ?? {};
                        final itemName = _getItemName(report);
                        final itemImage = _getItemImage(report);
                        final transferType = report['transfer_type']?.toString().toUpperCase() ?? 'TRANSFER';
                        final dateStr = report['transfer_date'] ?? report['created_at'];
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      transferType,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    dateStr != null 
                                      ? DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr))
                                      : '',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20.r,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: itemImage.isNotEmpty 
                                        ? NetworkImage('https://app.ecoteamsolar.com/$itemImage')
                                        : null,
                                    child: itemImage.isEmpty 
                                        ? Icon(_getItemIcon(report['transfer_type'] ?? ''), color: Colors.grey[500])
                                        : null,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemName,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Row(
                                          children: [
                                            Icon(Icons.arrow_forward, size: 14.sp, color: Colors.grey[500]),
                                            SizedBox(width: 4.w),
                                            Expanded(
                                              child: Text(
                                                '${fromSite['name'] ?? 'Site #${report['from_site_id'] ?? '?'}'} → ${toSite['name'] ?? 'Site #${report['to_site_id'] ?? '?'}'}',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.grey[600],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
