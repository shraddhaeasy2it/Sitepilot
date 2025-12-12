import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/admin/models/purchase_model.dart';
import 'package:ecoteam_app/admin/services/Allsupplier_service.dart';
import 'package:ecoteam_app/admin/services/purchase_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PurchaseInvoicesPage extends StatefulWidget {
  const PurchaseInvoicesPage({super.key});

  @override
  State<PurchaseInvoicesPage> createState() => _PurchaseInvoicesPageState();
}

class _PurchaseInvoicesPageState extends State<PurchaseInvoicesPage> {
  List<PurchaseInvoice> _invoices = [];
  List<Supplier> _suppliers = [];
  List<SiteModel> _sites = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final invoices = await ApiServicePurchaseInvoice.getInvoices();
      final suppliers = await ApiServicePurchaseInvoice.getSuppliers();
      final sites = await ApiServicePurchaseInvoice.getSites();

      setState(() {
        _invoices = invoices;
        _suppliers = suppliers;
        _sites = sites;
        _isLoading = false;
      });

      print(
        'Loaded ${_invoices.length} invoices, ${_suppliers.length} suppliers, ${_sites.length} sites',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
      print('Error loading all data: $e');
    }
  }

  List<PurchaseInvoice> get _filteredInvoices {
    if (_searchQuery.isEmpty) {
      return _invoices;
    }
    return _invoices.where((invoice) {
      return invoice.invoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          invoice.supplierInvoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          _getSupplierName(
            invoice.supplierId,
          ).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          _getSiteName(
            invoice.siteId,
          ).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showAddInvoiceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditInvoiceBottomSheet(
        suppliers: _suppliers,
        sites: _sites,
        onInvoiceSaved: () {
          // Refresh the data immediately after successful creation
          _loadAllData();
        },
        onSupplierCreated: _loadSuppliers, // Callback to refresh suppliers
      ),
    );
  }

  void _showEditInvoiceBottomSheet(PurchaseInvoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditInvoiceBottomSheet(
        invoice: invoice,
        suppliers: _suppliers,
        sites: _sites,
        onInvoiceSaved: _loadAllData,
        onSupplierCreated: _loadSuppliers, // Callback to refresh suppliers
      ),
    );
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await ApiServicePurchaseInvoice.getSuppliers();
      setState(() {
        _suppliers = suppliers;
      });
    } catch (e) {
      print('Error loading suppliers: $e');
    }
  }

  void _showDeleteInvoiceDialog(PurchaseInvoice invoice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Invoice',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete invoice ${invoice.invoiceNumber}?',
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
                  await ApiServicePurchaseInvoice.deleteInvoice(invoice.id);
                  // Remove from local list immediately for better UX
                  setState(() {
                    _invoices.removeWhere((inv) => inv.id == invoice.id);
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Invoice ${invoice.invoiceNumber} deleted successfully',
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
                        content: Text('Failed to delete invoice: $e'),
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

  String _getSiteName(int siteId) {
    try {
      final site = _sites.firstWhere((site) => site.id == siteId);
      return site.name;
    } catch (e) {
      print(
        'Site not found for id: $siteId, available sites: ${_sites.map((s) => '${s.id}: ${s.name}').toList()}',
      );
      return 'Unknown Site';
    }
  }

  String _getSupplierName(int supplierId) {
    try {
      final supplier = _suppliers.firstWhere(
        (supplier) => supplier.id == supplierId,
      );
      return supplier.name;
    } catch (e) {
      return 'Unknown Supplier';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Purchase Invoices',
          style: TextStyle(color: Colors.white),
        ),
        toolbarHeight: 80.h,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
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
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 28.sp),
            onPressed: _showAddInvoiceBottomSheet,
            tooltip: 'Add New Invoice',
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 28.sp),
            onPressed: _loadAllData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                  ElevatedButton(
                    onPressed: _loadAllData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search invoices...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Entry Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${_filteredInvoices.length} of ${_invoices.length} invoices',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Invoice Cards
                Expanded(
                  child: _invoices.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No invoices found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first invoice',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _filteredInvoices[index];
                            return InvoiceCard(
                              invoice: invoice,
                              getSiteName: _getSiteName,
                              getSupplierName: _getSupplierName,
                              onEdit: () =>
                                  _showEditInvoiceBottomSheet(invoice),
                              onDelete: () => _showDeleteInvoiceDialog(invoice),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  final PurchaseInvoice invoice;
  final String Function(int) getSiteName;
  final String Function(int) getSupplierName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.getSiteName,
    required this.getSupplierName,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getInvoiceTypeDisplay(String invoiceType) {
    switch (invoiceType) {
      case 'general_po':
        return 'General PO';
      case 'minor_misc_service':
        return 'Minor Miscellaneous Service';
      default:
        return invoiceType.replaceAll('_', ' ').toTitleCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2a43a0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getInvoiceTypeDisplay(invoice.invoiceType),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: invoice.status == 'Cancelled'
                        ? Colors.red
                        : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    invoice.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(invoice.invoiceDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      color: const Color(0xFF2a43a0),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getSupplierName(invoice.supplierId),
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  getSiteName(invoice.siteId),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (invoice.supplierInvoiceNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.receipt, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Supplier: ${invoice.supplierInvoiceNumber}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rs ${invoice.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class AddEditInvoiceBottomSheet extends StatefulWidget {
  final PurchaseInvoice? invoice;
  final List<Supplier> suppliers;
  final List<SiteModel> sites;
  final VoidCallback? onInvoiceSaved;
  final VoidCallback? onSupplierCreated;

  const AddEditInvoiceBottomSheet({
    super.key,
    this.invoice,
    required this.suppliers,
    required this.sites,
    this.onInvoiceSaved,
    this.onSupplierCreated,
  });

  @override
  State<AddEditInvoiceBottomSheet> createState() =>
      _AddEditInvoiceBottomSheetState();
}

class _AddEditInvoiceBottomSheetState extends State<AddEditInvoiceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _supplierInvoiceNoController =
      TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();

  int? _selectedSiteId;
  int? _selectedSupplierId;
  final List<MaterialItem> _materialItems = [];
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedDate;
  bool _isSubmitting = false;
  List<MaterialModel> _materials = [];
  List<UnitModel> _units = [];
  bool _isLoadingMaterials = false;
  
  // Invoice type dropdown value
  String _selectedInvoiceType = 'general_po';
  final List<Map<String, String>> _invoiceTypeOptions = [
    {'value': 'general_po', 'label': 'General PO'},
    {'value': 'minor_misc_service', 'label': 'Minor Miscellaneous Service Bills'},
  ];

  // Local suppliers list that can be updated
  List<Supplier> _localSuppliers = [];

  @override
  void initState() {
    super.initState();
    // Initialize with passed suppliers
    _localSuppliers = widget.suppliers;
    _loadMaterialsAndUnits();

    if (widget.invoice != null) {
      // Edit mode - populate fields
      _invoiceNoController.text = widget.invoice!.invoiceNumber;
      _supplierInvoiceNoController.text = widget.invoice!.supplierInvoiceNumber;

      _selectedSiteId = widget.invoice!.siteId;
      _selectedSupplierId = widget.invoice!.supplierId;
      _selectedInvoiceType = widget.invoice!.invoiceType;

      _invoiceDateController.text = _formatDateForDisplay(
        DateTime.parse(widget.invoice!.invoiceDate),
      );
      _selectedDate = DateTime.parse(widget.invoice!.invoiceDate);

      // Populate materials only if invoice type is general_po
      if (_selectedInvoiceType == 'general_po' && widget.invoice!.items != null) {
        for (var item in widget.invoice!.items!) {
          String materialName = 'Material ${item.materialId}';
          String unitSymbol = item.unit;

          _materialItems.add(
            MaterialItem(
              materialId: item.materialId,
              materialName: materialName,
              quantity: item.quantity.toString(),
              unit: unitSymbol,
              price: item.price.toStringAsFixed(2),
              subtotal: item.subtotal.toStringAsFixed(2),
            ),
          );
        }
      }
    } else {
      // Add mode - set default values
      _invoiceNoController.text =
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      _invoiceDateController.text = _formatDateForDisplay(DateTime.now());
      _selectedDate = DateTime.now();
      _selectedSupplierId = _localSuppliers.isNotEmpty
          ? _localSuppliers.first.id
          : null;
      _selectedSiteId = widget.sites.isNotEmpty ? widget.sites.first.id : null;

      // Add one empty material item for add mode if invoice type is general_po
      if (_selectedInvoiceType == 'general_po') {
        _addMaterialItem();
      }
    }
  }

  // Add this method to refresh local suppliers
  Future<void> _refreshSuppliers() async {
    try {
      final suppliers = await ApiServicePurchaseInvoice.getSuppliers();
      setState(() {
        _localSuppliers = suppliers;
      });
    } catch (e) {
      print('Error refreshing suppliers: $e');
    }
  }

  Future<void> _loadMaterialsAndUnits() async {
    setState(() {
      _isLoadingMaterials = true;
    });

    try {
      final materials = await ApiServicePurchaseInvoice.getMaterials();
      final units = await ApiServicePurchaseInvoice.getUnits();

      setState(() {
        _materials = materials;
        _units = units;
        _isLoadingMaterials = false;
      });

      // If in edit mode and we have materials, update the material names
      if (widget.invoice != null && _materials.isNotEmpty) {
        for (int i = 0; i < _materialItems.length; i++) {
          final item = _materialItems[i];
          try {
            final material = _materials.firstWhere(
              (m) => m.id == item.materialId,
            );
            if (material.name != item.materialName) {
              setState(() {
                _materialItems[i] = MaterialItem(
                  materialId: item.materialId,
                  materialName: material.name,
                  quantity: item.quantity,
                  unit: item.unit,
                  price: item.price,
                  subtotal: item.subtotal,
                );
              });
            }
          } catch (e) {
            print('Material not found for id: ${item.materialId}');
          }
        }
      }

      print('Loaded ${_materials.length} materials and ${_units.length} units');
    } catch (e) {
      print('Error loading materials or units: $e');
      setState(() {
        _isLoadingMaterials = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load materials: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
        _invoiceDateController.text = _formatDateForDisplay(picked);
      });
    }
  }

  Future<void> _pickFile() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedFile = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedFile = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateSupplierBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateSupplierBottomSheet(
        onSupplierCreated: (newSupplierId) async {
          // First refresh the parent's supplier list
          widget.onSupplierCreated?.call();
          
          // Then refresh our local supplier list
          await _refreshSuppliers();
          
          // Wait a moment for the state to update
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Set the newly created supplier as selected
          if (mounted) {
            setState(() {
              _selectedSupplierId = newSupplierId;
            });
          }
        },
      ),
    );
  }

  void _addMaterialItem() {
    setState(() {
      _materialItems.add(MaterialItem());
    });
  }

  void _updateMaterialItem(int index, MaterialItem updatedItem) {
    setState(() {
      _materialItems[index] = updatedItem;
    });
  }

  void _removeMaterialItem(int index) {
    setState(() {
      _materialItems.removeAt(index);
    });
  }

  double get _totalAmount {
    if (_selectedInvoiceType == 'minor_misc_service') {
      // For minor misc service, you might want to add a separate field for total amount
      // For now, we'll return 0 or you can add a separate text field for total amount
      return 0;
    }
    
    double total = 0;
    for (var item in _materialItems) {
      if (item.subtotal.isNotEmpty) {
        total += double.tryParse(item.subtotal) ?? 0;
      }
    }
    return total;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInvoiceType == 'general_po' && _materialItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one material item for General PO'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSiteId == null || _selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select site and supplier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> invoiceData = {
        'invoice_number': _invoiceNoController.text,
        'invoice_date': _invoiceDateController.text,
        'supplier_invoice_number': _supplierInvoiceNoController.text,
        'supplier_id': _selectedSupplierId.toString(),
        'total_amount': _totalAmount.toStringAsFixed(2),
        'site_id': _selectedSiteId.toString(),
        'created_by': '1', // Assuming current user ID is 1
        'workspace_id': '1', // Assuming workspace ID is 1
        'invoice_type': _selectedInvoiceType,
        'invoice_file': _selectedFile,
      };

      // Add items only for general_po
      if (_selectedInvoiceType == 'general_po') {
        invoiceData['items'] = _materialItems
            .where((item) => item.materialId > 0)
            .map(
              (item) => {
                'material_id': item.materialId.toString(),
                'quantity': item.quantity,
                'unit': item.unit,
                'price': item.price,
                'subtotal': item.subtotal,
              },
            )
            .toList();
      }

      print('Submitting invoice data: $invoiceData');

      PurchaseInvoice result;
      if (widget.invoice != null) {
        result = await ApiServicePurchaseInvoice.updateInvoice(
          widget.invoice!.id,
          invoiceData,
        );
      } else {
        result = await ApiServicePurchaseInvoice.createInvoice(invoiceData);
      }

      print('Invoice saved successfully: ${result.invoiceNumber}');

      if (mounted) {
        Navigator.pop(context);
        widget.onInvoiceSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.invoice != null
                  ? 'Invoice ${result.invoiceNumber} updated successfully'
                  : 'Invoice ${result.invoiceNumber} created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error submitting form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save invoice: $e'),
            backgroundColor: Colors.red,
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
    final bool isEdit = widget.invoice != null;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Invoice' : 'Create Purchase Invoice',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                const SizedBox(height: 24),

                // Invoice Number
                const Text(
                  'Invoice Number*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _invoiceNoController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    hintText: 'Enter Invoice Number',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter invoice number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Supplier Invoice Number
                const Text(
                  'Supplier Invoice Number',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _supplierInvoiceNoController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    hintText: 'Enter Supplier Invoice Number',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Project/Site
                const Text(
                  'Project / Site*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: _selectedSiteId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  items: widget.sites.map((site) {
                    return DropdownMenuItem<int>(
                      value: site.id,
                      child: Text(site.name),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSiteId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a site';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Invoice Type
                const Text(
                  'Invoice Type*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedInvoiceType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  items: _invoiceTypeOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedInvoiceType = value!;
                            // If switching to general_po and no items, add one
                            if (value == 'general_po' && _materialItems.isEmpty) {
                              _addMaterialItem();
                            }
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select invoice type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Invoice Materials Section - Only show for General PO
                if (_selectedInvoiceType == 'general_po') ...[
                  const Text(
                    'Invoice Material',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingMaterials) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else ...[
                    // Material Items List
                    if (_materialItems.isNotEmpty) ...[
                      ..._materialItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return MaterialItemRow(
                          item: item,
                          index: index,
                          materials: _materials,
                          units: _units,
                          onUpdate: (updatedItem) =>
                              _updateMaterialItem(index, updatedItem),
                          onRemove: _isSubmitting
                              ? null
                              : () => _removeMaterialItem(index),
                        );
                      }),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Add empty material item row if no items
                      MaterialItemRow(
                        item: MaterialItem(),
                        index: 0,
                        materials: _materials,
                        units: _units,
                        onUpdate: (updatedItem) =>
                            _updateMaterialItem(0, updatedItem),
                        onRemove: null,
                      ),
                    ],

                    // Add Item Button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _addMaterialItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],

                // Invoice Date
                const Text(
                  'Invoice Date*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _invoiceDateController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _isSubmitting ? null : () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select invoice date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Supplier
                const Text(
                  'Supplier*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedSupplierId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  items: _localSuppliers.map((supplier) {
                    return DropdownMenuItem<int>(
                      value: supplier.id,
                      child: Text(
                        supplier.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSupplierId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a supplier';
                    }
                    return null;
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 8),

                // Create New Supplier Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _showCreateSupplierBottomSheet,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create New Supplier'),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Invoice File Upload
                const Text(
                  'Invoice File',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _pickFile,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Icon(Icons.upload_file),
                          const SizedBox(height: 4),
                          const Text('Choose File'),
                          const SizedBox(height: 2),
                          Text(
                            _selectedFile != null
                                ? _selectedFile!.path.split('/').last
                                : 'No file chosen',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Allowed: pdf, jpg, jpeg, png, doc, docx',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Total Amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rs ${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                              : Text(isEdit ? 'Update' : 'Create'),
                        ),
                      ),
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
}
// Update the CreateSupplierBottomSheet to return the created supplier ID
class CreateSupplierBottomSheet extends StatefulWidget {
  final Function(int)? onSupplierCreated; // Changed to return supplier ID

  const CreateSupplierBottomSheet({
    super.key,
    this.onSupplierCreated,
  });

  @override
  State<CreateSupplierBottomSheet> createState() => _CreateSupplierBottomSheetState();
}

class _CreateSupplierBottomSheetState extends State<CreateSupplierBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _upiScreenshot1;
  final ImagePicker _picker = ImagePicker();

  int? _selectedCategoryId;
  List<SupplierCategory> _categories = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await SupplierApiService.getSupplierCategories();
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickUpiScreenshot1() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _upiScreenshot1 = File(image.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create multipart request for file uploads
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${SupplierApiService.baseUrl}/suppliers'),
      );

      // Add required fields based on API screenshot
      request.fields['name'] = _nameController.text;
      request.fields['category_id'] = _selectedCategoryId!.toString();
      request.fields['created_by'] = '1'; // Default user ID
      request.fields['workspace_id'] = '1'; // Default workspace ID
      
      // Add optional phone field if entered
      if (_phoneController.text.isNotEmpty) {
        request.fields['phone'] = _phoneController.text;
      }

      // Add UPI screenshot if available
      if (_upiScreenshot1 != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'upi_screenshot_1',
            _upiScreenshot1!.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Supplier creation response status: ${response.statusCode}');
      print('Supplier creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 1) {
          final supplierData = responseData['data'];
          final newSupplierId = supplierData['id'] as int;
          
          if (mounted) {
            Navigator.pop(context);
            // Pass the new supplier ID back
            widget.onSupplierCreated?.call(newSupplierId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Supplier created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else if (response.statusCode == 422) {
        // Handle validation errors
        final responseData = json.decode(response.body);
        print('Validation errors: $responseData');
        
        String errorMessage = 'Validation failed';
        if (responseData is Map && responseData.containsKey('errors')) {
          final errors = responseData['errors'];
          if (errors is Map) {
            final errorList = errors.entries.map((e) => '${e.key}: ${e.value.join(', ')}').toList();
            errorMessage = errorList.join('\n');
          }
        }
        
        throw Exception(errorMessage);
      } else {
        throw Exception('Failed to create supplier. Status code: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error creating supplier: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create supplier: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create New Supplier',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                const SizedBox(height: 24),

                // Name
                const Text(
                  'Name*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    hintText: 'Enter Supplier Name',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter supplier name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category
                const Text(
                  'Category*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 16),

                // Phone (Optional)
                const Text(
                  'Phone',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    hintText: 'Enter Phone Number',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // UPI Screenshot (Optional)
                const Text(
                  'UPI Screenshot',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _pickUpiScreenshot1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Icon(Icons.upload_file),
                          const SizedBox(height: 4),
                          const Text('Choose File'),
                          const SizedBox(height: 2),
                          Text(
                            _upiScreenshot1 != null
                                ? _upiScreenshot1!.path.split('/').last
                                : 'No file chosen',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Allowed: jpg, jpeg, png',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Close'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                              : const Text('Save Supplier'),
                        ),
                      ),
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
}// Material Item Class
class MaterialItem {
  int materialId;
  String materialName;
  String quantity;
  String unit;
  String price;
  String subtotal;

  MaterialItem({
    this.materialId = 0,
    this.materialName = '',
    this.quantity = '',
    this.unit = '',
    this.price = '',
    this.subtotal = '0.00',
  });

  // Add copyWith method for easier updates
  MaterialItem copyWith({
    int? materialId,
    String? materialName,
    String? quantity,
    String? unit,
    String? price,
    String? subtotal,
  }) {
    return MaterialItem(
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}

class MaterialItemRow extends StatefulWidget {
  final MaterialItem item;
  final int index;
  final List<MaterialModel> materials;
  final List<UnitModel> units;
  final Function(MaterialItem) onUpdate;
  final Function()? onRemove;

  const MaterialItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.materials,
    required this.units,
    required this.onUpdate,
    this.onRemove,
  });

  @override
  State<MaterialItemRow> createState() => _MaterialItemRowState();
}

class _MaterialItemRowState extends State<MaterialItemRow> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _subtotalController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  MaterialModel? _selectedMaterial;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(MaterialItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    // Initialize with item data
    _quantityController.text = widget.item.quantity;
    _priceController.text = widget.item.price;
    _subtotalController.text = widget.item.subtotal;
    _unitController.text = widget.item.unit;

    // Find the material by ID for edit mode
    if (widget.item.materialId > 0) {
      try {
        _selectedMaterial = widget.materials.firstWhere(
          (material) => material.id == widget.item.materialId,
        );
        // Set the unit from the material if available
        if (_selectedMaterial?.unit != null) {
          _unitController.text = _selectedMaterial!.unit!.symbol;
        }
      } catch (e) {
        _selectedMaterial = null;
      }
    } else {
      _selectedMaterial = null;
    }
  }

  void _calculateSubtotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final subtotal = quantity * price;

    setState(() {
      _subtotalController.text = subtotal.toStringAsFixed(2);
    });

    // Update the parent with new item data
    widget.onUpdate(
      MaterialItem(
        materialId: _selectedMaterial?.id ?? 0,
        materialName: _selectedMaterial?.name ?? '',
        quantity: _quantityController.text,
        unit: _unitController.text,
        price: _priceController.text,
        subtotal: _subtotalController.text,
      ),
    );
  }

  // Get unique materials by ID to avoid duplicates
  List<MaterialModel> get _uniqueMaterials {
    final uniqueMaterials = <MaterialModel>[];
    final seenIds = <int>{};

    for (final material in widget.materials) {
      if (!seenIds.contains(material.id)) {
        seenIds.add(material.id);
        uniqueMaterials.add(material);
      }
    }
    return uniqueMaterials;
  }

  void _showMaterialSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Select Material',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _uniqueMaterials.length,
                itemBuilder: (context, index) {
                  final material = _uniqueMaterials[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(material.name),
                      subtitle: Text(
                        'Price: \$${material.price.toStringAsFixed(2)}',
                      ),
                      trailing: _selectedMaterial?.id == material.id
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedMaterial = material;
                          _priceController.text = material.price
                              .toStringAsFixed(2);
                          if (material.unit != null) {
                            _unitController.text = material.unit!.symbol;
                          } else {
                            _unitController.text = '';
                          }
                          _calculateSubtotal();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      height: null,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(255, 202, 202, 202)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              /// Material Selection
              Expanded(
                flex: 2,
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _selectedMaterial?.name ?? 'Select Material',
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    labelText: 'Material',
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  onTap: _showMaterialSelectionDialog,
                ),
              ),
              const SizedBox(width: 12),

              /// Qty | Unit
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    // Qty Input
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          hintText: 'Quantity',
                          labelText: 'QTY',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calculateSubtotal(),
                      ),
                    ),

                    // Unit Display
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          _unitController.text.isEmpty
                              ? 'Unit'
                              : _unitController.text,
                          style: TextStyle(
                            color: _unitController.text.isEmpty
                                ? Colors.grey
                                : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              /// Price Input
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Price',
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _calculateSubtotal(),
                ),
              ),
              const SizedBox(width: 12),

              /// Subtotal Display
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _subtotalController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Subtotal',
                    hintText: '0.00',
                  ),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              /// Delete button
              if (widget.onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _subtotalController.dispose();
    _unitController.dispose();
    super.dispose();
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String toTitleCase() {
    return split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}