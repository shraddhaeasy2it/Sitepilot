// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:ecoteam_app/models/dashboard/site_model.dart';

// class SupplierLedger extends StatefulWidget {
//   final String? selectedSiteId;
//   final Function(String) onSiteChanged;
//   final List<Site> sites;
//   const SupplierLedger({
//     super.key,
//     required this.selectedSiteId,
//     required this.onSiteChanged,
//     required this.sites,
//   });

//   @override
//   State<SupplierLedger> createState() => _SupplierLedgerState();
// }

// class _SupplierLedgerState extends State<SupplierLedger> {
//   final List<SupplierTransaction> _transactions = [];
//   bool _isLoading = false;
//   String _searchQuery = "";
//   // Form controllers
//   final TextEditingController _supplierNameController = TextEditingController();
//   final TextEditingController _invoiceNoController = TextEditingController();
//   final TextEditingController _amountController = TextEditingController();
//   final TextEditingController _dateController = TextEditingController();
//   final TextEditingController _dueDateController = TextEditingController();
//   String _status = "Pending";
//   // Color constants
//   static const Color primaryColor = Color(0xFF6f88e2);
//   static const Color primaryDark = Color(0xFF5a73d1);
//   static const Color backgroundColor = Color(0xFFF8F9FF);
//   static const Color cardColor = Color(0xFFF8F9FF); // Changed to backgroundColor
//   static const Color textPrimary = Color(0xFF2D3748);
//   static const Color textSecondary = Color(0xFF718096);

//   @override
//   void initState() {
//     super.initState();
//     _loadTransactions();
//   }

//   @override
//   void dispose() {
//     _supplierNameController.dispose();
//     _invoiceNoController.dispose();
//     _amountController.dispose();
//     _dateController.dispose();
//     _dueDateController.dispose();
//     super.dispose();
//   }

//   // Helper method to get the current site name
//   String _getCurrentSiteName() {
//     if (widget.selectedSiteId == null) {
//       return 'All Sites';
//     }
//     final site = widget.sites.firstWhere(
//       (site) => site.id == widget.selectedSiteId,
//       orElse: () =>
//           Site(id: '', name: 'Unknown Site', address: '', companyId: ''),
//     );
//     return site.name;
//   }

//   void _loadTransactions() {
//     setState(() => _isLoading = true);
//     Future.delayed(const Duration(milliseconds: 500), () {
//       setState(() {
//         _transactions.addAll([
//           SupplierTransaction(
//             supplierName: "Johnson Supplies",
//             invoiceNo: "INV-2023-001",
//             date: DateTime.now().subtract(const Duration(days: 5)),
//             amount: 12500.00,
//             paymentDue: DateTime.now().add(const Duration(days: 25)),
//             status: "Pending",
//           ),
//           SupplierTransaction(
//             supplierName: "Alpha Construction",
//             invoiceNo: "INV-2023-045",
//             date: DateTime.now().subtract(const Duration(days: 10)),
//             amount: 8500.50,
//             paymentDue: DateTime.now().add(const Duration(days: 5)),
//             status: "Due Soon",
//           ),
//           SupplierTransaction(
//             supplierName: "Global Trading",
//             invoiceNo: "INV-2023-112",
//             date: DateTime.now().subtract(const Duration(days: 30)),
//             amount: 32000.75,
//             paymentDue: DateTime.now().subtract(const Duration(days: 2)),
//             status: "Overdue",
//           ),
//           SupplierTransaction(
//             supplierName: "Alex Enterprises",
//             invoiceNo: "INV-2023-002",
//             date: DateTime.now().subtract(const Duration(days: 15)),
//             amount: 18500.00,
//             paymentDue: DateTime.now().add(const Duration(days: 45)),
//             status: "Pending",
//           ),
//         ]);
//         _isLoading = false;
//       });
//     });
//   }

