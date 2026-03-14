import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/models/stock_model.dart';
import 'package:ecoteam_app/admin/services/stock_service.dart';
import 'package:ecoteam_app/contractor/services/report_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/services/api_ser.dart';
import 'package:intl/intl.dart';

class StockTab extends StatefulWidget {
  final String? selectedSiteId;
  final String? selectedSiteName;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const StockTab({
    super.key,
    required this.selectedSiteId,
    required this.selectedSiteName,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab> {
  List<StockReportItem> _stockItems = [];
  List<StockReportItem> _filteredStockItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Modern color scheme matching MaterialScreen
  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color backgroundColor = Color(0xFFf8f9fa);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  @override
  void didUpdateWidget(StockTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSiteId != widget.selectedSiteId) {
      _loadStockData();
    }
  }

  Future<void> _loadStockData() async {
    if (widget.selectedSiteId == null) {
      if (mounted) {
        setState(() {
          _stockItems = [];
          _filteredStockItems = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final siteId = int.tryParse(widget.selectedSiteId ?? '');
      if (siteId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final items = await StockService.instance.getStockReport(siteId);
      if (mounted) {
        setState(() {
          _stockItems = items;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stock report: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Optional: show snackbar only on actual error, not just parse fail
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredStockItems = _stockItems.where((item) {
        final matchesCategory = _selectedCategory == 'All' ||
            item.categoryName == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty ||
            item.materialName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // _buildHeaderStats(),
          _buildSearchBar(),
          _buildHeaderWithPDF(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                  onPressed: _showPDFBottomSheet,
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    size: 24,
                    color: Color.fromARGB(255, 29, 29, 29),
                  ),
                ),
              ),
              SizedBox(width: 20.w),
            ],
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildInventoryList(_filteredStockItems),
          ),
        ],
      ),
      // FAB kept if needed for adding stock manually later
      // floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildHeaderStats() {
    final totalItems = _stockItems.length;
    // Assuming low stock if qty < 10 for demo, or you can add logic
    final lowStockCount = _stockItems
        .where((item) => item.totalQty < 10)
        .length;
    final inStockCount = totalItems - lowStockCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Items',
              '$totalItems',
              Icons.inventory_2_rounded,
              primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'In Stock',
              '$inStockCount',
              Icons.check_circle_rounded,
              const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Low Stock',
              '$lowStockCount',
              Icons.warning_rounded,
              const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _searchQuery = value;
          _applyFilter();
        },
        decoration: InputDecoration(
          hintText: 'Search stock...',
          hintStyle: TextStyle(color: textSecondary),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _applyFilter();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHeaderWithPDF() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [Expanded(child: _buildCategoryFilter())]),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      'All',
      ..._stockItems
          .map((e) => e.categoryName)
          .where((name) =>
              name != null &&
              name.isNotEmpty &&
              name.toLowerCase() != 'null')
          .toSet(),
    ];

    return Container(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'All';
                  _applyFilter();
                });
              },
              backgroundColor: const Color(0xFFEEF2FF),
              selectedColor: primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventoryList(List<StockReportItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No stock data found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: EdgeInsets.only(bottom: 9.h),
          color: cardColor,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.inventory_2,
                    color: const Color.fromARGB(255, 66, 89, 170),
                    size: 19.sp,
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
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: item.materialName,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color.fromARGB(
                                        255,
                                        44,
                                        44,
                                        44,
                                      ),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '  •  ',
                                  ),
                                  TextSpan(
                                    text: '${item.totalQty} ${item.unitSymbol}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),

                          if (Provider.of<CompanySiteProvider>(
                            context,
                            listen: false,
                          ).hasPermission('stock-report transfer'))
                            InkWell(
                              onTap: () {
                                _showTransferBottomSheet(item);
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: Icon(
                                  Icons.swap_horiz,
                                  color: Color(0xFF2a43a0),
                                  size: 23.sp,
                                ),
                              ),
                            ),
                          SizedBox(width: 10.w),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Category: ${item.categoryName}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Price: ₹${item.materialPrice}/${item.unitSymbol} | Reorder Level: ${item.reorderLevel}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransferBottomSheet(StockReportItem? preSelectedItem) {
    if (widget.selectedSiteId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TransferStockSheet(
          currentSiteId: widget.selectedSiteId!,
          sites: widget.sites,
          stockItems: _stockItems,
          preSelectedItem: preSelectedItem,
          onTransferSuccess: _loadStockData,
        );
      },
    );
  }

  void _showPDFBottomSheet() {
    final currentDate = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stock Report',
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
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildReportItem(
                    'Date',
                    formattedDate,
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
                    'Total Items',
                    _filteredStockItems.length.toString(),
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
            ),
            const SizedBox(height: 24),
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
                  label: const Text('View PDF', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
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

  Future<void> _viewPDF([VoidCallback? onSuccess]) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Convert stock items to list format for PDF generation
      // Use _filteredStockItems instead of _stockItems to respect the filter
      final stockData = _filteredStockItems
          .map(
            (item) => [
              item.materialName,
              item.categoryName,
              item.totalQty.toString(),
              item.unitSymbol,
              item.materialPrice,
            ],
          )
          .toList();

      final pdfPath = await ReportService.generateStockPDF(
        stockData,
        widget.selectedSiteName ?? 'All Sites',
        categoryFilter: _selectedCategory,
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      if (onSuccess != null) {
        onSuccess();
      }

      await ReportService.openFile(pdfPath);
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

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF2a43a0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'stock_fab',
        onPressed: () {
          // Add new item logic if needed
        },
        elevation: 0,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class TransferStockSheet extends StatefulWidget {
  final String currentSiteId;
  final List<Site> sites;
  final List<StockReportItem> stockItems;
  final StockReportItem? preSelectedItem;
  final VoidCallback onTransferSuccess;

  const TransferStockSheet({
    Key? key,
    required this.currentSiteId,
    required this.sites,
    required this.stockItems,
    this.preSelectedItem,
    required this.onTransferSuccess,
  }) : super(key: key);

  @override
  _TransferStockSheetState createState() => _TransferStockSheetState();
}

class _TransferStockSheetState extends State<TransferStockSheet> {
  String? _selectedToSiteId;
  StockReportItem? _selectedMaterial;
  late TextEditingController _quantityController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMaterial = widget.preSelectedItem;
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter out current site from destination sites
    final otherSites = widget.sites
        .where((s) => s.id != widget.currentSiteId)
        .toList();

    // Define colors to match parent
    final primaryColor = const Color(0xFF4a63c0);
    final textPrimary = const Color(0xFF2D3748);
    final textSecondary = const Color(0xFF718096);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            'Transfer Material',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // To Site Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedToSiteId,
                    decoration: InputDecoration(
                      labelText: 'To Site',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: otherSites.map((site) {
                      return DropdownMenuItem(
                        value: site.id,
                        child: Text(site.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedToSiteId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Material Dropdown
                  DropdownButtonFormField<StockReportItem>(
                    value: _selectedMaterial,
                    decoration: InputDecoration(
                      labelText: 'Material',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: widget.stockItems.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item.materialName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedMaterial = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Current Stock Display
                  if (_selectedMaterial != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Current Stock:',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 70, 81, 97),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_selectedMaterial!.totalQty} ${_selectedMaterial!.unitSymbol}',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Quantity Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Transfer Quantity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_selectedMaterial != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _selectedMaterial!.unitSymbol,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (_selectedToSiteId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select destination site',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (_selectedMaterial == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select material'),
                                  ),
                                );
                                return;
                              }
                              if (_quantityController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter quantity'),
                                  ),
                                );
                                return;
                              }

                              final qty = double.tryParse(
                                _quantityController.text,
                              );
                              if (qty == null || qty <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid quantity'),
                                  ),
                                );
                                return;
                              }

                              if (qty > _selectedMaterial!.totalQty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Insufficient stock'),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSubmitting = true);

                              try {
                                final payload = {
                                  "record_date": DateTime.now()
                                      .toIso8601String()
                                      .split('T')[0],
                                  "from_site_id": int.parse(
                                    widget.currentSiteId,
                                  ),
                                  "to_site_id": int.parse(_selectedToSiteId!),
                                  "created_by": 1, // TODO: Get actual user ID
                                  "workspace_id":
                                      1, // TODO: Get actual workspace ID
                                  "items": [
                                    {
                                      "material_id":
                                          _selectedMaterial!.materialId,
                                      "quantity": qty,
                                      "unit": _selectedMaterial!.unitSymbol,
                                      "price": _selectedMaterial!.materialPrice,
                                    },
                                  ],
                                };

                                final response = await ApiService.postRequest(
                                  '/material-transfer',
                                  payload,
                                );

                                if (response['success'] == true) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Transfer successful',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        55,
                                        160,
                                        51,
                                      ),
                                    ),
                                  );
                                  widget.onTransferSuccess();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response['message'] ??
                                            'Transfer failed',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Transfer Stock',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
