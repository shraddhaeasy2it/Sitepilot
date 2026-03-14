import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/admin/models/purchase_order_model.dart';
import 'package:ecoteam_app/admin/models/grn_model.dart';
import 'package:ecoteam_app/admin/services/purchase_services.dart';
import 'package:ecoteam_app/admin/services/grn_service.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';

class GRNMaterialItem {
  final Map<String, dynamic> itemData;
  final TextEditingController receivedQtyController;
  final TextEditingController acceptedQtyController;
  final TextEditingController rejectedQtyController;
  final TextEditingController remarksController;

  GRNMaterialItem({
    required this.itemData,
  })  : receivedQtyController = TextEditingController(text: itemData['remaining_qty']?.toString() ?? '0'),
        acceptedQtyController = TextEditingController(text: itemData['remaining_qty']?.toString() ?? '0'),
        rejectedQtyController = TextEditingController(text: '0'),
        remarksController = TextEditingController();

  void dispose() {
    receivedQtyController.dispose();
    acceptedQtyController.dispose();
    rejectedQtyController.dispose();
    remarksController.dispose();
  }
}

class AddGRNBottomSheet extends StatefulWidget {
  final List<Site> sites;
  final String? selectedSiteId;
  final int? workspaceId;
  final int? userId;
  final GRNModel? grnToEdit;
  final PurchaseOrderModel? initialPO;
  final VoidCallback onGRNSaved;

  const AddGRNBottomSheet({
    super.key,
    required this.sites,
    this.selectedSiteId,
    this.workspaceId,
    this.userId,
    this.grnToEdit,
    this.initialPO,
    required this.onGRNSaved,
  });

  @override
  State<AddGRNBottomSheet> createState() => _AddGRNBottomSheetState();
}

