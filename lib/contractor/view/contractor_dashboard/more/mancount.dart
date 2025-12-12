import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:io';

// Import your existing pages and models
import 'package:ecoteam_app/admin/models/manpower_model.dart' hide ManpowerType;
import 'package:ecoteam_app/admin/services/manpower_services.dart';
import 'package:ecoteam_app/admin/services/manpowerType_services.dart';
import 'package:ecoteam_app/admin/models/mapowerType_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';

class ManpowerCountScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  ManpowerCountScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<ManpowerCountScreen> createState() => _ManpowerCountScreenState();
}

class _ManpowerCountScreenState extends State<ManpowerCountScreen> {
  // Services
  final ManpowerService _manpowerService = ManpowerService();
  final ManpowerTypeService _manpowerTypeService = ManpowerTypeService();
  // Calculate overall total manpower from all records
  int _calculateOverallTotal() {
    return _records.fold(0, (sum, record) {
      return sum + (record.totalCount ?? 0);
    });
  }
// For report date range
DateTime _reportStartDate = DateTime.now();
DateTime _reportEndDate = DateTime.now();
List<ManpowerRecord> _reportRecords = [];
int _reportTotalManpower = 0;
Map<String, int> _reportCategoryTotals = {};
  // State
  List<ManpowerRecord> _records = [];
  List<ManpowerType> _manpowerTypes = [];
  DropdownData? _dropdownData;

  // UI State
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  List<ManpowerRecord> _filteredRecords = [];

