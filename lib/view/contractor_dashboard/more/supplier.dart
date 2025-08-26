import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/models/dashboard/site_model.dart';

class SupplierLedger extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  const SupplierLedger({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<SupplierLedger> createState() => _SupplierLedgerState();
}

class _SupplierLedgerState extends State<SupplierLedger> {
  final List<SupplierTransaction> _transactions = [];
  bool _isLoading = false;
  String _searchQuery = "";
  // Form controllers
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  String _status = "Pending";
  // Color constants
  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryLight = Color(0xFF8fa4e8);
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color cardColor = Color(0xFFF8F9FF); // Changed to backgroundColor
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _invoiceNoController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  // Helper method to get the current site name
  String _getCurrentSiteName() {
    if (widget.selectedSiteId == null) {
      return 'All Sites';
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () =>
          Site(id: '', name: 'Unknown Site', address: '', companyId: ''),
    );
    return site.name;
  }

  void _loadTransactions() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _transactions.addAll([
          SupplierTransaction(
            supplierName: "Johnson Supplies",
            invoiceNo: "INV-2023-001",
            date: DateTime.now().subtract(const Duration(days: 5)),
            amount: 12500.00,
            paymentDue: DateTime.now().add(const Duration(days: 25)),
            status: "Pending",
          ),
          SupplierTransaction(
            supplierName: "Alpha Construction",
            invoiceNo: "INV-2023-045",
            date: DateTime.now().subtract(const Duration(days: 10)),
            amount: 8500.50,
            paymentDue: DateTime.now().add(const Duration(days: 5)),
            status: "Due Soon",
          ),
          SupplierTransaction(
            supplierName: "Global Trading",
            invoiceNo: "INV-2023-112",
            date: DateTime.now().subtract(const Duration(days: 30)),
            amount: 32000.75,
            paymentDue: DateTime.now().subtract(const Duration(days: 2)),
            status: "Overdue",
          ),
          SupplierTransaction(
            supplierName: "Alex Enterprises",
            invoiceNo: "INV-2023-002",
            date: DateTime.now().subtract(const Duration(days: 15)),
            amount: 18500.00,
            paymentDue: DateTime.now().add(const Duration(days: 45)),
            status: "Pending",
          ),
        ]);
        _isLoading = false;
      });
    });
  }

  List<SupplierTransaction> get _filteredTransactions {
    List<SupplierTransaction> filtered = _transactions.where((t) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          t.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.invoiceNo.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
    // Sort by payment due date (overdue first, then due soon, then pending)
    filtered.sort((a, b) {
      if (a.status == "Overdue" && b.status != "Overdue") return -1;
      if (a.status != "Overdue" && b.status == "Overdue") return 1;
      if (a.status == "Due Soon" && b.status == "Pending") return -1;
      if (a.status == "Pending" && b.status == "Due Soon") return 1;
      return a.paymentDue.compareTo(b.paymentDue);
    });
    return filtered;
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search supplier...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildTransactionCard(SupplierTransaction transaction) {
    Color statusColor = Colors.grey;
    if (transaction.status == "Due Soon") {
      statusColor = Colors.orange;
    } else if (transaction.status == "Overdue") {
      statusColor = Colors.red;
    } else if (transaction.status == "Paid") {
      statusColor = Colors.green;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: cardColor, // Using backgroundColor for card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditTransactionBottomSheet(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction.supplierName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          transaction.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      GestureDetector(
                        onTap: () {
                          _showDeleteConfirmationDialog(transaction);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Invoice: ${transaction.invoiceNo}",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Amount", style: TextStyle(color: Colors.grey[600])),
                      Text(
                        NumberFormat.currency(
                          symbol: 'Rs ',
                        ).format(transaction.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Due Date", style: TextStyle(color: Colors.grey[600])),
                      Text(
                        DateFormat('MMM dd, yyyy').format(transaction.paymentDue),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transaction.status == "Overdue"
                              ? Colors.red
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (transaction.status == "Overdue" ||
                  transaction.status == "Due Soon")
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _markAsPaid(transaction),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text("Mark as Paid"),
                    style: TextButton.styleFrom(foregroundColor: primaryColor),
                  ),
                ),
            ],
          ),
        ),
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
                Icons.receipt_long_outlined,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'Start by adding your first transaction'
                  : 'Try adjusting your search criteria',
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionBottomSheet() {
    // Clear controllers when opening the bottom sheet
    _supplierNameController.clear();
    _invoiceNoController.clear();
    _amountController.clear();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _dueDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().add(const Duration(days: 30)));
    _status = "Pending";
    _showTransactionBottomSheet();
  }

  void _showEditTransactionBottomSheet(SupplierTransaction transaction) {
    // Populate controllers with transaction data
    _supplierNameController.text = transaction.supplierName;
    _invoiceNoController.text = transaction.invoiceNo;
    _amountController.text = transaction.amount.toString();
    _dateController.text = DateFormat('yyyy-MM-dd').format(transaction.date);
    _dueDateController.text = DateFormat('yyyy-MM-dd').format(transaction.paymentDue);
    _status = transaction.status;
    _showTransactionBottomSheet(transaction: transaction);
  }

  void _showTransactionBottomSheet({SupplierTransaction? transaction}) {
    final isEditing = transaction != null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit : Icons.add_card,
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
                                isEditing ? 'Edit Transaction' : 'Add New Transaction',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                isEditing ? 'Update transaction details' : 'Enter transaction details below',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _supplierNameController,
                      decoration: const InputDecoration(
                        labelText: "Supplier Name",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _invoiceNoController,
                      decoration: const InputDecoration(
                        labelText: "Invoice Number",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: "Amount",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                        prefixText: "Rs ",
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: "Date",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setSheetState(() {
                            _dateController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(pickedDate);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dueDateController,
                      decoration: const InputDecoration(
                        labelText: "Due Date",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_available_outlined),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setSheetState(() {
                            _dueDateController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(pickedDate);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: "Status",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: ["Pending", "Due Soon", "Overdue", "Paid"].map((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setSheetState(() {
                          _status = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
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
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          isEditing ? Icons.update : Icons.add,
                          color: Colors.white,
                        ),
                        label: Text(
                          isEditing ? 'Update Transaction' : 'Add Transaction',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => isEditing 
                            ? _updateTransaction(transaction!) 
                            : _addTransaction(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _addTransaction() {
    if (_supplierNameController.text.isEmpty ||
        _invoiceNoController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _dueDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final newTransaction = SupplierTransaction(
      supplierName: _supplierNameController.text,
      invoiceNo: _invoiceNoController.text,
      date: DateFormat('yyyy-MM-dd').parse(_dateController.text),
      amount: double.tryParse(_amountController.text) ?? 0,
      paymentDue: DateFormat('yyyy-MM-dd').parse(_dueDateController.text),
      status: _status,
    );
    setState(() {
      _transactions.add(newTransaction);
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Transaction added successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateTransaction(SupplierTransaction transaction) {
    if (_supplierNameController.text.isEmpty ||
        _invoiceNoController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _dueDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final index = _transactions.indexOf(transaction);
    setState(() {
      _transactions[index] = SupplierTransaction(
        supplierName: _supplierNameController.text,
        invoiceNo: _invoiceNoController.text,
        date: DateFormat('yyyy-MM-dd').parse(_dateController.text),
        amount: double.tryParse(_amountController.text) ?? 0,
        paymentDue: DateFormat('yyyy-MM-dd').parse(_dueDateController.text),
        status: _status,
      );
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Transaction updated successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteConfirmationDialog(SupplierTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete the transaction with ${transaction.supplierName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTransaction(transaction);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(SupplierTransaction transaction) {
    final index = _transactions.indexOf(transaction);
    setState(() {
      _transactions.remove(transaction);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction with ${transaction.supplierName} deleted successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _transactions.insert(index, transaction);
            });
          },
        ),
      ),
    );
  }

  void _markAsPaid(SupplierTransaction transaction) {
    final index = _transactions.indexOf(transaction);
    setState(() {
      _transactions[index] = SupplierTransaction(
        supplierName: transaction.supplierName,
        invoiceNo: transaction.invoiceNo,
        date: transaction.date,
        amount: transaction.amount,
        paymentDue: transaction.paymentDue,
        status: "Paid",
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Marked ${transaction.invoiceNo} as Paid"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportStatements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Export Statements"),
        content: const Text(
          "Select format to export supplier payment statements:",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Export started successfully")),
              );
            },
            child: const Text("PDF", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Export started successfully")),
              );
            },
            child: const Text("Excel", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Supplier Ledger - ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: _getCurrentSiteName(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportStatements,
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(
                              _filteredTransactions[index],
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddTransactionBottomSheet,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Transaction',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class SupplierTransaction {
  final String supplierName;
  final String invoiceNo;
  final DateTime date;
  final double amount;
  final DateTime paymentDue;
  final String status;
  
  SupplierTransaction({
    required this.supplierName,
    required this.invoiceNo,
    required this.date,
    required this.amount,
    required this.paymentDue,
    required this.status,
  });
}