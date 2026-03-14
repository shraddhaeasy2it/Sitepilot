import 'package:ecoteam_app/admin/models/consumptionLog_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecoteam_app/admin/services/consumption_services.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:ecoteam_app/contractor/services/report_services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

// Simple Project class for sites
class ConsumptionProject {
  final String id;
  final String name;

  ConsumptionProject({required this.id, required this.name});
}

class ConsumptionMaterialModel {
  final int id;
  final String name;
  final ConsumptionUnit? unit;
  final int? categoryId;
  final String? category;

  ConsumptionMaterialModel({
    required this.id,
    required this.name,
    this.unit,
    this.categoryId,
    this.category,
  });

  factory ConsumptionMaterialModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return ConsumptionMaterialModel(
      id: int.tryParse(id) ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      unit: json['unit'] != null
          ? ConsumptionUnit.fromJson(json['unit'])
          : null,
      categoryId: json['category_id'] != null
          ? int.tryParse(json['category_id'].toString())
          : null,
      category: json['category']?.toString(),
    );
  }
}

class ConsumptionUnit {
  final int id;
  final String name;

  ConsumptionUnit({required this.id, required this.name});

  factory ConsumptionUnit.fromJson(Map<String, dynamic> json) {
    return ConsumptionUnit(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      name: json['name']?.toString() ?? 'unit',
    );
  }
}

class ConsumptionMachinery {
  final int id;
  final String name;

  ConsumptionMachinery({required this.id, required this.name});
}

class ConsumptionLogPage extends StatefulWidget {
  final bool isEmbedded;
  final String? selectedSiteId;
  final int? userId;
  final int? activityId;
  final int? activityCompletedId;
  final bool isFormOnly;
  const ConsumptionLogPage({
    super.key,
    this.isEmbedded = false,
    this.selectedSiteId,
    this.userId,
    this.activityId,
    this.activityCompletedId,
    this.isFormOnly = false,
  });

  @override
  State<ConsumptionLogPage> createState() => _ConsumptionLogPageState();
}

class _ConsumptionLogPageState extends State<ConsumptionLogPage> {
  List<Consumption> consumptions = [];
  final List<Consumption> _allConsumptions = [];

  // API Configuration
  final ConsumptionService _consumptionService = ConsumptionService();

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Fuel', 'All Material'];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  // Data for form
  List<ConsumptionProject> _sites = [];
  List<ConsumptionMachinery> _machineries = [];
  List<ConsumptionMaterialModel> _materialsAll = [];
  List<ConsumptionMaterialModel> _materialsFuel = [];
  String? _nextConsumptionNumber;
  bool _isDataLoading = false;
  Timer? _permissionTimer;

  // For report
  DateTime _reportStartDate = DateTime.now();
  DateTime _reportEndDate = DateTime.now();
  List<Consumption> _reportRecords = [];
  Map<String, double> _reportDateTotals = {};
  int _reportTotalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadConsumptions();
    _loadFormData();