class _AddGRNBottomSheetState extends State<AddGRNBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final GRNService _grnService = GRNService();

  final TextEditingController _grnDateController = TextEditingController();
  final TextEditingController _challanNumberController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _gateEntryNumberController = TextEditingController();
  final TextEditingController _receivedByController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  int? _selectedSiteId;
  PurchaseOrderModel? _selectedPO;
  String? _selectedPOSupplierName;
  String? _selectedPOSiteName;
  List<PurchaseOrderModel> _purchaseOrders = [];
  List<GRNMaterialItem> _items = [];
  
  bool _isLoadingPOs = false;
  bool _isSubmitting = false;
  int _currentStep = 0;

  Future<void> _loadPurchaseOrders() async {
    if (_selectedSiteId == null || widget.workspaceId == null) return;
    
    setState(() => _isLoadingPOs = true);
    try {
      final responseBody = await _grnService.getGRNCreateData(
        workspaceId: widget.workspaceId!,
        siteId: _selectedSiteId!,
      );

      if (mounted) {
        setState(() {
          final List<dynamic> posData = responseBody['data']?['purchase_orders'] ?? [];
          _purchaseOrders = posData.map((json) => PurchaseOrderModel.fromJson(json)).toList();
          
          // If we are editing, ensure the current PO is in the list
          if (widget.grnToEdit != null && widget.grnToEdit!.purchaseOrder != null) {
            bool exists = _purchaseOrders.any((p) => p.id == widget.grnToEdit!.purchaseOrder!.id);
            if (!exists) {
              _purchaseOrders.insert(0, widget.grnToEdit!.purchaseOrder!);
            }
            
            // Auto-select and fetch details
            final po = _purchaseOrders.firstWhere((p) => p.id == widget.grnToEdit!.purchaseOrder!.id);
            _onPOSelected(po);
          } else if (widget.initialPO != null) {
            bool exists = _purchaseOrders.any((p) => p.id == widget.initialPO!.id);
            if (!exists) {
              _purchaseOrders.insert(0, widget.initialPO!);
            }
            // Auto-select and fetch details
            final po = _purchaseOrders.firstWhere((p) => p.id == widget.initialPO!.id);
            _onPOSelected(po);
          }
          
          _isLoadingPOs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPOs = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Purchase Orders: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedSiteId = int.tryParse(widget.selectedSiteId ?? '');
    
    if (widget.grnToEdit != null) {
      final edit = widget.grnToEdit!;
      _grnDateController.text = edit.grnDate != null 
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(edit.grnDate!))
          : DateFormat('yyyy-MM-dd').format(DateTime.now());
      _challanNumberController.text = edit.deliveryChallanNumber ?? '';
      _vehicleNumberController.text = edit.vehicleNumber ?? '';
      _gateEntryNumberController.text = edit.gateEntryNumber ?? '';
      _receivedByController.text = edit.receivedBy ?? '';
      _descriptionController.text = edit.description ?? '';
      _remarksController.text = edit.remarks ?? '';
      _selectedSiteId = int.tryParse(edit.siteId ?? '');
    } else {
      _grnDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
    _loadPurchaseOrders();
  }

  void _onPOSelected(PurchaseOrderModel? po) async {
    if (po == null) {
      setState(() {
        _selectedPO = null;
        _items = [];
      });
      return;
    }

    setState(() {
      _selectedPO = po;
      _isLoadingPOs = true;
    });

    try {
      final details = await _grnService.getGRNPODetails(poId: po.id);
      final List<dynamic> itemsData = details['data']?['items'] ?? [];
      final poData = details['data']?['po'] ?? {};

      if (mounted) {
        setState(() {
          // Backfill supplier/site names if missing (common in edit mode)
          _selectedPOSupplierName = poData['supplier_name']?.toString() ?? po.supplier?.name;
          _selectedPOSiteName = poData['site_name']?.toString() ?? po.site?.name;
          
          // Dispose old items
          for (var item in _items) {
            item.dispose();
          }
          
          if (widget.grnToEdit != null && widget.grnToEdit!.purchaseOrder?.id == po.id) {
            // Mapping existing GRN items to PO items
            _items = itemsData.map((data) {
              final grnItem = widget.grnToEdit!.items?.firstWhere(
                (gi) => gi.poItemId == data['id'].toString(),
                orElse: () => GRNItem(id: 0),
              );
              
              final item = GRNMaterialItem(itemData: data);
              if (grnItem != null && grnItem.id != 0) {
                item.receivedQtyController.text = grnItem.receivedQty ?? '0';
                item.acceptedQtyController.text = grnItem.acceptedQty ?? '0';
                item.rejectedQtyController.text = grnItem.rejectedQty ?? '0';
              }
              return item;
            }).toList();
          } else {
            _items = itemsData.map((data) => GRNMaterialItem(itemData: data)).toList();
          }
          
          _isLoadingPOs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPOs = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PO details: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _grnDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPO == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Purchase Order')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final grnData = {
        'po_id': _selectedPO!.id,
        'grn_date': _grnDateController.text,
        'delivery_challan_number': _challanNumberController.text,
        'vehicle_number': _vehicleNumberController.text,
        'gate_entry_number': _gateEntryNumberController.text,
        'description': _descriptionController.text,
        'received_by': _receivedByController.text,
        'remarks': _remarksController.text,
        'items': _items.map((item) => {
          'po_item_id': item.itemData['id'],
          'received_qty': double.tryParse(item.receivedQtyController.text) ?? 0,
          'accepted_qty': double.tryParse(item.acceptedQtyController.text) ?? 0,
          'rejected_qty': double.tryParse(item.rejectedQtyController.text) ?? 0,
          'remarks': item.remarksController.text,
        }).toList(),
      };

      if (widget.grnToEdit != null) {
        await _grnService.updateGRN(widget.grnToEdit!.id, grnData);
      } else {
        await _grnService.createGRN(grnData);
      }

      if (mounted) {
        widget.onGRNSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
       
          SnackBar(content: Text('GRN ${widget.grnToEdit != null ? 'updated' : 'created'} successfully'),backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save GRN: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _grnDateController.dispose();
    _challanNumberController.dispose();
    _vehicleNumberController.dispose();
    _gateEntryNumberController.dispose();
    _receivedByController.dispose();
    _descriptionController.dispose();
    _remarksController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 1) {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _currentStep++);
                    }
                  } else {
                    _submitForm();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    Navigator.pop(context);
                  }
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4a63c0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isSubmitting 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_currentStep == 1 ? 'Submit' : 'Next', style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Details & PO'),
                    isActive: _currentStep >= 0,
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildPOStep(),
                          const Divider(height: 32),
                          _buildInfoStep(),
                        ],
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('Items'),
                    isActive: _currentStep >= 1,
                    content: SingleChildScrollView(child: _buildItemsStep()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.add_shopping_cart, color: Color(0xFF4a63c0)),
          const SizedBox(width: 12),
          Text(
            widget.grnToEdit != null ? 'Edit GRN' : 'Add New GRN',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _grnDateController,
          label: 'GRN Date',
          icon: Icons.calendar_today,
          readOnly: true,
          onTap: _selectDate,
        ),
        _buildTextField(
          controller: _challanNumberController,
          label: 'Delivery Challan Number',
          icon: Icons.numbers,
        ),
        _buildTextField(
          controller: _vehicleNumberController,
          label: 'Vehicle Number',
          icon: Icons.local_shipping,
        ),
        _buildTextField(
          controller: _gateEntryNumberController,
          label: 'Gate Entry Number',
          icon: Icons.door_front_door,
        ),
        _buildTextField(
          controller: _receivedByController,
          label: 'Received By',
          icon: Icons.person,
        ),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          icon: Icons.description,
        ),
        _buildTextField(
          controller: _remarksController,
          label: 'Remarks',
          icon: Icons.comment,
        ),
      ],
    );
  }

  String _formatPODate(String? poDate) {
    if (poDate == null || poDate == 'N/A') return 'N/A';
    try {
      DateTime dt = DateTime.parse(poDate);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      return poDate;
    }
  }

  Widget _buildPOStep() {
    return Column(
      children: [
        if (_isLoadingPOs)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<PurchaseOrderModel>(
            value: _selectedPO,
            decoration: InputDecoration(
              labelText: 'Select Purchase Order*',
              labelStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.receipt_long, color: Color(0xFF4a63c0)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            items: _purchaseOrders.map((po) {
              return DropdownMenuItem(
                value: po,
                child: Text(po.poNumber ?? 'PO-${po.id}'),
              );
            }).toList(),
            onChanged: _onPOSelected,
            validator: (v) => v == null ? 'Please select a PO' : null,
          ),
        if (_selectedPO != null) ...[
          const SizedBox(height: 16),
          _buildInfoRow('Supplier', _selectedPOSupplierName ?? 'N/A'),
          _buildInfoRow('Site', _selectedPOSiteName ?? 'N/A'),
          _buildInfoRow('PO Date', _formatPODate(_selectedPO!.poDate ?? 'N/A')),
        ],
      ],
    );
  }

  Widget _buildItemsStep() {
    if (_items.isEmpty) {
      return const Center(child: Text('No items found in selected PO'));
    }
    return Column(
      children: _items.map((item) => _buildItemCard(item)).toList(),
    );
  }

  Widget _buildItemCard(GRNMaterialItem item) {
    return Card(
      color: Colors.white60,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.itemData['material_name'] ?? 'Unknown Material',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ordered: ${item.itemData['ordered_qty']} ${item.itemData['unit'] ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text('Remaining: ${item.itemData['remaining_qty']} ${item.itemData['unit'] ?? ''}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildSmallTextField(
                    controller: item.receivedQtyController,
                    label: 'Received',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSmallTextField(
                    controller: item.acceptedQtyController,
                    label: 'Accepted',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSmallTextField(
                    controller: item.rejectedQtyController,
                    label: 'Rejected',
                  ),
                ),
              ],
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xFF4a63c0)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (v) {
          if (label == 'GRN Date' && (v == null || v.isEmpty)) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSmallTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        keyboardType: label == 'Remarks' ? TextInputType.text : TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: const Color.fromARGB(255, 209, 209, 209)!),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
