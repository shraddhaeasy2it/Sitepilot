import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PurchaseInvoice {
  final String invoiceNo;
  final String invoiceDate;
  final String supplier;
  final String site;
  final double totalAmount;
  final String? invoiceFile;
  final String? supplierInvoiceNumber;
  final List<InvoiceMaterial>? materials;

  PurchaseInvoice({
    required this.invoiceNo,
    required this.invoiceDate,
    required this.supplier,
    required this.site,
    required this.totalAmount,
    this.invoiceFile,
    this.supplierInvoiceNumber,
    this.materials,
  });
}

class InvoiceMaterial {
  final String material;
  final double quantity;
  final String unit;
  final double price;
  final double subtotal;

  InvoiceMaterial({
    required this.material,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.subtotal,
  });
}

class PurchaseInvoicesPage extends StatefulWidget {
  const PurchaseInvoicesPage({super.key});

  @override
  State<PurchaseInvoicesPage> createState() => _PurchaseInvoicesPageState();
}

class _PurchaseInvoicesPageState extends State<PurchaseInvoicesPage> {
  final List<PurchaseInvoice> _invoices = [
    PurchaseInvoice(
      invoiceNo: 'INV-0010',
      invoiceDate: '07-10-2025',
      supplier: 'Shivam Constructions 1',
      site: 'Vijay Residency',
      totalAmount: 42134.00,
      supplierInvoiceNumber: 'SUP-INV-0010',
      materials: [
        InvoiceMaterial(
          material: 'Steel',
          quantity: 15,
          unit: 'kg',
          price: 956.00,
          subtotal: 14340.00,
        ),
        InvoiceMaterial(
          material: 'Blocks (AAC, concrete)',
          quantity: 12,
          unit: 'pcs',
          price: 980.00,
          subtotal: 11760.00,
        ),
        InvoiceMaterial(
          material: 'Concrete',
          quantity: 13,
          unit: 'kg',
          price: 780.00,
          subtotal: 10140.00,
        ),
        InvoiceMaterial(
          material: 'Shovel',
          quantity: 14,
          unit: 'liters',
          price: 421.00,
          subtotal: 5894.00,
        ),
      ],
    ),
    PurchaseInvoice(
      invoiceNo: 'INV-0009',
      invoiceDate: '14-10-2025',
      supplier: 'Shivam Constructions 1',
      site: 'Vijay Residency',
      totalAmount: 45449.00,
    ),
    PurchaseInvoice(
      invoiceNo: 'INV-0008',
      invoiceDate: '22-09-2025',
      supplier: 'Raj Materials 2',
      site: 'Nisarg Residency',
      totalAmount: 16208.00,
    ),
    PurchaseInvoice(
      invoiceNo: 'INV-0007',
      invoiceDate: '24-09-2025',
      supplier: 'GreenLogix Services 5',
      site: 'Vijay Residency',
      totalAmount: 3075.00,
    ),
    PurchaseInvoice(
      invoiceNo: 'INV-0006',
      invoiceDate: '19-09-2025',
      supplier: 'Shivam Constructions 1',
      site: 'Nisarg Residency',
      totalAmount: 8272.00,
    ),
    PurchaseInvoice(
      invoiceNo: 'INV-0005',
      invoiceDate: '20-09-2025',
      supplier: 'Raj Materials 2',
      site: 'Easy2IT SEO',
      totalAmount: 14030.00,
    ),
    PurchaseInvoice(
      invoiceNo: 'INV-0004',
      invoiceDate: '12-10-2025',
      supplier: 'Shivam Constructions 1',
      site: 'Nisarg Residency',
      totalAmount: 33949.00,
    ),
    PurchaseInvoice(
      invoiceNo: 'INV-0003',
      invoiceDate: '23-09-2025',
      supplier: 'GreenLogix Services 5',
      site: 'Nisarg Residency',
      totalAmount: 18482.00,
    ),
    PurchaseInvoice(
      invoiceNo: 'INV-0002',
      invoiceDate: '24-09-2025',
      supplier: 'GreenLogix Services 5',
      site: 'Vijay Residency',
      totalAmount: 14226.00,
    ),
  ];

  final List<String> _sites = [
    'Vijay Residency',
    'Nisarg Residency',
    'Easy2IT SEO',
  ];

