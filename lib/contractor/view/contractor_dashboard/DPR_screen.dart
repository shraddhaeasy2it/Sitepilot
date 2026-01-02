import 'package:ecoteam_app/admin/models/DPR_model.dart';
import 'package:ecoteam_app/admin/services/DPR_services.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/dashboard_page.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/profilepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

// Add PDF dependencies
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:io';

import '../../../contractor/models/site_model.dart';

class DPRScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final String token;
  final int workspaceId;
  final int createdBy;
  final String? currentCompany;

  const DPRScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    required this.token,
    required this.workspaceId,
    required this.createdBy,
    this.currentCompany,
  });

  @override
  State<DPRScreen> createState() => _DPRScreenState();
}

class _DPRScreenState extends State<DPRScreen> {
  late CompanySiteProvider _companyProvider;
  List<DPRModel> _dprList = [];
    
  int? _workspaceId;
  List<DPRModel> _filteredList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // For report date range
  DateTime _reportStartDate = DateTime.now();
  DateTime _reportEndDate = DateTime.now();
  List<DPRModel> _reportRecords = [];
  double _reportTotalMachineHours = 0;
  double _reportTotalDiesel = 0;
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
    _loadDPRs();
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

  Future<void> _loadDPRs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await DPRService.getDPRs(
        token: widget.token,
        siteId: widget.selectedSiteId != null
            ? int.parse(widget.selectedSiteId!)
            : null,
        workspaceId: widget.workspaceId,
        createdBy: widget.createdBy,
      );

      setState(() {
        _dprList = response.data;
        _filteredList = _dprList;
        _isLoading = false;
      });

