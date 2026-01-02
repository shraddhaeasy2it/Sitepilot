import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  final List<Map<String, dynamic>> _inventory = [
    {
      'name': 'Cement',
      'category': 'Building Material',
      'stock': 25,
      'reorderLevel': 20,
      'usageTrend': 'High',
      'unit': 'bags',
      'icon': Icons.business_center,
    },
    {
      'name': 'Bricks',
      'category': 'Building Material',
      'stock': 120,
      'reorderLevel': 100,
      'usageTrend': 'Medium',
      'unit': 'pieces',
      'icon': Icons.construction,
    },
    {
      'name': 'Steel Rods',
      'category': 'Structural',
      'stock': 10,
      'reorderLevel': 15,
      'usageTrend': 'Low',
      'unit': 'tons',
      'icon': Icons.engineering,
    },
  ];

  String _selectedCategory = 'All';

  // Modern color scheme matching MaterialScreen
  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color primaryDark = Color(0xFF2a43a0);
  static const Color backgroundColor = Color(0xFFf8f9fa);
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Color(0xFFEEF2FF);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  Widget build(BuildContext context) {
    final filteredInventory = _selectedCategory == 'All'
        ? _inventory
        : _inventory
            .where((item) => item['category'] == _selectedCategory)
            .toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      // No AppBar as it's provided by MaterialScreen
      body: Column(
        children: [
          _buildHeaderStats(),
          _buildCategoryFilter(),
          Expanded(child: _buildInventoryList(filteredInventory)),
        ],
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildHeaderStats() {
    final lowStockCount =
        _inventory.where((item) => item['stock'] < item['reorderLevel']).length;
    final totalItems = _inventory.length;
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
              successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Low Stock',
              '$lowStockCount',
              Icons.warning_rounded,
              errorColor,
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

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Building Material', 'Structural'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                });
              },
              backgroundColor: surfaceColor,
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

  Widget _buildInventoryList(List<Map<String, dynamic>> items) {
    return items.isEmpty
        ? Center(
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
                  'No inventory items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first item to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final isLowStock =
                  (item['stock'] as num) < (item['reorderLevel'] as num);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showEditItemBottomSheet(item),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLowStock
                              ? errorColor.withOpacity(0.2)
                              : primaryColor.withOpacity(0.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item['icon'] ?? Icons.inventory_2_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: textPrimary,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          isLowStock
                                              ? Icons.warning_rounded
                                              : Icons.check_circle_rounded,
                                          color: isLowStock
                                              ? errorColor
                                              : successColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _deleteItem(item),
                                          child: Icon(
                                            Icons.delete_rounded,
                                            color: errorColor.withOpacity(0.7),
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['stock']} ${item['unit'] ?? 'units'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: const Color.fromARGB(
                                      255,
                                      59,
                                      59,
                                      59,
                                    ),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: surfaceColor,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        item['category'],
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: textSecondary.withOpacity(0.4),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Usage: ${item['usageTrend']}',
                                      style: const TextStyle(
                                        color: textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
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
            },
          );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [primaryColor, primaryDark],
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
          // Add new item logic
        },
        elevation: 0,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await _showDeleteConfirmation(item['name']);
    if (confirmed) {
      setState(() {
        _inventory.removeWhere((element) => element['name'] == item['name']);
      });
      _showSnackBar('${item['name']} deleted', errorColor);
    }
  }

  Future<bool> _showDeleteConfirmation(String itemName) async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $itemName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showEditItemBottomSheet(Map<String, dynamic> item) {
    // Basic implementation for viewing/editing
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
