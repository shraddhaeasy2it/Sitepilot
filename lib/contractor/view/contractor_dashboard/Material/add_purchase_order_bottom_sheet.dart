import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/admin/models/purchase_model.dart';
import 'package:ecoteam_app/admin/models/purchase_order_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/admin/models/unit_model.dart';
import 'package:ecoteam_app/admin/services/purchase_services.dart';
import 'package:ecoteam_app/admin/services/indent_service.dart';
import 'package:ecoteam_app/admin/models/indent_model.dart';

class AddEditPurchaseOrderBottomSheet extends StatefulWidget {
  final List<Site> sites;
  final int? preselectedSiteId;
  final int? workspaceId;
  final int? userId;
  final VoidCallback? onPOSaved;
  final PurchaseOrderModel? poToEdit;
  final int? preselectedIndentId;

  const AddEditPurchaseOrderBottomSheet({
    Key? key,
    required this.sites,
    this.preselectedSiteId,
    this.workspaceId,
    this.userId,
    this.onPOSaved,
    this.poToEdit,
    this.preselectedIndentId,
  }) : super(key: key);

  @override
  State<AddEditPurchaseOrderBottomSheet> createState() => _AddEditPurchaseOrderBottomSheetState();
}

class POMaterialItem {
  int? materialId;
  String? unit;
  int? selectedGstId;
  double? availableQty; // Added availableQty
  
  final TextEditingController qtyController = TextEditingController(text: '1');
  final TextEditingController priceController = TextEditingController(text: '0');
  final TextEditingController discountController = TextEditingController(text: '0');
  final TextEditingController taxController = TextEditingController(text: '0'); // Added taxController
  final TextEditingController remarksController = TextEditingController();

  double get quantity => double.tryParse(qtyController.text) ?? 0.0;
  double get price => double.tryParse(priceController.text) ?? 0.0;
  double get discountAmount => double.tryParse(discountController.text) ?? 0.0;
  
  double taxableValueValue = 0; // Internal cache or just use the getter
  double get taxableValue => (quantity * price) - discountAmount;
  
  double gstRate = 0.0;

  double get taxAmount => taxableValue * (gstRate / 100);
  double get subtotal => taxableValue + taxAmount;

  POMaterialItem({
    this.materialId,
    this.unit,
    this.selectedGstId,
    this.availableQty,
  });

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
    discountController.dispose();
    taxController.dispose();
    remarksController.dispose();
  }
}