      print(
        'Loaded ${_dprList.length} DPRs for site ${widget.selectedSiteId ?? "All Sites"}',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load DPRs: $e';
        _isLoading = false;
      });
      print('Error loading DPRs: $e');
    }
  }

  void _filterDPRs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredList = _dprList;
      } else {
        _filteredList = _dprList.where((dpr) {
          return dpr.workDetails.toLowerCase().contains(query.toLowerCase()) ||
              dpr.date.toLowerCase().contains(query.toLowerCase()) ||
              dpr.machineryAdvances.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              dpr.maintenanceNotes.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showAddDPRBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditDPRBottomSheet(
        token: widget.token,
        workspaceId: widget.workspaceId,
        createdBy: widget.createdBy,
        preselectedSiteId: widget.selectedSiteId != null
            ? int.parse(widget.selectedSiteId!)
            : null,
        onDPRSaved: () {
          _loadDPRs();
        },
      ),
    );
  }

  void _showEditDPRBottomSheet(DPRModel dpr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditDPRBottomSheet(
        dpr: dpr,
        token: widget.token,
        workspaceId: widget.workspaceId,
        createdBy: widget.createdBy,
        preselectedSiteId: widget.selectedSiteId != null
            ? int.parse(widget.selectedSiteId!)
            : null,
        onDPRSaved: _loadDPRs,
      ),
    );
  }

  void _showDeleteDPRDialog(DPRModel dpr) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete DPR',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete DPR for ${dpr.formattedDate}?',
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
                  await DPRService.deleteDPR(token: widget.token, id: dpr.id!);
                  setState(() {
                    _dprList.removeWhere((item) => item.id == dpr.id);
                    _filterDPRs(_searchQuery);
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'DPR for ${dpr.formattedDate} deleted successfully',
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
                        content: Text('Failed to delete DPR: $e'),
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
    _reportRecords = _dprList.where((record) {
      try {
        final recordDate = DateTime.parse(record.date);
        return (recordDate.isAtSameMomentAs(_reportStartDate) ||
                recordDate.isAfter(_reportStartDate)) &&
            (recordDate.isAtSameMomentAs(_reportEndDate) ||
                recordDate.isBefore(
                  _reportEndDate.add(const Duration(days: 1)),
                ));
      } catch (e) {
        return false;
      }
    }).toList();

    // Calculate totals for the filtered records
    _reportTotalMachineHours = 0;
    _reportTotalDiesel = 0;
    _reportDateTotals.clear();

    for (var record in _reportRecords) {
      _reportTotalMachineHours += record.machineHours;
      _reportTotalDiesel += record.dieselConsumption;

      // Sum up by date
      final dateKey = record.date;
      _reportDateTotals[dateKey] =
          (_reportDateTotals[dateKey] ?? 0) + record.machineHours;
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
                    'DPR Report',
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _downloadPDF(() => Navigator.pop(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4a63c0),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text(
                      'Download PDF',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black54,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
            'Total Records',
            _reportRecords.length.toString(),
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem(
            'Total Machine Hours',
            _reportTotalMachineHours.toStringAsFixed(2),
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem(
            'Total Diesel (L)',
            _reportTotalDiesel.toStringAsFixed(2),
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
          'No DPR data for selected date range',
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
            'Date-wise Machine Hours',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_reportDateTotals[date]!.toStringAsFixed(2)} hrs',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2a43a0),
                        fontSize: 14,
                      ),
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
            'Individual DPR Records',
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
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.date,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Ops: ${record.numberOfOperators}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${record.machineHours.toStringAsFixed(2)} hrs',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2a43a0),
                            ),
                          ),
                          Text(
                            '${record.dieselConsumption}L',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          if (_reportRecords.length > 5)
            Text(
              '... and ${_reportRecords.length - 5} more records',
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

    // Filter records by date range
    final filteredRecords = _dprList.where((record) {
      try {
        final recordDate = DateTime.parse(record.date);
        return (recordDate.isAtSameMomentAs(_reportStartDate) ||
                recordDate.isAfter(_reportStartDate)) &&
            (recordDate.isAtSameMomentAs(_reportEndDate) ||
                recordDate.isBefore(
                  _reportEndDate.add(const Duration(days: 1)),
                ));
      } catch (e) {
        return false;
      }
    }).toList();

    // Group and calculate totals by date
    final Map<String, Map<String, double>> dailyStats = {};
    double totalMachineHours = 0;
    double totalDiesel = 0;

    for (var record in filteredRecords) {
      totalMachineHours += record.machineHours;
      totalDiesel += record.dieselConsumption;

      if (!dailyStats.containsKey(record.date)) {
        dailyStats[record.date] = {
          'machine_hours': 0.0,
          'diesel': 0.0,
          'operators': 0.0,
          'records': 0.0,
        };
      }

      dailyStats[record.date]!['machine_hours'] =
          dailyStats[record.date]!['machine_hours']! + record.machineHours;
      dailyStats[record.date]!['diesel'] =
          dailyStats[record.date]!['diesel']! + record.dieselConsumption;
      dailyStats[record.date]!['operators'] =
          dailyStats[record.date]!['operators']! + record.numberOfOperators;
      dailyStats[record.date]!['records'] =
          dailyStats[record.date]!['records']! + 1;
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
                    'Daily Progress Report (DPR)',
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
                            'Total DPRs: ${filteredRecords.length}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Total Machine Hours: ${totalMachineHours.toStringAsFixed(2)}',
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
                            'Total Diesel: ${totalDiesel.toStringAsFixed(2)}L',
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
                'Date-wise DPR Summary',
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
                    2: const pw.FlexColumnWidth(1), // DPRs
                    3: const pw.FlexColumnWidth(1), // Operators
                    4: const pw.FlexColumnWidth(1), // Machine Hours
                    5: const pw.FlexColumnWidth(1), // Diesel
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
                            'DPRs',
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
                            'Operators',
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
                            'Machine Hrs',
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
                            'Diesel (L)',
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

                    // Data rows for each date
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
                                stats['records']!.toStringAsFixed(0),
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                stats['operators']!.toStringAsFixed(0),
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                stats['machine_hours']!.toStringAsFixed(2),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColor.fromInt(0xFF2a43a0),
                                ),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                stats['diesel']!.toStringAsFixed(2),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColor.fromInt(0xFF4CAF50),
                                ),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                          ],
                        );
                      } catch (e) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              child: pw.Text(dateStr),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text('-'),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text('0'),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text('0'),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text('0.00'),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text('0.00'),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                          ],
                        );
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
                            filteredRecords
                                .fold(0, (sum, r) => sum + r.numberOfOperators)
                                .toString(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            totalMachineHours.toStringAsFixed(2),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: PdfColor.fromInt(0xFF2a43a0),
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            totalDiesel.toStringAsFixed(2),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: PdfColor.fromInt(0xFF4CAF50),
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
                      'No DPR data found for the selected date range',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                    ),
                  ),
                ),

              pw.SizedBox(height: 30),

              // Detailed Records Section
              if (filteredRecords.isNotEmpty)
                pw.Text(
                  'Detailed DPR Records',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF2a43a0),
                  ),
                ),
              pw.SizedBox(height: 10),

              // Show first 5 detailed records
              ...filteredRecords.take(5).map((record) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5, color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Date: ${record.date}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Operators: ${record.numberOfOperators}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              'Machine: ${record.machineHours.toStringAsFixed(2)} hrs',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColor.fromInt(0xFF2a43a0),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              'Diesel: ${record.dieselConsumption}L',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColor.fromInt(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (record.workDetails.isNotEmpty)
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Work: ${record.workDetails}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }).toList(),

              if (filteredRecords.length > 5)
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    '... and ${filteredRecords.length - 5} more records',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey,
                    ),
                  ),
                ),

              pw.SizedBox(height: 20),

              // Statistics Section
              if (sortedDates.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF8F9FA),
                    border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Statistics',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF2a43a0),
                        ),
                      ),
                      pw.SizedBox(height: 12),

                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Avg. Daily Machine Hours:',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                'Avg. Diesel per Day:',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                'Avg. Operators per Day:',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),

                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                '${(totalMachineHours / sortedDates.length).toStringAsFixed(2)} hrs',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                '${(totalDiesel / sortedDates.length).toStringAsFixed(2)}L',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                '${(filteredRecords.fold(0, (sum, r) => sum + r.numberOfOperators) / sortedDates.length).toStringAsFixed(1)}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              pw.SizedBox(height: 20),

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
                      'Report Details:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Generated on: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Generated by: DPR Management System',
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
          'dpr_report_${siteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
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
          content: Text('Failed to download PDF: $e'),
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
              onChanged: _filterDPRs,
              decoration: InputDecoration(
                hintText: 'Search DPRs...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _filterDPRs('');
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
              child: Icon(Icons.description, size: 64, color: primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              widget.selectedSiteId != null
                  ? 'No DPRs for this site'
                  : 'No DPRs found',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty && _dprList.isEmpty
                  ? (widget.selectedSiteId != null
                        ? 'Start by adding a DPR for ${_getCurrentSiteName()}'
                        : 'Start by adding your first DPR')
                  : 'Try adjusting your search criteria',
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            if (widget.selectedSiteId != null) ...[
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
                  onPressed: _showAddDPRBottomSheet,
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
                      'Add DPR',
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

  Widget _buildDPRCard(DPRModel dpr) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
          onTap: () => _showEditDPRBottomSheet(dpr),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with date and action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: primaryColor,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dpr.formattedDate,
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
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showEditDPRBottomSheet(dpr),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryDark.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: primaryDark,
                              size: 20,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showDeleteDPRDialog(dpr),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // First row: Start Reading and End Reading
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.speed,
                        'Start Reading',
                        '${dpr.machineStartReading}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.speed,
                        'End Reading',
                        '${dpr.machineEndReading}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Second row: Machine Hours and Operators
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.timer,
                        'Machine Hours',
                        '${dpr.machineHours.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.people,
                        'Operators',
                        '${dpr.numberOfOperators}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Third row: Diesel and Machinery Advances
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.local_gas_station,
                        'Diesel (L)',
                        '${dpr.dieselConsumption}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.directions,
                        'Machinery Advances',
                        dpr.machineryAdvances,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),



                ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoItem(IconData icon, String label, String value) {
    return Row(
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
                  fontSize: 9,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
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
    );
  }

  double get _totalMachineHours {
    return _dprList.fold<double>(0, (sum, dpr) => sum + dpr.machineHours);
  }

  double get _totalDieselConsumption {
    return _dprList.fold<double>(0, (sum, dpr) => sum + dpr.dieselConsumption);
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
              'Daily Progress Reports',
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
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        actions: [
          
          // Report Button

          // Notification Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
            child: const FaIcon(
              FontAwesomeIcons.bell,
              size: 18,
              color: Colors.white,
            ),
          ),

          // Chat Button
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
            icon: const FaIcon(
              FontAwesomeIcons.commentDots,
              size: 18,
            ),
            color: Colors.white,
          ),

          // Profile Avatar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/avtar.jpg'),
              radius: 15,
            ),
          ),
          SizedBox(width: 15.h),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDPRBottomSheet,
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: primaryDark,
        tooltip: 'Add New DPR',
      ),

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
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _loadDPRs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        child: Text(
                          'Retry',
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
                        'Record: ${_filteredList.length} DPRs',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 95, 107, 124),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
                  child: _dprList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 100,
                          ),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final dpr = _filteredList[index];
                            return _buildDPRCard(dpr);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

   
}