  // Daily count tracking for quick add
  final Map<String, int> _dailyManpowerCount = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_filterRecords);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load manpower types
      final types = await _manpowerTypeService.getManpowerTypes();
      _manpowerTypes = types;

      // Load dropdown data for forms
      _dropdownData = await _manpowerService.getDropdownData();

      // Load records
      await _loadManpowerRecords();

      // Initialize daily count from records
      _initializeDailyCount();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadInitialData: $e');
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
      _showErrorSnackbar('Failed to load data: $e');
    }
  }

  Future<void> _loadManpowerRecords() async {
    try {
      final records = await _manpowerService.getManpowerRecords();
      setState(() {
        _records = records;
        _filteredRecords = List.from(records);
      });
    } catch (e) {
      print('Error loading manpower records: $e');
      // Try with specific site if available
      if (widget.selectedSiteId != null) {
        try {
          final siteId = int.tryParse(widget.selectedSiteId!);
          if (siteId != null) {
            // You might need to adjust this based on your actual API
            final records = await _manpowerService
                .getManpowerRecordsBySiteAndWorkspace(siteId, 1);
            setState(() {
              _records = records;
              _filteredRecords = List.from(records);
            });
          }
        } catch (e2) {
          print('Error loading fallback records: $e2');
          setState(() {
            _records = [];
            _filteredRecords = [];
          });
        }
      }
    }
  }

  void _initializeDailyCount() {
    // Clear previous counts
    _dailyManpowerCount.clear();

    // Initialize with all manpower types
    for (var type in _manpowerTypes) {
      _dailyManpowerCount[type.name] = 0;
    }

    // Calculate counts for selected date
    final todayKey = _formatDateKey(_selectedDate);
    final todayRecords = _records.where((record) {
      return record.workDate == todayKey;
    }).toList();

    // Sum up counts for each manpower type
    for (var record in todayRecords) {
      for (var entry in record.manpowerCounts.entries) {
        final type = entry.key;
        final count = entry.value;
        _dailyManpowerCount[type] = (_dailyManpowerCount[type] ?? 0) + count;
      }
    }
  }

  String _formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = List.from(_records);
      } else {
        _filteredRecords = _records.where((record) {
          return record.workDate.toLowerCase().contains(query) ||
              record.supplier.toLowerCase().contains(query) ||
              record.site.toLowerCase().contains(query) ||
              (record.totalCount != null &&
                  record.totalCount.toString().contains(query));
        }).toList();
      }
    });
  }

  Future<void> _refreshData() async {
    await _loadInitialData();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data refreshed')));
  }

  // Add this method for adding new record via AppBar button
  Future<void> _addNewRecord() async {
    if (_dropdownData == null) {
      _showErrorSnackbar('Please wait, loading dropdown data...');
      return;
    }

    final result = await showModalBottomSheet<ManpowerRecord?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ManpowerBottomSheet(
          dropdownData: _dropdownData!,
          onSave: (newRecord) => newRecord,
          selectedDate: _selectedDate,
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        setState(() {
          _isLoading = true;
        });

        final createdRecord = await _manpowerService.createManpowerRecord(
          result,
        );
        setState(() {
          _records.add(createdRecord);
          _filterRecords();
          _isLoading = false;
        });
        _showSuccessSnackbar('Record created successfully');

        // Update daily count
        _initializeDailyCount();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Failed to create record: $e');
      }
    }
  }

  Widget _buildCountRow(String type) {
    final currentCount = _dailyManpowerCount[type] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(type, style: const TextStyle(fontSize: 16))),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (currentCount > 0) {
                    setState(() {
                      _dailyManpowerCount[type] = currentCount - 1;
                    });
                  }
                },
              ),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  '$currentCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _dailyManpowerCount[type] = currentCount + 1;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuickAddRecord(Map<String, int> counts) async {
    if (_dropdownData == null ||
        _dropdownData!.sites.isEmpty ||
        _dropdownData!.suppliers.isEmpty) {
      _showErrorSnackbar('Please configure sites and suppliers first');
      return;
    }

    // Create a manpower record
    final record = ManpowerRecord(
      workDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      supplier: _dropdownData!.suppliers.values.first,
      site: widget.selectedSiteId != null
          ? widget.sites
                .firstWhere(
                  (s) => s.id == widget.selectedSiteId,
                  orElse: () => widget.sites.first,
                )
                .name
          : _dropdownData!.sites.values.first,
      manpowerCounts: counts,
      siteId: widget.selectedSiteId != null
          ? int.tryParse(widget.selectedSiteId!) ??
                _dropdownData!.sites.keys.first
          : _dropdownData!.sites.keys.first,
      supplierId: _dropdownData!.suppliers.keys.first,
      workspaceId: 1,
      createdBy: 1,
      totalCount: counts.values.fold(0, (sum, count) => sum! + count),
    );

    try {
      setState(() {
        _isLoading = true;
      });

      final createdRecord = await _manpowerService.createManpowerRecord(record);
      setState(() {
        _records.add(createdRecord);
        _filterRecords();
        _isLoading = false;
      });
      _showSuccessSnackbar('Manpower added successfully');

      // Update daily count
      _initializeDailyCount();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Failed to add manpower: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // Reload data for selected date
      _initializeDailyCount();
    }
  }

  Future<void> _manageManpowerTypes() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ManpowerTypesBottomSheet(
          onTypesUpdated: () async {
            // Reload manpower types
            try {
              final updatedTypes = await _manpowerTypeService
                  .getManpowerTypes();
              setState(() {
                _manpowerTypes = updatedTypes;
                // Reinitialize daily count
                _initializeDailyCount();
              });
            } catch (e) {
              print('Error updating manpower types: $e');
            }
          },
        ),
      ),
    );
  }

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
  _reportRecords = _records.where((record) {
    try {
      final recordDate = DateTime.parse(record.workDate);
      return (recordDate.isAtSameMomentAs(_reportStartDate) || 
              recordDate.isAfter(_reportStartDate)) &&
             (recordDate.isAtSameMomentAs(_reportEndDate) || 
              recordDate.isBefore(_reportEndDate.add(const Duration(days: 1))));
    } catch (e) {
      return false;
    }
  }).toList();

  // Calculate totals for the filtered records
  _reportTotalManpower = 0;
  _reportCategoryTotals.clear();
  
  for (var record in _reportRecords) {
    _reportTotalManpower += record.totalCount ?? 0;
    
    // Sum up categories
    for (var entry in record.manpowerCounts.entries) {
      _reportCategoryTotals[entry.key] = 
          (_reportCategoryTotals[entry.key] ?? 0) + entry.value;
    }
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
                  'Manpower Report',
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
                    _buildCategoryBreakdown(),
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
                  label: const Text('Download PDF', style: TextStyle(fontSize: 12)),
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
          'Total Manpower',
          _reportTotalManpower.toString(),
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
Widget _buildCategoryBreakdown() {
  final typesWithCounts = _manpowerTypes.where(
    (type) => (_reportCategoryTotals[type.name] ?? 0) > 0
  ).toList();
  
  if (typesWithCounts.isEmpty) {
    return const Center(
      child: Text(
        'No manpower data for selected date range',
        style: TextStyle(color: Colors.grey),
      ),
    );
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
          'Category Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2a43a0),
          ),
        ),
        const SizedBox(height: 12),
        ...typesWithCounts.map(
          (type) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    type.name,
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
                    '${_reportCategoryTotals[type.name] ?? 0}',
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
          'Individual Records',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2a43a0),
          ),
        ),
        const SizedBox(height: 12),
        ..._reportRecords.take(10).map((record) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${record.workDate} - ${record.site}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                '${record.totalCount ?? 0}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a43a0),
                ),
              ),
            ],
          ),
        )).toList(),
        if (_reportRecords.length > 10)
          Text(
            '... and ${_reportRecords.length - 10} more records',
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
  final filteredRecords = _records.where((record) {
    try {
      final recordDate = DateTime.parse(record.workDate);
      return (recordDate.isAtSameMomentAs(_reportStartDate) || 
              recordDate.isAfter(_reportStartDate)) &&
             (recordDate.isAtSameMomentAs(_reportEndDate) || 
              recordDate.isBefore(_reportEndDate.add(const Duration(days: 1))));
    } catch (e) {
      return false;
    }
  }).toList();

  // Group and calculate totals by date
  final Map<String, int> manpowerByDate = {};
  int totalManpower = 0;
  
  for (var record in filteredRecords) {
    final dateTotal = record.totalCount ?? 0;
    totalManpower += dateTotal;
    manpowerByDate[record.workDate] = (manpowerByDate[record.workDate] ?? 0) + dateTotal;
  }

  // Sort dates
  final sortedDates = manpowerByDate.keys.toList()..sort();
  
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
                  'Manpower Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF2a43a0),
                  ),
                ),
                pw.Text(
                  'Site: ${_getCurrentSiteName()}',
                  style: pw.TextStyle(fontSize: 12),
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
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Total Records: ${filteredRecords.length}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'Total Manpower: $totalManpower',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Dates with Data: ${sortedDates.length}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 25),
            
            // Date-wise Manpower Summary
            pw.Text(
              'Date-wise Manpower Summary',
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
                  1: const pw.FlexColumnWidth(2),   // Day
                  2: const pw.FlexColumnWidth(1),   // Count
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
                            fontSize: 12,
                          ),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          'Day',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          'Manpower Count',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                    ],
                  ),
                  
                  // Data rows for each date
                  ...sortedDates.map(
                    (dateStr) {
                      try {
                        final date = DateTime.parse(dateStr);
                        final formattedDate = DateFormat('dd-MMM-yyyy').format(date);
                        final dayName = DateFormat('EEEE').format(date);
                        final manpowerCount = manpowerByDate[dateStr] ?? 0;
                        
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              child: pw.Text(
                                formattedDate,
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                              padding: const pw.EdgeInsets.all(8),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                dayName,
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                              padding: const pw.EdgeInsets.all(8),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                manpowerCount.toString(),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromInt(0xFF2a43a0),
                                ),
                              ),
                              padding: const pw.EdgeInsets.all(8),
                            ),
                          ],
                        );
                      } catch (e) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              child: pw.Text(dateStr),
                              padding: const pw.EdgeInsets.all(8),
                            ),
                            pw.Padding(
                              child:pw.Text('-'),
                              padding: const pw.EdgeInsets.all(8),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                (manpowerByDate[dateStr] ?? 0).toString(),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              padding: const pw.EdgeInsets.all(8),
                            ),
                          ],
                        );
                      }
                    },
                  ).toList(),
                  
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
                            fontSize: 12,
                          ),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child:pw.Text(''),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          totalManpower.toString(),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColor.fromInt(0xFF2a43a0),
                          ),
                        ),
                        padding: const pw.EdgeInsets.all(8),
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
                    'No manpower data found for the selected date range',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ),
            
            pw.SizedBox(height: 30),
            
            // Daily Averages & Statistics
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
                              'Average Daily Manpower:',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Highest Daily Count:',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Lowest Daily Count:',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Days with Data:',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              '${(totalManpower / sortedDates.length).toStringAsFixed(1)}',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              manpowerByDate.values.isNotEmpty 
                                ? manpowerByDate.values.reduce((a, b) => a > b ? a : b).toString()
                                : '0',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              manpowerByDate.values.isNotEmpty 
                                ? manpowerByDate.values.reduce((a, b) => a < b ? a : b).toString()
                                : '0',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              '${sortedDates.length}',
                              style: pw.TextStyle(
                                fontSize: 11,
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
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Generated on: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Generated by: Manpower Management System',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Site: ${_getCurrentSiteName()}',
                    style: pw.TextStyle(fontSize: 9),
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

List<pw.Widget> _buildRecordRows(List<ManpowerRecord> records) {
  final rows = <pw.Widget>[];
  
  for (var record in records) {
    rows.add(
      pw.Table(
        border: pw.TableBorder.all(width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(2), // Date
          1: const pw.FlexColumnWidth(2), // Site
          2: const pw.FlexColumnWidth(2), // Supplier
          3: const pw.FlexColumnWidth(1), // Total
        },
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                child: pw.Text(
                  record.workDate,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                padding: const pw.EdgeInsets.all(6),
              ),
              pw.Padding(
                child: pw.Text(
                  record.site,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                padding: const pw.EdgeInsets.all(6),
              ),
              pw.Padding(
                child: pw.Text(
                  record.supplier,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                padding: const pw.EdgeInsets.all(6),
              ),
              pw.Padding(
                child: pw.Text(
                  '${record.totalCount ?? 0}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                padding: const pw.EdgeInsets.all(6),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  return rows;
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
    final fileName = 'manpower_report_${siteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
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
    
    _showErrorSnackbar('Failed to download PDF: $e');
  }
}
  Future<void> _sharePDF([VoidCallback? onSuccess]) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    final pdfBytes = await _generatePdfBytes();
    final siteName = _getCurrentSiteName().replaceAll(' ', '_');
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'manpower_report_${siteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf',
    );
    
    if (onSuccess != null) {
      onSuccess();
    }
    
    _showSuccessSnackbar('PDF shared successfully!');
  } catch (e) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    _showErrorSnackbar('Failed to share PDF: $e');
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

  Widget _buildManpowerCard(ManpowerRecord record) {
    // Calculate total manpower count
    final totalManpower =
        record.totalCount ??
        record.manpowerCounts.values.fold(0, (sum, count) => sum! + count);

    // Format date
    final formattedDate = _formatDate(record.workDate);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2a43a0).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _viewRecord(record),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2a43a0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF2a43a0),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Work Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(
                                      0xFF718096,
                                    ).withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2a43a0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _editRecord(record),
                            color: const Color(0xFF2a43a0),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () => _deleteRecord(record),
                            color: Colors.red,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Site and Supplier details
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.location_on,
                        'Site',
                        record.site,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.business,
                        'Supplier',
                        record.supplier,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Total and updated time
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a43a0).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2a43a0).withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Manpower',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalManpower',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2a43a0),
                            ),
                          ),
                        ],
                      ),
                      if (record.updatedAt != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Last Updated',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF718096),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(record.updatedAt!),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
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
  }

  Widget _buildCompactInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2a43a0).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF718096)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
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

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _viewRecord(ManpowerRecord record) async {
    if (_dropdownData == null) {
      _showErrorSnackbar('Please wait, loading dropdown data...');
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ManpowerBottomSheet(
          record: record,
          dropdownData: _dropdownData!,
          isViewMode: true,
        ),
      ),
    );
  }

  Future<void> _editRecord(ManpowerRecord record) async {
    if (_dropdownData == null) {
      _showErrorSnackbar('Please wait, loading dropdown data...');
      return;
    }

    final result = await showModalBottomSheet<ManpowerRecord?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ManpowerBottomSheet(
          record: record,
          dropdownData: _dropdownData!,
          onSave: (updatedRecord) => updatedRecord,
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        setState(() {
          _isLoading = true;
        });

        final updatedRecord = await _manpowerService.updateManpowerRecord(
          result,
        );
        setState(() {
          final index = _records.indexWhere((r) => r.id == updatedRecord.id);
          if (index != -1) {
            _records[index] = updatedRecord;
          }
          _filterRecords();
          _isLoading = false;
        });
        _showSuccessSnackbar('Record updated successfully');

        // Update daily count
        _initializeDailyCount();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Failed to update record: $e');
      }
    }
  }

  Future<void> _deleteRecord(ManpowerRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
          'Are you sure you want to delete the record for ${record.workDate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() {
          _isLoading = true;
        });

        await _manpowerService.deleteManpowerRecord(record.id!);
        setState(() {
          _records.removeWhere((r) => r.id == record.id);
          _filterRecords();
          _isLoading = false;
        });
        _showSuccessSnackbar('Record deleted successfully');

        // Update daily count
        _initializeDailyCount();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Failed to delete record: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.h,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manpower Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3),
            Text(
              _getCurrentSiteName(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _manageManpowerTypes,
            tooltip: 'Manage Manpower Types',
          ),

          IconButton(
            icon: const Icon(Icons.summarize),
            onPressed: _generateReport,
            tooltip: 'Generate Report',
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 28.sp),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date selector and quick stats
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Records: ${_filteredRecords.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2a43a0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              'Total: ${_calculateOverallTotal()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search manpower records...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Records count
                // Records count and total manpower
                const SizedBox(height: 16),

                // Manpower Records List
                Expanded(
                  child: _filteredRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No manpower records found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Selected date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed:
                                    _addNewRecord, // Changed from _quickAddManpower to _addNewRecord
                                child: const Text('Add Manpower Record'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: _filteredRecords.length,
                            itemBuilder: (context, index) {
                              final record = _filteredRecords[index];
                              return _buildManpowerCard(record);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRecord,
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF3a53b0),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Custom ManpowerBottomSheet (simplified version)
class ManpowerBottomSheet extends StatefulWidget {
  final ManpowerRecord? record;
  final DropdownData dropdownData;
  final Function(ManpowerRecord)? onSave;
  final bool isViewMode;
  final DateTime? selectedDate;

  const ManpowerBottomSheet({
    super.key,
    this.record,
    required this.dropdownData,
    this.onSave,
    this.isViewMode = false,
    this.selectedDate,
  });

  @override
  State<ManpowerBottomSheet> createState() => _ManpowerBottomSheetState();
}

class _ManpowerBottomSheetState extends State<ManpowerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _manpowerTypeController;
  int? _selectedSupplierId;
  int? _selectedSiteId;
  final List<int> _selectedTypes = [];
  final Map<String, int> _manpowerCounts = {};

  @override
  void initState() {
    super.initState();

    final record = widget.record;
    _dateController = TextEditingController(
      text:
          record?.workDate ??
          (widget.selectedDate != null
              ? DateFormat('yyyy-MM-dd').format(widget.selectedDate!)
              : DateFormat('yyyy-MM-dd').format(DateTime.now())),
    );

    _manpowerTypeController = TextEditingController();

    if (record?.supplierId != null) {
      _selectedSupplierId = record!.supplierId;
    }

    if (record?.siteId != null) {
      _selectedSiteId = record!.siteId;
    }

    if (record != null) {
      _manpowerCounts.addAll(record.manpowerCounts);
      _selectedTypes.addAll(
        widget.dropdownData.manpowerTypes.entries
            .where((e) => _manpowerCounts.containsKey(e.value))
            .map((e) => e.key)
            .toList(),
      );
    }

    _updateSelectedText();
  }

  void _updateSelectedText() {
    final types = widget.dropdownData.manpowerTypes;
    _manpowerTypeController.text = _selectedTypes
        .map((id) => types[id] ?? 'Unknown')
        .join(", ");
  }

  void _selectManpowerTypes() async {
    final manpowerTypes = widget.dropdownData.manpowerTypes;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text("Select Manpower Types"),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Done",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: manpowerTypes.entries.map((e) {
                    return Row(
                      children: [
                        Checkbox(
                          value: _selectedTypes.contains(e.key),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedTypes.add(e.key);
                                _manpowerCounts[e.value] =
                                    _manpowerCounts[e.value] ?? 0;
                              } else {
                                _selectedTypes.remove(e.key);
                                _manpowerCounts.remove(e.value);
                              }
                            });
                            _updateSelectedText();
                          },
                        ),
                        Expanded(child: Text(e.value)),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            enabled: _selectedTypes.contains(e.key),
                            decoration: const InputDecoration(
                              hintText: 'Count',
                            ),
                            controller: TextEditingController(
                              text: _manpowerCounts[e.value]?.toString() ?? '',
                            ),
                            onChanged: (v) {
                              setState(() {
                                _manpowerCounts[e.value] = int.tryParse(v) ?? 0;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _calculateTotalCount() =>
      _manpowerCounts.values.fold(0, (sum, c) => sum + c);

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final rec = ManpowerRecord(
        id: widget.record?.id,
        workDate: _dateController.text,
        supplier: widget.dropdownData.suppliers[_selectedSupplierId] ?? '',
        site: widget.dropdownData.sites[_selectedSiteId] ?? '',
        manpowerCounts: Map.from(_manpowerCounts),
        siteId: _selectedSiteId,
        supplierId: _selectedSupplierId,
        workspaceId: widget.record?.workspaceId ?? 1,
        createdBy: widget.record?.createdBy ?? 1,
        totalCount: _calculateTotalCount(),
      );

      widget.onSave?.call(rec);
      Navigator.pop(context, rec);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = widget.dropdownData.suppliers;
    final sites = widget.dropdownData.sites;

    if (widget.isViewMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("View Manpower"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: Color(0xFF2a43a0),
              ),
              title: const Text("Work Date"),
              subtitle: Text(_dateController.text),
            ),
            ListTile(
              leading: const Icon(Icons.business, color: Color(0xFF2a43a0)),
              title: const Text("Supplier"),
              subtitle: Text(suppliers[_selectedSupplierId] ?? 'N/A'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF2a43a0)),
              title: const Text("Site"),
              subtitle: Text(sites[_selectedSiteId] ?? 'N/A'),
            ),
            const SizedBox(height: 6),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Manpower Types",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._manpowerCounts.entries.map((entry) {
              return ListTile(
                leading: const Icon(Icons.people, color: Color(0xFF2a43a0)),
                title: Text(entry.key),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a43a0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Count: ${entry.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a43a0),
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Manpower:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _calculateTotalCount().toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2a43a0),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.record == null ? "Create Manpower" : "Edit Manpower",
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: "Work Date",
                prefixIcon: Icon(Icons.calendar_month),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Date required";
                try {
                  DateTime.parse(v);
                } catch (_) {
                  return "Invalid date format (YYYY-MM-DD)";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: _selectedSupplierId,
              decoration: const InputDecoration(
                labelText: "Supplier",
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Select Supplier'),
                ),
                ...suppliers.entries
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
              ],
              onChanged: (v) => setState(() => _selectedSupplierId = v),
              validator: (v) => v == null ? "Select supplier" : null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: _selectedSiteId,
              decoration: const InputDecoration(
                labelText: "Site",
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Select Site'),
                ),
                ...sites.entries
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
              ],
              onChanged: (v) => setState(() => _selectedSiteId = v),
              validator: (v) => v == null ? "Select site" : null,
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _manpowerTypeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Manpower Types",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              onTap: _selectManpowerTypes,
              validator: (_) =>
                  _selectedTypes.isEmpty ? "Select at least one type" : null,
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Manpower:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _calculateTotalCount().toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a43a0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: _saveRecord,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(12),
                backgroundColor: const Color(0xFF2a43a0),
                foregroundColor: Colors.white,
              ),
              child: Text(
                widget.record == null ? "Create Record" : "Update Record",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Manpower Types Bottom Sheet (Modern & Simple UI)
class ManpowerTypesBottomSheet extends StatefulWidget {
  final VoidCallback? onTypesUpdated;

  const ManpowerTypesBottomSheet({super.key, this.onTypesUpdated});

  @override
  State<ManpowerTypesBottomSheet> createState() =>
      _ManpowerTypesBottomSheetState();
}

class _ManpowerTypesBottomSheetState extends State<ManpowerTypesBottomSheet> {
  final ManpowerTypeService _service = ManpowerTypeService();
  List<ManpowerType> _manpowerTypes = [];
  List<ManpowerType> _filteredManpowerTypes = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _loadManpowerTypes();
    _searchController.addListener(_filterManpowerTypes);
  }

  Future<void> _loadManpowerTypes() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final types = await _service.getManpowerTypes();
      if (mounted) {
        setState(() {
          _manpowerTypes = types;
          _filteredManpowerTypes = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading manpower types: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load manpower types: $e');
      }
    }
  }

  void _filterManpowerTypes() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        _filteredManpowerTypes = _manpowerTypes
            .where((type) => type.name.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addManpowerType() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorSnackBar('Please enter a name');
      return;
    }

    try {
      final newType = ManpowerType(
        id: 0,
        name: name,
        status: 0,
        siteId: 1,
        createdBy: 1,
        workspaceId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _service.createManpowerType(newType);

      _nameController.clear();
      _descriptionController.clear();
      setState(() {
        _showAddForm = false;
      });

      _showSuccessSnackBar('Manpower type added successfully');
      await _loadManpowerTypes();

      widget.onTypesUpdated?.call();
    } catch (e) {
      print('Error adding manpower type: $e');
      _showErrorSnackBar('Failed to add manpower type: $e');
    }
  }

  Future<void> _editManpowerType(ManpowerType manpowerType) async {
    final TextEditingController editController = TextEditingController(
      text: manpowerType.name,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a43a0),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Edit Manpower Type',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: editController,
                            decoration: const InputDecoration(
                              hintText: 'Enter manpower type name',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: const Color(
                                        0xFF2a43a0,
                                      ).withOpacity(0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Color(0xFF2a43a0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final String name = editController.text
                                        .trim();
                                    if (name.isEmpty) {
                                      _showErrorSnackBar('Please enter a name');
                                      return;
                                    }
                                    Navigator.pop(context);
                                    await _updateManpowerType(
                                      manpowerType,
                                      name,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2a43a0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: const Text(
                                    'Update',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateManpowerType(
    ManpowerType manpowerType,
    String name,
  ) async {
    try {
      final updatedType = manpowerType.copyWith(name: name);
      await _service.updateManpowerType(updatedType);
      _showSuccessSnackBar('Manpower type updated successfully');
      await _loadManpowerTypes();

      widget.onTypesUpdated?.call();
    } catch (e) {
      print('Error updating manpower type: $e');
      _showErrorSnackBar('Failed to update manpower type: $e');
    }
  }

  Future<void> _deleteManpowerType(int id, String name) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 30,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Delete Manpower Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                'Are you sure you want to delete "$name"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _confirmDelete(id, name);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int id, String name) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _service.deleteManpowerType(id);

      if (success) {
        _showSuccessSnackBar('"$name" deleted successfully');
        await _loadManpowerTypes();

        widget.onTypesUpdated?.call();
      } else {
        _showErrorSnackBar('Failed to delete "$name"');
      }
    } catch (e) {
      print('Error deleting manpower type: $e');
      _showErrorSnackBar('Failed to delete "$name": $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: 40,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                    const Text(
                      'Manage Manpower Types',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2a43a0),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadManpowerTypes,
                      icon: const Icon(
                        Icons.refresh,
                        color: Color(0xFF2a43a0),
                        size: 24,
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showAddForm = !_showAddForm;
                          if (!_showAddForm) {
                            _nameController.clear();
                            _descriptionController.clear();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showAddForm
                            ? Colors.grey.shade300
                            : const Color(0xFF2a43a0),
                        foregroundColor: _showAddForm
                            ? Colors.grey
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(
                        _showAddForm ? Icons.close : Icons.add,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Add Form (Collapsible)
          if (_showAddForm)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Manpower Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2a43a0),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Type Name Field
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Type Name (e.g., Carpenter, Electrician)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Description Field (Optional)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Description (Optional)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Add Button
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 35,

                      child: ElevatedButton(
                        onPressed: _addManpowerType,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2a43a0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add Manpower Type',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manpower Types',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_filteredManpowerTypes.length} entries',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // Manpower Types List (Simple with Dividers)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2a43a0)),
                        SizedBox(height: 16),
                        Text(
                          'Loading manpower types...',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : _filteredManpowerTypes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _manpowerTypes.isEmpty
                              ? 'No manpower types found'
                              : 'No results found for "${_searchController.text}"',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        if (_manpowerTypes.isEmpty && !_showAddForm)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showAddForm = true;
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2a43a0),
                            ),
                            child: const Text(
                              'Click here to add your first type',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: _filteredManpowerTypes.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Color.fromARGB(255, 207, 207, 207),
                    ),
                    itemBuilder: (context, index) {
                      final manpowerType = _filteredManpowerTypes[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        leading: Container(
                          width: 40,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2a43a0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.work_outline,
                            color: Color(0xFF2a43a0),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          manpowerType.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${manpowerType.id}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit Button
                            IconButton(
                              onPressed: () => _editManpowerType(manpowerType),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF2a43a0),
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            // Delete Button
                            IconButton(
                              onPressed: () => _deleteManpowerType(
                                manpowerType.id,
                                manpowerType.name,
                              ),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        onTap: () => _editManpowerType(manpowerType),
                      );
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
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
