import 'dart:async';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Import your existing pages and models
import 'package:ecoteam_app/admin/models/manpower_model.dart' hide ManpowerType;
import 'package:ecoteam_app/admin/services/manpower_services.dart';
import 'package:ecoteam_app/admin/services/manpowerType_services.dart';
import 'package:ecoteam_app/admin/models/mapowerType_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';
import 'package:provider/provider.dart';

class ManpowerCountScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final int? workspaceId;
  final String? currentCompany;
  final int? userId;
  final bool isFormOnly;
  final int? activityId;
  final int? activityCompletedId;

  ManpowerCountScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    this.workspaceId,
    this.currentCompany,
    this.userId,
    this.isFormOnly = false,
    this.activityId,
    this.activityCompletedId,
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
  int? _reportSelectedSupplierId;
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

  // User and Workspace ID
  int _userId = 0;
  int _currentWorkspaceId = 0;

  // Daily count tracking for quick add
  final Map<String, int> _dailyManpowerCount = {};

  Timer? _permissionTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_filterRecords);

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  @override
  void didUpdateWidget(ManpowerCountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _filterRecords();
    }
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

      // Load User and Workspace ID
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr);
        if (userData['user'] != null && userData['user']['id'] != null) {
          _userId = userData['user']['id'] is int
              ? userData['user']['id']
              : int.tryParse(userData['user']['id'].toString()) ?? 0;
        } else if (userData['id'] != null) {
          _userId = userData['id'] is int
              ? userData['id']
              : int.tryParse(userData['id'].toString()) ?? 0;
        }
      }

      // Fallback to provider if still 0
      if (_userId == 0) {
        final provider = Provider.of<CompanySiteProvider>(
          context,
          listen: false,
        );
        if (provider.currentUserId != null) {
          _userId = provider.currentUserId!;
        }
      }

      // Priority: Widget userId -> Stored -> Provider -> Default (0)
      if (widget.userId != null && widget.userId! > 0) {
        _userId = widget.userId!;
      } else {
        // Fallback checks (existing logic)
        final prefs = await SharedPreferences.getInstance();
        final userDataStr = prefs.getString('user_data');
        if (userDataStr != null) {
          final userData = jsonDecode(userDataStr);
          if (userData['user'] != null && userData['user']['id'] != null) {
            _userId = userData['user']['id'] is int
                ? userData['user']['id']
                : int.tryParse(userData['user']['id'].toString()) ?? 0;
          } else if (userData['id'] != null) {
            _userId = userData['id'] is int
                ? userData['id']
                : int.tryParse(userData['id'].toString()) ?? 0;
          }
        }

        // Fallback to provider if still 0
        if (_userId == 0) {
          final provider = Provider.of<CompanySiteProvider>(
            context,
            listen: false,
          );
          if (provider.currentUserId != null) {
            _userId = provider.currentUserId!;
          }
        }
      }

      // Priority: Widget Workspace ID -> Provider/Stored Workspace -> Default (0)
      // Priority: Widget Workspace ID -> Provider -> Default
      if (widget.workspaceId != null && widget.workspaceId! > 0) {
        _currentWorkspaceId = widget.workspaceId!;
      } else {
        // Fallback to provider
        final provider = Provider.of<CompanySiteProvider>(
          context,
          listen: false,
        );
        if (provider.selectedCompanyId != null) {
          _currentWorkspaceId = int.tryParse(provider.selectedCompanyId!) ?? 0;
        }
      }

      _initializeDailyCount();
      _filterRecords(); // Apply filter immediately

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
          final siteId = int.tryParse(
            widget.selectedSiteId!.replaceAll(RegExp(r'[^0-9]'), ''),
          );
          if (siteId != null) {
            // Use current workspace ID if available, otherwise default to 0 (which might need handling on API side or be invalid)
            // Using 1 as a last resort fallback if acceptable, or preferably 0 to indicate "unknown"
            final wsId = _currentWorkspaceId > 0 ? _currentWorkspaceId : 1;

            final records = await _manpowerService
                .getManpowerRecordsBySiteAndWorkspace(siteId, wsId);
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
      var filtered = _records;

      // Filter by Site
      if (widget.selectedSiteId != null) {
        final siteId = int.tryParse(
          widget.selectedSiteId!.replaceAll(RegExp(r'[^0-9]'), ''),
        );
        if (siteId != null) {
          filtered = filtered
              .where(
                (record) => record.siteId == siteId,
              ) // Assuming record has siteId
              .toList();
        }
      }

      if (query.isNotEmpty) {
        filtered = filtered.where((record) {
          return record.workDate.toLowerCase().contains(query) ||
              record.supplier.toLowerCase().contains(query) ||
              record.site.toLowerCase().contains(query) ||
              (record.totalCount != null &&
                  record.totalCount.toString().contains(query));
        }).toList();
      }
      _filteredRecords = filtered;
    });
  }

  Future<void> _refreshData() async {
    await Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    ).refreshPermissions();
    await _loadInitialData();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data refreshed')));
  }

  // Add this method for adding new record via AppBar button
  Future<void> _addNewRecord() async {
    // Use logic from Supplier Screen (widget.userId ?? Provider ?? 1)

    if (_dropdownData == null) {
      _showErrorSnackbar('Please wait, loading dropdown data...');
      return;
    }

    final result = await showModalBottomSheet<ManpowerRecord?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.70,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ManpowerBottomSheet(
          dropdownData: _dropdownData!,
          selectedDate: _selectedDate,
          initialSiteId: widget.selectedSiteId != null
              ? int.tryParse(
                  widget.selectedSiteId!.replaceAll(RegExp(r'[^0-9]'), ''),
                )
              : null,
          userId:
              widget.userId ??
              (Provider.of<CompanySiteProvider>(
                    context,
                    listen: false,
                  ).currentUserId ??
                  1),
          workspaceId: _currentWorkspaceId > 0 ? _currentWorkspaceId : 0,
          scrollController: scrollController,
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Ensure dynamic IDs are used
        // If bottom sheet didn't set them (or set them to defaults), override with current context if valid
        if (result.createdBy == null || result.createdBy == 0) {
          result.createdBy =
              widget.userId ??
              (Provider.of<CompanySiteProvider>(
                    context,
                    listen: false,
                  ).currentUserId ??
                  1);
        }

        // CRITICAL: Force use of current workspace if available
        if (_currentWorkspaceId > 0) {
          result.workspaceId = _currentWorkspaceId;
        } else if (result.workspaceId == null || result.workspaceId == 0) {
          result.workspaceId = 0; // Fallback only if absolutely necessary
        }

        final recordToCreate = result
          ..activityId = widget.activityId
          ..activityCompletedId = widget.activityCompletedId;

        print('=== ADD MANPOWER REQUEST ===');
        print('activity_completed_id: ${widget.activityCompletedId}');
        print('Manpower payload: ${recordToCreate.toJson()}');

        final createdRecord = await _manpowerService.createManpowerRecord(
          recordToCreate,
        );
        print('=== ADD MANPOWER RESPONSE ===');
        print('Created record: ${createdRecord.toJson()}');
        print('=============================');

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
          ? int.tryParse(
                  widget.selectedSiteId!.replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                _dropdownData!.sites.keys.first
          : _dropdownData!.sites.keys.first,
      supplierId: _dropdownData!.suppliers.keys.first,
      workspaceId: _currentWorkspaceId > 0
          ? _currentWorkspaceId
          : 0, // Use dynamic workspace or valid default
      createdBy:
          widget.userId ??
          (Provider.of<CompanySiteProvider>(
                context,
                listen: false,
              ).currentUserId ??
              1),
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
          userId: _userId,
          workspaceId: _currentWorkspaceId,
          siteId: widget.selectedSiteId != null
              ? int.tryParse(
                  widget.selectedSiteId!.replaceAll(RegExp(r'[^0-9]'), ''),
                )
              : null,
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
    _reportSelectedSupplierId = null;

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

        // Date filter
        bool dateMatch =
            (recordDate.isAtSameMomentAs(_reportStartDate) ||
                recordDate.isAfter(_reportStartDate)) &&
            (recordDate.isAtSameMomentAs(_reportEndDate) ||
                recordDate.isBefore(
                  _reportEndDate.add(const Duration(days: 1)),
                ));

        // Supplier filter
        bool supplierMatch =
            _reportSelectedSupplierId == null ||
            record.supplierId == _reportSelectedSupplierId;

        return dateMatch && supplierMatch;
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

              // Supplier Selection
              const Text(
                'Select Supplier:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a43a0),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _reportSelectedSupplierId,
                    isExpanded: true,
                    hint: const Text('All Suppliers'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Suppliers'),
                      ),
                      if (_dropdownData != null)
                        ..._dropdownData!.suppliers.entries.map(
                          (entry) => DropdownMenuItem<int?>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _reportSelectedSupplierId = value;
                        _updateReportData();
                      });
                    },
                  ),
                ),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (Provider.of<CompanySiteProvider>(
                    context,
                  ).hasPermission('manpower export'))
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
                  //   ElevatedButton.icon(
                  //     onPressed: () =>
                  //         _downloadPDF(() => Navigator.pop(context)),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: const Color(0xFF4a63c0),
                  //       foregroundColor: Colors.white,
                  //       elevation: 4,
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 12,
                  //         vertical: 10,
                  //       ),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //     ),
                  //     icon: const Icon(Icons.download, size: 16),
                  //     label: const Text(
                  //       'Download PDF',
                  //       style: TextStyle(fontSize: 12),
                  //     ),
                  //   ),
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
          'Manpower_report_${siteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
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
    final typesWithCounts = _manpowerTypes
        .where((type) => (_reportCategoryTotals[type.name] ?? 0) > 0)
        .toList();

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
          ..._reportRecords
              .take(10)
              .map(
                (record) => Padding(
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
                ),
              )
              .toList(),
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

        // Date filter
        bool dateMatch =
            (recordDate.isAtSameMomentAs(_reportStartDate) ||
                recordDate.isAfter(_reportStartDate)) &&
            (recordDate.isAtSameMomentAs(_reportEndDate) ||
                recordDate.isBefore(
                  _reportEndDate.add(const Duration(days: 1)),
                ));

        // Supplier filter
        bool supplierMatch =
            _reportSelectedSupplierId == null ||
            record.supplierId == _reportSelectedSupplierId;

        return dateMatch && supplierMatch;
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
      manpowerByDate[record.workDate] =
          (manpowerByDate[record.workDate] ?? 0) + dateTotal;
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
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Supplier: ${_reportSelectedSupplierId != null && _dropdownData != null ? _dropdownData!.suppliers[_reportSelectedSupplierId] ?? 'Unknown' : 'All Suppliers'}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
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
                    1: const pw.FlexColumnWidth(2), // Day
                    2: const pw.FlexColumnWidth(1), // Count
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
                    ...sortedDates.map((dateStr) {
                      try {
                        final date = DateTime.parse(dateStr);
                        final formattedDate = DateFormat(
                          'dd-MMM-yyyy',
                        ).format(date);
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
                              child: pw.Text('-'),
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
                              fontSize: 12,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(8),
                        ),
                        pw.Padding(
                          child: pw.Text(''),
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
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                    ),
                  ),
                ),

              pw.SizedBox(height: 30),

              // Daily Averages & Statistics
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
      final fileName =
          'manpower_report_${siteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
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
        filename:
            'manpower_report_${siteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf',
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
                              Icons.calendar_month,
                              color: Color(0xFF2a43a0),
                              size: 16,
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
                                    fontSize: 16,
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
                    ),
                    if (Provider.of<CompanySiteProvider>(
                          context,
                        ).hasPermission('manpower show') ||
                        Provider.of<CompanySiteProvider>(
                          context,
                        ).hasPermission('manpower edit') ||
                        Provider.of<CompanySiteProvider>(
                          context,
                        ).hasPermission('manpower delete'))
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () =>
                                  _showManpowerOptionsBottomSheet(record),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.more_vert,
                                  color: const Color(0xFF718096),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Site and Supplier details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactInfoItem(
                      Icons.business,
                      'Supplier',
                      record.supplier,
                    ),

                    const SizedBox(height: 12),

                    // Total and updated time
                    Row(
                      children: [
                        Icon(
                          Icons.all_inbox,
                          color: const Color(0xFF718096),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        const Text(
                          'Total Manpower: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$totalManpower',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
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
    return Row(
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ManpowerBottomSheet(
          record: record,
          dropdownData: _dropdownData!,
          isViewMode: true,
          scrollController: scrollController,
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
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.70,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ManpowerBottomSheet(
          record: record,
          dropdownData: _dropdownData!,
          scrollController: scrollController,
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
    if (widget.isFormOnly) {
      if (_dropdownData == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Add Manpower',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarHeight: 60,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4a63c0),
                  Color(0xFF3a53b0),
                  Color(0xFF2a43a0),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
          ),
        ),
        body: ManpowerBottomSheet(
          dropdownData: _dropdownData!,
          selectedDate: _selectedDate,
          initialSiteId: widget.selectedSiteId != null
              ? int.tryParse(
                  widget.selectedSiteId!.replaceAll(RegExp(r'[^0-9]'), ''),
                )
              : null,
          userId: widget.userId ?? _userId,
          workspaceId: _currentWorkspaceId > 0 ? _currentWorkspaceId : 0,
          isPage: true,
          activityId: widget.activityId,
          onSave: (record) async {
            try {
              // Ensure dynamic IDs are used
              if (record.createdBy == null || record.createdBy == 0) {
                record.createdBy = widget.userId ?? _userId;
              }
              if (_currentWorkspaceId > 0) {
                record.workspaceId = _currentWorkspaceId;
              }
              record.activityId = widget.activityId;
              record.activityCompletedId = widget.activityCompletedId;

              print('Payload for Manpower: ${record.toJson()}');
              final response = await _manpowerService.createManpowerRecord(
                record,
              );
              print('API Response: $response');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Manpower record created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              print('Error creating manpower record: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create record: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74.h,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manpower Management',
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
        actions: buildNotificationActions(
          context: context,
          selectedSiteId: widget.selectedSiteId,
          sites: widget.sites,
          currentCompany: widget.currentCompany ?? '',
          workspaceId: widget.workspaceId,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date selector and quick stats
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
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
                      if (Provider.of<CompanySiteProvider>(
                        context,
                        listen: false,
                      ).hasPermission('manpower export'))
                        IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Color.fromARGB(255, 29, 29, 29),
                            size: 24,
                          ),
                          onPressed: _generateReport,
                          tooltip: 'Generate Report',
                        ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search manpower...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 120, 138, 206),
                          width: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

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
                              // const SizedBox(height: 8),
                              // Text(
                              //   'Selected date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                              //   style: const TextStyle(
                              //     fontSize: 14,
                              //     color: Colors.grey,
                              //   ),
                              // ),
                              // const SizedBox(height: 16),
                              // ElevatedButton(
                              //   onPressed:
                              //       Provider.of<CompanySiteProvider>(
                              //         context,
                              //       ).hasPermission('manpower create')
                              //       ? _addNewRecord
                              //       : null, // Changed from _quickAddManpower to _addNewRecord
                              //   child: const Text('Add Manpower Record'),
                              // ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
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
      // floatingActionButton:
      //     Provider.of<CompanySiteProvider>(
      //       context,
      //     ).hasPermission('manpower create')
      //     ? FloatingActionButton(
      //         onPressed: _addNewRecord,
      //         child: Icon(Icons.add, color: Colors.white),
      //         backgroundColor: Color(0xFF3a53b0),
      //       )
      //     : null,
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? backgroundColor,
    required VoidCallback onTap,
    Color color = const Color(0xFF2D3748),
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF2a43a0).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
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

  void _showManpowerOptionsBottomSheet(ManpowerRecord record) {
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
            if (Provider.of<CompanySiteProvider>(
              context,
            ).hasPermission('manpower show'))
              _buildOptionTile(
                icon: Icons.visibility_outlined,
                title: 'View Full Details',
                iconColor: const Color(0xFF2a43a0),
                backgroundColor: const Color(0xFF2a43a0).withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _viewRecord(record);
                },
              ),

            // if (Provider.of<CompanySiteProvider>(
            //   context,
            // ).hasPermission('manpower edit'))
            //   _buildOptionTile(
            //     icon: Icons.edit_outlined,
            //     title: 'Edit Record',
            //     iconColor: Colors.blue,
            //     backgroundColor: Colors.blue.withOpacity(0.1),
            //     onTap: () {
            //       Navigator.pop(context);
            //       _editRecord(record);
            //     },
            //   ),
            if (Provider.of<CompanySiteProvider>(
              context,
            ).hasPermission('manpower delete'))
              _buildOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Record',
                color: Colors.red,
                iconColor: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    _deleteRecord(record);
                  });
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Custom ManpowerBottomSheet (simplified version)
class ManpowerBottomSheet extends StatefulWidget {
  final ManpowerRecord? record;
  final DropdownData dropdownData;
  final Future<void> Function(ManpowerRecord)? onSave;
  final bool isViewMode;
  final DateTime? selectedDate;
  final int? initialSiteId;
  final int? userId;
  final int? workspaceId;
  final bool isPage;
  final int? activityId;

  const ManpowerBottomSheet({
    super.key,
    this.record,
    required this.dropdownData,
    this.onSave,
    this.isViewMode = false,
    this.selectedDate,
    this.initialSiteId,
    this.userId,
    this.workspaceId,
    this.scrollController,
    this.isPage = false,
    this.activityId,
  });

  final ScrollController? scrollController;

  @override
  State<ManpowerBottomSheet> createState() => _ManpowerBottomSheetState();
}

// Helper class for row state
class ManpowerRowState {
  int? typeId;
  TextEditingController countController;
  ManpowerRowState({this.typeId, required this.countController});

  void dispose() {
    countController.dispose();
  }
}

class _ManpowerBottomSheetState extends State<ManpowerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  int? _selectedSupplierId;
  int? _selectedSiteId;

  // Dynamic rows structure
  List<ManpowerRowState> _dynamicRows = [];
  Map<int, String> _availableManpowerTypes = {};

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

    if (record?.supplierId != null) {
      _selectedSupplierId = record!.supplierId;
      // Validate if supplier exists in dropdown data, otherwise set to null
      if (!widget.dropdownData.suppliers.containsKey(_selectedSupplierId)) {
        _selectedSupplierId = null;
      }
    }

    if (record?.siteId != null) {
      _selectedSiteId = record!.siteId;
    } else if (widget.initialSiteId != null) {
      _selectedSiteId = widget.initialSiteId;
    }

    // Validate if site exists in dropdown data, otherwise set to null
    if (_selectedSiteId != null &&
        !widget.dropdownData.sites.containsKey(_selectedSiteId)) {
      _selectedSiteId = null;
    }

    // Auto-select first site if no site is selected (required since we removed the dropdown)
    if (_selectedSiteId == null && widget.dropdownData.sites.isNotEmpty) {
      _selectedSiteId = widget.dropdownData.sites.keys.first;
    }

    _availableManpowerTypes = Map.from(widget.dropdownData.manpowerTypes);

    if (record != null) {
      record.manpowerCounts.forEach((name, count) {
        // Find ID from name
        final entry = _availableManpowerTypes.entries.firstWhere(
          (e) => e.value == name,
          orElse: () => const MapEntry(-1, ""),
        );
        if (entry.key != -1) {
          _dynamicRows.add(
            ManpowerRowState(
              typeId: entry.key,
              countController: TextEditingController(text: count.toString()),
            ),
          );
        }
      });
    }

    // Add one empty row if creating a new record
    if (_dynamicRows.isEmpty && !widget.isViewMode) {
      _addRow();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    for (var row in _dynamicRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _dynamicRows.add(
        ManpowerRowState(
          typeId: null,
          countController: TextEditingController(),
        ),
      );
    });
  }

  void _removeRow(int index) {
    setState(() {
      _dynamicRows[index].dispose();
      _dynamicRows.removeAt(index);
    });
  }

  Future<void> _refreshManpowerTypes() async {
    try {
      final service = ManpowerTypeService();
      final types = await service.getManpowerTypes();
      if (mounted) {
        setState(() {
          _availableManpowerTypes = {for (var t in types) t.id: t.name};
        });
      }
    } catch (e) {
      print('Error refreshing manpower types: $e');
    }
  }

  void _addManpowerType() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddManpowerTypeBottomSheet(
        onTypeAdded: _refreshManpowerTypes,
        siteId: _selectedSiteId ?? 0,
        workspaceId: widget.workspaceId ?? widget.record?.workspaceId ?? 1,
        userId: widget.userId ?? widget.record?.createdBy ?? 1,
      ),
    );
  }

  int _calculateTotalCount() {
    int total = 0;
    for (var row in _dynamicRows) {
      total += int.tryParse(row.countController.text) ?? 0;
    }
    return total;
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, int> manpowerCounts = {};
      for (var row in _dynamicRows) {
        if (row.typeId != null) {
          final typeName = _availableManpowerTypes[row.typeId];
          if (typeName != null) {
            manpowerCounts[typeName] =
                int.tryParse(row.countController.text) ?? 0;
          }
        }
      }

      if (manpowerCounts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one manpower type'),
          ),
        );
        return;
      }

      final rec = ManpowerRecord(
        id: widget.record?.id,
        workDate: _dateController.text,
        supplier: widget.dropdownData.suppliers[_selectedSupplierId] ?? '',
        site: widget.dropdownData.sites[_selectedSiteId] ?? '',
        manpowerCounts: manpowerCounts,
        siteId: _selectedSiteId,
        supplierId: _selectedSupplierId,
        workspaceId: widget.workspaceId ?? widget.record?.workspaceId ?? 1,
        createdBy: widget.userId ?? widget.record?.createdBy ?? 1,
        totalCount: _calculateTotalCount(),
        activityId: widget.activityId,
      );

      if (widget.onSave != null) {
        await widget.onSave!(rec);
      } else {
        Navigator.pop(context, rec);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = widget.dropdownData.suppliers;
    final sites = widget.dropdownData.sites;
    final isEdit = widget.record != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isPage
            ? null
            : const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: widget.isPage
            ? null
            : [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          if (!widget.isPage)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Header
          if (!widget.isPage)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4a63c0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isViewMode
                          ? Icons.visibility_outlined
                          : (isEdit ? Icons.edit : Icons.add_circle_outline),
                      color: const Color(0xFF4a63c0),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isViewMode
                              ? 'View Manpower'
                              : (isEdit ? 'Edit Manpower' : 'Add Manpower'),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          widget.isViewMode
                              ? 'Details of manpower record'
                              : (isEdit
                                    ? 'Update existing manpower record'
                                    : 'Create new manpower record'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey[300]),

          // Content
          Expanded(
            child: widget.isViewMode
                ? _buildViewContent(suppliers, sites)
                : _buildEditContent(suppliers, sites),
          ),
        ],
      ),
    );
  }

  Widget _buildViewContent(Map<int, String> suppliers, Map<int, String> sites) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        _buildDetailItem(
          Icons.calendar_today,
          "Work Date",
          _dateController.text,
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          Icons.location_on,
          "Site",
          sites[_selectedSiteId] ?? 'N/A',
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          Icons.business,
          "Supplier",
          suppliers[_selectedSupplierId] ?? 'N/A',
        ),
        const SizedBox(height: 24),
        const Text(
          "Manpower Counts",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...widget.record?.manpowerCounts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          "${entry.key}:",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4a63c0),
                      ),
                    ),
                  ],
                ),
              );
            }) ??
            [],
        const SizedBox(height: 24),
        Container(
          width: 150,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF4a63c0).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4a63c0).withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Total Manpower: ",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                _calculateTotalCount().toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4a63c0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 150,
          height: 40,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEditContent(Map<int, String> suppliers, Map<int, String> sites) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _dateController,
            decoration: InputDecoration(
              labelText: "Work Date",
              hintText: 'Select date',
              prefixIcon: Icon(
                Icons.calendar_month,
                color: const Color(0xFF4a63c0),
                size: 20.sp,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 214, 215, 216),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: Color(0xFF4a63c0),
                  width: 1.0,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.tryParse(_dateController.text) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
              }
            },
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
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedSupplierId,
            decoration: InputDecoration(
              labelText: "Supplier",
              prefixIcon: Icon(
                Icons.business,
                color: const Color(0xFF4a63c0),
                size: 20.sp,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 214, 215, 216),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: Color(0xFF4a63c0),
                  width: 1.0,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Select Supplier'),
              ),
              ...suppliers.entries.map(
                (e) =>
                    DropdownMenuItem<int>(value: e.key, child: Text(e.value)),
              ),
            ],
            onChanged: (v) => setState(() => _selectedSupplierId = v),
            validator: (v) => v == null ? "Select supplier" : null,
          ),

          const SizedBox(height: 16),
          const Text(
            "Manpower Details",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._dynamicRows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      isExpanded: true, // ⭐ important
                      value: row.typeId,
                      decoration: InputDecoration(
                        hintText: 'Type',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      items: _availableManpowerTypes.entries.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => row.typeId = v),
                      validator: (v) => v == null ? "Required" : null,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: row.countController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Count',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                  ),

                  const SizedBox(width: 4),

                  SizedBox(
                    width: 40, // ⭐ prevents overflow
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeRow(index),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Row'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4a63c0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (Provider.of<CompanySiteProvider>(
                context,
              ).hasPermission('manpower-type create'))
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addManpowerType,
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: const Text('ManpowerType'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4a63c0),
                      side: const BorderSide(color: Color(0xFF4a63c0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4a63c0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2a43a0),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.record == null ? "Create Record" : "Update Record",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4a63c0), size: 20),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Manpower Types Bottom Sheet (Modern & Simple UI)