// Keep your existing AddEditDPRBottomSheet class as is...
// [The rest of your AddEditDPRBottomSheet class remains unchanged]

class AddEditDPRBottomSheet extends StatefulWidget {
  final DPRModel? dpr;
  final String token;
  final int workspaceId;
  final int createdBy;
  final int? preselectedSiteId;
  final VoidCallback? onDPRSaved;

  const AddEditDPRBottomSheet({
    super.key,
    this.dpr,
    required this.token,
    required this.workspaceId,
    required this.createdBy,
    this.preselectedSiteId,
    this.onDPRSaved,
  });

  @override
  State<AddEditDPRBottomSheet> createState() => _AddEditDPRBottomSheetState();
}

class _AddEditDPRBottomSheetState extends State<AddEditDPRBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startReadingController = TextEditingController();
  final TextEditingController _endReadingController = TextEditingController();
  final TextEditingController _operatorsController = TextEditingController();
  final TextEditingController _workDetailsController = TextEditingController();
  final TextEditingController _dieselController = TextEditingController();
  final TextEditingController _maintenanceController = TextEditingController();
  final TextEditingController _machineryController = TextEditingController();

  DateTime? _selectedDate;
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

    if (widget.dpr != null) {
      // Edit mode
      _dateController.text = widget.dpr!.date;
      _startReadingController.text = widget.dpr!.machineStartReading.toString();
      _endReadingController.text = widget.dpr!.machineEndReading.toString();
      _operatorsController.text = widget.dpr!.numberOfOperators.toString();
      _workDetailsController.text = widget.dpr!.workDetails;
      _dieselController.text = widget.dpr!.dieselConsumption.toString();
      _maintenanceController.text = widget.dpr!.maintenanceNotes;
      _machineryController.text = widget.dpr!.machineryAdvances;
      _selectedDate = DateTime.parse(widget.dpr!.date);
    } else {
      // Add mode - set default date to today
      _selectedDate = DateTime.now();
      _dateController.text = _formatDateForDisplay(_selectedDate!);
      _operatorsController.text = '1';
      _dieselController.text = '0.0';
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
        _dateController.text = _formatDateForDisplay(picked);
      });
    }
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? '*' : ''),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              prefixIcon: Icon(icon, color: textSecondary, size: 20),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              hintStyle: TextStyle(
                color: textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (double.parse(_startReadingController.text) >
        double.parse(_endReadingController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End reading must be greater than start reading'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> dprData = {
        'date': _dateController.text,
        'machine_start_reading': double.parse(_startReadingController.text),
        'machine_end_reading': double.parse(_endReadingController.text),
        'number_of_operators': int.parse(_operatorsController.text),
        'work_details': _workDetailsController.text,
        'diesel_consumption': double.parse(_dieselController.text),
        'maintenance_notes': _maintenanceController.text,
        'machinery_advances': _machineryController.text,
        'status': 0,
        'site_id': widget.preselectedSiteId ?? 3, // Use preselected or default
        'workspace_id': widget.workspaceId,
        'created_by': widget.createdBy,
      };

      if (widget.dpr != null) {
        await DPRService.updateDPR(
          token: widget.token,
          id: widget.dpr!.id!,
          data: dprData,
        );
      } else {
        await DPRService.createDPR(token: widget.token, data: dprData);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onDPRSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.dpr != null
                  ? 'DPR updated successfully'
                  : 'DPR created successfully',
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
            content: Text('Failed to save DPR: $e'),
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
    final bool isEdit = widget.dpr != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                              isEdit ? Icons.edit : Icons.add_circle,
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
                                  isEdit
                                      ? 'Edit DPR'
                                      : 'Create Daily Progress Report',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  isEdit
                                      ? 'Update DPR details'
                                      : 'Enter DPR details below',
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

                      // Date
                      _buildEnhancedTextField(
                        controller: _dateController,
                        label: 'Date',
                        hint: 'Select Date',
                        icon: Icons.calendar_today,
                        isRequired: true,
                        readOnly: true,
                        onTap: _isSubmitting
                            ? null
                            : () => _selectDate(context),
                      ),
                      const SizedBox(height: 16),

                      // Machine Start Reading
                      _buildEnhancedTextField(
                        controller: _startReadingController,
                        label: 'Machine Start Reading',
                        hint: 'Enter start reading',
                        icon: Icons.speed,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Machine End Reading
                      _buildEnhancedTextField(
                        controller: _endReadingController,
                        label: 'Machine End Reading',
                        hint: 'Enter end reading',
                        icon: Icons.speed,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Number of Operators
                      _buildEnhancedTextField(
                        controller: _operatorsController,
                        label: 'Number of Operators',
                        hint: 'Enter number of operators',
                        icon: Icons.people,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Machinery Advances
                      _buildEnhancedTextField(
                        controller: _machineryController,
                        label: 'Machinery Advances',
                        hint: 'Enter machinery advances',
                        icon: Icons.directions,
                      ),
                      const SizedBox(height: 16),

                      // Work Details
                      _buildEnhancedTextField(
                        controller: _workDetailsController,
                        label: 'Work Details',
                        hint: 'Enter work details',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Diesel Consumption
                      _buildEnhancedTextField(
                        controller: _dieselController,
                        label: 'Diesel Consumption (L)',
                        hint: 'Enter diesel consumption',
                        icon: Icons.local_gas_station,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Maintenance Notes
                      _buildEnhancedTextField(
                        controller: _maintenanceController,
                        label: 'Maintenance Notes',
                        hint: 'Enter maintenance notes',
                        icon: Icons.build,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Machine Hours Preview
                      if (_startReadingController.text.isNotEmpty &&
                          _endReadingController.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
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
                                'Machine Hours:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${(double.tryParse(_endReadingController.text) ?? 0) - (double.tryParse(_startReadingController.text) ?? 0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
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
                                      : Text(
                                          isEdit ? 'Update DPR' : 'Create DPR',
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
}
