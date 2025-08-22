import 'package:flutter/material.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const InventoryDetailScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
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

  // Modern color scheme with #6f88e2 as primary
  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color backgroundColor = Color(0xFFF8F9FC);
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Color(0xFFEEF2FF);
  static const Color successColor = Color(0xFF10B981);
  // static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final filteredInventory = _selectedCategory == 'All'
        ? _inventory
        : _inventory.where((item) => item['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 90,
        title: Text(
          'Inventory - ${widget.siteName}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6f88e2),
                Color(0xFF5a73d1),
                Color(0xFF4a63c0),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeaderStats(),
          // _buildCategoryFilter(),
          Expanded(child: _buildInventoryList(filteredInventory)),
        ],
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildHeaderStats() {
    final lowStockCount = _inventory.where((item) => item['stock'] < item['reorderLevel']).length;
    final totalItems = _inventory.length;
    final inStockCount = totalItems - lowStockCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          _buildStatCard('Total Items', totalItems.toString(), Icons.inventory_2_rounded, primaryColor),
          const SizedBox(width: 12),
          _buildStatCard('In Stock', inStockCount.toString(), Icons.check_circle_rounded, successColor),
          const SizedBox(width: 12),
          _buildStatCard('Low Stock', lowStockCount.toString(), Icons.warning_rounded, errorColor),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 24), // Simplified icon without background
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        final item = items[index];
        final isLowStock = item['stock'] < item['reorderLevel'];

        return Dismissible(
          key: Key(item['name'] + index.toString()),
          background: _buildSwipeBackground(primaryColor, Icons.edit_rounded),
          secondaryBackground: _buildSwipeBackground(errorColor, Icons.delete_rounded),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Edit action
              _showEditItemDialog(item);
              return false; // Don't dismiss - we'll handle it in the dialog
            } else {
              // Delete action
              return await _showDeleteConfirmation(item['name']);
            }
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              setState(() {
                _inventory.removeWhere((element) => element['name'] == item['name']);
              });
              _showSnackBar('${item['name']} deleted', errorColor);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showStockOptions(item),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLowStock ? errorColor.withOpacity(0.2) : primaryColor.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] ?? Icons.inventory_2_rounded,
                        color: isLowStock ? errorColor : primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item['stock']} ${item['unit'] ?? 'units'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: isLowStock ? errorColor : successColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item['category'],
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: textSecondary.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Usage: ${item['usageTrend']}',
                                  style: const TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Icon(
                            isLowStock ? Icons.warning_rounded : Icons.check_circle_rounded,
                            color: isLowStock ? errorColor : successColor,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isLowStock ? 'Low Stock' : 'In Stock',
                            style: TextStyle(
                              color: isLowStock ? errorColor : successColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSwipeBackground(Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: icon == Icons.edit_rounded 
              ? MainAxisAlignment.start 
              : MainAxisAlignment.end,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              icon == Icons.edit_rounded ? 'Edit' : 'Delete',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(String itemName) async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $itemName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            child: Text(
              'Cancel',
              style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showEditItemDialog(Map<String, dynamic> item) {
    final TextEditingController nameController = TextEditingController(text: item['name']);
    final TextEditingController stockController = TextEditingController(text: item['stock'].toString());
    final TextEditingController reorderController = TextEditingController(text: item['reorderLevel'].toString());
    final TextEditingController unitController = TextEditingController(text: item['unit']);
    
    String category = item['category'];
    String usageTrend = item['usageTrend'];
    
    final List<String> categoryOptions = ['Structural', 'Building Material', 'Construction'];
    final List<String> usageOptions = ['High', 'Medium', 'Low'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.edit_rounded, color: primaryColor, size: 28),
                    const SizedBox(width: 16),
                    const Text(
                      'Edit Material',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildModernInputField('Material Name', Icons.inventory_2_rounded, (val) {}, controller: nameController),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: category,
                    items: categoryOptions.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) category = val;
                    },
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildModernInputField('Unit (e.g., bags, pieces)', Icons.straighten_rounded, (val) {}, controller: unitController),
                const SizedBox(height: 20),
                _buildModernInputField('Current Stock', Icons.add_circle_rounded, (val) {}, controller: stockController, isNumber: true),
                const SizedBox(height: 20),
                _buildModernInputField('Reorder Level', Icons.warning_rounded, (val) {}, controller: reorderController, isNumber: true),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: usageTrend,
                    items: usageOptions.map((usage) {
                      return DropdownMenuItem(value: usage, child: Text(usage));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) usageTrend = val;
                    },
                    decoration: InputDecoration(
                      labelText: 'Usage Trend',
                      prefixIcon: Icon(Icons.trending_up_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryColor, Color(0xFF4A5FCC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final stock = int.tryParse(stockController.text) ?? 0;
                          final reorderLevel = int.tryParse(reorderController.text) ?? 10;
                          
                          setState(() {
                            item['name'] = nameController.text;
                            item['category'] = category;
                            item['stock'] = stock;
                            item['reorderLevel'] = reorderLevel;
                            item['unit'] = unitController.text;
                            item['usageTrend'] = usageTrend;
                          });
                          Navigator.pop(context);
                          _showSnackBar('${nameController.text} updated successfully', successColor);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF4A5FCC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: FloatingActionButton.extended(
        onPressed: _showAddStockBottomSheet,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Add Stock',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
    );
  }

  void _showStockOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Manage ${item['name']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildOptionTile(
                      Icons.remove_circle_rounded,
                      'Log Usage (Stock Out)',
                      'Record material consumption',
                      const Color.fromARGB(255, 243, 145, 145),
                      () {
                        Navigator.pop(context);
                        _logStockUsage(item);
                      },
                    ),
                    _buildOptionTile(
                      Icons.add_circle_rounded,
                      'Receive Stock (Stock In)',
                      'Add new material inventory',
                      successColor,
                      () {
                        Navigator.pop(context);
                        _receiveStock(item);
                      },
                    ),
                    _buildOptionTile(
                      Icons.tune_rounded,
                      'Set Reorder Level',
                      'Configure low stock threshold',
                      primaryColor,
                      () {
                        Navigator.pop(context);
                        _setReorderLevel(item);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.1), width: 1),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _logStockUsage(Map<String, dynamic> item) {
    _showNumberInputDialog(
      title: 'Log Usage',
      subtitle: 'Enter quantity used for ${item['name']}',
      icon: Icons.remove_circle_rounded,
      iconColor: errorColor,
      onConfirm: (qty) {
        if (qty > item['stock']) {
          _showSnackBar('Not enough stock available', errorColor);
          return;
        }
        setState(() {
          item['stock'] -= qty;
        });
        _showSnackBar('${item['name']} stock reduced by $qty', successColor);
      },
    );
  }

  void _receiveStock(Map<String, dynamic> item) {
    _showNumberInputDialog(
      title: 'Receive Stock',
      subtitle: 'Enter quantity received for ${item['name']}',
      icon: Icons.add_circle_rounded,
      iconColor: successColor,
      onConfirm: (qty) {
        setState(() {
          item['stock'] += qty;
        });
        _showSnackBar('${item['name']} stock increased by $qty', successColor);
      },
    );
  }

  void _setReorderLevel(Map<String, dynamic> item) {
    _showNumberInputDialog(
      title: 'Set Reorder Level',
      subtitle: 'Configure low stock threshold for ${item['name']}',
      icon: Icons.tune_rounded,
      iconColor: primaryColor,
      initialValue: item['reorderLevel'],
      onConfirm: (val) {
        setState(() {
          item['reorderLevel'] = val;
        });
        _showSnackBar('${item['name']} reorder level set to $val', primaryColor);
      },
    );
  }

  void _showNumberInputDialog({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    int initialValue = 1,
    required Function(int) onConfirm,
  }) {
    final controller = TextEditingController(text: '$initialValue');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          margin: const EdgeInsets.only(top: 16),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter quantity',
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: iconColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            child: Text(
              'Cancel',
              style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 0) {
                onConfirm(value);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStockBottomSheet() {
    String name = '';
    String category = 'Building Material';
    int stock = 0;
    int reorderLevel = 10;
    String unit = 'units';

    final List<String> categoryOptions = ['Structural', 'Building Material', 'Construction'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 24,
              right: 24,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.add_box_rounded, color: primaryColor, size: 28),
                      const SizedBox(width: 16),
                      const Text(
                        'Add New Material',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildModernInputField('Material Name', Icons.inventory_2_rounded, (val) => name = val),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: category,
                      items: categoryOptions.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) category = val;
                      },
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_rounded, color: primaryColor),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildModernInputField('Unit (e.g., bags, pieces)', Icons.straighten_rounded, (val) => unit = val),
                  const SizedBox(height: 20),
                  _buildModernInputField('Initial Stock', Icons.add_circle_rounded, (val) => stock = int.tryParse(val) ?? 0, isNumber: true),
                  const SizedBox(height: 20),
                  _buildModernInputField('Reorder Level', Icons.warning_rounded, (val) => reorderLevel = int.tryParse(val) ?? 10, isNumber: true),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryColor, Color(0xFF4A5FCC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (name.isNotEmpty && category.isNotEmpty && stock >= 0) {
                              setState(() {
                                _inventory.add({
                                  'name': name,
                                  'category': category,
                                  'stock': stock,
                                  'reorderLevel': reorderLevel,
                                  'usageTrend': 'Medium',
                                  'unit': unit.isNotEmpty ? unit : 'units',
                                  'icon': Icons.inventory_2_rounded,
                                });
                              });
                              Navigator.pop(context);
                              _showSnackBar('New material added successfully', successColor);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            'Add Material',
                            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
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
      },
    );
  }

  Widget _buildModernInputField(
    String label, 
    IconData icon, 
    Function(String) onChanged, {
    bool isNumber = false,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        onChanged: onChanged,
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.2),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}