  final List<String> _suppliers = [
    'Shivam Constructions 1',
    'Raj Materials 2',
    'GreenLogix Services 5',
  ];

  final List<String> _materials = [
    'Steel',
    'Blocks (AAC, concrete)',
    'Concrete',
    'Shovel',
    'Cement',
    'Sand',
    'Bricks',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<PurchaseInvoice> get _filteredInvoices {
    if (_searchQuery.isEmpty) {
      return _invoices;
    }
    return _invoices.where((invoice) {
      return invoice.invoiceNo.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          invoice.supplier.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          invoice.site.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showAddInvoiceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddEditInvoiceBottomSheet(),
    );
  }

  void _showEditInvoiceBottomSheet(PurchaseInvoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditInvoiceBottomSheet(invoice: invoice),
    );
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
            'Are you sure you want to delete invoice ${invoice.invoiceNo}?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _invoices.removeWhere(
                    (inv) => inv.invoiceNo == invoice.invoiceNo,
                  );
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Invoice ${invoice.invoiceNo} deleted successfully',
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
            icon: const Icon(Icons.add),
            onPressed: _showAddInvoiceBottomSheet,
            tooltip: 'Add New Invoice',
          ),
        ],
      ),
      body: Column(
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
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Invoice Cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filteredInvoices.length,
              itemBuilder: (context, index) {
                final invoice = _filteredInvoices[index];
                return InvoiceCard(
                  invoice: invoice,
                  onEdit: () => _showEditInvoiceBottomSheet(invoice),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onEdit,
    required this.onDelete,
  });

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
                Text(
                  invoice.invoiceNo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2a43a0),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      color: Color(0xFF2a43a0),
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
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(invoice.invoiceDate, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    invoice.supplier,
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
                Text(invoice.site, style: const TextStyle(fontSize: 14)),
              ],
            ),
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

  const AddEditInvoiceBottomSheet({super.key, this.invoice});

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

  String? _selectedSite;
  String? _selectedSupplier;
  final List<MaterialItem> _materialItems = [];

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      // Edit mode - populate fields
      _invoiceNoController.text = widget.invoice!.invoiceNo;
      _supplierInvoiceNoController.text =
          widget.invoice!.supplierInvoiceNumber ?? '';
      _selectedSite = widget.invoice!.site;
      _selectedSupplier = widget.invoice!.supplier;
      _invoiceDateController.text = _formatDateForDisplay(
        DateTime(2025, 10, 7),
      );
      _selectedDate = DateTime(2025, 10, 7);

      // Populate materials for edit mode
      if (widget.invoice!.materials != null) {
        for (var material in widget.invoice!.materials!) {
          _materialItems.add(
            MaterialItem(
              material: material.material,
              quantity: material.quantity.toString(),
              unit: material.unit,
              price: material.price.toStringAsFixed(2),
              subtotal: material.subtotal.toStringAsFixed(2),
            ),
          );
        }
      }
    } else {
      // Add mode - set default values
      _invoiceNoController.text = 'INV-0011';
      _invoiceDateController.text = _formatDateForDisplay(
        DateTime(2025, 10, 17),
      );
      _selectedDate = DateTime(2025, 10, 17);
      _selectedSupplier = 'Shivam Constructions 1';
      _selectedSite = 'Nisarg Residency';
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
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
    double total = 0;
    for (var item in _materialItems) {
      if (item.subtotal.isNotEmpty) {
        total += double.tryParse(item.subtotal) ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.invoice != null;

    return SingleChildScrollView(
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
              Center(
                child: Text(
                  isEdit ? 'Edit Material' : 'Create Purchase Invoice',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  hintText: 'Enter invoice number',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ), // Reduced padding
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
                  ), // Reduced padding
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),

              // Project/Site
              const Text(
                'Project / Site*',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4), // Reduced spacing
              DropdownButtonFormField<String>(
                value: _selectedSite,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ), // Reduced padding
                  isDense: true, // This significantly reduces height
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Vijay Residency',
                    child: Text('Vijay Residency'),
                  ),
                  DropdownMenuItem(
                    value: 'Nisarg Residency',
                    child: Text('Nisarg Residency'),
                  ),
                  DropdownMenuItem(
                    value: 'Easy2IT SEO',
                    child: Text('Easy2IT SEO'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSite = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a site';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Invoice Materials Section
              const Text(
                'Invoice Material',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Materials Header
              const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'MATERIAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'QUANTITY | UNIT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'PRICE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'SUBTOTAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(width: 30), // Space for delete button
                ],
              ),
              const SizedBox(height: 8),

              // Material Items List
              if (_materialItems.isNotEmpty) ...[
                ..._materialItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return MaterialItemRow(
                    item: item,
                    index: index,
                    onUpdate: (updatedItem) =>
                        _updateMaterialItem(index, updatedItem),
                    onRemove: () => _removeMaterialItem(index),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Add empty material item row if no items
              if (_materialItems.isEmpty)
                MaterialItemRow(
                  item: MaterialItem(),
                  index: 0,
                  onUpdate: (updatedItem) =>
                      _updateMaterialItem(0, updatedItem),
                  onRemove: null,
                ),

              // Add Item Button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addMaterialItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ),
              const SizedBox(height: 16),

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
                onTap: () => _selectDate(context),
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
              DropdownButtonFormField<String>(
                value: _selectedSupplier,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Shivam Constructions 1',
                    child: Text('Shivam Constructions 1'),
                  ),
                  DropdownMenuItem(
                    value: 'Raj Materials 2',
                    child: Text('Raj Materials 2'),
                  ),
                  DropdownMenuItem(
                    value: 'GreenLogix Services 5',
                    child: Text('GreenLogix Services 5'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSupplier = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a supplier';
                  }
                  return null;
                },
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
                  onPressed: () {
                    // Implement file picker
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Icon(Icons.upload_file),
                        SizedBox(height: 4),
                        Text('Choose File'),
                        SizedBox(height: 2),
                        Text(
                          'No file chosen',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      onPressed: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Save invoice logic here
                          Navigator.pop(context);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(isEdit ? 'Update' : 'Create'),
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
}

class MaterialItem {
  String material;
  String quantity;
  String unit;
  String price;
  String subtotal;

  MaterialItem({
    this.material = '',
    this.quantity = '',
    this.unit = '',
    this.price = '',
    this.subtotal = '0.00',
  });
}

class MaterialItemRow extends StatefulWidget {
  final MaterialItem item;
  final int index;
  final Function(MaterialItem) onUpdate;
  final Function()? onRemove;

  const MaterialItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.onUpdate,
    this.onRemove,
  });

  @override
  State<MaterialItemRow> createState() => _MaterialItemRowState();
}

class _MaterialItemRowState extends State<MaterialItemRow> {
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _subtotalController = TextEditingController();

  final List<String> _availableMaterials = [
    'Steel',
    'Blocks (AAC, concrete)',
    'Concrete',
    'Shovel',
    'Cement',
    'Sand',
    'Bricks',
  ];

  final List<String> _availableUnits = [
    'kg',
    'pcs',
    'liters',
    'units',
    'bags',
    'tons',
  ];

  @override
  void initState() {
    super.initState();
    _materialController.text = widget.item.material;
    _quantityController.text = widget.item.quantity;
    _unitController.text = widget.item.unit;
    _priceController.text = widget.item.price;
    _subtotalController.text = widget.item.subtotal;
  }

  void _calculateSubtotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final subtotal = quantity * price;

    _subtotalController.text = subtotal.toStringAsFixed(2);

    widget.onUpdate(
      MaterialItem(
        material: _materialController.text,
        quantity: _quantityController.text,
        unit: _unitController.text,
        price: _priceController.text,
        subtotal: _subtotalController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Material Dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _materialController.text.isEmpty
                  ? null
                  : _materialController.text,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Material',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              items: _availableMaterials.map((material) {
                return DropdownMenuItem(
                  value: material,
                  child: Text(material, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _materialController.text = value ?? '';
                });
                _calculateSubtotal();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Quantity and Unit
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateSubtotal(),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _unitController.text.isEmpty
                        ? null
                        : _unitController.text,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                    ),
                    items: _availableUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _unitController.text = value ?? '';
                      });
                      _calculateSubtotal();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Price
          Expanded(
            child: TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateSubtotal(),
            ),
          ),
          const SizedBox(width: 8),

          // Subtotal
          Expanded(
            child: TextFormField(
              controller: _subtotalController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              readOnly: true,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),

          // Delete Button
          if (widget.onRemove != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: widget.onRemove,
            ),
        ],
      ),
    );
  }
}