//   List<SupplierTransaction> get _filteredTransactions {
//     List<SupplierTransaction> filtered = _transactions.where((t) {
//       final matchesSearch =
//           _searchQuery.isEmpty ||
//           t.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           t.invoiceNo.toLowerCase().contains(_searchQuery.toLowerCase());
//       return matchesSearch;
//     }).toList();
//     // Sort by payment due date (overdue first, then due soon, then pending)
//     filtered.sort((a, b) {
//       if (a.status == "Overdue" && b.status != "Overdue") return -1;
//       if (a.status != "Overdue" && b.status == "Overdue") return 1;
//       if (a.status == "Due Soon" && b.status == "Pending") return -1;
//       if (a.status == "Pending" && b.status == "Due Soon") return 1;
//       return a.paymentDue.compareTo(b.paymentDue);
//     });
//     return filtered;
//   }

//   Widget _buildSearchBar() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return Container(
//           margin: const EdgeInsets.all(16),
//           child: TextField(
//             onChanged: (value) => setState(() => _searchQuery = value),
//             decoration: InputDecoration(
//               hintText: 'Search supplier...',
//               prefixIcon: Icon(Icons.search, color: primaryColor),
//               suffixIcon: _searchQuery.isNotEmpty
//                   ? IconButton(
//                       icon: const Icon(Icons.clear),
//                       onPressed: () => setState(() => _searchQuery = ''),
//                       color: textSecondary,
//                     )
//                   : null,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 borderSide: BorderSide.none,
//               ),
//               filled: true,
//               fillColor: Colors.white,
//               hintStyle: TextStyle(
//                 color: textSecondary,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildTransactionCard(SupplierTransaction transaction) {
//     Color statusColor = Colors.grey;
//     if (transaction.status == "Due Soon") {
//       statusColor = Colors.orange;
//     } else if (transaction.status == "Overdue") {
//       statusColor = Colors.red;
//     } else if (transaction.status == "Paid") {
//       statusColor = Colors.green;
//     }
    
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isSmallScreen = constraints.maxWidth < 600;
        
