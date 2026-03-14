import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/admin/models/employee_model.dart';
import 'package:ecoteam_app/admin/models/purchase_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/admin/models/unit_model.dart';
import 'package:ecoteam_app/admin/services/purchase_services.dart';
import 'package:ecoteam_app/admin/services/employee_services.dart';
import 'package:ecoteam_app/admin/services/indent_service.dart';
import 'package:ecoteam_app/admin/models/indent_model.dart';

class AddIndentBottomSheet extends StatefulWidget {
  final List<Site> sites;
  final int? preselectedSiteId;
  final int? workspaceId;
  final int? userId; // Used for "created_by"
  final Function(IndentModel)? onIndentSaved;
  final IndentModel? indentToEdit;

  const AddIndentBottomSheet({
    Key? key,
    required this.sites,
    this.preselectedSiteId,
    this.workspaceId,
    this.userId,
    this.onIndentSaved,
    this.indentToEdit,
  }) : super(key: key);

  @override
  State<AddIndentBottomSheet> createState() => _AddIndentBottomSheetState();
}

class IndentMaterialItem {
  int? materialId;
  String materialName;
  String quantity;
  String unit;
  String price;
  String remarks;

  IndentMaterialItem({
    this.materialId,
    this.materialName = '',
    this.quantity = '',
    this.unit = '',
    this.price = '',
    this.remarks = '',
  });
}

class _AddIndentBottomSheetState extends State<AddIndentBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _indentDateController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _itemRemarkController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  int? _selectedSiteId;
  int? _selectedSupplierId;
  List<String> _selectedEmployeeIds = [];

  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedIndentDate;
  DateTime? _selectedDeliveryDate;

  bool _isSubmitting = false;
  bool _isLoadingData = false;

  List<MaterialModel> _materials = [];
  List<UnitModel> _units = [];
  List<Supplier> _suppliers = [];
  Map<String, String> _usersMap = {}; // Use Map for id -> name mapping
  List<Site> _fetchedSites = [];
  String _nextIndentNumber = '';

  // Currently we only support adding one material item array block based on Postman details
  final IndentMaterialItem _materialItem = IndentMaterialItem();

  // Colors
  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