    // Auto-refresh permissions every 10 seconds
    _permissionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _refreshPermissions();
      }
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
    _permissionTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConsumptions() async {
    setState(() => _isLoading = true);

    try {
      final consumptionsData = await _consumptionService.getConsumptions();

      setState(() {
        _allConsumptions.clear();
        if (widget.selectedSiteId != null) {
          _allConsumptions.addAll(
            consumptionsData
                .where((c) => c.siteId == widget.selectedSiteId)
                .toList(),
          );
        } else {
          _allConsumptions.addAll(consumptionsData);
        }
        consumptions = _allConsumptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading data');
    }
  }

  @override
  void didUpdateWidget(ConsumptionLogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _loadConsumptions();
    }
  }

  Future<void> _loadFormData() async {
    setState(() => _isDataLoading = true);

    try {
      // Load all form data from create-data endpoint
      final formData = await _consumptionService.fetchCreateData();

      // Load sites from create-data response
      _sites = _parseSitesFromCreateData(formData);

      // Load machineries from create-data response
      _machineries = _parseMachineriesFromCreateData(formData);

      // Load materials from create-data response
      _materialsAll = _parseMaterialsFromCreateData(formData, 'materials_all');
      _materialsFuel = _parseMaterialsFromCreateData(
        formData,
        'materials_fuels',
      );

      // Extract next consumption number
      if (formData.containsKey('next_consumption_number')) {
        _nextConsumptionNumber = formData['next_consumption_number']?.toString();
      }

      setState(() => _isDataLoading = false);
    } catch (e) {
      setState(() => _isDataLoading = false);
      _showErrorSnackBar('Error loading form data');
    }
  }

  List<ConsumptionProject> _parseSitesFromCreateData(
    Map<String, dynamic> formData,
  ) {
    final List<ConsumptionProject> sites = [];

    if (formData.containsKey('sites')) {
      final sitesMap = formData['sites'] as Map<String, dynamic>;

      sitesMap.forEach((key, value) {
        sites.add(ConsumptionProject(id: key, name: value.toString()));
      });
    }

    // Add default site if empty
    if (sites.isEmpty) {
      sites.add(ConsumptionProject(id: '1', name: 'Default Site'));
    }

    return sites;
  }

  List<ConsumptionMachinery> _parseMachineriesFromCreateData(
    Map<String, dynamic> formData,
  ) {
    final List<ConsumptionMachinery> machineries = [];

    if (formData.containsKey('machinery_options')) {
      final machineryMap =
          formData['machinery_options'] as Map<String, dynamic>;

      machineryMap.forEach((key, value) {
        machineries.add(
          ConsumptionMachinery(
            id: int.tryParse(key) ?? 0,
            name: value.toString(),
          ),
        );
      });
    }

    // Add default machinery if empty
    if (machineries.isEmpty) {
      machineries.add(ConsumptionMachinery(id: 1, name: 'Default Machinery'));
    }

    // Sort by name for better UX
    machineries.sort((a, b) => a.name.compareTo(b.name));

    return machineries;
  }

  List<ConsumptionMaterialModel> _parseMaterialsFromCreateData(
    Map<String, dynamic> formData,
    String materialsKey,
  ) {
    final List<ConsumptionMaterialModel> materials = [];

    if (formData.containsKey(materialsKey)) {
      final materialsMap = formData[materialsKey] as Map<String, dynamic>;

      materialsMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          materials.add(ConsumptionMaterialModel.fromJson(value, key));
        }
      });
    }

    // Sort by name for better UX
    materials.sort((a, b) => a.name.compareTo(b.name));

    return materials;
  }

  DateTime _parseDate(String? dateString) {
    if (dateString == null) return DateTime.now();
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  void _filterConsumptions(String type) {
    setState(() {
      _selectedFilter = type;
      if (type == 'All') {
        consumptions = _allConsumptions;
      } else if (type == 'Fuel') {
        consumptions = _allConsumptions
            .where((c) => c.consumptionType.toLowerCase().contains('fuel'))
            .toList();
      } else if (type == 'All Material') {
        consumptions = _allConsumptions
            .where((c) => !c.consumptionType.toLowerCase().contains('fuel'))
            .toList();
      }
    });
  }

  Future<void> _addConsumption() async {
    if (_isDataLoading) {
      _showErrorSnackBar('Loading form data, please wait...');
      return;
    }

    final result = await showModalBottomSheet<Consumption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ConsumptionFormSheet(
            sites: _sites,
            machineries: _machineries,
            materialsAll: _materialsAll,
            materialsFuel: _materialsFuel,
            currentSiteId: widget.selectedSiteId,
            currentWorkspaceId: Provider.of<CompanySiteProvider>(
              context,
              listen: false,
            ).selectedCompanyId,
            nextConsumptionNumber: _nextConsumptionNumber,
            scrollController: scrollController,
          );
        },
      ),
    );

    if (result != null) {
      await _saveConsumptionToAPI(result);
    }
  }

  Future<void> _saveConsumptionToAPI(Consumption consumption) async {
    try {
      setState(() => _isLoading = true);

      // Prepare the request body according to your API structure
      final Map<String, dynamic> requestBody = {
        "consumption_date": consumption.consumptionDate.toIso8601String().split(
          'T',
        )[0],
        "site_id": int.parse(consumption.siteId ?? '1'),
        "consumption_type": consumption.consumptionType,
        "created_by": widget.userId ?? 1,
        "workspace_id":
            int.tryParse(
              Provider.of<CompanySiteProvider>(
                context,
                listen: false,
              ).selectedCompanyId ??
                  '1',
            ) ??
            1,
        "items":
            consumption.items
                ?.map(
                  (item) => {
                    "material_id": item.materialId ?? 8,
                    "quantity": item.quantity.toString(),
                    "unit": item.unit,
                    "remarks": consumption.remarks ?? "Added from app",
                  },
                )
                .toList() ??
            [],
        "remarks": consumption.remarks ?? "",
        "activity_id": consumption.activityId ?? widget.activityId,
        "activity_completed_id": widget.activityCompletedId,
      };

      // Add machinery fields only if they exist and consumption type is fuel
      if (consumption.consumptionType == 'fuel') {
        if (consumption.machineryType != null) {
          requestBody["machinery_type"] = consumption.machineryType;
        }
        if (consumption.machineryId != null) {
          requestBody["machinery_id"] = consumption.machineryId;
        }
      }

      print('Sending request: $requestBody');

      print('=== ADD CONSUMPTION REQUEST ===');
      print('activity_completed_id: ${widget.activityCompletedId}');
      print('Request body: $requestBody');

      final response = await _consumptionService.createConsumption(requestBody);
      print('=== ADD CONSUMPTION RESPONSE ===');
      print('Response: $response');
      print('================================');
      
      await _loadConsumptions();
      _showSuccessSnackBar('Consumption added successfully');
    } catch (e) {
      _showErrorSnackBar('Error adding consumption: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateConsumptionInAPI(Consumption consumption) async {
    try {
      setState(() => _isLoading = true);

      final Map<String, dynamic> requestBody = {
        "consumption_date": consumption.consumptionDate.toIso8601String().split(
          'T',
        )[0],
        "site_id": int.parse(consumption.siteId ?? '1'),
        "consumption_type": consumption.consumptionType,
        "created_by": widget.userId ?? 1,
        "workspace_id":
            int.tryParse(
              Provider.of<CompanySiteProvider>(
                context,
                listen: false,
              ).selectedCompanyId ??
                  '1',
            ) ??
            1,
        "items":
            consumption.items
                ?.map(
                  (item) => {
                    "material_id": item.materialId ?? 8,
                    "quantity": item.quantity.toString(),
                    "unit": item.unit,
                    "remarks": consumption.remarks ?? "Updated from app",
                  },
                )
                .toList() ??
            [],
        "remarks": consumption.remarks ?? "",
        "activity_id": consumption.activityId ?? widget.activityId,
        "activity_completed_id": widget.activityCompletedId,
      };

      // Add machinery fields only if they exist and consumption type is fuel
      if (consumption.consumptionType == 'fuel') {
        if (consumption.machineryType != null) {
          requestBody["machinery_type"] = consumption.machineryType;
        }
        if (consumption.machineryId != null) {
          requestBody["machinery_id"] = consumption.machineryId;
        }
      }

      print('Sending update request: $requestBody');

      final response = await _consumptionService.updateConsumption(
        consumption.id,
        requestBody,
      );
      print('API Response (Update): $response');

      await _loadConsumptions();
      _showSuccessSnackBar('Consumption updated successfully');
    } catch (e) {
      _showErrorSnackBar('Error updating consumption: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteConsumptionFromAPI(Consumption consumption) async {
    try {
      setState(() => _isLoading = true);

      await _consumptionService.deleteConsumption(consumption.id);
      await _loadConsumptions();
      _showSuccessSnackBar('Consumption deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Error deleting consumption: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _viewConsumption(Consumption consumption) async {
    if (_isDataLoading) {
      _showErrorSnackBar('Loading form data, please wait...');
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ConsumptionFormSheet(
            consumption: consumption,
            sites: _sites,
            machineries: _machineries,
            materialsAll: _materialsAll,
            materialsFuel: _materialsFuel,
            isViewMode: true,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  void _editConsumption(Consumption consumption) async {
    if (_isDataLoading) {
      _showErrorSnackBar('Loading form data, please wait...');
      return;
    }

    final result = await showModalBottomSheet<Consumption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ConsumptionFormSheet(
            consumption: consumption,
            sites: _sites,
            machineries: _machineries,
            materialsAll: _materialsAll,
            materialsFuel: _materialsFuel,
            currentSiteId: widget.selectedSiteId,
            currentWorkspaceId: Provider.of<CompanySiteProvider>(
              context,
              listen: false,
            ).selectedCompanyId,
            nextConsumptionNumber: _nextConsumptionNumber,
            scrollController: scrollController,
          );
        },
      ),
    );

    if (result != null) {
      await _updateConsumptionInAPI(result);
    }
  }

  void _deleteConsumption(Consumption consumption) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Consumption',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${consumption.consumptionNo}?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteConsumptionFromAPI(consumption);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ==================== PDF REPORT FUNCTIONALITY ====================

  Future<void> _generateReport() async {
    // Initialize report with default values (Current Month to Today)
    final now = DateTime.now();
    _reportStartDate = DateTime(now.year, now.month, 1);
    _reportEndDate = now;

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
    // Filter records by date range, using the currently filtered list (consumptions)
    _reportRecords = consumptions.where((consumption) {
      
      final consumptionDate = consumption.consumptionDate;
      return (consumptionDate.isAtSameMomentAs(_reportStartDate) ||
              consumptionDate.isAfter(_reportStartDate)) &&
          (consumptionDate.isAtSameMomentAs(_reportEndDate) ||
              consumptionDate.isBefore(
                _reportEndDate.add(const Duration(days: 1)),
              ));
    }).toList();

    // Calculate totals
    _reportTotalCount = _reportRecords.length;
    _reportDateTotals.clear();
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
          height: screenHeight * 0.60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Consumption Report',
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
                  const Text('to', style: TextStyle(fontSize: 14),),
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

              const SizedBox(height: 20),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFf8f9fa),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Records Found:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$_reportTotalCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2a43a0),
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
                ],
              ),
              // // Download Button
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton.icon(
              //     onPressed: _reportTotalCount > 0
              //         ? () {
              //             _downloadPDF();
              //           }
              //         : null,
              //     icon: const Icon(Icons.download, color: Colors.white),
              //     label: const Text(
              //       'Download PDF Report',
              //       style: TextStyle(color: Colors.white, fontSize: 16),
              //     ),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: const Color(0xFF2a43a0),
              //       padding: const EdgeInsets.symmetric(vertical: 16),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 10),
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

      // Prepare data for ReportService
      final List<Map<String, dynamic>> data = _reportRecords.map((c) {
        String material = '';
        String quantity = '';
        if (c.items != null && c.items!.isNotEmpty) {
          material = c.items!.map((i) => i.material).join(', ');
          quantity = c.items!.map((i) => '${i.quantity} ${i.unit}').join(', ');
        }

        return {
          'consumptionNo': c.consumptionNo,
          'date': DateFormat('yyyy-MM-dd').format(c.consumptionDate),
          'type': c.consumptionType.toUpperCase(),
          'material': material,
          'quantity': quantity,
          'remarks': c.remarks ?? '',
        };
      }).toList();

      final siteName = _sites
          .firstWhere(
            (s) => s.id == widget.selectedSiteId,
            orElse: () => ConsumptionProject(id: '0', name: 'All Sites'),
          )
          .name;

      // Generate PDF bytes
      final List<int> bytes = await ReportService.generateConsumptionPDF(
        data,
        siteName,
        _reportStartDate,
        _reportEndDate,
        filterType: _selectedFilter
      );

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final safeSiteName = siteName.replaceAll(' ', '_');
      final fileName =
          'consumption_report_${safeSiteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes, flush: true);

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

  Future<void> _downloadPDF() async {
    try {
      if (Platform.isAndroid) {
        await _requestStoragePermission();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      // ReportService expects List<Map<String, dynamic>>
      final List<Map<String, dynamic>> data = _reportRecords.map((c) {
        String material = '';
        String quantity = '';
        if (c.items != null && c.items!.isNotEmpty) {
          material = c.items!.map((i) => i.material).join(', ');
          quantity = c.items!.map((i) => '${i.quantity} ${i.unit}').join(', ');
        }

        return {
          'consumptionNo': c.consumptionNo,
          'date': DateFormat('yyyy-MM-dd').format(c.consumptionDate),
          'type': c.consumptionType.toUpperCase(),
          'material': material,
          'quantity': quantity,
          'remarks': c.remarks ?? '',
        };
      }).toList();

      final siteName = _sites.firstWhere(
        (s) => s.id == widget.selectedSiteId,
        orElse: () => ConsumptionProject(id: '0', name: 'All Sites'),
      ).name;

      final List<int> bytes = await ReportService.generateConsumptionPDF(
        data,
        siteName,
        _reportStartDate,
        _reportEndDate,
      );

      final directory = await _getDownloadDirectory();
      final safeSiteName = siteName.replaceAll(' ', '_');
      final fileName = 'consumption_report_${safeSiteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes, flush: true);

      // Open file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to ${file.path}'),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );

      await OpenFile.open(file.path);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return;
      }
      
      // Keep checking for manageExternalStorage if storage failed (Android 11+)
      if (await Permission.manageExternalStorage.request().isGranted) {
        return;
      }
    }
  }
 
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        bool hasPermission = await Permission.storage.isGranted || 
                             await Permission.manageExternalStorage.isGranted;
        
        if (hasPermission) {
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

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search consumption logs...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(11),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          _performSearch(value);
                        },
                      ),
                    ),
                  ),
                  if (widget.isEmbedded) ...[],
                ],
              ),
            ],
          ),
        ),

        // Export Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                 'Records: ${consumptions.length}',
                 style: TextStyle(
                   color: Colors.grey.shade600,
                   fontSize: 14,
                   fontWeight: FontWeight.w500,
                 )
               ),
               if (Provider.of<CompanySiteProvider>(context).hasPermission('consumption-log show')) // Using show/export permission
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
        SizedBox(height: 10.h),
        // Consumption List
        Expanded(
          child: _isLoading
              ? _buildLoadingIndicator()
              : consumptions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: consumptions.length,
                  itemBuilder: (context, index) {
                    final consumption = consumptions[index];
                    return ConsumptionCard(
                      consumption: consumption,
                      onShowOptions: () => _showOptionsBottomSheet(consumption),
                      isLast: index == consumptions.length - 1,
                    );
                  },
                ),
        ),
      ],
    );

   if (widget.isEmbedded) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: content,

    // floatingActionButton:
    //     Provider.of<CompanySiteProvider>(
    //       context,
    //     ).hasPermission('consumption-log create')
    //     ? FloatingActionButton(
    //         onPressed: _addConsumption,
    //         child: const Icon(Icons.add, color: Colors.white),
    //         backgroundColor: const Color.fromRGBO(42, 67, 160, 1),
    //         tooltip: 'Add consumption',
    //       )
    //     : null,F
  );
}

    if (widget.isFormOnly) {
      return Scaffold(
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
        "Add Consumption",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 4.h),

      /// Optional subtitle (remove if not needed)
      Text(
        "Daily Progress Report",
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 13.sp,
          fontWeight: FontWeight.w400,
        ),
      ),
    ],
  ),

  iconTheme: const IconThemeData(color: Colors.white),

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
    ),
  ),
),
        body: _isDataLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ConsumptionFormSheet(
                  sites: _sites,
                  machineries: _machineries,
                  materialsAll: _materialsAll,
                  materialsFuel: _materialsFuel,
                  currentSiteId: widget.selectedSiteId,
                  currentWorkspaceId: Provider.of<CompanySiteProvider>(
                    context,
                    listen: false,
                  ).selectedCompanyId,
                  nextConsumptionNumber: _nextConsumptionNumber,
                  onSave: (consumption) async {
                    await _saveConsumptionToAPI(consumption);
                    if (mounted) Navigator.pop(context);
                  },
                  isPage: true,
                  activityId: widget.activityId,
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Manage Consumption Log',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
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
        centerTitle: false,
      ),

      body: content,
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _filterConsumptions(_selectedFilter);
    } else {
      final filtered = _allConsumptions.where((consumption) {
        return consumption.consumptionNo.toLowerCase().contains(
              query.toLowerCase(),
            ) ||
            consumption.site.toLowerCase().contains(query.toLowerCase()) ||
            (consumption.items?.any(
                  (item) =>
                      item.material.toLowerCase().contains(query.toLowerCase()),
                ) ??
                false);
      }).toList();

      setState(() {
        consumptions = filtered;
      });
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading consumption logs...',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No consumption logs found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new consumption log to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color Iconcolor,
    required String title,
    Color? backgroundColor,
    required VoidCallback onTap,
    Color color = const Color(0xFF2D3748),
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF6f88e2).withOpacity(0.1),
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

  void _showOptionsBottomSheet(Consumption consumption) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
                listen: false,
              ).hasPermission('consumption-log show'))
                _buildOptionTile(
                  icon: Icons.visibility_outlined,
                  title: 'View Details',
                  Iconcolor: const Color.fromARGB(255, 37, 49, 158),
                  backgroundColor: const Color.fromARGB(
                    255,
                    37,
                    49,
                    158,
                  ).withOpacity(0.1),
                  onTap: () {
                    Navigator.pop(context);
                    _viewConsumption(consumption);
                  },
                ),
              // if (Provider.of<CompanySiteProvider>(
              //   context,
              //   listen: false,
              // ).hasPermission('consumption-log edit'))
              //   _buildOptionTile(
              //     icon: Icons.edit,
              //     title: 'Edit',
              //     Iconcolor: Colors.blue,
              //     backgroundColor: Colors.blue.withOpacity(0.1),
              //     onTap: () {
              //       Navigator.pop(context);
              //       _editConsumption(consumption);
              //     },
              //   ),
              if (Provider.of<CompanySiteProvider>(
                context,
                listen: false,
              ).hasPermission('consumption-log delete'))
                _buildOptionTile(
                  icon: Icons.delete,
                  title: 'Delete',
                  Iconcolor: Colors.red,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteConsumption(consumption);
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class ConsumptionCard extends StatelessWidget {
  final Consumption consumption;
  final VoidCallback onShowOptions;
  final bool isLast;

  const ConsumptionCard({
    super.key,
    required this.consumption,
    required this.onShowOptions,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isFuel = consumption.consumptionType.toLowerCase().contains('fuel');
    
    // Colors matching StockTab / App Theme
    const Color primaryColor = Color(0xFF4a63c0);
    const Color cardColor = Colors.white;

    return Card(
      margin: EdgeInsets.only(bottom: 9.h, left: 16.w, right: 16.w),
      color: cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22.r,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.receipt_long,
                color: primaryColor,
                size: 19.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          consumption.consumptionNo,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 41, 41, 41),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (Provider.of<CompanySiteProvider>(
                            context,
                          ).hasPermission('consumption-log show') ||
                          Provider.of<CompanySiteProvider>(
                            context,
                          ).hasPermission('consumption-log edit') ||
                          Provider.of<CompanySiteProvider>(
                            context,
                          ).hasPermission('consumption-log delete'))
                        InkWell(
                          onTap: onShowOptions,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.grey.shade600,
                              size: 20.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),

                  // Footer: Type | Date | Machinery(opt)
                  Row(
                    children: [
                      Text(
                        isFuel ? 'Fuel' : 'Material',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isFuel
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(' • ', style: TextStyle(color: Colors.grey[400])),
                      Text(
                        _formatDate(consumption.consumptionDate),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      
                    ],
                  ),

                  // File Attachment Indicator
                  if (consumption.consumptionFile != 'N/A') ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 14.sp,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            consumption.consumptionFile,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class ConsumptionFormSheet extends StatefulWidget {
  final Consumption? consumption;
  final List<ConsumptionProject> sites;
  final List<ConsumptionMachinery> machineries;
  final List<ConsumptionMaterialModel> materialsAll;
  final List<ConsumptionMaterialModel> materialsFuel;
  final Function(Consumption)? onSave;
  final bool isViewMode;
  final String? currentSiteId;
  final String? currentWorkspaceId;
  final String? nextConsumptionNumber;
  final int? activityId;
  final bool isPage;
  final ScrollController? scrollController;

  const ConsumptionFormSheet({
    super.key,
    this.consumption,
    required this.sites,
    required this.machineries,
    required this.materialsAll,
    required this.materialsFuel,
    this.onSave,
    this.isViewMode = false,
    this.currentSiteId,
    this.currentWorkspaceId,
    this.nextConsumptionNumber,
    this.activityId,
    this.isPage = false,
    this.scrollController,
  });

  @override
  State<ConsumptionFormSheet> createState() => _ConsumptionFormSheetState();
}

class _ConsumptionFormSheetState extends State<ConsumptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final List<ConsumptionItem> _items = [];

  // Form controllers
  final TextEditingController _consumptionNoController =
      TextEditingController();
  final TextEditingController _consumptionDateController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String _selectedConsumptionType = 'All Material';
  String? _selectedSiteId;
  String? _selectedMachineryType;
  int? _selectedMachineryId;

  final List<String> _consumptionTypes = ['All Material'];
  final List<String> _machineryTypes = ['own', 'rental'];

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : s;

  // Item fields controllers (for multiple items)
  final List<TextEditingController> _quantityControllers = [];
  final List<int?> _selectedMaterialIds = [];
  final List<String> _selectedUnits = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.consumption != null) {
      // Edit mode - populate fields
      final consumption = widget.consumption!;
      _consumptionNoController.text = consumption.consumptionNo;
      _consumptionDateController.text = _formatDate(
        consumption.consumptionDate,
      );

      // Set consumption type to 'All Material' (hiding Fuel option as requested)
      _selectedConsumptionType = 'All Material';

      // Set site ID - ensure it's in the list
      // For Edit, normally we keep existing site, but user requested 'take current site'
      // If we strictly follow "when add, edit ... take current site", we overwrite it.
      // But usually specific records belong to specific sites.
      // However, if the site dropdown is gone, we can't change it.
      // If existing site is different from current selected site, it might be confusing.
      // But assuming the context is filtered by site, they should be same.
      _selectedSiteId = widget.currentSiteId ?? _findSiteId(consumption);
      _remarksController.text = consumption.remarks ?? '';

      // Set machinery fields only if consumption type is Fuel
      if (_selectedConsumptionType == 'Fuel') {
        _selectedMachineryType = consumption.machineryType?.toLowerCase();
        _selectedMachineryId = consumption.machineryId;
        if (_selectedMachineryId != null &&
            !widget.machineries.any((m) => m.id == _selectedMachineryId)) {
          _selectedMachineryId = null;
        }
      }

      // Initialize items
      if (consumption.items != null && consumption.items!.isNotEmpty) {
        for (var item in consumption.items!) {
          _quantityControllers.add(
            TextEditingController(text: item.quantity.toString()),
          );
          _selectedMaterialIds.add(item.materialId);
          _selectedUnits.add(item.unit);
        }
        // Check if materials are in the current list
        for (int i = 0; i < _selectedMaterialIds.length; i++) {
          final currentMaterials = _selectedConsumptionType == 'Fuel'
              ? widget.materialsFuel
              : widget.materialsAll;
          if (_selectedMaterialIds[i] != null &&
              !currentMaterials.any((m) => m.id == _selectedMaterialIds[i])) {
            _selectedMaterialIds[i] = null;
            _selectedUnits[i] = 'unit';
          }
        }
      } else {
        // Add one empty item field by default
        _addNewItemField();
      }
    } else {
      // Add mode - set default values
      _consumptionNoController.text = widget.nextConsumptionNumber ?? 'DCM-0011';
      _consumptionDateController.text = _formatDate(DateTime.now());
      _selectedSiteId = widget.currentSiteId;
      // Add one empty item field by default
      _addNewItemField();
    }
  }

  String? _findSiteId(Consumption consumption) {
    if (consumption.siteId != null &&
        widget.sites.any((s) => s.id == consumption.siteId)) {
      return consumption.siteId;
    }

    // Try to find by name
    final matchingSite = widget.sites.firstWhere(
      (s) => s.name == consumption.site,
      orElse: () => widget.sites.isNotEmpty
          ? widget.sites.first
          : ConsumptionProject(id: '1', name: 'Default Site'),
    );

    return matchingSite.id;
  }

  int? _findMachineryId(Consumption consumption) {
    if (consumption.machineryId != null &&
        widget.machineries.any((m) => m.id == consumption.machineryId)) {
      return consumption.machineryId;
    }

    // Try to find by name
    if (consumption.machinery != null) {
      final matchingMachinery = widget.machineries.firstWhere(
        (m) => m.name == consumption.machinery,
        orElse: () => widget.machineries.isNotEmpty
            ? widget.machineries.first
            : ConsumptionMachinery(id: 1, name: 'Default Machinery'),
      );
      return matchingMachinery.id;
    }

    return widget.machineries.isNotEmpty ? widget.machineries.first.id : null;
  }

  void _addNewItemField() {
    setState(() {
      _quantityControllers.add(TextEditingController());
      _selectedMaterialIds.add(null);
      _selectedUnits.add('unit');
    });
  }

  void _removeItemField(int index) {
    setState(() {
      if (_quantityControllers.length > index) {
        _quantityControllers.removeAt(index);
      }
      if (_selectedMaterialIds.length > index) {
        _selectedMaterialIds.removeAt(index);
      }
      if (_selectedUnits.length > index) {
        _selectedUnits.removeAt(index);
      }
      if (_items.length > index) {
        _items.removeAt(index);
      }
    });
  }

  void _onMaterialChanged(int? newValue, int index) {
    if (newValue != null) {
      final currentMaterials = _selectedConsumptionType == 'Fuel'
          ? widget.materialsFuel
          : widget.materialsAll;
      final selectedMaterial = currentMaterials.firstWhere(
        (m) => m.id == newValue,
      );

      setState(() {
        _selectedMaterialIds[index] = newValue;
        _selectedUnits[index] = selectedMaterial.unit?.name ?? 'unit';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedSiteId != null) {
      // Validate items
      for (int i = 0; i < _quantityControllers.length; i++) {
        if (_selectedMaterialIds[i] == null ||
            _quantityControllers[i].text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all item fields')),
          );
          return;
        }
      }

      // Build items list
      final List<ConsumptionItem> items = [];
      final currentMaterials = _selectedConsumptionType == 'Fuel'
          ? widget.materialsFuel
          : widget.materialsAll;

      for (int i = 0; i < _quantityControllers.length; i++) {
        final materialId = _selectedMaterialIds[i];
        if (materialId != null) {
          final material = currentMaterials.firstWhere(
            (m) => m.id == materialId,
          );
          items.add(
            ConsumptionItem(
              material: material.name,
              quantity: double.parse(_quantityControllers[i].text),
              unit: _selectedUnits[i],
              materialId: materialId,
            ),
          );
        }
      }

      // For rental machinery type, clear machinery selection
      if (_selectedConsumptionType == 'Fuel' &&
          _selectedMachineryType == 'rental') {
        _selectedMachineryId = null;
      }

      final siteName = widget.sites
          .firstWhere((s) => s.id == _selectedSiteId)
          .name;
      final machineryName = _selectedMachineryId != null
          ? widget.machineries
                .firstWhere((m) => m.id == _selectedMachineryId)
                .name
          : null;

      final consumption = Consumption(
        id: widget.consumption?.id ?? 0,
        consumptionNo: _consumptionNoController.text,
        consumptionDate: _parseDate(_consumptionDateController.text),
        consumptionType: _selectedConsumptionType == 'Fuel' ? 'fuel' : 'all',
        site: siteName,
        consumptionFile: 'N/A',
        remarks: _remarksController.text.isEmpty
            ? null
            : _remarksController.text,
        items: items.isEmpty ? null : items,
        machineryType: _selectedConsumptionType == 'Fuel'
            ? _selectedMachineryType?.toLowerCase()
            : null,
        machinery: _selectedConsumptionType == 'Fuel' ? machineryName : null,
        siteId: _selectedSiteId,
        machineryId: _selectedConsumptionType == 'Fuel'
            ? _selectedMachineryId
            : null,
        activityId: widget.activityId,
      );

      if (widget.onSave != null) {
        await widget.onSave!(consumption);
      } else {
        Navigator.pop(context, consumption);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  DateTime _parseDate(String dateString) {
    final parts = dateString.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_consumptionDateController.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _consumptionDateController.text = _formatDate(picked);
      });
    }
  }

  void _onConsumptionTypeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedConsumptionType = newValue;

        // Reset machinery fields when switching from Fuel to All Material
        if (newValue == 'All Material') {
          _selectedMachineryType = null;
          _selectedMachineryId = null;
        }

        // Reset material selections
        for (int i = 0; i < _selectedMaterialIds.length; i++) {
          _selectedMaterialIds[i] = null;
          _selectedUnits[i] = 'unit';
        }
      });
    }
  }

  Widget _buildItemField(int index) {
    final currentMaterials = _selectedConsumptionType == 'Fuel'
        ? (widget.materialsFuel.isNotEmpty
              ? widget.materialsFuel
              : widget.materialsAll)
        : widget.materialsAll;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_quantityControllers.length > 1 && !widget.isViewMode)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _removeItemField(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _selectedMaterialIds[index],
              decoration: InputDecoration(
                labelText: 'Material *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    10,
                  ), // or any value you prefer
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Select Material'),
                ),
                ...currentMaterials.map((ConsumptionMaterialModel material) {
                  return DropdownMenuItem<int?>(
                    value: material.id,
                    child: Text(material.name),
                  );
                }).toList(),
              ],
              onChanged: widget.isViewMode
                  ? null
                  : (value) => _onMaterialChanged(value, index),
              validator: widget.isViewMode
                  ? null
                  : (value) {
                      if (value == null) {
                        return 'Please select material';
                      }
                      return null;
                    },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityControllers[index],
                    keyboardType: TextInputType.number,
                    readOnly: widget.isViewMode,
                    decoration: InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // or any value you prefer
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    validator: widget.isViewMode
                        ? null
                        : (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _selectedUnits[index],
                    ),
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // or any value you prefer
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineryTypeField() {
    return DropdownButtonFormField<String?>(
      value: _selectedMachineryType,
      decoration: InputDecoration(
        labelText: 'Machinery Type *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // or any value you prefer
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Select Machinery Type'),
        ),
        ..._machineryTypes.map((String type) {
          return DropdownMenuItem<String?>(
            value: type,
            child: Text(_capitalize(type)),
          );
        }).toList(),
      ],
      onChanged: widget.isViewMode
          ? null
          : (String? newValue) {
              setState(() {
                _selectedMachineryType = newValue;
                // Reset machinery selection when type changes
                _selectedMachineryId = null;
              });
            },
    );
  }

  Widget _buildMachineryField() {
    return DropdownButtonFormField<int?>(
      value: _selectedMachineryId,
      decoration: InputDecoration(
        labelText: 'Machinery *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // or any value you prefer
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Select Machinery'),
        ),
        ...widget.machineries.map((ConsumptionMachinery machinery) {
          return DropdownMenuItem<int?>(
            value: machinery.id,
            child: Text(machinery.name),
          );
        }).toList(),
      ],
      onChanged: widget.isViewMode
          ? null
          : (int? newValue) {
              setState(() {
                _selectedMachineryId = newValue;
              });
            },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildItemView(int index) {
    final currentMaterials = _selectedConsumptionType == 'Fuel'
        ? widget.materialsFuel
        : widget.materialsAll;
    final material = _selectedMaterialIds[index] != null
        ? currentMaterials.firstWhere(
            (m) => m.id == _selectedMaterialIds[index],
            orElse: () => ConsumptionMaterialModel(id: 0, name: 'Unknown'),
          )
        : ConsumptionMaterialModel(id: 0, name: 'Unknown');

    return Card(
      margin: const EdgeInsets.only(bottom: 2),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildInfoRow('Material', material.name),
            _buildInfoRow(
              'Quantity',
              '${_quantityControllers[index].text} ${material.unit?.name ?? 'unit'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewContent() {
    final showMachineryFields = _selectedConsumptionType == 'Fuel';
    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Consumption Number', _consumptionNoController.text),
          _buildInfoRow('Consumption Date', _consumptionDateController.text),
          _buildInfoRow('Consumption Type', _selectedConsumptionType),
          _buildInfoRow(
            'Site',
            widget.sites
                .firstWhere(
                  (s) => s.id == _selectedSiteId,
                  orElse: () => ConsumptionProject(id: '', name: 'Unknown'),
                )
                .name,
          ),
          if (showMachineryFields) ...[
            _buildInfoRow(
              'Machinery Type',
              _selectedMachineryType != null
                  ? _capitalize(_selectedMachineryType!)
                  : 'N/A',
            ),
            if (_selectedMachineryType == 'own')
              _buildInfoRow(
                'Machinery',
                _selectedMachineryId != null
                    ? widget.machineries
                          .firstWhere(
                            (m) => m.id == _selectedMachineryId,
                            orElse: () =>
                                ConsumptionMachinery(id: 0, name: 'Unknown'),
                          )
                          .name
                    : 'N/A',
              ),
          ],
          const SizedBox(height: 19),
          const Text(
            'Consumption Items',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          ...List.generate(
            _quantityControllers.length,
            (index) => _buildItemView(index),
          ),
          if (_remarksController.text.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildInfoRow('Remarks', _remarksController.text),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.consumption != null;
    final showMachineryFields = _selectedConsumptionType == 'Fuel';

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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFF4a63c0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isViewMode
                          ? Icons.visibility_outlined
                          : (isEdit ? Icons.edit : Icons.add_box),
                      color: Color(0xFF4a63c0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isViewMode
                              ? 'View Consumption'
                              : (isEdit ? 'Edit Consumption' : 'Add Consumption'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          widget.isViewMode
                              ? 'Details of consumption log'
                              : (isEdit
                                  ? 'Update consumption details'
                                  : 'Enter consumption details below'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (!widget.isPage)
          const SizedBox(height: 16),
          if (!widget.isPage)
          Divider(height: 1, color: Colors.grey[300]),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: widget.isViewMode
                  ? _buildViewContent()
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        controller: widget.scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            // Consumption Number
                        TextFormField(
                          controller: _consumptionNoController,
                          readOnly: widget.isViewMode,
                          decoration: InputDecoration(
                            labelText: 'Consumption Number *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          validator: widget.isViewMode
                              ? null
                              : (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter consumption number';
                                  }
                                  return null;
                                },
                        ),
                        const SizedBox(height: 10),

                        // Consumption Type - HIDDEN and fixed to 'All Material'
                        /* 
                        DropdownButtonFormField<String>(
                          value: _selectedConsumptionType,
                          decoration: InputDecoration(
                            labelText: 'Consumption Type *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: _consumptionTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: widget.isViewMode
                              ? null
                              : _onConsumptionTypeChanged,
                          validator: widget.isViewMode
                              ? null
                              : (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select consumption type';
                                  }
                                  return null;
                                },
                        ),
                        const SizedBox(height: 10),
                        */

                        // Consumption Date
                        TextFormField(
                          controller: _consumptionDateController,
                          decoration: InputDecoration(
                            labelText: 'Consumption Date *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                            suffixIcon: Icon(Icons.calendar_today),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          readOnly: true,
                          onTap: widget.isViewMode ? null : _selectDate,
                          validator: widget.isViewMode
                              ? null
                              : (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select consumption date';
                                  }
                                  return null;
                                },
                        ),
                        const SizedBox(height: 10),

                      

                       

                        // Machinery Type (only for Fuel) - REQUIRED
                        if (showMachineryFields) ...[
                          _buildMachineryTypeField(),
                          const SizedBox(height: 10),
                        ],

                        // Machinery (only for Fuel and Own type)
                        if (showMachineryFields &&
                            _selectedMachineryType == 'own') ...[
                          _buildMachineryField(),
                          const SizedBox(height: 10),
                        ],

                       
                        // Items Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Consumption Items',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!widget.isViewMode)
                              IconButton(
                                onPressed: _addNewItemField,
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF4A63C0),
                                        const Color(0xFF2A43A0)
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
                                tooltip: 'Add New Item',
                              ),
                          ],
                        ),

                        // Dynamic Item Fields
                        ...List.generate(
                          _quantityControllers.length,
                          (index) => _buildItemField(index),
                        ),

                        // Add Item Button
                       

                        // Remarks
                        TextFormField(
                          controller: _remarksController,
                          maxLines: 2,
                          readOnly: widget.isViewMode,
                          decoration: InputDecoration(
                            labelText: 'Remarks',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // or any value you prefer
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),

    
    const SizedBox(height: 14),
    if (!widget.isViewMode)
      SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2a43a0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isEdit ? 'Update' : 'Add',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 16)),
            ),
          ),
        const SizedBox(height: 14),
        ],
      ),
    );
    
  }
}
