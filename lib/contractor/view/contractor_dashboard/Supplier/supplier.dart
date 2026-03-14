import 'dart:async';
import 'dart:typed_data';
import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/admin/services/Allsupplier_service.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Supplier/supplier_categary_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

// Add this import if you have a site model
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';

class SupplierLedger extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final int? workspaceId;
  final String? currentCompany;
  final int? userId;

  const SupplierLedger({
    Key? key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    this.currentCompany,
    this.workspaceId,
    this.userId,
  }) : super(key: key);

  @override
  State<SupplierLedger> createState() => _AllSupplierPageState();
}

class _AllSupplierPageState extends State<SupplierLedger> {
  final TextEditingController _searchController = TextEditingController();
  List<Supplier> _allSuppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Report state
  DateTime _reportStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _reportEndDate = DateTime.now();
  int? _reportSelectedCategoryId;

  // Dynamic lists for categories and types
  List<SupplierCategory> _categories = [];
  List<SupplierType> _types = [
    SupplierType(id: 1, name: 'individual', description: 'Individual'),
    SupplierType(id: 2, name: 'company', description: 'Company'),
    SupplierType(id: 3, name: 'partnership', description: 'Partnership'),
    SupplierType(
      id: 4,
      name: 'LLP',
      description: 'Limited Liability Partnership',
    ),
  ];

  // Color constants matching SupplierLedger
  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color backgroundColor = Color.fromARGB(255, 249, 249, 253);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  Timer? _permissionTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterSuppliers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  // Helper method to get the current site name
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final suppliers = await SupplierApiService.getSuppliers(
        workspaceId: widget.workspaceId,
        siteId: widget.selectedSiteId,
      );
      final categories = await SupplierApiService.getSupplierCategories();

      setState(() {
        _allSuppliers = suppliers;
        _filteredSuppliers = suppliers;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showSnackBar('Failed to load data: $e');
    }
  }

