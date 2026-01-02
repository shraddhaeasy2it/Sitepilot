import 'package:ecoteam_app/admin/models/payment_model.dart';
import 'package:ecoteam_app/admin/services/payment_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaymentScreen extends StatefulWidget {
  final String? selectedSiteName;
  final int? selectedSiteId;

  const PaymentScreen({super.key, this.selectedSiteName, this.selectedSiteId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Payment> payments = [];
  List<Payment> filteredPayments = [];
  bool isLoading = true;
  String searchQuery = '';
  DropdownData? dropdownData;
  int? workspaceId = 3; // Default workspace ID

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load payments
      final paymentsData = await PaymentService.getPayments();

      // Load initial dropdown data for forms (without site filter initially)
      final dropdown = await PaymentService.getDropdownData(
        workspaceId: workspaceId ?? 3,
      );

      setState(() {
        if (widget.selectedSiteId != null) {
          paymentsData.removeWhere((p) => p.siteId != widget.selectedSiteId);
        }

        payments = paymentsData;
        filteredPayments = paymentsData;
        dropdownData = dropdown;
        isLoading = false;
      });

      // Log dropdown data for debugging
      if (dropdown != null) {
        print('Sites loaded: ${dropdown.sites?.length ?? 0}');
        print('Suppliers loaded: ${dropdown.suppliers?.length ?? 0}');
        print('Invoices loaded: ${dropdown.invoices?.length ?? 0}');
        print('Next Payment Number: ${dropdown.nextPaymentNumber}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  void _showAddEditBottomSheet({Payment? payment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PaymentFormBottomSheet(
        payment: payment,
        dropdownData: dropdownData,
        onSave: (updatedPayment) {
          _loadData(); // Refresh the list
        },
        workspaceId: workspaceId,
      ),
    );
  }

  void _deletePayment(int paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PaymentService.deletePayment(paymentId);
        _loadData(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting payment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Payments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.selectedSiteName != null
                  ? 'Site: ${widget.selectedSiteName}'
                  : 'All Sites',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
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

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditBottomSheet(),
            tooltip: 'Add Payment',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                
                hintText: 'Search payments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterPayments,
            ),
          ),

          // Total Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Payments: ${filteredPayments.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Search: "$searchQuery"'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _filterPayments(''),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Payment Cards List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPayments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No payments found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = filteredPayments[index];
                      return PaymentCard(
                        payment: payment,
                        onEdit: () => _showAddEditBottomSheet(payment: payment),
                        onDelete: () => _deletePayment(payment.id!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _filterPayments(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredPayments = payments;
      } else {
        filteredPayments = payments.where((payment) {
          final paymentNumber = payment.paymentNumber?.toLowerCase() ?? '';
          final supplierName = payment.supplier?.name?.toLowerCase() ?? '';
          final referenceNumber = payment.referenceNumber?.toLowerCase() ?? '';
          final invoiceNumber =
              payment.invoice?.invoiceNumber?.toLowerCase() ?? '';
          final siteName = payment.site?.name?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return paymentNumber.contains(searchLower) ||
              supplierName.contains(searchLower) ||
              referenceNumber.contains(searchLower) ||
              invoiceNumber.contains(searchLower) ||
              siteName.contains(searchLower);
        }).toList();
      }
    });
  }
}

class PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Payment Number and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.paymentNumber ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2a43a0),
                      ),
                    ),
                   Text(
                      _formatDate(payment.paymentDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 136, 136, 136),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      color: Color(0xFF2a43a0),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      color: Colors.red,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Payment Details Grid
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  _buildDetailItem(
                    'Supplier:',
                    payment.supplier?.name ?? 'N/A',
                  ),
                  _buildDetailItem(
                    'Invoice:',
                    payment.invoice?.invoiceNumber ?? 'N/A',
                  ),
                ),
                _buildDetailRow(
                   _buildDetailItem(
                    'Type:',
                    _formatPaymentType(payment.paymentType),
                  ),
                  _buildDetailItem('Amount:', '₹ ${payment.amount ?? '0.00'}'),
                ),
                
                _buildDetailRow(
                  _buildDetailItem('Mode:', _formatMode(payment.mode)),
                  _buildDetailItem(
                    'Reference:',
                    payment.referenceNumber ?? 'N/A',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPaymentType(String? type) {
    if (type == null) return 'N/A';
    return type.replaceAll('_', ' ').toUpperCase();
  }

  String _formatMode(String? mode) {
    if (mode == null) return 'N/A';
    return mode.replaceAll('_', ' ').toUpperCase();
  }
}

class PaymentFormBottomSheet extends StatefulWidget {
  final Payment? payment;
  final DropdownData? dropdownData;
  final Function(Payment?) onSave;
  final int? workspaceId;

  const PaymentFormBottomSheet({
    super.key,
    this.payment,
    this.dropdownData,
    required this.onSave,
    this.workspaceId = 3,
  });

  @override
  State<PaymentFormBottomSheet> createState() => _PaymentFormBottomSheetState();
}

class _PaymentFormBottomSheetState extends State<PaymentFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late PaymentFormData _formData;
  bool _isSubmitting = false;
  bool _isLoadingSuppliers = false;
  bool _isLoadingInvoices = false;
  bool _isInitialDataLoaded = false; // Track if initial data is loaded

  // Dropdown values
  String? _selectedSiteId;
  String? _selectedSupplierId;
  String? _selectedInvoiceId;
  String? _selectedPaymentType;
  String? _selectedMode;

  // Dynamic data
  Map<String, String> _supplierInvoices = {};

  // Store data
  List<Site> _sites = [];
  Map<String, String> _suppliers = {};

  double _remainingAmount = 0.0;

  // Payment type options
  final List<String> _paymentTypeOptions = ['against_invoice', 'advance'];

  // Payment mode options
  final List<String> _modeOptions = [
    'bank_transfer',
    'upi',
    'cash',
    'cheque',
    'card',
  ];

  // Text controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentNumberController =
      TextEditingController();
  final TextEditingController _remainingAmountController =
      TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadInitialData();
  }

  void _initializeForm() {
    if (widget.payment != null) {
      _formData = PaymentFormData(
        paymentNumber: widget.payment!.paymentNumber,
        supplierId: widget.payment!.supplierId,
        purchaseInvoiceId: widget.payment!.purchaseInvoiceId,
        siteId: widget.payment!.siteId,
        paymentDate: widget.payment!.paymentDate?.substring(0, 10),
        amount: widget.payment!.amount,
        paymentType: widget.payment!.paymentType,
        mode: widget.payment!.mode,
        referenceNumber: widget.payment!.referenceNumber,
        notes: widget.payment!.notes,
        paymentProofFile: widget.payment!.paymentProofFile,
        createdBy: widget.payment!.createdBy,
        workspaceId: widget.payment!.workspaceId,
      );
      _selectedSiteId = widget.payment!.siteId?.toString();
      _selectedSupplierId = widget.payment!.supplierId?.toString();
      _selectedInvoiceId = widget.payment!.purchaseInvoiceId?.toString();
      _selectedPaymentType = widget.payment!.paymentType;
      _selectedMode = widget.payment!.mode;
      _amountController.text = widget.payment!.amount ?? '';
      _paymentNumberController.text = widget.payment!.paymentNumber ?? '';
      _paymentDateController.text =
          widget.payment!.paymentDate?.substring(0, 10) ?? '';
      _remainingAmountController.text = (widget.payment!.remainingAmount ?? 0.0)
          .toStringAsFixed(2);
      _remainingAmount = widget.payment!.remainingAmount ?? 0.0;
    } else {
      _formData = PaymentFormData(
        paymentDate: DateTime.now().toString().substring(0, 10),
        createdBy: 1,
        workspaceId: widget.workspaceId ?? 1,
      );
      _selectedPaymentType = _paymentTypeOptions[0];
      _selectedMode = _modeOptions[0];
      _paymentDateController.text = DateTime.now().toString().substring(0, 10);
      _paymentNumberController.text =
          widget.dropdownData?.nextPaymentNumber ?? 'PAY-0000';
      _formData.paymentNumber = _paymentNumberController.text;
    }
  }

  void _loadInitialData() async {
    try {
      // Load sites from dropdown data
      if (widget.dropdownData?.sites != null) {
        setState(() {
          _sites = widget.dropdownData!.sites!;
        });
      }

      // For edit mode, load suppliers for the current site
      if (widget.payment != null && widget.payment!.siteId != null) {
        _selectedSiteId = widget.payment!.siteId.toString();
        await _loadSuppliersForSite(
          widget.payment!.siteId!,
          isInitialLoad: true,
        );
      }

      // Mark initial data as loaded
      setState(() {
        _isInitialDataLoaded = true;
      });
    } catch (e) {
      print('Error loading initial data: $e');
      setState(() {
        _isInitialDataLoaded = true; // Still mark as loaded even if error
      });
    }
  }

  Future<void> _loadSuppliersForSite(
    int siteId, {
    bool isInitialLoad = false,
  }) async {
    if (siteId == 0) return;

    setState(() {
      _isLoadingSuppliers = true;
      if (!isInitialLoad) {
        // When changing site, clear supplier selection
        _selectedSupplierId = null;
      }
    });

    try {
      final suppliersMap = await PaymentService.getSuppliersBySite(
        siteId,
        widget.workspaceId ?? 3,
      );

      // Build new suppliers map
      final Map<String, String> newSuppliers = {};
      suppliersMap.forEach((key, supplier) {
        newSuppliers[supplier.id?.toString() ?? key] =
            supplier.name ?? 'Unknown Supplier';
      });

      setState(() {
        _suppliers = newSuppliers;

        // Only set selected supplier if we're in edit mode AND this is initial load
        // AND the supplier exists in the new list
        if (isInitialLoad &&
            widget.payment != null &&
            widget.payment!.supplierId != null) {
          String supplierIdStr = widget.payment!.supplierId.toString();
          if (_suppliers.containsKey(supplierIdStr)) {
            _selectedSupplierId = supplierIdStr;

            // Load invoices if needed
            if (_selectedPaymentType == 'against_invoice') {
              _loadSupplierInvoices(widget.payment!.supplierId!);
            }
          } else {
            // Supplier not found for this site - reset to null
            _selectedSupplierId = null;
          }
        }
      });
    } catch (e) {
      print('Error loading suppliers for site: $e');
      setState(() {
        _suppliers = {};
        _selectedSupplierId = null;
      });
    } finally {
      setState(() {
        _isLoadingSuppliers = false;
      });
    }
  }

  Future<void> _loadSupplierInvoices(int supplierId) async {
    if (supplierId == 0 || _selectedPaymentType != 'against_invoice') return;

    setState(() {
      _isLoadingInvoices = true;
    });

    try {
      final invoices = await PaymentService.getSupplierInvoices(supplierId);
      setState(() {
        _supplierInvoices = invoices;

        // Check if current invoice exists
        if (widget.payment?.purchaseInvoiceId != null) {
          String invoiceIdStr = widget.payment!.purchaseInvoiceId.toString();
          if (_supplierInvoices.containsKey(invoiceIdStr)) {
            _selectedInvoiceId = invoiceIdStr;
            _updateRemainingAmount(_selectedInvoiceId);
          }
        }
      });
    } catch (e) {
      print('Error loading invoices: $e');
      setState(() {
        _supplierInvoices = {};
      });
    } finally {
      setState(() {
        _isLoadingInvoices = false;
      });
    }
  }

  Future<void> _updateRemainingAmount(String? invoiceId) async {
    if (invoiceId != null && invoiceId.isNotEmpty) {
      try {
        final invoice = await PaymentService.getInvoiceDetails(
          int.parse(invoiceId),
        );
        setState(() {
          _remainingAmount = invoice?.remainingAmount ?? 0.0;
          _remainingAmountController.text = _remainingAmount.toStringAsFixed(2);
        });
      } catch (e) {
        print('Error updating remaining amount: $e');
      }
    }
  }

  // Helper method for title case
  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _getPaymentTypeDisplay(String? type) {
    if (type == null) return 'Against Invoice';
    return _toTitleCase(type.replaceAll('_', ' '));
  }

  String _getModeDisplay(String? mode) {
    if (mode == null) return 'Bank Transfer';
    return _toTitleCase(mode.replaceAll('_', ' '));
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    try {
      _formData.paymentType = _selectedPaymentType;
      _formData.mode = _selectedMode;
      _formData.siteId = _selectedSiteId != null
          ? int.parse(_selectedSiteId!)
          : null;
      _formData.supplierId = _selectedSupplierId != null
          ? int.parse(_selectedSupplierId!)
          : null;
      _formData.purchaseInvoiceId = _selectedInvoiceId != null
          ? int.parse(_selectedInvoiceId!)
          : null;
      _formData.amount = _amountController.text;
      _formData.paymentDate = _paymentDateController.text;

      Payment? savedPayment;

      if (widget.payment != null) {
        savedPayment = await PaymentService.updatePayment(
          widget.payment!.id!,
          _formData,
        );
      } else {
        savedPayment = await PaymentService.createPayment(_formData);
      }

      widget.onSave(savedPayment);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.payment != null ? 'Payment updated!' : 'Payment created!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.payment != null
                          ? 'Edit Payment'
                          : 'Create Payment',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Payment Number
                TextFormField(
                  controller: _paymentNumberController,
                  decoration: InputDecoration(
                    labelText: 'Payment Number*',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  readOnly: widget.payment == null,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter payment number'
                      : null,
                ),

                const SizedBox(height: 16),

                // Show loading indicator while initial data is loading (for edit mode)
                if (widget.payment != null && !_isInitialDataLoaded)
                  const Center(child: CircularProgressIndicator()),

                if (widget.payment == null || _isInitialDataLoaded)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        child: Column(
                          children: [
                            // Site Dropdown
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedSiteId,
                              decoration: InputDecoration(
                                labelText: 'Site*',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('Select Site'),
                                ),
                                ..._sites
                                    .map(
                                      (site) => DropdownMenuItem(
                                        value: site.id.toString(),
                                        child: Text(
                                          site.name ?? 'Unknown Site',
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSiteId = value;
                                  _selectedSupplierId =
                                      null; // Clear supplier when site changes
                                  _selectedInvoiceId = null;
                                  _suppliers.clear();
                                  _supplierInvoices.clear();
                                  _remainingAmount = 0.0;
                                  _remainingAmountController.text = '0.00';
                                });

                                if (value != null && value.isNotEmpty) {
                                  _loadSuppliersForSite(int.parse(value));
                                }
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please select site'
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Payment Date
                            TextFormField(
                              controller: _paymentDateController,
                              decoration: InputDecoration(
                                labelText: 'Payment Date*',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _paymentDateController.text = date
                                            .toString()
                                            .substring(0, 10);
                                      });
                                    }
                                  },
                                ),
                              ),
                              readOnly: true,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please select date'
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Payment Type
                            DropdownButtonFormField<String>(
                              value: _selectedPaymentType,
                              decoration: InputDecoration(
                                labelText: 'Payment Type*',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _paymentTypeOptions
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(_getPaymentTypeDisplay(type)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentType = value;
                                  if (value == 'advance') {
                                    _selectedInvoiceId = null;
                                    _supplierInvoices.clear();
                                    _remainingAmount = 0.0;
                                    _remainingAmountController.text = '0.00';
                                  } else if (value == 'against_invoice' &&
                                      _selectedSupplierId != null) {
                                    _loadSupplierInvoices(
                                      int.parse(_selectedSupplierId!),
                                    );
                                  }
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please select type'
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Reference Number
                            TextFormField(
                              initialValue: _formData.referenceNumber,
                              decoration: InputDecoration(
                                labelText: 'Reference Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onSaved: (value) =>
                                  _formData.referenceNumber = value,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Right Column
                      Expanded(
                        child: Column(
                          children: [
                            // Supplier Dropdown - FIXED: Use conditional value
                            Stack(
                              children: [
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  // CRITICAL FIX: Use conditional value based on whether suppliers are loaded
                                  value:
                                      _suppliers.containsKey(
                                        _selectedSupplierId,
                                      )
                                      ? _selectedSupplierId
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: 'Supplier*',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text('Select Supplier'),
                                    ),
                                    ..._suppliers.entries
                                        .map(
                                          (entry) => DropdownMenuItem(
                                            value: entry.key,
                                            child: Text(entry.value),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSupplierId = value;
                                      _selectedInvoiceId = null;
                                      _supplierInvoices.clear();
                                      _remainingAmount = 0.0;
                                      _remainingAmountController.text = '0.00';
                                    });

                                    if (value != null &&
                                        value.isNotEmpty &&
                                        _selectedPaymentType ==
                                            'against_invoice') {
                                      _loadSupplierInvoices(int.parse(value));
                                    }
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Please select supplier'
                                      : null,
                                ),
                                if (_isLoadingSuppliers)
                                  const Positioned.fill(
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Payment Mode
                            DropdownButtonFormField<String>(
                              value: _selectedMode,
                              decoration: InputDecoration(
                                labelText: 'Payment Mode*',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _modeOptions
                                  .map(
                                    (mode) => DropdownMenuItem(
                                      value: mode,
                                      child: Text(_getModeDisplay(mode)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedMode = value),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please select mode'
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Amount
                            TextFormField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: 'Amount*',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixText: '\Rs ',
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Please enter amount';
                                if (double.tryParse(value) == null)
                                  return 'Please enter valid amount';
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Invoice Dropdown (only for against_invoice)
                            if (_selectedPaymentType == 'against_invoice')
                              Stack(
                                children: [
                                  DropdownButtonFormField<String>(
                                    value:
                                        _supplierInvoices.containsKey(
                                          _selectedInvoiceId,
                                        )
                                        ? _selectedInvoiceId
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: 'Purchase Invoice*',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: '',
                                        child: Text('Select Invoice'),
                                      ),
                                      ..._supplierInvoices.entries
                                          .map(
                                            (entry) => DropdownMenuItem(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ),
                                          )
                                          .toList(),
                                    ],
                                    onChanged: (value) {
                                      setState(
                                        () => _selectedInvoiceId = value,
                                      );
                                      _updateRemainingAmount(value);
                                    },
                                    validator: (value) {
                                      if (_selectedPaymentType ==
                                              'against_invoice' &&
                                          (value == null || value.isEmpty)) {
                                        return 'Please select invoice';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_isLoadingInvoices)
                                    const Positioned.fill(
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                ],
                              ),

                            if (_selectedPaymentType != 'against_invoice')
                              const SizedBox(height: 56),

                            const SizedBox(height: 16),

                            // Remaining Amount
                            TextFormField(
                              controller: _remainingAmountController,
                              decoration: InputDecoration(
                                labelText: 'Remaining Amount',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixText: '\Rs ',
                              ),
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Notes
                if (widget.payment == null || _isInitialDataLoaded)
                  TextFormField(
                    initialValue: _formData.notes,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                    onSaved: (value) => _formData.notes = value,
                  ),

                const SizedBox(height: 24),

                // Buttons
                if (widget.payment == null || _isInitialDataLoaded)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _savePayment,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.payment != null ? 'Update' : 'Create',
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

  @override
  void dispose() {
    _amountController.dispose();
    _paymentNumberController.dispose();
    _remainingAmountController.dispose();
    _paymentDateController.dispose();
    super.dispose();
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String toTitleCase() {
    return split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}