//         return Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             color: cardColor,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: primaryColor.withOpacity(0.08),
//                 blurRadius: 20,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: () => _showEditTransactionBottomSheet(transaction),
//               child: Padding(
//                 padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Header row with icon, supplier name, status, and delete button
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: primaryColor.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Icon(
//                             Icons.receipt_long,
//                             color: primaryColor,
//                             size: 22,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             transaction.supplierName,
//                             style: TextStyle(
//                               fontSize: isSmallScreen ? 16 : 18,
//                               fontWeight: FontWeight.bold,
//                               color: textPrimary,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         // Status and Delete button
//                         Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: statusColor.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(20),
//                                 border: Border.all(
//                                   color: statusColor.withOpacity(0.3),
//                                 ),
//                               ),
//                               child: Text(
//                                 transaction.status,
//                                 style: TextStyle(
//                                   color: statusColor,
//                                   fontSize: isSmallScreen ? 9 : 11,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             // Delete button
//                             GestureDetector(
//                               onTap: () {
//                                 _showDeleteConfirmationDialog(transaction);
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.all(4),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Icon(
//                                   Icons.delete,
//                                   color: Colors.red,
//                                   size: 18,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
                    
//                     const SizedBox(height: 12),
                    
//                     // First row: Invoice and Due Date side by side
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildCompactInfoItem(
//                             Icons.receipt_outlined,
//                             'Invoice',
//                             transaction.invoiceNo,
//                             isSmallScreen: isSmallScreen,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: _buildCompactInfoItem(
//                             Icons.event_available_outlined,
//                             'Due Date',
//                             DateFormat('MMM dd, yyyy').format(transaction.paymentDue),
//                             isSmallScreen: isSmallScreen,
//                             textColor: transaction.status == "Overdue" ? Colors.red : textPrimary,
//                           ),
//                         ),
//                       ],
//                     ),
                    
//                     const SizedBox(height: 8),
                    
//                     // Second row: Amount and Transaction Date side by side
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildCompactInfoItem(
//                             Icons.currency_rupee,
//                             'Amount',
//                             NumberFormat.currency(
//                               symbol: 'Rs ',
//                             ).format(transaction.amount),
//                             isSmallScreen: isSmallScreen,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: _buildCompactInfoItem(
//                             Icons.access_time,
//                             'Transaction Date',
//                             DateFormat('MMM dd, yyyy').format(transaction.date),
//                             isSmallScreen: isSmallScreen,
//                           ),
//                         ),
//                       ],
//                     ),
                    
//                     const SizedBox(height: 8),
                    
//                     // Mark as Paid button if applicable
//                     if (transaction.status == "Overdue" || transaction.status == "Due Soon")
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: TextButton.icon(
//                           onPressed: () => _markAsPaid(transaction),
//                           icon: const Icon(Icons.check_circle, size: 18),
//                           label: const Text("Mark as Paid"),
//                           style: TextButton.styleFrom(
//                             foregroundColor: primaryColor,
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // Helper method for compact info items
//   Widget _buildCompactInfoItem(
//     IconData icon, 
//     String label, 
//     String value, {
//     bool isSmallScreen = false,
//     Color textColor = textPrimary,
//   }) {
//     return Container(
//       padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: primaryColor.withOpacity(0.1)),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             size: isSmallScreen ? 14 : 16,
//             color: primaryColor,
//           ),
//           const SizedBox(width: 6),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 9 : 10,
//                     color: textSecondary,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 1),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 12 : 13,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: primaryColor.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.receipt_long_outlined,
//                 size: 64,
//                 color: primaryColor,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'No transactions found',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: textPrimary,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               _searchQuery.isEmpty
//                   ? 'Start by adding your first transaction'
//                   : 'Try adjusting your search criteria',
//               style: TextStyle(fontSize: 16, color: textSecondary),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showAddTransactionBottomSheet() {
//     // Clear controllers when opening the bottom sheet
//     _supplierNameController.clear();
//     _invoiceNoController.clear();
//     _amountController.clear();
//     _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     _dueDateController.text = DateFormat(
//       'yyyy-MM-dd',
//     ).format(DateTime.now().add(const Duration(days: 30)));
//     _status = "Pending";
//     _showTransactionBottomSheet();
//   }

//   void _showEditTransactionBottomSheet(SupplierTransaction transaction) {
//     // Populate controllers with transaction data
//     _supplierNameController.text = transaction.supplierName;
//     _invoiceNoController.text = transaction.invoiceNo;
//     _amountController.text = transaction.amount.toString();
//     _dateController.text = DateFormat('yyyy-MM-dd').format(transaction.date);
//     _dueDateController.text = DateFormat('yyyy-MM-dd').format(transaction.paymentDue);
//     _status = transaction.status;
//     _showTransactionBottomSheet(transaction: transaction);
//   }

//   void _showTransactionBottomSheet({SupplierTransaction? transaction}) {
//     final isEditing = transaction != null;
    
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.7,
//         minChildSize: 0.5,
//         maxChildSize: 0.9,
//         builder: (context, scrollController) {
//           return StatefulBuilder(
//             builder: (context, setSheetState) {
//               return Container(
//                 decoration: const BoxDecoration(
//                   color: backgroundColor,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 20,
//                       offset: Offset(0, -5),
//                     ),
//                   ],
//                 ),
//                 child: Padding(
//                   padding: EdgeInsets.only(
//                     bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//                     left: 20,
//                     right: 20,
//                     top: 24,
//                   ),
//                   child: Scrollbar(
//                     controller: scrollController,
//                     thumbVisibility: false,
//                     child: SingleChildScrollView(
//                       controller: scrollController,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           Center(
//                             child: Container(
//                               width: 40,
//                               height: 4,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(2),
//                               ),
//                             ),
//                           ),
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: primaryColor.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Icon(
//                                   isEditing ? Icons.edit : Icons.add_card,
//                                   color: primaryColor,
//                                   size: 28,
//                                 ),
//                               ),
//                               const SizedBox(width: 16),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       isEditing ? 'Edit Transaction' : 'Add New Transaction',
//                                       style: const TextStyle(
//                                         fontSize: 24,
//                                         fontWeight: FontWeight.bold,
//                                         color: textPrimary,
//                                       ),
//                                     ),
//                                     Text(
//                                       isEditing ? 'Update transaction details' : 'Enter transaction details below',
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         color: textSecondary,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 32),
//                           _buildEnhancedTextField(
//                             controller: _supplierNameController,
//                             label: 'Supplier Name',
//                             hint: 'e.g. Johnson Supplies',
//                             icon: Icons.business_outlined,
//                           ),
//                           const SizedBox(height: 20),
//                           _buildEnhancedTextField(
//                             controller: _invoiceNoController,
//                             label: 'Invoice Number',
//                             hint: 'e.g. INV-2023-001',
//                             icon: Icons.receipt_outlined,
//                           ),
//                           const SizedBox(height: 20),
//                           _buildEnhancedTextField(
//                             controller: _amountController,
//                             label: 'Amount',
//                             hint: 'e.g. 12500.00',
//                             icon: Icons.currency_rupee_outlined,
//                             keyboardType: TextInputType.numberWithOptions(decimal: true),
//                           ),
//                           const SizedBox(height: 20),
//                           _buildEnhancedTextField(
//                             controller: _dateController,
//                             label: 'Date',
//                             hint: 'Select date',
//                             icon: Icons.calendar_today,
//                             readOnly: true,
//                             onTap: () async {
//                               DateTime? pickedDate = await showDatePicker(
//                                 context: context,
//                                 initialDate: DateTime.now(),
//                                 firstDate: DateTime(2000),
//                                 lastDate: DateTime(2101),
//                               );
//                               if (pickedDate != null) {
//                                 setSheetState(() {
//                                   _dateController.text = DateFormat(
//                                     'yyyy-MM-dd',
//                                   ).format(pickedDate);
//                                 });
//                               }
//                             },
//                           ),
//                           const SizedBox(height: 20),
//                           _buildEnhancedTextField(
//                             controller: _dueDateController,
//                             label: 'Due Date',
//                             hint: 'Select due date',
//                             icon: Icons.event_available_outlined,
//                             readOnly: true,
//                             onTap: () async {
//                               DateTime? pickedDate = await showDatePicker(
//                                 context: context,
//                                 initialDate: DateTime.now().add(
//                                   const Duration(days: 30),
//                                 ),
//                                 firstDate: DateTime(2000),
//                                 lastDate: DateTime(2101),
//                               );
//                               if (pickedDate != null) {
//                                 setSheetState(() {
//                                   _dueDateController.text = DateFormat(
//                                     'yyyy-MM-dd',
//                                   ).format(pickedDate);
//                                 });
//                               }
//                             },
//                           ),
//                           const SizedBox(height: 20),
//                           _buildEnhancedDropdown(
//                             value: _status,
//                             label: 'Status',
//                             icon: Icons.info_outline,
//                             items: ["Pending", "Due Soon", "Overdue", "Paid"],
//                             onChanged: (val) {
//                               setSheetState(() {
//                                 _status = val!;
//                               });
//                             },
//                           ),
//                           const SizedBox(height: 32),
//                           Container(
//                             height: 56,
//                             decoration: BoxDecoration(
//                               gradient: const LinearGradient(
//                                 colors: [primaryColor, primaryDark],
//                                 begin: Alignment.centerLeft,
//                                 end: Alignment.centerRight,
//                               ),
//                               borderRadius: BorderRadius.circular(16),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: primaryColor.withOpacity(0.3),
//                                   blurRadius: 12,
//                                   offset: const Offset(0, 6),
//                                 ),
//                               ],
//                             ),
//                             child: ElevatedButton.icon(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.transparent,
//                                 shadowColor: Colors.transparent,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(16),
//                                 ),
//                               ),
//                               icon: Icon(
//                                 isEditing ? Icons.update : Icons.add,
//                                 color: Colors.white,
//                                 size: 22,
//                               ),
//                               label: Text(
//                                 isEditing ? 'Update Transaction' : 'Add Transaction',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               onPressed: () => isEditing 
//                                   ? _updateTransaction(transaction!) 
//                                   : _addTransaction(),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildEnhancedTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     bool readOnly = false,
//     VoidCallback? onTap,
//     TextInputType? keyboardType,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboardType,
//         readOnly: readOnly,
//         onTap: onTap,
//         style: const TextStyle(
//           color: textPrimary,
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//         decoration: InputDecoration(
//           labelText: label,
//           hintText: hint,
//           prefixIcon: Icon(
//             icon,
//             color: primaryColor,
//             size: 22,
//           ),
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide.none,
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: primaryColor, width: 2),
//           ),
//           labelStyle: TextStyle(
//             color: textSecondary,
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//           hintStyle: TextStyle(
//             color: textSecondary.withOpacity(0.7),
//             fontSize: 14,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEnhancedDropdown({
//     required String value,
//     required String label,
//     required IconData icon,
//     required List<String> items,
//     required Function(String?) onChanged,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: DropdownButtonFormField<String>(
//         value: value,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon, color: primaryColor, size: 22),
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide.none,
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide(color: primaryColor, width: 2),
//           ),
//           labelStyle: TextStyle(
//             color: textSecondary,
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         dropdownColor: Colors.white,
//         style: const TextStyle(
//           color: textPrimary,
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//         items: items
//             .map((item) => DropdownMenuItem(value: item, child: Text(item)))
//             .toList(),
//         onChanged: onChanged,
//       ),
//     );
//   }

//   void _addTransaction() {
//     if (_supplierNameController.text.isEmpty ||
//         _invoiceNoController.text.isEmpty ||
//         _amountController.text.isEmpty ||
//         _dateController.text.isEmpty ||
//         _dueDateController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Row(
//             children: [
//               Icon(Icons.error_outline, color: Colors.white),
//               SizedBox(width: 12),
//               Text("Please fill all fields"),
//             ],
//           ),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       );
//       return;
//     }
//     final newTransaction = SupplierTransaction(
//       supplierName: _supplierNameController.text,
//       invoiceNo: _invoiceNoController.text,
//       date: DateFormat('yyyy-MM-dd').parse(_dateController.text),
//       amount: double.tryParse(_amountController.text) ?? 0,
//       paymentDue: DateFormat('yyyy-MM-dd').parse(_dueDateController.text),
//       status: _status,
//     );
//     setState(() {
//       _transactions.add(newTransaction);
//     });
//     Navigator.pop(context);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.add_circle, color: Colors.white),
//             const SizedBox(width: 12),
//             Text("Transaction added successfully"),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   void _updateTransaction(SupplierTransaction transaction) {
//     if (_supplierNameController.text.isEmpty ||
//         _invoiceNoController.text.isEmpty ||
//         _amountController.text.isEmpty ||
//         _dateController.text.isEmpty ||
//         _dueDateController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Row(
//             children: [
//               Icon(Icons.error_outline, color: Colors.white),
//               SizedBox(width: 12),
//               Text("Please fill all fields"),
//             ],
//           ),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       );
//       return;
//     }
    
//     final index = _transactions.indexOf(transaction);
//     setState(() {
//       _transactions[index] = SupplierTransaction(
//         supplierName: _supplierNameController.text,
//         invoiceNo: _invoiceNoController.text,
//         date: DateFormat('yyyy-MM-dd').parse(_dateController.text),
//         amount: double.tryParse(_amountController.text) ?? 0,
//         paymentDue: DateFormat('yyyy-MM-dd').parse(_dueDateController.text),
//         status: _status,
//       );
//     });
//     Navigator.pop(context);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.white),
//             const SizedBox(width: 12),
//             Text("Transaction updated successfully"),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   void _showDeleteConfirmationDialog(SupplierTransaction transaction) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Transaction'),
//         content: Text('Are you sure you want to delete the transaction with ${transaction.supplierName}?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _deleteTransaction(transaction);
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _deleteTransaction(SupplierTransaction transaction) {
//     final index = _transactions.indexOf(transaction);
//     setState(() {
//       _transactions.remove(transaction);
//     });
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.delete, color: Colors.white),
//             const SizedBox(width: 12),
//             Text('Transaction with ${transaction.supplierName} deleted successfully'),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         action: SnackBarAction(
//           label: 'Undo',
//           textColor: Colors.white,
//           onPressed: () {
//             setState(() {
//               _transactions.insert(index, transaction);
//             });
//           },
//         ),
//       ),
//     );
//   }

//   void _markAsPaid(SupplierTransaction transaction) {
//     final index = _transactions.indexOf(transaction);
//     setState(() {
//       _transactions[index] = SupplierTransaction(
//         supplierName: transaction.supplierName,
//         invoiceNo: transaction.invoiceNo,
//         date: transaction.date,
//         amount: transaction.amount,
//         paymentDue: transaction.paymentDue,
//         status: "Paid",
//       );
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.white),
//             const SizedBox(width: 12),
//             Text("Marked ${transaction.invoiceNo} as Paid"),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   void _exportStatements() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Export Statements"),
//         content: const Text(
//           "Select format to export supplier payment statements:",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
//             onPressed: () {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Export started successfully")),
//               );
//             },
//             child: const Text("PDF", style: TextStyle(color: Colors.white)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
//             onPressed: () {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Export started successfully")),
//               );
//             },
//             child: const Text("Excel", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         elevation: 0,
//         toolbarHeight: 80,
//         backgroundColor: Colors.transparent,
//         title: RichText(
//           text: TextSpan(
//             children: [
//               const TextSpan(
//                 text: 'Supplier Ledger - ',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               TextSpan(
//                 text: _getCurrentSiteName(),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download),
//             onPressed: _exportStatements,
//           ),
//         ],
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             borderRadius: const BorderRadius.vertical(
//               bottom: Radius.circular(24),
//             ),
//             gradient: const LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: primaryColor.withOpacity(0.3),
//                 blurRadius: 20,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator(color: primaryColor))
//           : Column(
//               children: [
//                 _buildSearchBar(),
//                 Expanded(
//                   child: _filteredTransactions.isEmpty
//                       ? _buildEmptyState()
//                       : ListView.builder(
//                           itemCount: _filteredTransactions.length,
//                           itemBuilder: (context, index) {
//                             return _buildTransactionCard(
//                               _filteredTransactions[index],
//                             );
//                           },
//                         ),
//                 ),
//               ],
//             ),
//       floatingActionButton: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: primaryColor.withOpacity(0.3),
//               blurRadius: 20,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: FloatingActionButton.extended(
//           onPressed: _showAddTransactionBottomSheet,
//           backgroundColor: primaryColor,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           icon: const Icon(Icons.add),
//           label: const Text(
//             'Add Transaction',
//             style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class SupplierTransaction {
//   final String supplierName;
//   final String invoiceNo;
//   final DateTime date;
//   final double amount;
//   final DateTime paymentDue;
//   final String status;
  
//   SupplierTransaction({
//     required this.supplierName,
//     required this.invoiceNo,
//     required this.date,
//     required this.amount,
//     required this.paymentDue,
//     required this.status,
//   });
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ecoteam_app/contractor/models/site_model.dart';

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
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color cardColor = Color(0xFFF8F9FF);
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
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search supplier...',
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ''),
                  color: textSecondary,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(
            color: textSecondary,
            fontSize: 16,
          ),
        ),
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
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          onTap: () => _showEditTransactionBottomSheet(transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with icon, supplier name, status, and delete button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        transaction.supplierName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Status and Delete button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            transaction.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
                
                const SizedBox(height: 12),
                
                // First row: Invoice and Due Date side by side
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.receipt_outlined,
                        'Invoice',
                        transaction.invoiceNo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.event_available_outlined,
                        'Due Date',
                        DateFormat('MMM dd, yyyy').format(transaction.paymentDue),
                        textColor: transaction.status == "Overdue" ? Colors.red : textPrimary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Second row: Amount and Transaction Date side by side
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.currency_rupee,
                        'Amount',
                        NumberFormat.currency(
                          symbol: 'Rs ',
                        ).format(transaction.amount),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCompactInfoItem(
                        Icons.access_time,
                        'Transaction Date',
                        DateFormat('MMM dd, yyyy').format(transaction.date),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Mark as Paid button if applicable
                if (transaction.status == "Overdue" || transaction.status == "Due Soon")
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _markAsPaid(transaction),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text("Mark as Paid"),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for compact info items
  Widget _buildCompactInfoItem(
    IconData icon, 
    String label, 
    String value, {
    Color textColor = textPrimary,
  }) {
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
            color: primaryColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return StatefulBuilder(
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
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: scrollController,
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
                                      style: const TextStyle(
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
                          _buildEnhancedTextField(
                            controller: _supplierNameController,
                            label: 'Supplier Name',
                            hint: 'e.g. Johnson Supplies',
                            icon: Icons.business_outlined,
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedTextField(
                            controller: _invoiceNoController,
                            label: 'Invoice Number',
                            hint: 'e.g. INV-2023-001',
                            icon: Icons.receipt_outlined,
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedTextField(
                            controller: _amountController,
                            label: 'Amount',
                            hint: 'e.g. 12500.00',
                            icon: Icons.currency_rupee_outlined,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedTextField(
                            controller: _dateController,
                            label: 'Date',
                            hint: 'Select date',
                            icon: Icons.calendar_today,
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
                          const SizedBox(height: 20),
                          _buildEnhancedTextField(
                            controller: _dueDateController,
                            label: 'Due Date',
                            hint: 'Select due date',
                            icon: Icons.event_available_outlined,
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
                          const SizedBox(height: 20),
                          _buildEnhancedDropdown(
                            value: _status,
                            label: 'Status',
                            icon: Icons.info_outline,
                            items: ["Pending", "Due Soon", "Overdue", "Paid"],
                            onChanged: (val) {
                              setSheetState(() {
                                _status = val!;
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
                                size: 22,
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
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
            color: primaryColor,
            size: 22,
          ),
          filled: true,
          fillColor: Colors.white,
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
          labelStyle: TextStyle(
            color: textSecondary,
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

  Widget _buildEnhancedDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor, size: 22),
          filled: true,
          fillColor: Colors.white,
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
          labelStyle: TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("Please fill all fields"),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.add_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Transaction added successfully"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("Please fill all fields"),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Transaction updated successfully"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 12),
            Text('Transaction with ${transaction.supplierName} deleted successfully'),
          ],
        ),
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
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text("Marked ${transaction.invoiceNo} as Paid"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Export to PDF function
  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      final siteName = _getCurrentSiteName();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Add a page to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Supplier Ledger Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Site: $siteName | Generated on: $date',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Divider(thickness: 2),
                  ],
                ),
              ),
              
              // Table
              pw.Table.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF6f88e2),
                ),
                headers: ['Supplier', 'Invoice No', 'Date', 'Due Date', 'Amount', 'Status'],
                data: _filteredTransactions.map((transaction) => [
                  transaction.supplierName,
                  transaction.invoiceNo,
                  DateFormat('MMM dd, yyyy').format(transaction.date),
                  DateFormat('MMM dd, yyyy').format(transaction.paymentDue),
                  'Rs ${transaction.amount.toStringAsFixed(2)}',
                  transaction.status,
                ]).toList(),
              ),
              
              // Summary
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                child: pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Transactions: ${_filteredTransactions.length}'),
                  pw.Text('Total Amount: Rs ${_getTotalAmount().toStringAsFixed(2)}'),
                ],
              ),
            ];
          },
        ),
      );
      
      // Save the PDF document
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/supplier_ledger_$date.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Open the PDF file
      await OpenFile.open(file.path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.white),
              SizedBox(width: 12),
              Text("PDF exported successfully"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error exporting PDF: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Export to Excel function
  Future<void> _exportToExcel() async {
    try {
      // Create a new Excel document
      final xls.Workbook workbook = xls.Workbook();
      final xls.Worksheet sheet = workbook.worksheets[0];
      
      // Set column headers
      sheet.getRangeByName('A1').setText('Supplier');
      sheet.getRangeByName('B1').setText('Invoice No');
      sheet.getRangeByName('C1').setText('Date');
      sheet.getRangeByName('D1').setText('Due Date');
      sheet.getRangeByName('E1').setText('Amount');
      sheet.getRangeByName('F1').setText('Status');
      
      // Style the header row
      final xls.Range headerRange = sheet.getRangeByName('A1:F1');
      headerRange.cellStyle.backColor = '#6f88e2';
      headerRange.cellStyle.fontColor = '#FFFFFF';
      headerRange.cellStyle.bold = true;
      
      // Add data rows
      for (int i = 0; i < _filteredTransactions.length; i++) {
        final transaction = _filteredTransactions[i];
        sheet.getRangeByName('A${i + 2}').setText(transaction.supplierName);
        sheet.getRangeByName('B${i + 2}').setText(transaction.invoiceNo);
        sheet.getRangeByName('C${i + 2}').setText(DateFormat('MMM dd, yyyy').format(transaction.date));
        sheet.getRangeByName('D${i + 2}').setText(DateFormat('MMM dd, yyyy').format(transaction.paymentDue));
        sheet.getRangeByName('E${i + 2}').setNumber(transaction.amount);
        sheet.getRangeByName('F${i + 2}').setText(transaction.status);
      }
      
      // Auto fit columns
      sheet.autoFitColumn(1);
      sheet.autoFitColumn(2);
      sheet.autoFitColumn(3);
      sheet.autoFitColumn(4);
      sheet.autoFitColumn(5);
      sheet.autoFitColumn(6);
      
      // Save the Excel document
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      
      final directory = await getApplicationDocumentsDirectory();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${directory.path}/supplier_ledger_$date.xlsx');
      await file.writeAsBytes(bytes);
      
      // Open the Excel file
      await OpenFile.open(file.path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.table_chart, color: Colors.white),
              SizedBox(width: 12),
              Text("Excel exported successfully"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error exporting Excel: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to calculate total amount
  double _getTotalAmount() {
    return _filteredTransactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }

  void _showAllSuppliers() {
    // Get unique suppliers from transactions
    final uniqueSuppliers = _transactions
        .map((transaction) => transaction.supplierName)
        .toSet()
        .toList()
      ..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("All Suppliers"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: uniqueSuppliers.length,
            itemBuilder: (context, index) {
              final supplierName = uniqueSuppliers[index];
              final supplierTransactions = _transactions
                  .where((t) => t.supplierName == supplierName)
                  .toList();
              final totalAmount = supplierTransactions
                  .fold(0.0, (sum, t) => sum + t.amount);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    supplierName[0].toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(supplierName),
                subtitle: Text(
                  '${supplierTransactions.length} transactions • Rs ${totalAmount.toStringAsFixed(2)}',
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Filter transactions by this supplier
                  setState(() {
                    _searchQuery = supplierName;
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showSupplierCategories() {
    // Mock categories for demonstration
    final categories = {
      'Construction Materials': ['Johnson Supplies', 'Alpha Construction'],
      'Equipment & Tools': ['Global Trading'],
      'Services': ['Alex Enterprises'],
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supplier Categories"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final categoryName = categories.keys.elementAt(index);
              final suppliers = categories[categoryName]!;

              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.category,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(categoryName),
                subtitle: Text('${suppliers.length} suppliers'),
                children: suppliers.map((supplier) {
                  final supplierTransactions = _transactions
                      .where((t) => t.supplierName == supplier)
                      .toList();
                  final totalAmount = supplierTransactions
                      .fold(0.0, (sum, t) => sum + t.amount);

                  return ListTile(
                    leading: const SizedBox(width: 24),
                    title: Text(supplier),
                    subtitle: Text(
                      '${supplierTransactions.length} transactions • Rs ${totalAmount.toStringAsFixed(2)}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Filter transactions by this supplier
                      setState(() {
                        _searchQuery = supplier;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
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
              _exportToPDF();
            },
            child: const Text("PDF", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(context);
              _exportToExcel();
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
        toolbarHeight: 80.h,
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
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'all_suppliers':
                  _showAllSuppliers();
                  break;
                case 'supplier_categories':
                  _showSupplierCategories();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'all_suppliers',
                child: Row(
                  children: [
                    Icon(Icons.list, color: Color(0xFF6f88e2)),
                    SizedBox(width: 8),
                    Text('All Suppliers'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'supplier_categories',
                child: Row(
                  children: [
                    Icon(Icons.category, color: Color(0xFF6f88e2)),
                    SizedBox(width: 8),
                    Text('Supplier Categories'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.menu),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportStatements,
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(25),
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