@override
void dispose() {
  _unitController.dispose();
  _quantityController.dispose();
  _priceController.dispose();
  _itemRemarkController.dispose();
  super.dispose();
}
  @override
  void initState() {
    super.initState();
    _fetchedSites = widget.sites;

    _indentDateController.text = _formatDateForDisplay(DateTime.now());
    _selectedIndentDate = DateTime.now();

    if (widget.indentToEdit != null) {
      final edit = widget.indentToEdit!;
      _selectedSiteId = int.tryParse(edit.siteId ?? '');
      if (edit.indentDate != null) {
        _selectedIndentDate = DateTime.tryParse(edit.indentDate!);
        if (_selectedIndentDate != null) {
          _indentDateController.text = _formatDateForDisplay(_selectedIndentDate!);
        }
      }
      if (edit.deliveryDate != null) {
        _selectedDeliveryDate = DateTime.tryParse(edit.deliveryDate!);
        if (_selectedDeliveryDate != null) {
          _deliveryDateController.text = _formatDateForDisplay(_selectedDeliveryDate!);
        }
      }
      _remarkController.text = edit.rejectionReason ?? '';
      _descriptionController.text = edit.description ?? '';
      _selectedSupplierId = int.tryParse(edit.supplierId ?? '');
      // If we have items
      if (edit.items != null && edit.items!.isNotEmpty) {
        final item = edit.items!.first;
        _materialItem.materialId = int.tryParse(item.materialId ?? '');
        _materialItem.quantity = item.quantity ?? '';
        _materialItem.price = item.price ?? '';
        _materialItem.unit = item.unit ?? '';
        _materialItem.remarks = item.remarks ?? '';
        _quantityController.text = _materialItem.quantity;
        _priceController.text = _materialItem.price;
        _itemRemarkController.text = _materialItem.remarks;
      }
    } else {
      if (widget.preselectedSiteId != null) {
        _selectedSiteId = widget.preselectedSiteId;
      } else {
        _selectedSiteId = widget.sites.isNotEmpty ? int.tryParse(widget.sites.first.id) : null;
      }
    }

    _loadFormData();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoadingData = true);
    try {
      final workspaceId = widget.workspaceId ?? 1;
      final siteId = _selectedSiteId ?? widget.preselectedSiteId ?? 0;
      final createdBy = widget.userId ?? 1;

      // Fetch from the new indent create-data API
      final createData = await IndentService().getCreateData(
        workspaceId: workspaceId,
        siteId: siteId,
        createdBy: createdBy,
      );

      // Parse Materials
      final rawMaterials = createData['materials'];
      final materialsList = rawMaterials is List ? rawMaterials : [];
      final materials = materialsList.map((e) {
        if (e is Map) {
          return MaterialModel(
            id: int.tryParse(e['id']?.toString() ?? '0') ?? 0,
            name: e['name']?.toString() ?? '',
            sku: e['sku']?.toString() ?? '',
            categoryId: int.tryParse(e['category_id']?.toString() ?? '0') ?? 0,
            unitId: int.tryParse(e['unit_id']?.toString() ?? '0') ?? 0,
            price: double.tryParse(e['price']?.toString() ?? '0') ?? 0.0,
            unit: UnitModel(
               id: int.tryParse(e['unit_id']?.toString() ?? '0') ?? 0,
               name: e['unit_name']?.toString() ?? '',
               symbol: e['unit_name']?.toString() ?? '',
               isActive: 1, createdBy: 1, workspaceId: 1, status: 'Active', createdAt: '', updatedAt: ''
            ),
            description: '', reorderLevel: 0, status: 'Active', createdBy: 1, workspaceId: 1, createdAt: '', updatedAt: '',
          );
        }
        return null;
      }).whereType<MaterialModel>().toList();

      // Parse Suppliers
      final rawSuppliers = createData['suppliers'];
      final suppliersList = rawSuppliers is List ? rawSuppliers : [];
      final suppliers = suppliersList.map((e) {
        if (e is Map) {
          return Supplier.fromJson(Map<String, dynamic>.from(e));
        }
        return null;
      }).whereType<Supplier>().toList();
      
      // Parse Sites
      final rawSites = createData['sites'];
      final sitesList = rawSites is List ? rawSites : [];
      final sites = sitesList.map((e) {
        if (e is Map) {
          return Site(
            id: e['id']?.toString() ?? '',
            name: e['name']?.toString() ?? '',
            companyId: workspaceId.toString(),
            status: e['status']?.toString() ?? 'Ongoing',
          );
        }
        return null;
      }).whereType<Site>().toList();

      // Parse Users
      final rawUsers = createData['users'];
      final Map<String, String> usersMap = {};
      if (rawUsers is Map) {
        rawUsers.forEach((key, value) {
          usersMap[key.toString()] = value.toString();
        });
      } else if (rawUsers is List) {
         // Some APIs return empty list instead of empty map
      }

      // Fetch Units separately just in case or use from materials
      final units = await ApiServicePurchaseInvoice.getUnits();
      
      final nextIndent = createData['next_indent_number']?.toString() ?? '';

      if (mounted) {
        setState(() {
          _materials = materials;
          _units = units;
          _suppliers = suppliers;
          if (sites.isNotEmpty) _fetchedSites = sites;
          _usersMap = usersMap;
          _nextIndentNumber = nextIndent;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading create data for indent: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load form data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _selectDate(BuildContext context, bool isDeliveryDate) async {
    final initialDate = isDeliveryDate 
        ? (_selectedDeliveryDate ?? DateTime.now())
        : (_selectedIndentDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isDeliveryDate) {
          _selectedDeliveryDate = picked;
          _deliveryDateController.text = _formatDateForDisplay(picked);
        } else {
          _selectedIndentDate = picked;
          _indentDateController.text = _formatDateForDisplay(picked);
        }
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
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
                    }
                  },
                ), 
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: primaryColor),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
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
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMultiSelectEmployees() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign To'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _usersMap.length,
                  itemBuilder: (context, index) {
                    final userId = _usersMap.keys.elementAt(index);
                    final userName = _usersMap[userId] ?? 'Unknown';
                    final isSelected = _selectedEmployeeIds.contains(userId);
                    return CheckboxListTile(
                      title: Text(userName),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedEmployeeIds.add(userId);
                          } else {
                            _selectedEmployeeIds.remove(userId);
                          }
                        });
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please wait, loading site data...')));
      return;
    }
    // if (_selectedSupplierId == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
    //   return;
    // }
    if (_selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please assign to at least one user')));
      return;
    }
    if (_materialItem.materialId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a material item')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'workspace_id': widget.workspaceId ?? 1,
        'indent_date': _indentDateController.text,
        'site_id': _selectedSiteId,
        'description': _descriptionController.text,
        'assign_to': _selectedEmployeeIds,
        'delivery_date': _deliveryDateController.text,
        'remark': _remarkController.text,
        'created_by': widget.userId ?? 1,
        'items': [
          {
             'material_id': _materialItem.materialId,
             'quantity': _materialItem.quantity,
             'unit': _materialItem.unit,
             'price': _materialItem.price,
             'subtotal': (double.parse(_materialItem.quantity) * double.parse(_materialItem.price)).toString(),
             'remarks': _materialItem.remarks,
          }
        ]
      };

      IndentModel? result;
      if (widget.indentToEdit != null) {
        result = await IndentService().updateIndent(widget.indentToEdit!.id, data, referenceFile: _selectedFile);
        print('Update Indent Response: ${json.encode(data)}');
        print('API Result: $result');
      } else {
        result = await IndentService().createIndent(data, referenceFile: _selectedFile);
        print('Create Indent Response: ${json.encode(data)}');
        print('API Result: $result');
      }
      
      if (mounted) {
        Navigator.pop(context);
        if (result != null) {
          widget.onIndentSaved?.call(result);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Indent Created Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFf8f9fa),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoadingData
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.all(16.w),
                      children: [
                        _buildTextField(
                          controller: TextEditingController(
                            text: widget.indentToEdit?.indentNumber ?? _nextIndentNumber,
                          ),
                          label: 'Indent Number',
                          icon: Icons.tag,
                          readOnly: true,
                          
                        ),
                        SizedBox(height: 14.h),
                       
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _indentDateController,
                                label: 'Indent Date',
                                icon: Icons.calendar_today,
                                readOnly: true,
                                onTap: () => _selectDate(context, false),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildTextField(
                                controller: _deliveryDateController,
                                label: 'Delivery Date',
                                icon: Icons.event,
                                readOnly: true,
                                onTap: () => _selectDate(context, true),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        InkWell(
                          onTap: _showMultiSelectEmployees,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Assign To',
                              prefixIcon: Icon(Icons.people, color: primaryColor, size: 20.sp),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: Text(
                              _selectedEmployeeIds.isEmpty
                                  ? 'Select Employees'
                                  : '${_selectedEmployeeIds.length} users selected',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _buildTextField(
                          controller: _remarkController,
                          label: 'Remark (Optional)',
                          icon: Icons.note,
                        ),
                        SizedBox(height: 14.h),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description (Optional)',
                          icon: Icons.description,
                        ),
                        SizedBox(height: 18.h),
                        _buildMaterialSection(),
                        SizedBox(height: 18.h),
                        _buildFileUploader(),
                        SizedBox(height: 80.h),
                      ],
                    ),
                  ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

Widget _buildMaterialSection() {
  return Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// Header
        Row(
          children: [
            Icon(Icons.inventory_2, color: primaryColor, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Material Detail',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        /// MATERIAL + UNIT
        Row(
          children: [

            /// Material Dropdown
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                value: _materialItem.materialId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Select Material",
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                ),
                items: _materials.map((m) {
                  return DropdownMenuItem<int>(
                    value: m.id,
                    child: Text(
                      m.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _materialItem.materialId = val;

                    if (val != null) {
                      final selectedMaterial =
                          _materials.firstWhere((m) => m.id == val);

                      /// Auto fill price
                      _materialItem.price =
                          selectedMaterial.price.toString();
                      _priceController.text = _materialItem.price;

                      /// Auto fetch unit
                      _materialItem.unit =
                          selectedMaterial.unit?.symbol ?? '';

                      /// Update Unit Field
                      _unitController.text = _materialItem.unit;
                    }
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),

            SizedBox(width: 12.w),

            /// Unit Field (Auto Filled)
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _unitController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Unit",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        /// QUANTITY + PRICE
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity",
                  prefixIcon: Icon(Icons.numbers),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onChanged: (v) => _materialItem.quantity = v,
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Price",
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                ),
                onChanged: (v) => _materialItem.price = v,
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        /// ITEM REMARK
        TextFormField(
          controller: _itemRemarkController,
          decoration: InputDecoration(
            labelText: "Item Remark",
            prefixIcon: Icon(Icons.notes),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 6.h,
              ),
          ),
          onChanged: (v) => _materialItem.remarks = v,
        ),
      ],
    ),
  );
}
  Widget _buildFileUploader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_file, color: primaryColor, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text('Reference File', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textPrimary)),
                ],
              ),
              if (_selectedFile != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => setState(() => _selectedFile = null),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_selectedFile != null)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8.r)),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file, color: Colors.grey, size: 24.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _selectedFile!.path.split('/').last,
                      style: TextStyle(fontSize: 14.sp, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload File'),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor, backgroundColor: Colors.white,
                elevation: 0,
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 18.sp),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      ),
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool readOnly = false,
  VoidCallback? onTap,
  TextInputType? keyboardType,
  Function(String)? onChanged,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    onTap: onTap,
    keyboardType: keyboardType,
    onChanged: onChanged,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor, size: 20.sp),

      /// 👇 ADD / MODIFY THIS
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 6.h,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
    ),
  );
}
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Center(child: Text(widget.indentToEdit != null ? 'Edit Indent' : 'Add Indent', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: textPrimary))),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Submit Indent', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
      ),
    );
  }
}
