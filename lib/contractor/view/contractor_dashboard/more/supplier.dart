

import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/admin/services/Allsupplier_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// Add this import if you have a site model
import 'package:ecoteam_app/contractor/models/site_model.dart';

class SupplierLedger extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const SupplierLedger({
    Key? key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
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
  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color cardColor = Color(0xFFF8F9FF);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterSuppliers);
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
      final suppliers = await SupplierApiService.getSuppliers();
      final categories = await SupplierApiService.getSupplierCategories();

      // Filter suppliers by selected site if applicable
      List<Supplier> filteredSuppliers = suppliers;
      if (widget.selectedSiteId != null) {
        filteredSuppliers = suppliers.where((supplier) {
          // Assuming Supplier model has a siteId field
          // If not, you might need to update your Supplier model
          return supplier.siteId.toString() == widget.selectedSiteId;
        }).toList();
      }

      setState(() {
        _allSuppliers = suppliers;
        _filteredSuppliers = filteredSuppliers;
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
      child: TextFormField(
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 2),
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
          errorStyle: const TextStyle(fontSize: 12),
        ),
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
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 2),
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
          errorStyle: const TextStyle(fontSize: 12),
        ),
        dropdownColor: Colors.white,
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
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
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
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.business,
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
                                  supplier.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${_getCategoryName(supplier.categoryId)} • ${supplier.siteId == 0 ? 'All Sites' : 'Site: ${supplier.siteId}'}',
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
                      const SizedBox(height: 24),

                      // Basic Information Section
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Contact Info Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailCard(
                              Icons.person_outline,
                              'Contact Person',
                              supplier.contactPerson,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailCard(
                              Icons.phone_outlined,
                              'Phone',
                              supplier.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (supplier.email != null && supplier.email!.isNotEmpty)
                        Column(
                          children: [
                            _buildDetailCard(
                              Icons.email_outlined,
                              'Email',
                              supplier.email!,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),

                      // Address Section
                      if (supplier.address != null &&
                          supplier.address!.isNotEmpty)
                        const Text(
                          'Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      if (supplier.address != null &&
                          supplier.address!.isNotEmpty)
                        const SizedBox(height: 8),

                      if (supplier.address != null &&
                          supplier.address!.isNotEmpty)
                        _buildDetailCard(
                          Icons.location_on_outlined,
                          'Address',
                          supplier.address!,
                        ),
                      if (supplier.address != null &&
                          supplier.address!.isNotEmpty)
                        const SizedBox(height: 12),

                      // Location Row
                      if ((supplier.city != null &&
                              supplier.city!.isNotEmpty) ||
                          (supplier.state != null &&
                              supplier.state!.isNotEmpty))
                        Row(
                          children: [
                            if (supplier.city != null &&
                                supplier.city!.isNotEmpty)
                              Expanded(
                                child: _buildDetailCard(
                                  Icons.location_city_outlined,
                                  'City',
                                  supplier.city!,
                                ),
                              ),
                            if (supplier.state != null &&
                                supplier.state!.isNotEmpty)
                              const SizedBox(width: 12),
                            if (supplier.state != null &&
                                supplier.state!.isNotEmpty)
                              Expanded(
                                child: _buildDetailCard(
                                  Icons.map_outlined,
                                  'State',
                                  supplier.state!,
                                ),
                              ),
                          ],
                        ),
                      if ((supplier.city != null &&
                              supplier.city!.isNotEmpty) ||
                          (supplier.state != null &&
                              supplier.state!.isNotEmpty))
                        const SizedBox(height: 12),

                      // Pincode & Country Row
                      if ((supplier.pincode != null &&
                              supplier.pincode!.isNotEmpty) ||
                          (supplier.country != null &&
                              supplier.country!.isNotEmpty))
                        Row(
                          children: [
                            if (supplier.pincode != null &&
                                supplier.pincode!.isNotEmpty)
                              Expanded(
                                child: _buildDetailCard(
                                  Icons.pin_drop_outlined,
                                  'Pincode',
                                  supplier.pincode!,
                                ),
                              ),
                            if (supplier.country != null &&
                                supplier.country!.isNotEmpty)
                              const SizedBox(width: 12),
                            if (supplier.country != null &&
                                supplier.country!.isNotEmpty)
                              Expanded(
                                child: _buildDetailCard(
                                  Icons.public_outlined,
                                  'Country',
                                  supplier.country!,
                                ),
                              ),
                          ],
                        ),
                      if ((supplier.pincode != null &&
                              supplier.pincode!.isNotEmpty) ||
                          (supplier.country != null &&
                              supplier.country!.isNotEmpty))
                        const SizedBox(height: 12),

                      // Tax Information Section
                      if ((supplier.gstNumber != null &&
                              supplier.gstNumber!.isNotEmpty) ||
                          (supplier.panNumber != null &&
                              supplier.panNumber!.isNotEmpty))
                        const Text(
                          'Tax Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      if ((supplier.gstNumber != null &&
                              supplier.gstNumber!.isNotEmpty) ||
                          (supplier.panNumber != null &&
                              supplier.panNumber!.isNotEmpty))
                        const SizedBox(height: 8),

                      if ((supplier.gstNumber != null &&
                              supplier.gstNumber!.isNotEmpty) ||
                          (supplier.panNumber != null &&
                              supplier.panNumber!.isNotEmpty))
                        Row(
                          children: [
                            if (supplier.gstNumber != null &&
                                supplier.gstNumber!.isNotEmpty)
                              Expanded(
                                child: _buildDetailCard(
                                  Icons.receipt_outlined,
                                  'GST Number',
                                  supplier.gstNumber!,
                                ),
                              ),
                            if (supplier.panNumber != null &&
                                supplier.panNumber!.isNotEmpty)
                              const SizedBox(width: 12),
                            if (supplier.panNumber != null &&
                                supplier.panNumber!.isNotEmpty)
                              Expanded(
                                child: _buildDetailCard(
                                  Icons.credit_card_outlined,
                                  'PAN Number',
                                  supplier.panNumber!,
                                ),
                              ),
                          ],
                        ),
                      if ((supplier.gstNumber != null &&
                              supplier.gstNumber!.isNotEmpty) ||
                          (supplier.panNumber != null &&
                              supplier.panNumber!.isNotEmpty))
                        const SizedBox(height: 12),

                      // Registration Number
                      if (supplier.registrationNumber != null &&
                          supplier.registrationNumber!.isNotEmpty)
                        _buildDetailCard(
                          Icons.assignment_outlined,
                          'Registration Number',
                          supplier.registrationNumber!,
                        ),
                      if (supplier.registrationNumber != null &&
                          supplier.registrationNumber!.isNotEmpty)
                        const SizedBox(height: 12),

                      // Bank Details Section
                      if ((supplier.bankName != null &&
                              supplier.bankName!.isNotEmpty) ||
                          (supplier.accountNumber != null &&
                              supplier.accountNumber!.isNotEmpty) ||
                          (supplier.ifscCode != null &&
                              supplier.ifscCode!.isNotEmpty))
                        const Text(
                          'Bank Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      if ((supplier.bankName != null &&
                              supplier.bankName!.isNotEmpty) ||
                          (supplier.accountNumber != null &&
                              supplier.accountNumber!.isNotEmpty) ||
                          (supplier.ifscCode != null &&
                              supplier.ifscCode!.isNotEmpty))
                        const SizedBox(height: 8),

                      if ((supplier.bankName != null &&
                              supplier.bankName!.isNotEmpty) ||
                          (supplier.accountNumber != null &&
                              supplier.accountNumber!.isNotEmpty))
                        Row(
                          children: [
                            if (supplier.bankName != null &&
                                supplier.bankName!.isNotEmpty)
                              Expanded(
                                child: _buildDetailCard(
                                  Icons.account_balance_outlined,
                                  'Bank Name',
                                  supplier.bankName!,
                                ),
                              ),
                            if (supplier.accountNumber != null &&
                                supplier.accountNumber!.isNotEmpty)
                              const SizedBox(width: 12),
                            if (supplier.accountNumber != null &&
                                supplier.accountNumber!.isNotEmpty)
                              Expanded(
                                child: _buildDetailCard(
                                  Icons.account_box_outlined,
                                  'Account Number',
                                  supplier.accountNumber!,
                                ),
                              ),
                          ],
                        ),
                      if ((supplier.bankName != null &&
                              supplier.bankName!.isNotEmpty) ||
                          (supplier.accountNumber != null &&
                              supplier.accountNumber!.isNotEmpty))
                        const SizedBox(height: 12),

                      // IFSC Code
                      if (supplier.ifscCode != null &&
                          supplier.ifscCode!.isNotEmpty)
                        _buildDetailCard(
                          Icons.code_outlined,
                          'IFSC Code',
                          supplier.ifscCode!,
                        ),
                      if (supplier.ifscCode != null &&
                          supplier.ifscCode!.isNotEmpty)
                        const SizedBox(height: 12),

                      // Payment Terms
                      if (supplier.paymentTerms != null &&
                          supplier.paymentTerms!.isNotEmpty)
                        _buildDetailCard(
                          Icons.schedule_outlined,
                          'Payment Terms',
                          supplier.paymentTerms!,
                        ),
                      if (supplier.paymentTerms != null &&
                          supplier.paymentTerms!.isNotEmpty)
                        const SizedBox(height: 12),

                      // Status
                      _buildDetailCard(
                        Icons.info_outline,
                        'Status',
                        supplier.status == '1' ? 'Active' : 'Inactive',
                        valueColor: supplier.status == '1'
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: primaryColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
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
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showAddEditSupplierBottomSheet(
                                    supplier: supplier,
                                  );
                                },
                                child: const Text(
                                  'Edit Supplier',
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
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
            onTap: () => _showSupplierDetailsBottomSheet(supplier),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with icon, name, category, status - EXACTLY like machinery
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.business,
                          color: primaryColor,
                          size: 22,
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
                                fontSize: isSmallScreen ? 16 : 18,
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
                                fontSize: isSmallScreen ? 12 : 14,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: supplier.status == '1'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: supplier.status == '1'
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              supplier.status == '1' ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: supplier.status == '1'
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: isSmallScreen ? 9 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete button - EXACTLY like machinery
                          GestureDetector(
                            onTap: () {
                              _showDeleteConfirmationDialog(supplier);
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

                  // Information rows - EXACT 2-column layout like machinery
                  // First row: Contact Person and Phone side by side
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primaryColor.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: isSmallScreen ? 14 : 16,
                                color: const Color.fromARGB(255, 109, 109, 109),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contact Person',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 9 : 10,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      supplier.contactPerson,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
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
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primaryColor.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: isSmallScreen ? 14 : 16,
                                color: const Color.fromARGB(255, 109, 109, 109),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Phone',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 9 : 10,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      supplier.phone,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
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
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Second row: Address and GST Number side by side
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primaryColor.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: isSmallScreen ? 14 : 16,
                                color: const Color.fromARGB(255, 109, 109, 109),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Address',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 9 : 10,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      supplier.address ?? 'Not specified',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
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
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primaryColor.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt,
                                size: isSmallScreen ? 14 : 16,
                                color: const Color.fromARGB(255, 109, 109, 109),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GST Number',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 9 : 10,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      supplier.gstNumber ?? 'Not specified',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error loading suppliers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _loadData,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
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
                          const SizedBox(height: 16),

                          Row(
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
                          const SizedBox(height: 24),

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
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter supplier name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

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
                                        getValue: (category) => category.id,
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
                                        icon: Icons.business_center_outlined,
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
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a type';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Contact Person and Phone Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        controller: contactPersonController,
                                        label: 'Contact Person *',
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
                                        label: 'Phone Number *',
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
                                const SizedBox(height: 16),

                                // Email
                                _buildEnhancedTextField(
                                  controller: emailController,
                                  label: 'Email',
                                  hint: 'e.g. contact@company.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
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
                                const SizedBox(height: 16),

                                // Address
                                _buildEnhancedTextField(
                                  controller: addressController,
                                  label: 'Address',
                                  hint: 'e.g. 123 Main Street',
                                  icon: Icons.location_on_outlined,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),

                                // City and State Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        controller: cityController,
                                        label: 'City',
                                        hint: 'e.g. Mumbai',
                                        icon: Icons.location_city_outlined,
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
                                const SizedBox(height: 16),

                                // Pincode and Country Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        controller: pincodeController,
                                        label: 'Pincode',
                                        hint: 'e.g. 400001',
                                        icon: Icons.pin_drop_outlined,
                                        keyboardType: TextInputType.number,
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
                                const SizedBox(height: 16),

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
                                const SizedBox(height: 16),

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
                                const SizedBox(height: 12),

                                // Bank Name and Account Number Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        controller: bankNameController,
                                        label: 'Bank Name',
                                        hint: 'e.g. State Bank of India',
                                        icon: Icons.account_balance_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        controller: accountNumberController,
                                        label: 'Account Number',
                                        hint: 'e.g. 1234567890',
                                        icon: Icons.account_box_outlined,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // IFSC Code
                                _buildEnhancedTextField(
                                  controller: ifscController,
                                  label: 'IFSC Code',
                                  hint: 'e.g. SBIN0001234',
                                  icon: Icons.code_outlined,
                                ),
                                const SizedBox(height: 16),

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
                                      isEditing ? Icons.update : Icons.add,
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
                                      if (formKey.currentState!.validate() &&
                                          selectedCategoryId != null &&
                                          selectedSiteId != null) {
                                        setModalState(() {
                                          isSubmitting = true;
                                        });

                                        try {
                                          final supplierData = Supplier(
                                            id: supplier?.id,
                                            name: nameController.text.trim(),
                                            categoryId: selectedCategoryId!,
                                            type: selectedType,
                                            contactPerson:
                                                contactPersonController.text
                                                    .trim(),
                                            phone: phoneController.text.trim(),
                                            email:
                                                emailController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : emailController.text.trim(),
                                            address:
                                                addressController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : addressController.text.trim(),
                                            city:
                                                cityController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : cityController.text.trim(),
                                            state:
                                                stateController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : stateController.text.trim(),
                                            pincode:
                                                pincodeController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : pincodeController.text.trim(),
                                            country:
                                                countryController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : countryController.text.trim(),
                                            gstNumber:
                                                gstController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : gstController.text.trim(),
                                            panNumber:
                                                panController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : panController.text.trim(),
                                            registrationNumber:
                                                registrationController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : registrationController.text
                                                      .trim(),
                                            bankName:
                                                bankNameController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : bankNameController.text
                                                      .trim(),
                                            accountNumber:
                                                accountNumberController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : accountNumberController.text
                                                      .trim(),
                                            ifscCode:
                                                ifscController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : ifscController.text.trim(),
                                            paymentTerms:
                                                paymentTermsController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : paymentTermsController.text
                                                      .trim(),
                                            siteId:
                                                int.tryParse(selectedSiteId!) ??
                                                2,
                                            workspaceId:
                                                supplier?.workspaceId ?? 0,
                                            createdBy: supplier?.createdBy ?? 1,
                                            isActive: supplier?.isActive ?? 1,
                                            status: supplier?.status ?? '0',
                                            createdAt: supplier?.createdAt,
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
                      child: Icon(Icons.category, color: primaryColor, size: 20),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80.h,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suppliers Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3),
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
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _showAddEditSupplierBottomSheet,
            icon: Icon(Icons.add),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _showCategoriesBottomSheet,
            tooltip: 'Categories',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
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
      body: Column(
        children: [
          _buildSearchBar(),
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
                  if (_searchController.text.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterSuppliers();
                      },
                      child: const Text(
                        'Clear Search',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
