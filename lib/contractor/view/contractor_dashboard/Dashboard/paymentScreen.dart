import 'package:ecoteam_app/admin/models/payment_model.dart';
import 'package:ecoteam_app/admin/services/payment_services.dart';
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart' as contractor_site;
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class PaymentsDetailScreen extends StatefulWidget {
  final String? selectedSiteName;
  final int? selectedSiteId;
  final int? workspaceId;
  final int? userId;

  const PaymentsDetailScreen({
    super.key,
    this.selectedSiteName,
    this.selectedSiteId,
    this.workspaceId,
    this.userId,
  });
  @override
  State<PaymentsDetailScreen> createState() => _PaymentsDetailScreenState();
}

class _PaymentsDetailScreenState extends State<PaymentsDetailScreen> {
  List<Payment> payments = [];
  List<Payment> filteredPayments = [];
  bool isLoading = true;
  String searchQuery = '';
  DropdownData? dropdownData;
  late int? workspaceId;
  Timer? _permissionTimer;

  // For report date range
  DateTime _reportStartDate = DateTime.now();
  DateTime _reportEndDate = DateTime.now();
  List<Payment> _reportRecords = [];
  double _reportTotalAmount = 0;
  int _reportTotalPayments = 0;
  Map<String, double> _reportDateTotals = {};