class _AddEditPurchaseOrderBottomSheetState extends State<AddEditPurchaseOrderBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _poNumberController = TextEditingController();
  final TextEditingController _poDateController = TextEditingController();
  final TextEditingController _deliveryTermsController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _paymentTermsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _additionalChargeController = TextEditingController(text: '0');
  final TextEditingController _additionalDeductionController = TextEditingController(text: '0');
  final TextEditingController _additionalDiscountController = TextEditingController(text: '0');

  int? _selectedSiteId;
  int? _selectedSupplierId;
  int? _selectedIndentId;
  String? _selectedTaxType;
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedPODate;
  DateTime? _selectedDeliveryDate;

  bool _isSubmitting = false;
  bool _isLoadingData = false;

  List<MaterialModel> _materials = [];
  List<UnitModel> _units = [];
  List<Supplier> _suppliers = [];
  List<Site> _fetchedSites = [];
  List<IndentModel> _indents = [];
  List<dynamic> _gstMasters = [];
  int? _selectedGstId;

  List<POMaterialItem> _items = [];
  int _currentStep = 0;

  double _totalTaxableValue = 0;
  double _totalCGST = 0;
  double _totalSGST = 0;
  double _totalIGST = 0;
  double _totalDiscount = 0;
  double _grandTotal = 0;

  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _fetchedSites = widget.sites;

    _poDateController.text = _formatDateForDisplay(DateTime.now());
    _selectedPODate = DateTime.now();

    if (widget.poToEdit != null) {
      final edit = widget.poToEdit!;
      _selectedSiteId = int.tryParse(edit.siteId ?? '');
      if (edit.poDate != null) {
        _selectedPODate = DateTime.tryParse(edit.poDate!);
        if (_selectedPODate != null) {
          _poDateController.text = _formatDateForDisplay(_selectedPODate!);
        }
      }
      if (edit.deliveryDate != null) {
        _selectedDeliveryDate = DateTime.tryParse(edit.deliveryDate!);
        if (_selectedDeliveryDate != null) {
          _deliveryDateController.text = _formatDateForDisplay(_selectedDeliveryDate!);
        }
      }
      _remarkController.text = edit.remark ?? '';
      _paymentTermsController.text = edit.paymentTermsConditions ?? '';
      _descriptionController.text = edit.description ?? '';
      _selectedSupplierId = int.tryParse(edit.supplierId ?? '');
      
      if (edit.items != null && edit.items!.isNotEmpty) {
        _items = edit.items!.map((item) {
          final pItem = POMaterialItem(
            materialId: item.material?.id,
            unit: item.unit,
          );
          pItem.qtyController.text = item.quantity ?? '0';
          pItem.priceController.text = item.price ?? '0';
          pItem.discountController.text = item.discount ?? '0'; // Pre-populate discount
          pItem.selectedGstId = int.tryParse(item.taxId ?? ''); // Pre-populate GST
          pItem.remarksController.text = item.remarks ?? '';
          return pItem;
        }).toList();
      } else {
        _items = [POMaterialItem()];
      }

      _selectedIndentId = int.tryParse(edit.indentId ?? '');
      _selectedTaxType = edit.taxType;
      _additionalChargeController.text = edit.additionalCharge ?? '0';
      _additionalDeductionController.text = edit.additionalDeduction ?? '0';
      _additionalDiscountController.text = edit.additionalDiscount ?? '0';
      _deliveryTermsController.text = edit.deliveryTermsConditions ?? '';
      _poNumberController.text = edit.poNumber ?? '';
    } else {
      if (widget.preselectedSiteId != null) {
        _selectedSiteId = widget.preselectedSiteId;
      } else {
        _selectedSiteId = widget.sites.isNotEmpty ? int.tryParse(widget.sites.first.id) : null;
      }
      _selectedIndentId = widget.preselectedIndentId;
      _items = [POMaterialItem()];
    }

    _loadFormData();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoadingData = true);
    try {
      final workspaceId = widget.workspaceId ?? 1;
      final siteId = _selectedSiteId ?? widget.preselectedSiteId ?? 0;
      final createdBy = widget.userId ?? 1;

      final createData = await ApiServicePurchaseInvoice.getPOCreateData(
        workspaceId: workspaceId,
        siteId: siteId,
      );

      final materials = createData['materials'] as List<MaterialModel>? ?? [];
      final suppliers = createData['suppliers'] as List<Supplier>? ?? [];
      final sitesData = createData['sites'] as List<SiteModel>? ?? [];
      final indents = createData['indents'] as List<IndentModel>? ?? [];
      
      final sites = sitesData.map((s) => Site(
        id: s.id.toString(),
        name: s.name,
        companyId: s.workspaceId.toString(),
        status: s.status,
      )).toList();
      
      final nextPoNumber = createData['next_po_number'] as String? ?? '';

      if (mounted) {
        setState(() {
          _materials = materials;
          _suppliers = suppliers;
          _indents = indents;
          _gstMasters = createData['gstMasters'] ?? createData['gst_masters'] ?? []; // Check both keys
          if (sites.isNotEmpty) _fetchedSites = sites;
          
          if (widget.poToEdit == null && nextPoNumber.isNotEmpty) {
            _poNumberController.text = nextPoNumber;
          }
          
          if (widget.poToEdit == null && _selectedIndentId != null) {
            _handleIndentSelection(_selectedIndentId);
          }
          
          _isLoadingData = false;
        });
        _calculateTotals();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load form data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleIndentSelection(int? val) {
    _selectedIndentId = val;
    if (val != null) {
      try {
        final indent = _indents.firstWhere((i) => i.id == val);
        if (indent.items != null && indent.items!.isNotEmpty) {
          _items = indent.items!.map((iItem) {
            final materialId = int.tryParse(iItem.materialId ?? '');
            final indentQty = double.tryParse(iItem.remainingQuantity ?? '0') ?? 0.0;
            final pItem = POMaterialItem(
              materialId: materialId,
              unit: iItem.unit,
              availableQty: indentQty,
            );
            pItem.qtyController.text = '0';
            pItem.priceController.text = iItem.price ?? '0';
            
            if (materialId != null) {
              try {
                final mat = _materials.firstWhere((m) => m.id == materialId);
                if (mat.gstId != null) {
                  pItem.selectedGstId = mat.gstId;
                }
              } catch (_) {}
            }
            return pItem;
          }).toList();
        }
      } catch (_) {}
    }
  }

  void _calculateTotals() {
    double taxable = 0;
    double cgst = 0;
    double sgst = 0;
    double igst = 0;
    double totalDisc = 0;

    for (var item in _items) {
      taxable += item.taxableValue;
      totalDisc += item.discountAmount;
      
      double rate = 0;
      if (item.selectedGstId != null) {
        final gst = _gstMasters.firstWhere((g) => int.tryParse(g['id'].toString()) == item.selectedGstId, orElse: () => null);
        if (gst != null) {
          rate = double.tryParse(gst['total_gst']?.toString() ?? '0') ?? 0;
        }
      }
      item.gstRate = rate;
      item.taxController.text = item.taxAmount.toStringAsFixed(2); // Update taxController

      double itemTax = item.taxAmount;
      if (_selectedTaxType == 'cgst') {
        cgst += itemTax / 2;
        sgst += itemTax / 2;
      } else {
        igst += itemTax;
      }
    }

    final addCharge = double.tryParse(_additionalChargeController.text) ?? 0;
    final addDeduc = double.tryParse(_additionalDeductionController.text) ?? 0;
    final addDisc = double.tryParse(_additionalDiscountController.text) ?? 0;

    setState(() {
      _totalTaxableValue = taxable;
      _totalCGST = cgst;
      _totalSGST = sgst;
      _totalIGST = igst;
      _totalDiscount = totalDisc + addDisc;
      _grandTotal = taxable + cgst + sgst + igst + addCharge - addDeduc - addDisc;
    });
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _selectDate(BuildContext context, bool isDeliveryDate) async {
    final initialDate = isDeliveryDate 
        ? (_selectedDeliveryDate ?? DateTime.now())
        : (_selectedPODate ?? DateTime.now());

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
          _selectedPODate = picked;
          _poDateController.text = _formatDateForDisplay(picked);
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validations to match Next button
    if (_poDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PO Date')));
      return;
    }
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }
    if (_selectedIndentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an Indent')));
      return;
    }
    if (_selectedTaxType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Tax Type')));
      return;
    }
    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please wait, loading site data...')));
      return;
    }
    if (_items.isEmpty || _items.any((item) => item.materialId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select material for all items')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
    final data = <String, dynamic>{
      'workspace_id': widget.workspaceId ?? 1,
      'po_number': _poNumberController.text,
      'po_date': _poDateController.text,
      'supplier_id': _selectedSupplierId,
      'site_id': _selectedSiteId,
      'description': _descriptionController.text,
      'delivery_date': _deliveryDateController.text,
      'payment_terms_conditions': _paymentTermsController.text,
      'delivery_terms_conditions': _deliveryTermsController.text,
      'created_by': widget.userId ?? 1,
      'status': widget.poToEdit?.status ?? 'Pending',
      'total_taxable_value': _totalTaxableValue.toString(),
      'grand_total': _grandTotal.toString(),
      'additional_charge': _additionalChargeController.text,
      'additional_deduction': _additionalDeductionController.text,
      'additional_discount': _additionalDiscountController.text,
    };

    if (_selectedTaxType != null) data['tax_type'] = _selectedTaxType;
    if (_selectedIndentId != null) data['indent_id'] = _selectedIndentId;
    if (_selectedGstId != null) data['tax_id'] = _selectedGstId;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      data['items[$i][material_id]'] = item.materialId;
      data['items[$i][quantity]'] = item.qtyController.text;
      if (item.unit != null) data['items[$i][unit]'] = item.unit;
      data['items[$i][price]'] = item.priceController.text;
      if (item.selectedGstId != null) {
        data['items[$i][tax_id]'] = item.selectedGstId; // Send tax_id
      }
      data['items[$i][discount]'] = item.discountController.text; // Send discount
      data['items[$i][subtotal]'] = item.subtotal.toString();
      data['items[$i][remarks]'] = item.remarksController.text;
    }

      if (widget.poToEdit != null) {
        await ApiServicePurchaseInvoice.updatePurchaseOrder(widget.poToEdit!.id, data, referenceFile: _selectedFile);
      } else {
        await ApiServicePurchaseInvoice.createPurchaseOrder(data, referenceFile: _selectedFile);
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onPOSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.poToEdit != null ? 'Purchase Order Updated' : 'Purchase Order Created'),
            backgroundColor: Colors.green,
          ),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          _buildStepIndicator(),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.all(16.w),
                              children: [
                                if (_currentStep == 0) ..._buildStep1(),
                                if (_currentStep == 1) _buildStep2(),
                                if (_currentStep == 2) ..._buildStep3(),
                              ],
                            ),
                          ),
                          _buildNavigationButtons(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Purchase Order Materials',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _items.add(POMaterialItem()));
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        /// Material List
        Column(
          children: _items
              .asMap()
              .entries
              .map((entry) => _buildMaterialCard(entry.key, entry.value))
              .toList(),
        ),
      ],
    ),
  );
}
Widget _buildMaterialCard(int index, POMaterialItem item) {
  return Container(
    margin: EdgeInsets.only(bottom: 10.h),
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 249, 249, 253),
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// Material Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Material ${index + 1}",
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                if (_items.length > 1) {
                  setState(() => _items.removeAt(index));
                  _calculateTotals();
                }
              },
            )
          ],
        ),

        SizedBox(height: 12.h),

        /// Material Dropdown
        _buildDropdownField<int>(
          value: item.materialId,
          label: 'Material',
          icon: Icons.category,
          items: _materials.map((m) {
            return DropdownMenuItem(
              value: m.id,
              child: Text(m.name),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              item.materialId = val;

                  if (val != null) {
                    final m = _materials.firstWhere((mat) => mat.id == val);
                    item.priceController.text = m.price.toString();
                    item.unit = m.unit?.symbol ?? '';
                    if (m.gstId != null) {
                      item.selectedGstId = m.gstId; // Auto-select GST
                    }
                  }
                });

                _calculateTotals();
              },
        ),

        SizedBox(height: 10.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Available Qty : ${item.availableQty?.toString() ?? '0'}",
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color.fromARGB(255, 48, 50, 53),
              ),
            ),
            Text(
              item.unit != null ? " (${item.unit})" : '',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color.fromARGB(255, 74, 81, 92),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),

        SizedBox(height: 15.h),

        /// Quantity + Unit + Price
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: [

            SizedBox(
              width: 110.w,
              child: _buildTextField(
                controller: item.qtyController,
                label: 'Qty',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateTotals(),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter Qty';
                  final q = double.tryParse(val) ?? 0;
                  if (q <= 0) return 'Invalid Qty';
                  if (item.availableQty != null && q > item.availableQty!) {
                    return 'Max ${item.availableQty}';
                  }
                  return null;
                },
              ),
            ),

           
            SizedBox(
              width: 120.w,
              child: _buildTextField(
                controller: item.priceController,
                label: 'Price',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateTotals(),
              ),
            ),
          ],
        ),

        SizedBox(height: 14.h),

        /// GST + Discount
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: [

            SizedBox(
              width: 130.w,
              child: _buildDropdownField<int>(
                value: item.selectedGstId,
                label: 'GST %',
                icon: Icons.percent,
                items: _gstMasters.map((gst) {
                  return DropdownMenuItem<int>(
                    value: int.tryParse(gst['id'].toString()),
                    child: Text("${gst['name']}"),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => item.selectedGstId = val);
                  _calculateTotals();
                },
                validator: (v) => null,
              ),
            ),

             SizedBox(
              width: 140.w,
              child: _buildTextField(
                controller: item.taxController,
                label: 'Tax',
                icon: Icons.receipt_long,
                readOnly: true,
              ),
            ),
          ],
        ),

        SizedBox(height: 20.h),


        /// Totals
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
           

           Expanded(
             child: Text(
                "Discount : ₹ ${item.discountAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color.fromARGB(255, 39, 150, 29),
                  fontWeight: FontWeight.w500,
                ),
              ),
           ),

            Expanded(
              child: Text(
                "Subtotal : ₹ ${item.subtotal.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
  DataRow _buildItemRow(int index, POMaterialItem item) {
    return DataRow(
      cells: [
        DataCell(SizedBox(
          width: 150.w,
          child: _buildDropdownField<int>(
            value: item.materialId,
            label: 'Select...',
            icon: Icons.category,
            items: _materials.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (val) {
              setState(() {
                item.materialId = val;
                if (val != null) {
                  final m = _materials.firstWhere((mat) => mat.id == val);
                  item.priceController.text = m.price.toString();
                  item.unit = m.unit?.symbol ?? '';
                }
              });
              _calculateTotals();
            },
          ),
        )),
        DataCell(Text('0')), // Placeholder for available qty
        DataCell(SizedBox(
          width: 80.w,
          child: TextFormField(
            controller: item.qtyController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateTotals(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        )),
        DataCell(Text(item.unit ?? '')),
        DataCell(SizedBox(
          width: 100.w,
          child: TextFormField(
            controller: item.priceController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateTotals(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        )),
        DataCell(SizedBox(
          width: 100.w,
          child: _buildDropdownField<int>(
            value: item.selectedGstId,
            label: 'GST',
            icon: Icons.percent,
            items: _gstMasters.map((gst) {
              return DropdownMenuItem<int>(
                value: int.tryParse(gst['id'].toString()),
                child: Text('${gst['rate']}%', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => item.selectedGstId = val);
              _calculateTotals();
            },
            validator: (v) => null,
          ),
        )),
        DataCell(Text('₹ ${item.taxAmount.toStringAsFixed(2)}')),
        DataCell(SizedBox(
          width: 100.w,
          child: TextFormField(
            controller: item.discountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateTotals(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        )),
        DataCell(Text('₹ ${item.subtotal.toStringAsFixed(2)}')),
        DataCell(IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          onPressed: () {
            if (_items.length > 1) {
              setState(() => _items.removeAt(index));
              _calculateTotals();
            }
          },
        )),
      ],
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

@override
void dispose() {
  _poNumberController.dispose();
  _poDateController.dispose();
  _deliveryTermsController.dispose();
  _deliveryDateController.dispose();
  _remarkController.dispose();
  _paymentTermsController.dispose();
  _descriptionController.dispose();
  _additionalChargeController.dispose();
  _additionalDeductionController.dispose();
  _additionalDiscountController.dispose();
  for (var item in _items) {
    item.dispose();
  }
  super.dispose();
}

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    final T? safeValue = (value == null || items.any((item) => item.value == value)) ? value : null;
    
    return DropdownButtonFormField<T>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator ?? (v) => v == null ? 'This field is required' : null,
    );
  }

  Widget _buildTaxTypeRadio() {
    return FormField<String>(
      validator: (value) => _selectedTaxType == null ? 'This field is required' : null,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Tax Type*', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: state.hasError ? Colors.red : primaryColor)),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Radio<String>(
                      value: 'cgst',
                      groupValue: _selectedTaxType,
                      onChanged: (v) {
                        setState(() => _selectedTaxType = v);
                        state.didChange(v);
                      },
                      activeColor: primaryColor,
                    ),
                    Text('CGST + SGST', style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 8.w),
                    Radio<String>(
                      value: 'igst',
                      groupValue: _selectedTaxType,
                      onChanged: (v) {
                        setState(() => _selectedTaxType = v);
                        state.didChange(v);
                        _calculateTotals();
                      },
                      activeColor: primaryColor,
                    ),
                    Text('IGST', style: TextStyle(fontSize: 12.sp)),
                  ],
                ),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: EdgeInsets.only(left: 14.w, top: 2.h),
                child: Text(
                  state.errorText!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12.sp),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTotalsSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 350.w,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            _buildTotalRow('Total Taxable Value:', _totalTaxableValue),
            if (_selectedTaxType == 'cgst') ...[
              _buildTotalRow('Total CGST:', _totalCGST),
              _buildTotalRow('Total SGST:', _totalSGST),
            ] else 
              _buildTotalRow('Total IGST:', _totalIGST),
            _buildTotalRow('Total Discount:', _totalDiscount),
            SizedBox(height: 4.h),
            const Divider(),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(child: Text('(+) Additional Charge:', style: TextStyle(fontSize: 12.sp, color: textSecondary))),
                SizedBox(
                  width: 120.w,
                  child: _buildTextField(controller: _additionalChargeController, label: '', icon: Icons.add, keyboardType: TextInputType.number, onChanged: (_) => _calculateTotals()),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(child: Text('(-) Additional Deduction:', style: TextStyle(fontSize: 12.sp, color: textSecondary))),
                SizedBox(
                  width: 120.w,
                  child: _buildTextField(controller: _additionalDeductionController, label: '', icon: Icons.remove, keyboardType: TextInputType.number, onChanged: (_) => _calculateTotals()),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(child: Text('(-) Additional Discount:', style: TextStyle(fontSize: 12.sp, color: textSecondary))),
                SizedBox(
                  width: 120.w,
                  child: _buildTextField(controller: _additionalDiscountController, label: '', icon: Icons.sell, keyboardType: TextInputType.number, onChanged: (_) => _calculateTotals()),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            const Divider(thickness: 1.5),
            SizedBox(height: 8.h),
            _buildTotalRow('Grand Total:', _grandTotal, isBold: true, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? textSecondary)),
          Text('₹ ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 13.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? textPrimary)),
        ],
      ),
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (v) {
        onChanged?.call(v);
        _calculateTotals();
      },
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
       
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            widget.poToEdit != null ? 'Edit Purchase Order' : 'Create Purchase Order',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _buildStepItem(0, 'Order Info', Icons.info_outline),
          _buildStepDivider(),
          _buildStepItem(1, 'Materials', Icons.inventory_2_outlined),
          _buildStepDivider(),
          _buildStepItem(2, 'Review', Icons.rate_review_outlined),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String title, IconData icon) {
    bool isActive = _currentStep == step;
    bool isCompleted = _currentStep > step;
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : (isActive ? primaryColor : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(color: isCompleted ? Colors.green : (isActive ? primaryColor : Colors.grey.shade300)),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              size: 20.sp,
              color: (isActive || isCompleted) ? Colors.white : Colors.grey,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 40.w,
      height: 1.h,
      color: Colors.grey.shade300,
      margin: EdgeInsets.only(bottom: 20.h),
    );
  }

 List<Widget> _buildStep1() {
  return [

    /// ROW 1
    Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _poNumberController,
            label: 'PO Number*',
            icon: Icons.tag,
            
          ),
        ),
        SizedBox(width: 16.w),   
        Expanded(
          child: _buildTextField(
            controller: _poDateController,
            label: 'PO Date*',
            icon: Icons.calendar_today,
            readOnly: true,
            onTap: () => _selectDate(context, false),
          ),
        ),
      ],
    ),

    SizedBox(height: 16.h),

    /// ROW 2
    Row(
      children: [
        Expanded(
          child: _buildDropdownField<int>(
            value: _selectedSupplierId,
            label: 'Supplier*',
            icon: Icons.local_shipping,
            items: _suppliers.map((s) {
              return DropdownMenuItem(
                value: s.id,
                child: Text(s.name ?? '', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedSupplierId = val),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildDropdownField<int>(
            value: _selectedIndentId,
            label: 'Indent*',
            icon: Icons.description,
            items: _indents.map((indent) {
              return DropdownMenuItem<int>(
                value: indent.id,
                child: Text(indent.indentNumber ?? ''),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _handleIndentSelection(val);
                _calculateTotals();
              });
            },
          ),
        ),
      ],
    ),

    SizedBox(height: 16.h),

    /// ROW 3
    Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _buildTaxTypeRadio(),

    SizedBox(height: 16.h),

    _buildTextField(
      controller: _deliveryDateController,
      label: 'Expected Delivery Date',
      icon: Icons.event,
      readOnly: true,
      onTap: () => _selectDate(context, true),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    ),
  ],
),

    SizedBox(height: 16.h),

    /// ROW 4
    _buildFileUploaderSection(),
  ];
}

  Widget _buildStep2() {
    return _buildMaterialSection();
  }

  List<Widget> _buildStep3() {
  return [

    _buildTotalsSection(),

    SizedBox(height: 15.h),

    Expanded(
      child: _buildTextField(
        controller: _descriptionController,
        label: 'Description',
        icon: Icons.description,
        maxLines: 1,
        validator: (v) => null,
      ),
    ),

    SizedBox(height: 14.h),

    _buildTextField(
      controller: _deliveryTermsController,
      label: 'Delivery Terms & Conditions',
      icon: Icons.gavel,
      maxLines: 1,
      validator: (v) => null,
    ),

    SizedBox(height: 14.h),

    _buildTextField(
      controller: _paymentTermsController,
      label: 'Payment Terms & Conditions',
      icon: Icons.payments,
      maxLines: 1,
      validator: (v) => null,
    ),
  ];
}

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton.icon(
            onPressed: () {
              if (_currentStep < 2) {
                // Focus out inside the form to force validation text update
                FocusScope.of(context).unfocus();

                // Form validation (show error message wrappers below inputs)
                bool isFormValid = _formKey.currentState!.validate();

                // Specific Check for Step 1
                if (_currentStep == 0) {
                  if (!isFormValid || _selectedSupplierId == null || _selectedIndentId == null || _selectedTaxType == null) {
                    HapticFeedback.heavyImpact();
                    if (_selectedSupplierId == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
                    else if (_selectedIndentId == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an Indent')));
                    else if (_selectedTaxType == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Tax Type')));
                    return;
                  }
                }
                
                // Specific Check for Step 2
                if (_currentStep == 1) {
                  if (!isFormValid || _items.isEmpty || _items.any((item) => item.materialId == null)) {
                    HapticFeedback.heavyImpact();
                    if (_items.isEmpty || _items.any((item) => item.materialId == null)) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select material for all items')));
                    }
                    return;
                  }
                }

                setState(() => _currentStep++);
              } else {
                if (!_isSubmitting) _submitForm();
              }
            },
            icon: Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward),
            label: Text(_currentStep == 2 ? (widget.poToEdit != null ? 'Update PO' : 'Create PO') : 'Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploaderSection() {
    return _buildFileUploader();
  }
}
