import 'package:ecoteam_app/admin/models/DPR_model.dart';
import 'package:ecoteam_app/admin/services/DPR_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../contractor/models/site_model.dart';

class AdminDPRScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final String token;
  final int workspaceId;
  final int createdBy;

  const AdminDPRScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    required this.token,
    required this.workspaceId,
    required this.createdBy,
  });

  @override
  State<AdminDPRScreen> createState() => _AdminDPRScreenState();
}

class _AdminDPRScreenState extends State<AdminDPRScreen> {
  List<DPRModel> _dprList = [];
  List<DPRModel> _filteredList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with date and action buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Date + text in column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dpr.formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2a43a0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Machinery Readings',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),

                // Right side: Edit & Delete in row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: const Color(0xFF2a43a0),
                      onPressed: () => _showEditDPRBottomSheet(dpr),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: () => _showDeleteDPRDialog(dpr),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date and action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [],
            ),
            const SizedBox(height: 4),

            // Start Reading and End Reading row
            Row(
              children: [
                const Icon(Icons.speed, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Start: ${dpr.machineStartReading}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'End: ${dpr.machineEndReading}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Machine Hours and Operators row
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hours: ${dpr.machineHours.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Operators: ${dpr.numberOfOperators}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Diesel and Machinery Advances row
            Row(
              children: [
                const Icon(
                  Icons.local_gas_station,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Diesel: ${dpr.dieselConsumption}L',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Advance: ${dpr.machineryAdvances}',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Work Details section
            if (dpr.workDetails.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Work Details: ${dpr.workDetails}',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Maintenance Notes section
            if (dpr.maintenanceNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.build, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maintenance Notes: ${dpr.maintenanceNotes}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                       
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
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
                          color: textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Machine Hours: ${_totalMachineHours.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Total Diesel: ${_totalDieselConsumption.toStringAsFixed(2)}L',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