  @override
  void initState() {
    super.initState();
    workspaceId = widget.workspaceId ?? 3;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _refreshPermissions();
    });

    _permissionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _refreshPermissions();
      }
    });
  }

  @override
  void dispose() {
    _permissionTimer?.cancel();
    super.dispose();
  }

  void _refreshPermissions() {
    Provider.of<CompanySiteProvider>(
      context,
      listen: false,
    ).refreshPermissions();
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
      ).showSnackBar(SnackBar(content: Text('Error loading data')));
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
        selectedSiteId: widget.selectedSiteId,
        userId: widget.userId,
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
        ).showSnackBar(SnackBar(content: Text('Error deleting payment')));
      }
    }
  }

  void _showPaymentDetailsBottomSheet(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
              Text(
                payment.paymentNumber ?? 'N/A',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Date', _formatDate(payment.paymentDate)),
                    const Divider(),
                    _buildDetailRow('Amount', '₹ ${payment.amount ?? '0.00'}'),
                    const Divider(),
                    _buildDetailRow(
                      'Supplier',
                      payment.supplier?.name ?? 'N/A',
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Invoice',
                      payment.invoice?.invoiceNumber ?? 'N/A',
                    ),

                    const Divider(),
                    _buildDetailRow(
                      'Type',
                      _formatPaymentType(payment.paymentType),
                    ),
                    const Divider(),
                    _buildDetailRow('Mode', _formatMode(payment.mode)),
                    if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                      const Divider(),
                      const Divider(),
                      _buildDetailRow('Notes', payment.notes!),
                    ],
                    if (payment.creator?.name != null || payment.invoice?.creator?.name != null) ...[
                      const Divider(),
                      _buildDetailRow(
                        'Created By',
                        payment.creator?.name ?? payment.invoice?.creator?.name ?? '',
                      ),
                    ],
                    if (payment.referenceNumber != null &&
                        payment.referenceNumber!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailRow(
                        'Reference No.',
                        payment.referenceNumber!,
                      ),
                    ],
                    if (payment.paymentProofFile != null &&
                        payment.paymentProofFile!.isNotEmpty) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment Proof',
                              style: TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 14,
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  _launchProofUrl(payment.paymentProofFile!),
                              child: const Text(
                                'View File',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child:
                        Provider.of<CompanySiteProvider>(
                          context,
                        ).hasPermission('manage-payment edit')
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddEditBottomSheet(payment: payment);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2a43a0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Edit'),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchProofUrl(String filePath) async {
    String url = filePath;
    if (!url.startsWith('http')) {
      // Construct full URL assuming storage path
      url = 'https://app.ecoteamsolar.com/$filePath';
    }

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open file: $url')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            overflow: TextOverflow.ellipsis,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 74.h,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              widget.selectedSiteName != null
                  ? 'Site: ${widget.selectedSiteName}'
                  : 'All Sites',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13.sp,
              ),
            ),
          ],
        ),

        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.r)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4a63c0),
                  Color(0xFF3a53b0),
                  Color(0xFF2a43a0),
                ],
              ),
            ),
          ),
        ),
        actions: buildNotificationActions(
          context: context,
          selectedSiteId: widget.selectedSiteId?.toString(),
          sites: (dropdownData?.sites ?? []).map((site) => 
            contractor_site.Site(
              id: site.id?.toString() ?? '',
              name: site.name ?? 'Unknown Site',
              companyId: workspaceId?.toString() ?? '0',
            )
          ).toList(),
          currentCompany: Provider.of<CompanySiteProvider>(context, listen: false).selectedCompanyName ?? '',
          workspaceId: workspaceId,
        ),
      ),
      floatingActionButton:
          Provider.of<CompanySiteProvider>(
            context,
          ).hasPermission('manage-payment create')
          ? FloatingActionButton(
              onPressed: () => _showAddEditBottomSheet(),
              backgroundColor: AppColors.gradientEnd,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: _filterPayments,
              decoration: InputDecoration(
                hintText: 'Search payments...',
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.card,
              ),
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
                Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.black12.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    tooltip: 'Generate Report',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _generateReport,
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      size: 24,
                      color: Color.fromARGB(255, 29, 29, 29),
                    ),
                  ),
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
                        onView: () => _showPaymentDetailsBottomSheet(payment),
                        canshow: Provider.of<CompanySiteProvider>(
                          context,
                          listen: false,
                        ).hasPermission('manage-payment show'),
                        canEdit: Provider.of<CompanySiteProvider>(
                          context,
                          listen: false,
                        ).hasPermission('manage-payment edit'),
                        canDelete: Provider.of<CompanySiteProvider>(
                          context,
                          listen: false,
                        ).hasPermission('manage-payment delete'),
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

  // ==================== PDF REPORT FUNCTIONALITY ====================

  Future<void> _generateReport() async {
    // Initialize report with default values (today's date)
    _reportStartDate = DateTime.now();
    _reportEndDate = DateTime.now();

    // Calculate initial report data
    _updateReportData();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReportSheet(),
    );
  }

  void _updateReportData() {
    // Filter records by date range
    _reportRecords = payments.where((payment) {
      if (payment.paymentDate == null) return false;
      try {
        final paymentDate = DateTime.parse(payment.paymentDate!);
        // Normalize dates to remove time component for comparison
        final normalizeDate = (DateTime d) => DateTime(d.year, d.month, d.day);
        final pDate = normalizeDate(paymentDate);
        final start = normalizeDate(_reportStartDate);
        final end = normalizeDate(_reportEndDate);

        return (pDate.isAtSameMomentAs(start) || pDate.isAfter(start)) &&
            (pDate.isAtSameMomentAs(end) || pDate.isBefore(end));
      } catch (e) {
        return false;
      }
    }).toList();

    // Calculate totals for the filtered records
    _reportTotalAmount = 0;
    _reportTotalPayments = _reportRecords.length;
    _reportDateTotals.clear();

    for (var payment in _reportRecords) {
      final amount = double.tryParse(payment.amount ?? '0') ?? 0;
      _reportTotalAmount += amount;

      // Sum up by date
      if (payment.paymentDate != null) {
        // Use just the date part for key
        final dateKey = payment.paymentDate!.substring(0, 10);
        _reportDateTotals[dateKey] = (_reportDateTotals[dateKey] ?? 0) + amount;
      }
    }
  }

  Widget _buildReportSheet() {
    final screenHeight = MediaQuery.of(context).size.height;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          height: screenHeight * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payments Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a43a0),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF2a43a0)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date Range Selection
              const Text(
                'Select Date Range:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a43a0),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _reportStartDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _reportStartDate = picked;
                            if (_reportStartDate.isAfter(_reportEndDate)) {
                              _reportEndDate = _reportStartDate;
                            }
                            _updateReportData();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(_reportStartDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('to', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _reportEndDate,
                          firstDate: _reportStartDate,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _reportEndDate = picked;
                            _updateReportData();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(_reportEndDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Report Summary
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildReportSummary(),
                      const SizedBox(height: 16),
                      _buildDateWiseSummary(),
                      const SizedBox(height: 16),
                      _buildRecordsList(),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _viewPDF(() => Navigator.pop(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 50, 160, 47),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text(
                      'View PDF',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _viewPDF([VoidCallback? onSuccess]) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfBytes = await _generatePdfBytes();
      final directory = await getTemporaryDirectory();
      // Safe file name
      final siteName = (widget.selectedSiteName ?? 'All_Sites').replaceAll(
        ' ',
        '_',
      );
      final fileName =
          'payment_report_${siteName}_${DateFormat('yyyyMMdd').format(_reportStartDate)}_to_${DateFormat('yyyyMMdd').format(_reportEndDate)}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes);

      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      if (onSuccess != null) {
        onSuccess();
      }

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${result.message}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to view PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildReportSummary() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4a63c0), Color(0xFF2a43a0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildReportItem(
            'Date Range',
            '${DateFormat('yyyy-MM-dd').format(_reportStartDate)} to ${DateFormat('yyyy-MM-dd').format(_reportEndDate)}',
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem(
            'Site',
            widget.selectedSiteName ?? 'All Sites',
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem(
            'Total Payments',
            _reportTotalPayments.toString(),
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem(
            'Total Amount',
            'Rs ${_reportTotalAmount.toStringAsFixed(2)}',
            Colors.white70,
            Colors.white,
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white30),
          const SizedBox(height: 10),
          _buildReportItem(
            'Report Generated',
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
            Colors.white70,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: TextStyle(color: labelColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateWiseSummary() {
    if (_reportDateTotals.isEmpty) {
      return const Center(
        child: Text(
          'No data for selected date range',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Sort dates
    final sortedDates = _reportDateTotals.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date-wise Expenditure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2a43a0),
            ),
          ),
          const SizedBox(height: 12),
          ...sortedDates.map(
            (date) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Rs ${_reportDateTotals[date]!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a43a0),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_reportRecords.isEmpty) {
      return Container();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Payments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2a43a0),
            ),
          ),
          const SizedBox(height: 12),
          ..._reportRecords
              .take(5)
              .map(
                (payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.paymentNumber ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              payment.supplier?.name ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs ${payment.amount ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2a43a0),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          if (_reportRecords.length > 5)
            Text(
              '... and ${_reportRecords.length - 5} more payments',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();

    final filteredRecords = _reportRecords;

    // Group and calculate totals by date
    final Map<String, Map<String, double>> dailyStats = {};
    double totalAmount = 0;

    for (var payment in filteredRecords) {
      final amount = double.tryParse(payment.amount ?? '0') ?? 0;
      totalAmount += amount;

      final dateKey = payment.paymentDate?.substring(0, 10) ?? 'Unknown';

      if (!dailyStats.containsKey(dateKey)) {
        dailyStats[dateKey] = {'amount': 0.0, 'count': 0.0};
      }

      dailyStats[dateKey]!['amount'] = dailyStats[dateKey]!['amount']! + amount;
      dailyStats[dateKey]!['count'] = dailyStats[dateKey]!['count']! + 1;
    }

    // Sort dates
    final sortedDates = dailyStats.keys.toList()..sort();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Payment Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF2a43a0),
                    ),
                  ),
                  pw.Text(
                    'Site: ${widget.selectedSiteName ?? 'All Sites'}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Report Details
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Report Period: ${DateFormat('dd MMM yyyy').format(_reportStartDate)} to ${DateFormat('dd MMM yyyy').format(_reportEndDate)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Total Payments: ${filteredRecords.length}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Total Amount: Rs ${totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Suppliers Count: ${filteredRecords.map((e) => e.supplierId).toSet().length}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Dates with Data: ${sortedDates.length}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 25),

              // Date-wise Summary Table
              pw.Text(
                'Date-wise Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF2a43a0),
                ),
              ),
              pw.SizedBox(height: 10),

              if (sortedDates.isNotEmpty)
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5), // Date
                    1: const pw.FlexColumnWidth(1), // Day
                    2: const pw.FlexColumnWidth(1), // Count
                    3: const pw.FlexColumnWidth(1.5), // Amount
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF2a43a0),
                      ),
                      children: [
                        pw.Padding(
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            'Day',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            'Payments',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                      ],
                    ),

                    // Data rows
                    ...sortedDates.map((dateStr) {
                      try {
                        final date = DateTime.parse(dateStr);
                        final formattedDate = DateFormat(
                          'dd-MMM-yyyy',
                        ).format(date);
                        final dayName = DateFormat('EEEE').format(date);
                        final stats = dailyStats[dateStr]!;

                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              child: pw.Text(
                                formattedDate,
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                dayName.substring(0, 3),
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                stats['count']!.toStringAsFixed(0),
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                            pw.Padding(
                              child: pw.Text(
                                'Rs ${stats['amount']!.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColor.fromInt(0xFF2a43a0),
                                ),
                              ),
                              padding: const pw.EdgeInsets.all(6),
                            ),
                          ],
                        );
                      } catch (e) {
                        return pw.TableRow(children: [pw.Text('Error')]);
                      }
                    }).toList(),

                    // Total row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF0F4FF),
                      ),
                      children: [
                        pw.Padding(
                          child: pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(''),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            filteredRecords.length.toString(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            'Rs ${totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: PdfColor.fromInt(0xFF2a43a0),
                            ),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                        ),
                      ],
                    ),
                  ],
                )
              else
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No payment data found for the selected date range',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                    ),
                  ),
                ),

              pw.SizedBox(height: 30),

              // DETAILED RECORDS SECTION
              if (filteredRecords.isNotEmpty) ...[
                pw.Text(
                  'Detailed Payments',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF2a43a0),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Table for detailed records
                pw.Table(
                  border: pw.TableBorder.all(
                    width: 0.5,
                    color: PdfColors.grey300,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1), // Payment #
                    1: const pw.FlexColumnWidth(1), // Date
                    2: const pw.FlexColumnWidth(1.5), // Supplier
                    3: const pw.FlexColumnWidth(1), // Type
                    4: const pw.FlexColumnWidth(1.2), // Amount
                    5: const pw.FlexColumnWidth(1.3), // Created By
                    6: const pw.FlexColumnWidth(0.8), // Proof
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF0F4FF),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Payment #',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Supplier',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Type',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Created By',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Proof',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Rows
                    ...filteredRecords.map((payment) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              payment.paymentNumber ?? 'N/A',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              payment.paymentDate?.substring(0, 10) ?? 'N/A',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              payment.supplier?.name ?? 'Unknown',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              _formatPaymentType(payment.paymentType),
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Rs ${payment.amount ?? '0'}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              payment.creator?.name ?? payment.invoice?.creator?.name ?? '-',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: payment.paymentProofFile != null &&
                                    payment.paymentProofFile!.isNotEmpty
                                ? pw.UrlLink(
                                    destination:
                                        'https://app.ecoteamsolar.com/${payment.paymentProofFile}',
                                    child: pw.Text(
                                      'View',
                                      style: const pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColors.blue,
                                        decoration: pw.TextDecoration.underline,
                                      ),
                                    ),
                                  )
                                : pw.Text(
                                    '-',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}

class PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;
  final bool canEdit;
  final bool canDelete;
  final bool canshow;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    this.canEdit = true,
    this.canDelete = true,
    this.canshow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      margin: EdgeInsets.only(bottom: 9.h),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: Color(0xFF2a43a0).withOpacity(0.1),
              child: Icon(
                Icons.receipt_long,
                color: Color(0xFF2a43a0),
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        payment.paymentNumber ?? 'N/A',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      if (canshow)
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF2a43a0,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.visibility_outlined,
                                              color: Color.fromARGB(
                                                255,
                                                37,
                                                49,
                                                158,
                                              ),
                                            ),
                                          ),
                                          title: const Text(
                                            'View Details',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            onView();
                                          },
                                        ),
                                      if (canEdit)
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF2a43a0,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Color(0xFF2a43a0),
                                            ),
                                          ),
                                          title: const Text(
                                            'Edit Payment',
                                            style: TextStyle(
                                             fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            onEdit();
                                          },
                                        ),
                                      if (canDelete)
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                          ),
                                          title: const Text(
                                            'Delete Payment',
                                            style: TextStyle(
                                             fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.red,
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            onDelete();
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },

                            child: const Icon(
                              Icons.more_vert,
                              color: Color.fromARGB(255, 107, 107, 107),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  _buildDetailText(
                    'Supplier: ${payment.supplier?.name ?? 'N/A'}',
                  ),
                  _buildDetailText('Amount: ₹ ${payment.amount ?? '0.00'}'),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            38,
                            51,
                            172,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          _formatPaymentType(payment.paymentType),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color.fromARGB(255, 38, 51, 172),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          _formatMode(payment.mode),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color.fromARGB(255, 63, 151, 66),
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  Widget _buildDetailText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
  final int? selectedSiteId;
  final int? userId;
  final bool hideSiteField;
  final String? fixedSiteName;

  const PaymentFormBottomSheet({
    super.key,
    this.payment,
    this.dropdownData,
    required this.onSave,
    this.workspaceId = 3,
    this.selectedSiteId,
    this.userId,
    this.hideSiteField = false,
    this.fixedSiteName,
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
  String? _selectedFileName;

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
        // Fallback to widget props if payment object has nulls (common when pre-filling for new requests)
        createdBy: widget.payment!.createdBy ?? widget.userId,
        workspaceId: widget.payment!.workspaceId ?? widget.workspaceId,
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
        createdBy: widget.userId,
        workspaceId: widget.workspaceId,
        siteId: widget.selectedSiteId, // Initialize with selected site
      );
      _selectedSiteId = widget.selectedSiteId
          ?.toString(); // Initialize dropdown value

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
        await _loadSiteData(widget.payment!.siteId!, isInitialLoad: true);
      }
      // For add mode with pre-selected site
      else if (widget.payment == null && widget.selectedSiteId != null) {
        _selectedSiteId = widget.selectedSiteId.toString();
        await _loadSiteData(widget.selectedSiteId!, isInitialLoad: true);
      }

      // Mark initial data as loaded
      setState(() {
        _isInitialDataLoaded = true;
      });
    } catch (e) {
      print('Error loading initial data');
      setState(() {
        _isInitialDataLoaded = true; // Still mark as loaded even if error
      });
    }
  }

  Future<void> _loadSiteData(int siteId, {bool isInitialLoad = false}) async {
    if (siteId == 0) return;

    setState(() {
      _isLoadingSuppliers = true;
      if (!isInitialLoad) {
        // When changing site, clear supplier selection
        _selectedSupplierId = null;
        _selectedInvoiceId = null; // Clear invoice too
      }
    });

    try {
      print(
        'CURRENT STATUS: Fetching data for Site ID: $siteId, Workspace ID: ${widget.workspaceId}',
      );
      // Use getDropdownData to get both suppliers and invoices for the site
      final dropdownData = await PaymentService.getDropdownData(
        siteId: siteId,
        workspaceId: widget.workspaceId ?? 3,
      );

      // Build new suppliers map
      final Map<String, String> newSuppliers = {};
      if (dropdownData.suppliers != null) {
        dropdownData.suppliers!.forEach((key, supplier) {
          newSuppliers[supplier.id?.toString() ?? key] =
              supplier.name ?? 'Unknown Supplier';
        });
      }

      // Build new invoices map
      final Map<String, String> newInvoices = {};
      if (dropdownData.invoices != null) {
        dropdownData.invoices!.forEach((key, invoice) {
          newInvoices[invoice.id?.toString() ?? key] =
              invoice.invoiceNumber ?? 'Unknown Invoice';
        });
      }

      setState(() {
        _suppliers = newSuppliers;
        _supplierInvoices = newInvoices; // Update invoices for the site

        // If in edit mode, ensure selected supplier is valid
        if (isInitialLoad &&
            widget.payment != null &&
            widget.payment!.supplierId != null) {
          String supplierIdStr = widget.payment!.supplierId.toString();
          if (_suppliers.containsKey(supplierIdStr)) {
            _selectedSupplierId = supplierIdStr;
          }
        }

        // If in edit mode, ensure selected invoice is valid
        if (isInitialLoad &&
            widget.payment != null &&
            widget.payment!.purchaseInvoiceId != null) {
          String invoiceIdStr = widget.payment!.purchaseInvoiceId.toString();
          // If we have invoices from site data, check if current one exists
          if (_supplierInvoices.containsKey(invoiceIdStr)) {
            _selectedInvoiceId = invoiceIdStr;
            _updateRemainingAmount(_selectedInvoiceId);
          } else if (_selectedSupplierId != null) {
            // Fallback: If not in site list, try fetching by supplier (legacy/specific behavior)
            // This covers cases where 'create-data' might not return ALL invoices or if the invoice is old
            if (_selectedPaymentType == 'against_invoice') {
              _loadSupplierInvoices(widget.payment!.supplierId!);
            }
          }
        }
      });
    } catch (e) {
      print('Error loading site data: $e');
      setState(() {
        _suppliers = {};
        _supplierInvoices = {}; // Clear invoices on error
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
          // Auto-fill the amount field with the remaining amount
          if (widget.payment == null) { // Only auto-fill for new payments, not when editing (unless explicitly desired, but safer for new)
             _amountController.text = _remainingAmount.toStringAsFixed(2);
          }
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

      // Only treat as update if payment ID exists
      if (widget.payment != null && widget.payment!.id != null) {
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

                // Show loading indicator while initial data is loading (for edit mode)
                if (widget.payment != null && !_isInitialDataLoaded)
                  const Center(child: CircularProgressIndicator()),

                if (widget.payment == null || _isInitialDataLoaded)
                  Column(
                    children: [
                      // Row 1: Payment Number | Payment Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _paymentNumberController,
                              decoration: InputDecoration(
                                labelText: 'Payment Number*',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              readOnly: widget.payment == null,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please enter payment number'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 2: Payment Type | Supplier
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
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
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Stack(
                              children: [
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
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
                                      if (_supplierInvoices.isEmpty) {
                                        _loadSupplierInvoices(int.parse(value));
                                      }
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 3: Purchase Invoice | Remaining Amount
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _selectedPaymentType == 'against_invoice'
                                ? Stack(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value:
                                            _supplierInvoices.containsKey(
                                              _selectedInvoiceId,
                                            )
                                            ? _selectedInvoiceId
                                            : null,
                                        decoration: InputDecoration(
                                          labelText: 'Purchase Invoice*',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        items: [
                                          const DropdownMenuItem(
                                            value: '',
                                            child: Text('Select Invoice'),
                                          ),
                                          ..._supplierInvoices.entries.map(
                                            (entry) => DropdownMenuItem(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ),
                                          ),
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
                                              (value == null ||
                                                  value.isEmpty)) {
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
                                  )
                                : const SizedBox(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 4: Amount | Payment Mode
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
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
                                if (value == null || value.isEmpty) {
                                  return 'Please enter amount';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter valid amount';
                                }
                                
                                // Validation: Amount cannot be greater than remaining amount
                                // Only check if payment type is 'against_invoice' and we have a remaining amount
                                if (_selectedPaymentType == 'against_invoice' && 
                                    double.tryParse(value)! > _remainingAmount) {
                                  return 'Amount cannot be greater than remaining amount (${_remainingAmount.toStringAsFixed(2)})';
                                }
                                
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
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
                          ),
                        ],
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
                        onSaved: (value) => _formData.referenceNumber = value,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Payment Proof File Picker
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFileName ??
                              (widget.payment?.paymentProofFile != null
                                  ? 'Current File: ...${widget.payment!.paymentProofFile!.split('/').last.length > 20 ? widget.payment!.paymentProofFile!.split('/').last.substring(0, 20) : widget.payment!.paymentProofFile!.split('/').last}'
                                  : 'No file selected'),
                          style: TextStyle(
                            color:
                                _selectedFileName != null ||
                                    widget.payment?.paymentProofFile != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: [
                                    'pdf',
                                    'jpg',
                                    'jpeg',
                                    'png',
                                  ],
                                );

                            if (result != null) {
                              setState(() {
                                _selectedFileName = result.files.single.name;
                                _formData.paymentProofFile =
                                    result.files.single.path;
                              });
                            }
                          } catch (e) {
                            print("Error picking file: $e");
                          }
                        },
                        child: const Text('Select Proof'),
                      ),
                    ],
                  ),
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
                    maxLines: 1,
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

class AppColors {
  static const Color primary = Color(0xFF6f88e2);
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color gradientStart = Color(0xFF4a63c0);
  static const Color gradientMid = Color(0xFF3a53b0);
  static const Color gradientEnd = Color(0xFF2a43a0);

  static const Color background = Color.fromARGB(255, 250, 250, 255);
  static const Color card = Colors.white;

  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
}
