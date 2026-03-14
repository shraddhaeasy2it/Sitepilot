import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/admin/models/DPR_model.dart';
import 'package:ecoteam_app/admin/services/DPR_services.dart';

class AddEditDPRScreen extends StatefulWidget {
  final DPRModel? dpr;
  final String token;
  final int workspaceId;
  final int createdBy;
  final int? preselectedSiteId;
  final String? siteName;
  final int? activityId;
  final int? activityCompletedId;
  final VoidCallback? onDPRSaved;

  const AddEditDPRScreen({
    super.key,
    this.dpr,
    required this.token,
    required this.workspaceId,
    required this.createdBy,
    this.preselectedSiteId,
    this.siteName,
    this.activityId,
    this.activityCompletedId,
    this.onDPRSaved,
  });

  @override
  State<AddEditDPRScreen> createState() => _AddEditDPRScreenState();
}

class _AddEditDPRScreenState extends State<AddEditDPRScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startReadingController = TextEditingController();
  final TextEditingController _endReadingController = TextEditingController();
  final TextEditingController _operatorsController = TextEditingController();
  final TextEditingController _workDetailsController = TextEditingController();
  final TextEditingController _maintenanceController = TextEditingController();

  DateTime? _selectedDate;
  bool _isSubmitting = false;
  List<dynamic> _machineryList = [];
  List<dynamic> _materialsList = [];
  int? _selectedMachineryId;
  String? _ownedByValue;
  String? _machineryError;
  bool _isLoadingMachinery = false;

  List<DPRItem> _items = [];
  File? _referenceFile;
  String? _fileName;

  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color backgroundColor = Color(0xFFf8f9fa);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _loadMachineryData();

    if (widget.dpr != null) {
      _dateController.text = widget.dpr!.date;
      _startReadingController.text = widget.dpr!.machineStartReading.toString();
      _endReadingController.text = widget.dpr!.machineEndReading.toString();
      _operatorsController.text = widget.dpr!.numberOfOperators.toString();
      _workDetailsController.text = widget.dpr!.workDetails;
      _maintenanceController.text = widget.dpr!.maintenanceNotes;
      _selectedDate = DateTime.parse(widget.dpr!.date);
      _selectedMachineryId = widget.dpr!.machineryId != 0
          ? widget.dpr!.machineryId
          : null;
      _items = List.from(widget.dpr!.items);
    } else {
      _selectedDate = DateTime.now();
      _dateController.text = _formatDateForDisplay(_selectedDate!);
      _operatorsController.text = '1';
    }
  }

  Future<void> _loadMachineryData() async {
    setState(() => _isLoadingMachinery = true);
    try {
      final response = await DPRService.fetchCreateData(
        siteId: widget.preselectedSiteId ?? 0,
        workspaceId: widget.workspaceId,
        createdBy: widget.createdBy,
      );

      if (mounted) {
        setState(() {
          _machineryList = response['machinery'] ?? [];
          _materialsList = response['materials'] ?? [];

          if (widget.dpr != null) {
            if (_selectedMachineryId != null) {
              final machinery = _machineryList.firstWhere(
                (m) => m['id'] == _selectedMachineryId,
                orElse: () => null,
              );
              if (machinery != null) {
                _ownedByValue = machinery['owned_by']?.toString();
              }
            }

            for (var item in _items) {
              final material = _materialsList.firstWhere(
                (m) => m['id'] == item.materialId,
                orElse: () => null,
              );
              if (material != null) {
                if (material['current_stock'] != null) {
                  item.currentStock = (material['current_stock'] as num)
                      .toDouble();
                }

                if (material['unit'] != null &&
                    material['unit']['name'] != null &&
                    item.unit.isEmpty) {
                  item.unit = material['unit']['name'];
                }
              }
            }
          }

          _isLoadingMachinery = false;
        });
      }
    } catch (e) {
      print('Error loading machinery: $e');
      if (mounted) {
        setState(() => _isLoadingMachinery = false);
      }
    }
  }

  void _addItem() {
    setState(() {
      _items.add(DPRItem(quantity: 0, unit: '', remarks: ''));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _pickFile() async {
    // Requires file_picker dependency implementation
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
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? '*' : ''),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color.fromARGB(255, 55, 68, 92),
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
            maxLines: maxLines ?? 1,
            minLines: 1,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
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
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
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

  Widget _buildItemRow(int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  value: _materialsList.any((m) => m['id'] == item.materialId)
                      ? item.materialId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Material',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: _materialsList.map((m) {
                    return DropdownMenuItem<int>(
                      value: m['id'],
                      child: Text(
                        m['name'] ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      item.materialId = val;
                      final material = _materialsList.firstWhere(
                        (m) => m['id'] == val,
                        orElse: () => null,
                      );
                      if (material != null &&
                          material['unit'] != null &&
                          material['unit']['name'] != null) {
                        item.unit = material['unit']['name'];
                        if (material['current_stock'] != null) {
                          item.currentStock = (material['current_stock'] as num)
                              .toDouble();
                        } else {
                          item.currentStock = 0.0;
                        }
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  decoration: InputDecoration(
                    labelText: 'Qty (Max: ${item.currentStock.toInt()})',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    final qty = int.tryParse(val ?? '0') ?? 0;
                    if (qty > item.currentStock) {
                      return 'Exceeds stock';
                    }
                    return null;
                  },
                  onChanged: (val) => item.quantity = int.tryParse(val) ?? 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey('unit_${item.materialId}_${item.unit}'),
                  initialValue: item.unit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (val) => item.unit = val,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: item.remarks,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 173, 173, 173),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (val) => item.remarks = val,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey('stock_${item.materialId}_${item.currentStock}'),
                  initialValue: item.currentStock.toStringAsFixed(2),
                  readOnly: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Stock',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 221, 221, 221),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 221, 221, 221),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMachineryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Machinery Name*',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color.fromARGB(255, 55, 68, 92),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _machineryError != null
                  ? Colors.red
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMachineryId,
              isExpanded: true,
              hint: const Text(
                'Select Machinery',
                style: TextStyle(fontSize: 14),
              ),
              items: _machineryList.map((m) {
                return DropdownMenuItem<int>(
                  value: m['id'],
                  child: Text(
                    m['name'] ?? '',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedMachineryId = val;
                  _machineryError = null;

                  final machinery = _machineryList.firstWhere(
                    (m) => m['id'] == val,
                    orElse: () => null,
                  );
                  if (machinery != null) {
                    _ownedByValue = machinery['owned_by'];
                  } else {
                    _ownedByValue = null;
                  }
                });
              },
            ),
          ),
        ),
        if (_machineryError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _machineryError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildOwnedByDropdown() {
    return _buildEnhancedTextField(
      controller: TextEditingController(text: _ownedByValue ?? ''),
      label: 'Owned By',
      hint: '',
      icon: Icons.person,
      readOnly: true,
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedMachineryId == null) {
      setState(() {
        _machineryError = 'Please select machinery';
      });
      return;
    }

    if ((double.tryParse(_startReadingController.text) ?? 0) >
        (double.tryParse(_endReadingController.text) ?? 0)) {
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
        'machine_start_reading':
            (double.tryParse(_startReadingController.text) ?? 0.0).toInt(),
        'machine_end_reading':
            (double.tryParse(_endReadingController.text) ?? 0.0).toInt(),
        'number_of_operators': int.tryParse(_operatorsController.text) ?? 0,
        'work_details': _workDetailsController.text,
        'diesel_consumption': 0,
        'maintenance_notes': _maintenanceController.text,
        'machinery_advances': '',
        'status': 0,
        'site_id': widget.preselectedSiteId ?? 14,
        'workspace_id': widget.workspaceId,
        'created_by': widget.createdBy,
        'machinery_id': _selectedMachineryId,
        'owned_by': _ownedByValue,
        'consumption_type': 'fuel',
        if (widget.activityId != null) 'activity_id': widget.activityId,
        if (widget.activityCompletedId != null)
          'activity_completed_id': widget.activityCompletedId,
        'items': _items.where((item) => item.materialId != null).toList(),
      };

      if (_referenceFile != null) {
        dprData['reference_file'] = _referenceFile;
      }

      print('=== ADD DPR REQUEST ===');
      print('activity_completed_id: ${widget.activityCompletedId}');
      print('DPR data: $dprData');

      if (widget.dpr != null) {
        final res = await DPRService.updateDPR(
          token: widget.token,
          id: widget.dpr!.id!,
          data: dprData,
        );
        print('=== ADD DPR RESPONSE (update) ===');
        print('Response: $res');
        print('=================================');
      } else {
        final res = await DPRService.createDPR(token: widget.token, data: dprData);
        print('=== ADD DPR RESPONSE (create) ===');
        print('Response: $res');
        print('=================================');
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
    if (_isLoadingMachinery) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(widget.dpr != null ? 'Edit DPR' : 'Create DPR'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool isEdit = widget.dpr != null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 74.h,
        centerTitle: true,
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
              isEdit ? 'Edit DPR' : 'Add DPR',
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
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildMachineryDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildOwnedByDropdown()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildEnhancedTextField(
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEnhancedTextField(
                        controller: _operatorsController,
                        label: 'Number of Operators',
                        hint: 'Enter number of operators',
                        icon: Icons.people,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildEnhancedTextField(
                        controller: _startReadingController,
                        label: 'Machine Start Reading',
                        hint: 'Enter start',
                        icon: Icons.speed,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEnhancedTextField(
                        controller: _endReadingController,
                        label: 'Machine End Reading',
                        hint: 'Enter end',
                        icon: Icons.speed,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildEnhancedTextField(
                        controller: _workDetailsController,
                        label: 'Work Details',
                        hint: 'Enter details',
                        icon: Icons.description,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEnhancedTextField(
                        controller: _maintenanceController,
                        label: 'Notes',
                        hint: 'Enter notes',
                        icon: Icons.build,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reference File',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 55, 68, 92),
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: _pickFile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.attach_file,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _fileName ?? 'Choose File',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _fileName != null
                                            ? textPrimary
                                            : textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (_fileName != null)
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _referenceFile = null;
                                        _fileName = null;
                                      }),
                                      child: const Icon(Icons.clear, size: 18),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fuel Consumption',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No fuel consumption items added',
                        style: TextStyle(color: textSecondary.withOpacity(0.7)),
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    _items.length,
                    (index) => _buildItemRow(index),
                  ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
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
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6f88e2), Color(0xFF4a63c0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  isEdit ? 'Update Progress' : 'Add Progress',
                                  style: const TextStyle(
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