  void _filterSuppliers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSuppliers = _allSuppliers.where((supplier) {
        final categoryName = _getCategoryName(supplier.categoryId);

        // First filter by site if applicable
        bool siteMatches = true;
        if (widget.selectedSiteId != null) {
          siteMatches = supplier.siteId.toString() == widget.selectedSiteId;
        }

        // Then filter by search query
        final searchMatches =
            supplier.name.toLowerCase().contains(query) ||
            categoryName.toLowerCase().contains(query) ||
            supplier.contactPerson.toLowerCase().contains(query) ||
            supplier.phone.toLowerCase().contains(query);

        return siteMatches && searchMatches;
      }).toList();
    });
  }

  String _getCategoryName(int categoryId) {
    try {
      final category = _categories.firstWhere((cat) => cat.id == categoryId);
      return category.name;
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showSiteSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Site',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // All Sites option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.selectedSiteId == null
                      ? primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.all_inclusive,
                  color: widget.selectedSiteId == null
                      ? primaryColor
                      : Colors.grey,
                ),
              ),
              title: const Text(
                'All Sites',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              trailing: widget.selectedSiteId == null
                  ? Icon(Icons.check, color: primaryColor)
                  : null,
              onTap: () {
                Navigator.pop(context);
                widget.onSiteChanged('');
                _loadData();
              },
            ),
            const Divider(height: 1),
            // Site list
            ...widget.sites.map((site) {
              final isSelected = widget.selectedSiteId == site.id;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: isSelected ? primaryColor : Colors.grey,
                  ),
                ),
                title: Text(
                  site.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                subtitle: site.companyId != null
                    ? Text(
                        'Company ID: ${site.companyId}',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
                trailing: isSelected
                    ? Icon(Icons.check, color: primaryColor)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  widget.onSiteChanged(site.id);
                  _loadData();
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
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
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? prefix, // 👈 ADD THIS
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Color(0xFF4a63c0), size: 20.sp),
        prefix: prefix, // 👈 USE HERE
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 214, 215, 216),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 189, 190, 197),
            width: 1.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
      ),
    );
  }

  Widget _buildEnhancedDropdown<T>({
    required T? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<dynamic> items,
    required String Function(dynamic) displayText,
    required T? Function(dynamic) getValue,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded:
          true, // Prevent overflow by allowing the dropdown to expand within constraints
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 214, 215, 216),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Color.fromARGB(
              255,
              189,
              190,
              197,
            ), // Different color when focused
            width: 1.0,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 2),
        prefixIcon: Icon(icon, color: Color(0xFF4a63c0), size: 20.sp),
      ),
      dropdownColor: const Color.fromARGB(255, 255, 255, 255),
      style: const TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: getValue(item),
          child: Text(
            displayText(item),
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis, // Prevent text overflow
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  void _deleteSupplier(Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirm Delete',
          style: TextStyle(color: textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete ${supplier.name}?',
          style: const TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupplierApiService.deleteSupplier(supplier.id!);
        await _loadData();
        _showSnackBar('Supplier deleted successfully', isSuccess: true);
      } catch (e) {
        _showSnackBar('Failed to delete supplier: $e');
      }
    }
  }

  void _showSupplierDetailsBottomSheet(Supplier supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  // Header
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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

                          // Supplier Name
                          Text(
                            supplier.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Category & Site
                          Text(
                            '${_getCategoryName(supplier.categoryId)} • ${supplier.siteId == 0 ? 'All Sites' : 'Site ${supplier.siteId}'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider
                  const SliverToBoxAdapter(
                    child: Divider(
                      height: 32,
                      thickness: 1,
                      indent: 24,
                      endIndent: 24,
                    ),
                  ),

                  // Contact Information
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.person_outline,
                            'Contact Person',
                            'Mr. ${supplier.contactPerson}', // ✅ Updated
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Phone',
                            '+91 ${supplier.phone}', // ✅ Updated
                          ),
                          if (supplier.email != null &&
                              supplier.email!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.email_outlined,
                              'Email',
                              supplier.email!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Address Section (if available)
                  if (supplier.address != null &&
                      supplier.address!.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Divider(
                        height: 32,
                        thickness: 1,
                        indent: 24,
                        endIndent: 24,
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Address',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.location_on_outlined,
                              'Address',
                              supplier.address!,
                              showIcon: true,
                            ),
                            if (supplier.city != null &&
                                supplier.city!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.location_city_outlined,
                                'City',
                                supplier.city!,
                                showIcon: true,
                              ),
                            ],
                            if (supplier.state != null &&
                                supplier.state!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.map_outlined,
                                'State',
                                supplier.state!,
                                showIcon: true,
                              ),
                            ],
                            if (supplier.pincode != null &&
                                supplier.pincode!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.pin_drop_outlined,
                                'Pincode',
                                supplier.pincode!,
                                showIcon: true,
                              ),
                            ],
                            if (supplier.country != null &&
                                supplier.country!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.public_outlined,
                                'Country',
                                supplier.country!,
                                showIcon: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Tax Information (if available)
                  if ((supplier.gstNumber != null &&
                          supplier.gstNumber!.isNotEmpty) ||
                      (supplier.panNumber != null &&
                          supplier.panNumber!.isNotEmpty) ||
                      (supplier.registrationNumber != null &&
                          supplier.registrationNumber!.isNotEmpty)) ...[
                    const SliverToBoxAdapter(
                      child: Divider(
                        height: 32,
                        thickness: 1,
                        indent: 24,
                        endIndent: 24,
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tax Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (supplier.gstNumber != null &&
                                supplier.gstNumber!.isNotEmpty)
                              _buildInfoRow(
                                Icons.receipt_outlined,
                                'GST Number',
                                supplier.gstNumber!,
                              ),
                            if (supplier.panNumber != null &&
                                supplier.panNumber!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.credit_card_outlined,
                                'PAN Number',
                                supplier.panNumber!,
                              ),
                            ],
                            if (supplier.registrationNumber != null &&
                                supplier.registrationNumber!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.assignment_outlined,
                                'Registration Number',
                                supplier.registrationNumber!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Bank Details (if available)
                  if ((supplier.bankName != null &&
                          supplier.bankName!.isNotEmpty) ||
                      (supplier.accountNumber != null &&
                          supplier.accountNumber!.isNotEmpty) ||
                      (supplier.ifscCode != null &&
                          supplier.ifscCode!.isNotEmpty) ||
                      (supplier.paymentTerms != null &&
                          supplier.paymentTerms!.isNotEmpty)) ...[
                    const SliverToBoxAdapter(
                      child: Divider(
                        height: 32,
                        thickness: 1,
                        indent: 24,
                        endIndent: 24,
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bank & Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (supplier.bankName != null &&
                                supplier.bankName!.isNotEmpty)
                              _buildInfoRow(
                                Icons.account_balance_outlined,
                                'Bank Name',
                                supplier.bankName!,
                              ),
                            if (supplier.accountNumber != null &&
                                supplier.accountNumber!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.account_box_outlined,
                                'Account Number',
                                supplier.accountNumber!,
                              ),
                            ],
                            if (supplier.ifscCode != null &&
                                supplier.ifscCode!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.code_outlined,
                                'IFSC Code',
                                supplier.ifscCode!,
                              ),
                            ],
                            if (supplier.paymentTerms != null &&
                                supplier.paymentTerms!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.schedule_outlined,
                                'Payment Terms',
                                supplier.paymentTerms!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Bottom spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool showIcon = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIcon) ...[
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterSuppliers(),
        decoration: InputDecoration(
          hintText: 'Search by name, category, contact person or phone...',
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterSuppliers();
                  },
                  color: textSecondary,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: textSecondary, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 254, 254),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(
                  255,
                  169,
                  171,
                  179,
                ).withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),

              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with icon, name, category, status - EXACTLY like machinery
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.business,
                            color: const Color.fromARGB(255, 66, 89, 170),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier.name,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 17,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getCategoryName(supplier.categoryId),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 13,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status and Delete button - EXACTLY like machinery
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (Provider.of<CompanySiteProvider>(
                                  context,
                                ).hasPermission('supplier show') ||
                                Provider.of<CompanySiteProvider>(
                                  context,
                                ).hasPermission('supplier edit') ||
                                Provider.of<CompanySiteProvider>(
                                  context,
                                ).hasPermission('supplier delete'))
                              // More Options Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () =>
                                      _showSupplierOptionsBottomSheet(supplier),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.more_vert,
                                      color: textSecondary,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSupplier(supplier);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
                Icons.business_outlined,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isEmpty
                  ? 'No suppliers found'
                  : 'No suppliers match your search',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isEmpty
                  ? widget.selectedSiteId == null
                        ? 'Start by adding your first supplier'
                        : 'No suppliers found for this site'
                  : 'Try adjusting your search criteria',
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterSuppliers();
                  },
                  child: const Text(
                    'Clear Search',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading suppliers for ${_getCurrentSiteName()}...',
            style: const TextStyle(fontSize: 16, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 34, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error loading suppliers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? backgroundColor,
    required VoidCallback onTap,
    Color color = const Color(0xFF2D3748),
  }) {
    if (color == Colors.red &&
        !Provider.of<CompanySiteProvider>(
          context,
          listen: false,
        ).hasPermission('supplier delete')) {
      return const SizedBox.shrink();
    }
    if (title == 'Edit Supplier' &&
        !Provider.of<CompanySiteProvider>(
          context,
          listen: false,
        ).hasPermission('supplier edit')) {
      return const SizedBox.shrink();
    }
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showSupplierOptionsBottomSheet(Supplier supplier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (Provider.of<CompanySiteProvider>(
              context,
            ).hasPermission('supplier show'))
              _buildOptionTile(
                icon: Icons.visibility_outlined,
                title: 'View Full Details',
                iconColor: const Color.fromARGB(255, 37, 49, 158),
                backgroundColor: const Color.fromARGB(
                  255,
                  37,
                  49,
                  158,
                ).withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _showSupplierDetailsBottomSheet(supplier);
                },
              ),
            if (Provider.of<CompanySiteProvider>(
              context,
            ).hasPermission('supplier edit'))
              _buildOptionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Supplier',
                iconColor: Colors.blue,
                backgroundColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _showAddEditSupplierBottomSheet(supplier: supplier);
                },
              ),
            if (Provider.of<CompanySiteProvider>(
              context,
            ).hasPermission('supplier delete'))
              _buildOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Supplier',
                color: Colors.red,
                iconColor: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    _showDeleteConfirmationDialog(supplier);
                  });
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddEditSupplierBottomSheet({Supplier? supplier}) {
    final isEditing = supplier != null;

    final nameController = TextEditingController(text: supplier?.name ?? '');
    final contactPersonController = TextEditingController(
      text: supplier?.contactPerson ?? '',
    );
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final addressController = TextEditingController(
      text: supplier?.address ?? '',
    );
    final cityController = TextEditingController(text: supplier?.city ?? '');
    final stateController = TextEditingController(text: supplier?.state ?? '');
    final pincodeController = TextEditingController(
      text: supplier?.pincode ?? '',
    );
    final countryController = TextEditingController(
      text: supplier?.country ?? '',
    );
    final gstController = TextEditingController(
      text: supplier?.gstNumber ?? '',
    );
    final panController = TextEditingController(
      text: supplier?.panNumber ?? '',
    );
    final registrationController = TextEditingController(
      text: supplier?.registrationNumber ?? '',
    );
    final bankNameController = TextEditingController(
      text: supplier?.bankName ?? '',
    );
    final accountNumberController = TextEditingController(
      text: supplier?.accountNumber ?? '',
    );
    final ifscController = TextEditingController(
      text: supplier?.ifscCode ?? '',
    );
    final paymentTermsController = TextEditingController(
      text: supplier?.paymentTerms ?? '',
    );

    // Initialize selected values
    int? selectedCategoryId = supplier?.categoryId;
    String selectedType = supplier?.type ?? _types.first.name;
    String? selectedSiteId =
        widget.selectedSiteId ?? supplier?.siteId.toString();

    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEditing ? Icons.edit : Icons.add_business,
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
                                  isEditing
                                      ? 'Edit Supplier'
                                      : 'Add New Supplier',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Site: ${_getCurrentSiteName()}',
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
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Scrollbar(
                          controller: scrollController,
                          thumbVisibility: false,
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                //const SizedBox(height: 14),

                                // Form
                                Form(
                                  key: formKey,
                                  child: Column(
                                    children: [
                                      // // Site selection (only for new supplier or if not filtered by site)
                                      // if (!isEditing || selectedSiteId == null)
                                      //   _buildEnhancedDropdown<String>(
                                      //     value: selectedSiteId ?? '',
                                      //     label: 'Site *',
                                      //     hint: 'Select site',
                                      //     icon: Icons.location_on_outlined,
                                      //     items: [
                                      //       MapEntry('', 'All Sites'),
                                      //       ...widget.sites.map(
                                      //         (site) => MapEntry(site.id, site.name),
                                      //       ),
                                      //     ],
                                      //     displayText: (entry) => entry.value,
                                      //     getValue: (entry) => entry.key,
                                      //     onChanged: (value) {
                                      //       setModalState(() {
                                      //         selectedSiteId = value;
                                      //       });
                                      //     },
                                      //     validator: (value) {
                                      //       if (value == null || value.isEmpty) {
                                      //         return 'Please select a site';
                                      //       }
                                      //       return null;
                                      //     },
                                      //   ),
                                      if (!isEditing || selectedSiteId == null)
                                        const SizedBox(height: 16),

                                      // Supplier Name
                                      _buildEnhancedTextField(
                                        controller: nameController,
                                        label: 'Supplier Name *',
                                        hint: 'e.g. Johnson Supplies',
                                        icon: Icons.business_outlined,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter supplier name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 10),

                                      // Category and Type Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildEnhancedDropdown<int>(
                                              value: selectedCategoryId,
                                              label: 'Category *',
                                              hint: 'Select category',
                                              icon: Icons.category_outlined,
                                              items: _categories,
                                              displayText: (category) =>
                                                  category.name,
                                              getValue: (category) =>
                                                  category.id,
                                              onChanged: (value) {
                                                setModalState(() {
                                                  selectedCategoryId = value;
                                                });
                                              },
                                              validator: (value) {
                                                if (value == null) {
                                                  return 'Please select a category';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEnhancedDropdown<String>(
                                              value: selectedType,
                                              label: 'Type *',
                                              hint: 'Select type',
                                              icon: Icons
                                                  .business_center_outlined,
                                              items: _types,
                                              displayText: (type) =>
                                                  type.name[0].toUpperCase() +
                                                  type.name.substring(1),
                                              getValue: (type) => type.name,
                                              onChanged: (value) {
                                                setModalState(() {
                                                  selectedType = value!;
                                                });
                                              },
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please select a type';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Contact Person and Phone Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildEnhancedTextField(
                                              controller:
                                                  contactPersonController,
                                              label: 'Contacts *',
                                              hint: 'e.g. John Doe',
                                              icon: Icons.person_outline,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Please enter contact person';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEnhancedTextField(
                                              controller: phoneController,
                                              label: 'Phone *',
                                              hint: 'e.g. 9876543210',
                                              icon: Icons.phone_outlined,
                                              keyboardType: TextInputType.phone,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Please enter phone number';
                                                }
                                                if (value.length < 10) {
                                                  return 'Please enter a valid phone number';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Email
                                      _buildEnhancedTextField(
                                        controller: emailController,
                                        label: 'Email',
                                        hint: 'e.g. contact@company.com',
                                        icon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value != null &&
                                              value.isNotEmpty) {
                                            final emailRegex = RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                            );
                                            if (!emailRegex.hasMatch(value)) {
                                              return 'Please enter a valid email address';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 10),

                                      // Address
                                      _buildEnhancedTextField(
                                        controller: addressController,
                                        label: 'Address',
                                        hint: 'e.g. 123 Main Street',
                                        icon: Icons.location_on_outlined,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 10),

                                      // City and State Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildEnhancedTextField(
                                              controller: cityController,
                                              label: 'City',
                                              hint: 'e.g. Mumbai',
                                              icon:
                                                  Icons.location_city_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEnhancedTextField(
                                              controller: stateController,
                                              label: 'State',
                                              hint: 'e.g. Maharashtra',
                                              icon: Icons.map_outlined,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Pincode and Country Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildEnhancedTextField(
                                              controller: pincodeController,
                                              label: 'Pincode',
                                              hint: 'e.g. 400001',
                                              icon: Icons.pin_drop_outlined,
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEnhancedTextField(
                                              controller: countryController,
                                              label: 'Country',
                                              hint: 'e.g. India',
                                              icon: Icons.public_outlined,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // GST and PAN Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildEnhancedTextField(
                                              controller: gstController,
                                              label: 'GST Number',
                                              hint: 'e.g. 27ABCDE1234F1Z5',
                                              icon: Icons.receipt_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEnhancedTextField(
                                              controller: panController,
                                              label: 'PAN Number',
                                              hint: 'e.g. ABCDE1234F',
                                              icon: Icons.credit_card_outlined,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Registration Number
                                      _buildEnhancedTextField(
                                        controller: registrationController,
                                        label: 'Registration Number',
                                        hint: 'e.g. U74999MH2014PTC123456',
                                        icon: Icons.assignment_outlined,
                                      ),
                                      const SizedBox(height: 24),

                                      // Bank Details Section
                                      const Text(
                                        'Bank Details',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Bank Name and Account Number Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildEnhancedTextField(
                                              controller: bankNameController,
                                              label: 'Bank Name',
                                              hint: 'e.g. State Bank of India',
                                              icon: Icons
                                                  .account_balance_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildEnhancedTextField(
                                              controller:
                                                  accountNumberController,
                                              label: 'Account Number',
                                              hint: 'e.g. 1234567890',
                                              icon: Icons.account_box_outlined,
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // IFSC Code
                                      _buildEnhancedTextField(
                                        controller: ifscController,
                                        label: 'IFSC Code',
                                        hint: 'e.g. SBIN0001234',
                                        icon: Icons.code_outlined,
                                      ),
                                      const SizedBox(height: 10),

                                      // Payment Terms
                                      _buildEnhancedTextField(
                                        controller: paymentTermsController,
                                        label: 'Payment Terms',
                                        hint: 'e.g. Net 30 days',
                                        icon: Icons.schedule_outlined,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),

                                // Action Buttons
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
                                    icon: isSubmitting
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            isEditing
                                                ? Icons.update
                                                : Icons.add,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                    label: Text(
                                      isSubmitting
                                          ? 'Processing...'
                                          : (isEditing
                                                ? 'Update Supplier'
                                                : 'Add Supplier'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: isSubmitting
                                        ? null
                                        : () async {
                                            if (formKey.currentState!
                                                    .validate() &&
                                                selectedCategoryId != null &&
                                                selectedSiteId != null) {
                                              setModalState(() {
                                                isSubmitting = true;
                                              });

                                              try {
                                                final supplierData = Supplier(
                                                  id: supplier?.id,
                                                  name: nameController.text
                                                      .trim(),
                                                  categoryId:
                                                      selectedCategoryId!,
                                                  type: selectedType,
                                                  contactPerson:
                                                      contactPersonController
                                                          .text
                                                          .trim(),
                                                  phone: phoneController.text
                                                      .trim(),
                                                  email:
                                                      emailController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : emailController.text
                                                            .trim(),
                                                  address:
                                                      addressController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : addressController.text
                                                            .trim(),
                                                  city:
                                                      cityController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : cityController.text
                                                            .trim(),
                                                  state:
                                                      stateController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : stateController.text
                                                            .trim(),
                                                  pincode:
                                                      pincodeController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : pincodeController.text
                                                            .trim(),
                                                  country:
                                                      countryController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : countryController.text
                                                            .trim(),
                                                  gstNumber:
                                                      gstController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : gstController.text
                                                            .trim(),
                                                  panNumber:
                                                      panController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : panController.text
                                                            .trim(),
                                                  registrationNumber:
                                                      registrationController
                                                          .text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : registrationController
                                                            .text
                                                            .trim(),
                                                  bankName:
                                                      bankNameController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : bankNameController.text
                                                            .trim(),
                                                  accountNumber:
                                                      accountNumberController
                                                          .text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : accountNumberController
                                                            .text
                                                            .trim(),
                                                  ifscCode:
                                                      ifscController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : ifscController.text
                                                            .trim(),
                                                  paymentTerms:
                                                      paymentTermsController
                                                          .text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : paymentTermsController
                                                            .text
                                                            .trim(),
                                                  siteId:
                                                      int.tryParse(
                                                        selectedSiteId!,
                                                      ) ??
                                                      2,
                                                  workspaceId:
                                                      supplier?.workspaceId ??
                                                      (widget.workspaceId ??
                                                          (int.tryParse(
                                                                Provider.of<
                                                                          CompanySiteProvider
                                                                        >(
                                                                          context,
                                                                          listen:
                                                                              false,
                                                                        )
                                                                        .selectedCompanyId ??
                                                                    '0',
                                                              ) ??
                                                              0)),
                                                  createdBy:
                                                      supplier?.createdBy ??
                                                      (widget.userId ??
                                                          (Provider.of<
                                                                    CompanySiteProvider
                                                                  >(
                                                                    context,
                                                                    listen:
                                                                        false,
                                                                  )
                                                                  .currentUserId ??
                                                              1)),
                                                  isActive:
                                                      supplier?.isActive ?? 1,
                                                  status:
                                                      supplier?.status ?? '0',
                                                  createdAt:
                                                      supplier?.createdAt,
                                                  updatedAt: DateTime.now()
                                                      .toIso8601String(),
                                                );

                                                if (isEditing) {
                                                  await SupplierApiService.updateSupplier(
                                                    supplierData,
                                                  );
                                                } else {
                                                  await SupplierApiService.addSupplier(
                                                    supplierData,
                                                  );
                                                }

                                                await _loadData();
                                                Navigator.pop(context);
                                                _showSnackBar(
                                                  isEditing
                                                      ? 'Supplier updated successfully'
                                                      : 'Supplier added successfully',
                                                  isSuccess: true,
                                                );
                                              } catch (e) {
                                                _showSnackBar(
                                                  'Failed to ${isEditing ? 'update' : 'add'} supplier: $e',
                                                );
                                              } finally {
                                                setModalState(() {
                                                  isSubmitting = false;
                                                });
                                              }
                                            }
                                          },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCategoriesBottomSheet() {
    final categoriesMap = <String, List<Supplier>>{};

    // Group suppliers by category
    for (final supplier in _filteredSuppliers) {
      final categoryName = _getCategoryName(supplier.categoryId);
      categoriesMap.putIfAbsent(categoryName, () => []).add(supplier);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Supplier Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categoriesMap.length,
                itemBuilder: (context, index) {
                  final categoryName = categoriesMap.keys.elementAt(index);
                  final suppliers = categoriesMap[categoryName]!;

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
                      return ListTile(
                        leading: const SizedBox(width: 24),
                        title: Text(supplier.name),
                        subtitle: Text(supplier.contactPerson),
                        onTap: () {
                          Navigator.pop(context);
                          _showSupplierDetailsBottomSheet(supplier);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAppBarOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.category, color: primaryColor),
                title: const Text('Supplier Categories'),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupplierCategoriesScreen(
                        userId: widget.userId,
                        workspaceId: widget.workspaceId,
                        siteId: int.tryParse(widget.selectedSiteId ?? ''),
                      ),
                    ),
                  );
                  // Refresh data when returning from categories screen
                  _loadData();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showImportExportBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Import Suppliers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text('Download Excel Template'),
                onTap: () {
                  Navigator.pop(context);
                  _generateExcelTemplate();
                },
              ),
             
              ListTile(
                leading: const Icon(Icons.upload_file, color: primaryColor),
                title: const Text('Import Excel File'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndParseExcel();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.orange),
                title: const Text('Import PDF File'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndParsePdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateExcelTemplate() async {
    _showSnackBar('Generating Excel template...', isSuccess: true);
    try {
      var excel = excel_pkg.Excel.createExcel();
      var sheet = excel['Sheet1'];

      final headers = [
        'Supplier Name*',
        'Category*',
        'Type*',
        'Contact Person*',
        'Phone*',
        'Email',
        'Address',
        'City',
        'State',
        'Pincode',
        'Country',
        'GST Number',
        'PAN Number',
        'Registration Number',
        'Bank Name',
        'Account Number',
        'IFSC Code',
        'Payment Terms'
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = excel_pkg.TextCellValue(headers[i]);
      }

      // Add sample data
      sheet
          .cell(
            excel_pkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
          )
          .value = excel_pkg.TextCellValue('Example Supplier');
      sheet
          .cell(
            excel_pkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1),
          )
          .value = excel_pkg.TextCellValue(
        _categories.isNotEmpty ? _categories.first.name : 'General',
      );
      sheet
          .cell(
            excel_pkg.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1),
          )
          .value = excel_pkg.TextCellValue('company');
      sheet
          .cell(
            excel_pkg.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1),
          )
          .value = excel_pkg.TextCellValue('John Doe');
      sheet
          .cell(
            excel_pkg.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1),
          )
          .value = excel_pkg.TextCellValue('9876543210');

      var fileBytes = excel.save();
      if (fileBytes == null) throw 'Failed to generate Excel bytes';

      // 1. Always save to a temporary location for immediate opening (no permission required)
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/supplier_template.xlsx';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(fileBytes, flush: true);

      // 2. Offer to save to a permanent location (Downloads folder)
      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Supplier Template',
          fileName: 'supplier_template.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: Uint8List.fromList(fileBytes),
        );
      } catch (e) {
        debugPrint('FilePicker saveFile error: $e');
      }

      if (savedPath != null) {
        _showSnackBar('Template saved to: $savedPath', isSuccess: true);
      }

      // 3. Always open from the temporary location to avoid permission issues in public folders
      final result = await OpenFile.open(tempPath);
      if (result.type != ResultType.done) {
        _showSnackBar('Could not open Excel: ${result.message}');
      }
    } catch (e) {
      _showSnackBar('Error generating Excel template: $e');
    }
  }

  

  int _getCategoryIdByName(String name) {
    try {
      return _categories.firstWhere((cat) => cat.name.toLowerCase() == name.toLowerCase()).id;
    } catch (e) {
      return _categories.isNotEmpty ? _categories.first.id : 1;
    }
  }

  Future<void> _pickAndParseExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        var bytes = File(result.files.single.path!).readAsBytesSync();
        var excel = excel_pkg.Excel.decodeBytes(bytes);
        List<Supplier> importedSuppliers = [];

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]!.rows;
          // Skip header row
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.isEmpty || row[0] == null) continue;

            final supplier = Supplier(
              name: row[0]?.value.toString() ?? '',
              categoryId: _getCategoryIdByName(row[1]?.value.toString() ?? ''),
              type: row[2]?.value.toString().toLowerCase() ?? 'company',
              contactPerson: row[3]?.value.toString() ?? '',
              phone: row[4]?.value.toString() ?? '',
              email: row[5]?.value.toString(),
              address: row[6]?.value.toString(),
              city: row[7]?.value.toString(),
              state: row[8]?.value.toString(),
              pincode: row[9]?.value.toString(),
              country: row[10]?.value.toString(),
              gstNumber: row[11]?.value.toString(),
              panNumber: row[12]?.value.toString(),
              registrationNumber: row[13]?.value.toString(),
              bankName: row[14]?.value.toString(),
              accountNumber: row[15]?.value.toString(),
              ifscCode: row[16]?.value.toString(),
              paymentTerms: row[17]?.value.toString(),
              siteId: int.tryParse(widget.selectedSiteId ?? '0') ??
                  (widget.sites.isNotEmpty ? int.tryParse(widget.sites.first.id) ?? 2 : 2),
              workspaceId: widget.workspaceId ??
                  (int.tryParse(
                        Provider.of<CompanySiteProvider>(
                          context,
                          listen: false,
                        ).selectedCompanyId ??
                        '0',
                      ) ??
                      0),
              createdBy: widget.userId ??
                  (Provider.of<CompanySiteProvider>(
                        context,
                        listen: false,
                      ).currentUserId ??
                      1),
              isActive: 1,
              status: '0',
            );
            importedSuppliers.add(supplier);
          }
        }

        setState(() => _isLoading = false);
        if (importedSuppliers.isNotEmpty) {
          _showImportPreviewSheet(importedSuppliers);
        } else {
          _showSnackBar('No valid data found in the file');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar('Error parsing Excel: $e');
      }
    }
  }

  Future<void> _pickAndParsePdf() async {
    // Note: Accurate PDF table parsing is complex in Flutter without specialized libraries.
    // This is a simplified version assuming a specific format or structured text.
    _showSnackBar('PDF Import is currently in Beta. Please use Excel for best results.');
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      _showSnackBar('Parsing PDF... (Heuristic approach)');
      // For now, we'll suggest using Excel as PDF extraction is highly unreliable for tabular data
      // without a very strict layout or a dedicated extraction library.
    }
  }

  void _showImportPreviewSheet(List<Supplier> suppliers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Preview Import',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('${suppliers.length} Records', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) {
                      final s = suppliers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_getCategoryName(s.categoryId)} | ${s.type}'),
                              Text('Contact: ${s.contactPerson} (${s.phone})'),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _processBulkImport(suppliers);
                      },
                      child: const Text('Confirm Import', style: TextStyle(color: Colors.white, fontSize: 16)),
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

  Future<void> _processBulkImport(List<Supplier> suppliers) async {
    setState(() => _isLoading = true);
    int successCount = 0;
    int failCount = 0;

    for (var s in suppliers) {
      try {
        await SupplierApiService.addSupplier(s);
        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('Failed to import ${s.name}: $e');
      }
    }

    setState(() => _isLoading = false);
    _loadData();
    _showSnackBar(
      'Import complete: $successCount success, $failCount failed',
      isSuccess: failCount == 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 248, 248, 250),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 74.h,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suppliers Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3),
            Text(
              "Site: ${_getCurrentSiteName()}",

              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ...buildNotificationActions(
            context: context,
            selectedSiteId: widget.selectedSiteId,
            sites: widget.sites,
            currentCompany: widget.currentCompany ?? '',
            workspaceId: widget.workspaceId,
          ),

          if (Provider.of<CompanySiteProvider>(
            context,
            listen: false,
          ).hasPermission('supplier-categories manage'))
            GestureDetector(
              onTap: () {
                _showAppBarOptionsBottomSheet();
              },
              child: const Icon(Icons.more_vert),
            ),
          const SizedBox(width: 10),
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
      floatingActionButton:
          Provider.of<CompanySiteProvider>(
            context,
          ).hasPermission('supplier create')
          ? FloatingActionButton(
              onPressed: _showAddEditSupplierBottomSheet,
              child: const Icon(Icons.add, color: Colors.white),
              backgroundColor: const Color.fromRGBO(
                42,
                67,
                160,
                1,
              ), // Any color you want
              tooltip: 'Add New Supplier',
            )
          : null,
      body: Column(
        children: [
          _buildSearchBar(),
          Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: Colors.black12.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            size: 24,
                            color: Color.fromARGB(255, 29, 29, 29),
                          ),
                          tooltip: 'Generate Supplier Report',
                          onPressed: _showReportSheet,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: Colors.black12.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.download_for_offline_outlined,
                            size: 24,
                            color: Color.fromARGB(255, 29, 29, 29),
                          ),
                          tooltip: 'Download Excel Sample',
                          onPressed: _generateExcelTemplate,
                        ),
                      ),
                      const SizedBox(width: 8),
                                       
                      Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: Colors.black12.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.upload_file_outlined,
                            size: 24,
                            color: Color.fromARGB(255, 29, 29, 29),
                          ),
                          tooltip: 'Import Excel File',
                          onPressed: _pickAndParseExcel,
                        ),
                      ),
                    ],
                  ),
          // Total Entries and Clear Search
          if (_searchController.text.isNotEmpty ||
              _filteredSuppliers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${_filteredSuppliers.length} supplier${_filteredSuppliers.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // IconButton(
                  //   icon: const Icon(Icons.category),
                  //   onPressed: _showCategoriesBottomSheet,
                  //   tooltip: 'Filter by Categories',
                  // ),
                  
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : _filteredSuppliers.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _filteredSuppliers.length,
                      itemBuilder: (context, index) {
                        return _buildSupplierCard(_filteredSuppliers[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Filter suppliers for summary
          final filteredForSummary = _filteredSuppliers.where((s) {
            final createdAt =
                DateTime.tryParse(s.createdAt ?? '') ?? DateTime(0);
            final isWithinDate =
                createdAt.isAfter(
                  _reportStartDate.subtract(const Duration(seconds: 1)),
                ) &&
                createdAt.isBefore(_reportEndDate.add(const Duration(days: 1)));
            final isCorrectCategory =
                _reportSelectedCategoryId == null ||
                s.categoryId == _reportSelectedCategoryId;
            return isWithinDate && isCorrectCategory;
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Generate Supplier Report',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Range Selection
                        const Text(
                          'Date Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateTile(
                                label: 'Start Date',
                                date: _reportStartDate,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _reportStartDate,
                                    firstDate: DateTime(2020),
                                    lastDate: _reportEndDate,
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      _reportStartDate = picked;
                                    });
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateTile(
                                label: 'End Date',
                                date: _reportEndDate,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _reportEndDate,
                                    firstDate: _reportStartDate,
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      _reportEndDate = picked;
                                    });
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Category Selection
                        _buildEnhancedDropdown<int?>(
                          value: _reportSelectedCategoryId,
                          label: 'Category (Optional)',
                          hint: 'All Categories',
                          icon: Icons.category_outlined,
                          items: [null, ..._categories.map((c) => c.id)],
                          displayText: (id) => id == null
                              ? 'All Categories'
                              : _getCategoryName(id),
                          getValue: (id) => id,
                          onChanged: (value) {
                            setModalState(() {
                              _reportSelectedCategoryId = value;
                            });
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 24),
                        // Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Report Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Suppliers in Period',
                                '${filteredForSummary.length}',
                              ),
                              _buildSummaryRow(
                                'Date Range',
                                '${DateFormat('dd MMM').format(_reportStartDate)} - ${DateFormat('dd MMM').format(_reportEndDate)}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Action Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
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
                      onPressed: () {
                        Navigator.pop(context);
                        _viewPDF(filteredForSummary);
                      },
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'View PDF Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  Widget _buildDateTile({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewPDF(List<Supplier> suppliers) async {
    try {
      final pdfBytes = await _generatePdfBytes(suppliers);
      final output = await getTemporaryDirectory();
      final file = File(
        "${output.path}/supplier_report_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      await file.writeAsBytes(pdfBytes);
      await OpenFile.open(file.path);
    } catch (e) {
      _showSnackBar('Error generating PDF: $e');
    }
  }

  Future<Uint8List> _generatePdfBytes(List<Supplier> suppliers) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Supplier Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Site: ${_getCurrentSiteName()}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Period: ${DateFormat('dd MMM yyyy').format(_reportStartDate)} - ${DateFormat('dd MMM yyyy').format(_reportEndDate)}',
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              data: <List<String>>[
                <String>[
                  'Supplier Name',
                  'Contact',
                  'Phone',
                  'Category',
                  'Type',
                ],
                ...suppliers.map(
                  (s) => [
                    s.name,
                    s.contactPerson,
                    s.phone,
                    _getCategoryName(s.categoryId),
                    s.type,
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