class ManpowerTypesBottomSheet extends StatefulWidget {
  final VoidCallback? onTypesUpdated;
  final int? userId;
  final int? workspaceId;
  final int? siteId;

  const ManpowerTypesBottomSheet({
    super.key,
    this.onTypesUpdated,
    this.userId,
    this.workspaceId,
    this.siteId,
  });

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
        siteId: widget.siteId ?? 1,
        createdBy: widget.userId ?? 1,
        workspaceId: widget.workspaceId ?? 1,
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
                        TextField(
                          controller: editController,
                          decoration: InputDecoration(
                            hintText: 'Enter manpower type name',
                            prefixIcon: Icon(
                              Icons.work_outline,
                              color: Color(0xFF4a63c0),
                              size: 20.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
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
                          ),
                          style: const TextStyle(fontSize: 16),
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
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Type Name (e.g., Carpenter, Electrician)',
                      prefixIcon: Icon(
                        Icons.work_outline,
                        color: Color(0xFF4a63c0),
                        size: 20.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
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
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 14),

                  // Description Field (Optional)
                  TextField(
                    controller: _descriptionController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Description (Optional)',
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: Color(0xFF4a63c0),
                        size: 20.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
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
                    ),
                    style: const TextStyle(fontSize: 14),
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

class AddManpowerTypeBottomSheet extends StatefulWidget {
  final VoidCallback? onTypeAdded;
  final int siteId;
  final int workspaceId;
  final int userId;

  const AddManpowerTypeBottomSheet({
    super.key,
    this.onTypeAdded,
    required this.siteId,
    required this.workspaceId,
    required this.userId,
  });

  @override
  State<AddManpowerTypeBottomSheet> createState() =>
      _AddManpowerTypeBottomSheetState();
}

class _AddManpowerTypeBottomSheetState
    extends State<AddManpowerTypeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manpowerTypeService = ManpowerTypeService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // No longer need to load dropdown data for text field
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newType = ManpowerType(
        id: 0,
        name: _nameController.text.trim(),
        status: 1,
        siteId: widget.siteId,
        workspaceId: widget.workspaceId,
        createdBy: widget.userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdType = await _manpowerTypeService.createManpowerType(
        newType,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manpower type added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onTypeAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Manpower Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a43a0),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Manpower Type Name',
                  hintText: 'Enter manpower type name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.work_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2a43a0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Add',
                            style: TextStyle(color: Colors.white),
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
}
