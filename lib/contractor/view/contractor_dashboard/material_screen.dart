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
import 'package:intl/intl.dart';

import '../../models/site_model.dart';

class MaterialScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  const MaterialScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<MaterialScreen> createState() => _PurchaseInvoicesPageState();
}

class _PurchaseInvoicesPageState extends State<MaterialScreen> {
  List<PurchaseInvoice> _invoices = [];
  List<Supplier> _suppliers = [];
  List<SiteModel> _sites = [];
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
    _loadAllData();
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

  // Get the current site ID
  String? get _currentSiteId {
    return widget.selectedSiteId;
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load suppliers and sites first
      final suppliers = await ApiServicePurchaseInvoice.getSuppliers();
      final sites = await ApiServicePurchaseInvoice.getSites();
      
      // Load invoices filtered by selected site
      List<PurchaseInvoice> invoices;
      if (_currentSiteId != null) {
        // Fetch invoices for the specific site
        invoices = await ApiServicePurchaseInvoice.getInvoicesBySiteId(
          int.parse(_currentSiteId!)
        );
      } else {
        // Fetch all invoices if no site is selected
        invoices = await ApiServicePurchaseInvoice.getInvoices();
      }

      setState(() {
        _invoices = invoices;
        _suppliers = suppliers;
        _sites = sites;
        _isLoading = false;
      });

      print(
        'Loaded ${_invoices.length} invoices for site ${_currentSiteId ?? "All Sites"}, ${_suppliers.length} suppliers, ${_sites.length} sites',
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
    // Pass the current site ID to the bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditInvoiceBottomSheet(
        suppliers: _suppliers,
        sites: _sites,
        preselectedSiteId: _currentSiteId != null ? int.parse(_currentSiteId!) : null,
        onInvoiceSaved: () {
          _loadAllData();
        },
        onSupplierCreated: _loadSuppliers,
      ),
    );
  }

  void _showEditInvoiceBottomSheet(PurchaseInvoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditInvoiceBottomSheet(
        invoice: invoice,
        suppliers: _suppliers,
        sites: _sites,
        preselectedSiteId: _currentSiteId != null ? int.parse(_currentSiteId!) : null,
        onInvoiceSaved: _loadAllData,
        onSupplierCreated: _loadSuppliers,
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search invoices...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
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
                hintStyle: TextStyle(
                  color: textSecondary,
                  fontSize: 16,
                ),
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
              child: Icon(
                Icons.receipt_long,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _currentSiteId != null ? 'No invoices for this site' : 'No invoices found',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty && _invoices.isEmpty
                  ? (_currentSiteId != null 
                      ? 'Start by adding an invoice for ${_getCurrentSiteName()}'
                      : 'Start by adding your first invoice')
                  : 'Try adjusting your search criteria',
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_currentSiteId != null) ...[
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
                  onPressed: _showAddInvoiceBottomSheet,
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
                      'Add Invoice',
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.red;
      case 'paid':
        return Colors.blue;
      default:
        return primaryColor;
    }
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
              'Material Purchase Invoice',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
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
        toolbarHeight: 80.h,
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
                      onPressed: _loadAllData,
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
                        '${_filteredInvoices.length} invoices',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Total: \Rs ${_invoices.fold<double>(0, (sum, invoice) => sum + invoice.totalAmount).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _invoices.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 100,
                          ),
                          itemCount: _filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _filteredInvoices[index];
                            return _buildInvoiceCard(invoice);
                          },
                        ),
                ),
              ],
            ),
     
    );
  }

  Widget _buildInvoiceCard(PurchaseInvoice invoice) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showEditInvoiceBottomSheet(invoice),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with invoice number and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.receipt,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  invoice.invoiceNumber,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Padding(
                            padding: const EdgeInsets.only(left: 44),
                            child: Text(
                              _getInvoiceTypeDisplay(invoice.invoiceType),
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(invoice.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(invoice.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        invoice.status,
                        style: TextStyle(
                          color: _getStatusColor(invoice.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Invoice details in compact grid
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.calendar_today,
                        'Date',
                        _formatDate(invoice.invoiceDate),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.business,
                        'Supplier',
                        _getSupplierName(invoice.supplierId),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.location_on,
                        'Site',
                        _getSiteName(invoice.siteId),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.receipt_long,
                        'Supplier Inv',
                        invoice.supplierInvoiceNumber.isNotEmpty
                            ? invoice.supplierInvoiceNumber
                            : 'N/A',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Total amount and actions row
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs ${invoice.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.edit, size: 18),
                              onPressed: () => _showEditInvoiceBottomSheet(invoice),
                              color: primaryColor,
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
                              icon: Icon(Icons.delete, size: 18),
                              onPressed: () => _showDeleteInvoiceDialog(invoice),
                              color: Colors.red,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
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
}

class AddEditInvoiceBottomSheet extends StatefulWidget {
  final PurchaseInvoice? invoice;
  final List<Supplier> suppliers;
  final List<SiteModel> sites;
  final int? preselectedSiteId; // New parameter for preselected site
  final VoidCallback? onInvoiceSaved;
  final VoidCallback? onSupplierCreated;

  const AddEditInvoiceBottomSheet({
    super.key,
    this.invoice,
    required this.suppliers,
    required this.sites,
    this.preselectedSiteId,
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
      
      // Set selected site ID from preselected value or first site
      if (widget.preselectedSiteId != null) {
        _selectedSiteId = widget.preselectedSiteId;
      } else {
        _selectedSiteId = widget.sites.isNotEmpty ? widget.sites.first.id : null;
      }

      // Add one empty material item for add mode if invoice type is general_po
      if (_selectedInvoiceType == 'general_po') {
        _addMaterialItem();
      }
    }
  }

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
        _invoiceDateController.text = _formatDateForDisplay(picked);
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
                  leading: const Icon(Icons.photo_library, color: primaryColor),
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
                  leading: const Icon(Icons.camera_alt, color: primaryColor),
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
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: const Text('Cancel'),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateSupplierBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateSupplierBottomSheet(
        onSupplierCreated: (newSupplierId) async {
          widget.onSupplierCreated?.call();
          
          await _refreshSuppliers();
          
          await Future.delayed(const Duration(milliseconds: 300));
          
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

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool hasError = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: hasError
                ? Colors.red
                : const Color.fromARGB(255, 105, 110, 126),
            size: 20,
          ),
          errorText: hasError ? 'Required' : null,
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: TextStyle(
            color: hasError ? Colors.red : textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    bool hasError = false,
    bool isReadOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          errorText: hasError ? 'Required' : null,
          prefixIcon: Icon(
            icon,
            color: hasError ? Colors.red : textSecondary,
            size: 20,
          ),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: TextStyle(
            color: hasError ? Colors.red : textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        dropdownColor: cardColor,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        items: items,
        onChanged: (_isSubmitting || isReadOnly) ? null : onChanged,
      ),
    );
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
        'site_id': _selectedSiteId.toString(), // This will be the selected site ID
        'created_by': '1',
        'workspace_id': '1',
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
            content: Text('Failed to save invoice: $e'),
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
    final bool isEdit = widget.invoice != null;
    final bool isPreselectedSite = widget.preselectedSiteId != null && !isEdit;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                                  isEdit ? 'Edit Invoice' : 'Create Purchase Invoice',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  isEdit ? 'Update invoice details' : 'Enter invoice details below',
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

                      // Invoice Number
                      
                      const SizedBox(height: 8),
                      _buildEnhancedTextField(
                        controller: _invoiceNoController,
                        label: 'Invoice Number',
                        hint: 'Enter Invoice Number',
                        icon: Icons.receipt,
                        isRequired: true,
                      ),
                      const SizedBox(height: 10),

                      // Supplier Invoice Number
                      
                      const SizedBox(height: 8),
                      _buildEnhancedTextField(
                        controller: _supplierInvoiceNoController,
                        label: 'Supplier Invoice Number',
                        hint: 'Enter Supplier Invoice Number',
                        icon: Icons.receipt_long,
                      ),
                      const SizedBox(height: 10),

                      // Project/Site
                      
                      const SizedBox(height: 8),
                      if (isPreselectedSite)
                        _buildPreselectedSiteDisplay()
                      else
                        _buildEnhancedDropdown<int>(
                          value: _selectedSiteId,
                          label: 'Select Site',
                          icon: Icons.business,
                          items: widget.sites.map((site) {
                            return DropdownMenuItem<int>(
                              value: site.id,
                              child: Text(site.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSiteId = value;
                            });
                          },
                        ),
                      const SizedBox(height: 10),

                      // Invoice Type
                      
                      const SizedBox(height: 8),
                      _buildEnhancedDropdown<String>(
                        value: _selectedInvoiceType,
                        label: 'Select Invoice Type',
                        icon: Icons.category,
                        items: _invoiceTypeOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option['value'],
                            child: Text(option['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedInvoiceType = value!;
                            if (value == 'general_po' && _materialItems.isEmpty) {
                              _addMaterialItem();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      // Invoice Materials Section - Only show for General PO
                      if (_selectedInvoiceType == 'general_po') ...[
                        const Text(
                          'Invoice Material',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_isLoadingMaterials) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: primaryColor),
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
                          const SizedBox(height: 13),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _addMaterialItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: primaryColor.withOpacity(0.3)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 13),
                        ],
                      ],

                      // Invoice Date
                      
                      const SizedBox(height: 8),
                      _buildEnhancedTextField(
                        controller: _invoiceDateController,
                        label: 'Invoice Date',
                        hint: 'Select Date',
                        icon: Icons.calendar_today,
                        isRequired: true,
                        readOnly: true,
                        onTap: _isSubmitting ? null : () => _selectDate(context),
                      ),
                      const SizedBox(height: 10),

                      // Supplier
                      
                      const SizedBox(height: 8),
                      _buildEnhancedDropdown<int>(
                      
                        value: _selectedSupplierId,
                        label: 'Select Supplier',
                        icon: Icons.business_center,
                        items: _localSuppliers.map((supplier) {
                          return DropdownMenuItem<int>(
                            value: supplier.id,
                            child: Text(
                              supplier.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSupplierId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Create New Supplier Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _showCreateSupplierBottomSheet,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create New Supplier'),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: primaryColor.withOpacity(0.3)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Invoice File Upload
                      const Text(
                        'Invoice File',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _pickFile,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.upload_file, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Choose File',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Allowed: pdf, jpg, jpeg, png, doc, docx',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Total Amount
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryColor.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Rs ${_totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                          isEdit ? 'Update Invoice' : 'Create Invoice',
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

  Widget _buildPreselectedSiteDisplay() {
    // Find the preselected site
    final preselectedSite = widget.sites.firstWhere(
  (site) => site.id == widget.preselectedSiteId,
  orElse: () => SiteModel(
    id: 0,
    name: 'Unknown Site',
    status: 'active',  // Added
    description: '',   // Added
    startDate: '',     // Added
    endDate: '',       // Added
    budget: 0.0,       // Added
    isActive: 1,       // Added
    type: '',          // Added
    currency: 'USD',   // Added
    profileProgress: '0', // Added
    progress: '0',     // Added
    taskProgress: '0', // Added
    estimateSize: 0.0, // Added
    copylinksetting: '', // Added
    workspaceId: 1,
    createdBy: 0,      // Added
    createdAt: '',     // Added
    updatedAt: '',     // Added
  ),
);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.business,
              color: primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Site',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preselectedSite.name,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'This invoice will be added to ${preselectedSite.name}',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock,
              color: primaryColor.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Update CreateSupplierBottomSheet with MaterialScreen style
class CreateSupplierBottomSheet extends StatefulWidget {
  final Function(int)? onSupplierCreated;

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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${SupplierApiService.baseUrl}/suppliers'),
      );

      request.fields['name'] = _nameController.text;
      request.fields['category_id'] = _selectedCategoryId!.toString();
      request.fields['created_by'] = '1';
      request.fields['workspace_id'] = '1';
      
      if (_phoneController.text.isNotEmpty) {
        request.fields['phone'] = _phoneController.text;
      }

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
            widget.onSupplierCreated?.call(newSupplierId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Supplier created successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else if (response.statusCode == 422) {
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

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool hasError = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: hasError
                ? Colors.red
                : const Color.fromARGB(255, 105, 110, 126),
            size: 20,
          ),
          errorText: hasError ? 'Required' : null,
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: TextStyle(
            color: hasError ? Colors.red : textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEnhancedDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    bool hasError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          errorText: hasError ? 'Required' : null,
          prefixIcon: Icon(
            icon,
            color: hasError ? Colors.red : textSecondary,
            size: 20,
          ),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: TextStyle(
            color: hasError ? Colors.red : textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        dropdownColor: cardColor,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        items: items,
        onChanged: _isSubmitting ? null : onChanged,
        validator: (value) {
          if (hasError && value == null) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                              Icons.person_add,
                              color: primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create New Supplier',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Enter supplier details below',
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

                      // Name
                      const Text(
                        'Name*',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEnhancedTextField(
                        controller: _nameController,
                        label: 'Supplier Name',
                        hint: 'Enter Supplier Name',
                        icon: Icons.person,
                        isRequired: true,
                      ),
                      const SizedBox(height: 20),

                      // Category
                      const Text(
                        'Category*',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: primaryColor))
                          : _buildEnhancedDropdown<int>(
                              value: _selectedCategoryId,
                              label: 'Select Category',
                              icon: Icons.category,
                              items: _categories.map((category) {
                                return DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                              hasError: _selectedCategoryId == null,
                            ),
                      const SizedBox(height: 20),

                      // Phone
                      const Text(
                        'Phone',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEnhancedTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // UPI Screenshot
                      const Text(
                        'UPI Screenshot',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _pickUpiScreenshot1,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.upload_file, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Choose File',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Allowed: jpg, jpeg, png',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                      : const Text(
                                          'Save Supplier',
                                          style: TextStyle(
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

// Material Item Class
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
    _quantityController.text = widget.item.quantity;
    _priceController.text = widget.item.price;
    _subtotalController.text = widget.item.subtotal;
    _unitController.text = widget.item.unit;

    if (widget.item.materialId > 0) {
      try {
        _selectedMaterial = widget.materials.firstWhere(
          (material) => material.id == widget.item.materialId,
        );
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
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Material',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _uniqueMaterials.length,
                    itemBuilder: (context, index) {
                      final material = _uniqueMaterials[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4a63c0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory,
                              color: Color(0xFF4a63c0),
                            ),
                          ),
                          title: Text(
                            material.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Price: \$${material.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF718096),
                            ),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color.fromARGB(255, 202, 202, 202)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Item ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              if (widget.onRemove != null) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: widget.onRemove,
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Material Selection
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFf8f9fa),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4a63c0).withOpacity(0.1)),
            ),
            child: ListTile(
              leading: const Icon(Icons.inventory, color: Color(0xFF4a63c0)),
              title: Text(
                _selectedMaterial?.name ?? 'Select Material',
                style: TextStyle(
                  color: _selectedMaterial != null
                      ? const Color(0xFF2D3748)
                      : const Color(0xFF718096),
                ),
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _showMaterialSelectionDialog,
            ),
          ),
          const SizedBox(height: 12),

          // Quantity and Unit row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8f9fa),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4a63c0).withOpacity(0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      labelText: 'Quantity',
                      labelStyle: TextStyle(color: Color(0xFF718096)),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateSubtotal(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8f9fa),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4a63c0).withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    _unitController.text.isEmpty
                        ? 'Unit'
                        : _unitController.text,
                    style: TextStyle(
                      color: _unitController.text.isEmpty
                          ? const Color(0xFF718096)
                          : const Color(0xFF2D3748),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price and Subtotal row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8f9fa),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4a63c0).withOpacity(0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      labelText: 'Price',
                      labelStyle: TextStyle(color: Color(0xFF718096)),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateSubtotal(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8f9fa),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4a63c0).withOpacity(0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _subtotalController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      labelText: 'Subtotal',
                      labelStyle: TextStyle(color: Color(0xFF718096)),
                    ),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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