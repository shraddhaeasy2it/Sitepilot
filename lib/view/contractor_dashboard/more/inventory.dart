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
  static const Color primaryDark = Color(0xFF4a63c0);
  static const Color backgroundColor = Color(0xFFF8F9FC);
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Color(0xFFEEF2FF);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final filteredInventory = _selectedCategory == 'All'
        ? _inventory
        : _inventory
              .where((item) => item['category'] == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 80,
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Inventory - ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: widget.siteName,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
            ),
          ),
        ),
      ),
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
    final lowStockCount = _inventory
        .where((item) => item['stock'] < item['reorderLevel'])
        .length;
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
              final isLowStock = item['stock'] < item['reorderLevel'];

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
                                    color: primaryColor,
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
                                          color: primaryColor,
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showEditItemBottomSheet(Map<String, dynamic> item) {
    final TextEditingController nameController = TextEditingController(
      text: item['name'],
    );
    final TextEditingController stockController = TextEditingController(
      text: item['stock'].toString(),
    );
    final TextEditingController reorderController = TextEditingController(
      text: item['reorderLevel'].toString(),
    );
    final TextEditingController unitController = TextEditingController(
      text: item['unit'],
    );

    String category = item['category'];
    String usageTrend = item['usageTrend'];

    final List<String> categoryOptions = [
      'Structural',
      'Building Material',
      'Construction',
    ];
    final List<String> usageOptions = ['High', 'Medium', 'Low'];

    bool nameError = false;
    bool stockError = false;
    bool reorderError = false;
    bool unitError = false;

    void validateForm(StateSetter setSheetState) {
      setSheetState(() {
        nameError = nameController.text.isEmpty;
        stockError = stockController.text.isEmpty;
        reorderError = reorderController.text.isEmpty;
        unitError = unitController.text.isEmpty;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
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
                                  Icons.edit,
                                  color: primaryColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Edit Material',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Update material information',
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
                          _buildEnhancedTextField(
                            controller: nameController,
                            label: 'Material Name',
                            hint: 'e.g. Cement, Steel Bars',
                            icon: Icons.inventory_2_outlined,
                            isRequired: true,
                            hasError: nameError,
                            onChanged: (value) {
                              if (value.isNotEmpty && nameError) {
                                setSheetState(() => nameError = false);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedDropdown(
                            value: category,
                            label: 'Category',
                            icon: Icons.category_outlined,
                            items: categoryOptions,
                            onChanged: (val) => category = val!,
                          ),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 600) {
                                return Column(
                                  children: [
                                    _buildEnhancedTextField(
                                      controller: stockController,
                                      label: 'Current Stock',
                                      hint: 'e.g. 100, 5.5',
                                      icon: Icons.numbers_outlined,
                                      isRequired: true,
                                      hasError: stockError,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        if (value.isNotEmpty && stockError) {
                                          setSheetState(
                                            () => stockError = false,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _buildEnhancedTextField(
                                      controller: unitController,
                                      label: 'Unit',
                                      hint: 'e.g. Bags, Tons',
                                      icon: Icons.straighten_outlined,
                                      isRequired: true,
                                      hasError: unitError,
                                      onChanged: (value) {
                                        if (value.isNotEmpty && unitError) {
                                          setSheetState(
                                            () => unitError = false,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                );
                              } else {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        controller: stockController,
                                        label: 'Current Stock',
                                        hint: 'e.g. 100, 5.5',
                                        icon: Icons.numbers_outlined,
                                        isRequired: true,
                                        hasError: stockError,
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          if (value.isNotEmpty && stockError) {
                                            setSheetState(
                                              () => stockError = false,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        controller: unitController,
                                        label: 'Unit',
                                        hint: 'e.g. Bags, Tons',
                                        icon: Icons.straighten_outlined,
                                        isRequired: true,
                                        hasError: unitError,
                                        onChanged: (value) {
                                          if (value.isNotEmpty && unitError) {
                                            setSheetState(
                                              () => unitError = false,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedTextField(
                            controller: reorderController,
                            label: 'Reorder Level',
                            hint: 'e.g. 20, 50',
                            icon: Icons.warning_amber_outlined,
                            isRequired: true,
                            hasError: reorderError,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if (value.isNotEmpty && reorderError) {
                                setSheetState(() => reorderError = false);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedDropdown(
                            value: usageTrend,
                            label: 'Usage Trend',
                            icon: Icons.trending_up_outlined,
                            items: usageOptions,
                            onChanged: (val) => usageTrend = val!,
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
                              icon: const Icon(
                                Icons.update,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: const Text(
                                'Update Material',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                validateForm(setSheetState);
                                if (nameError ||
                                    stockError ||
                                    reorderError ||
                                    unitError) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Please fill all required fields',
                                          ),
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

                                final stock =
                                    int.tryParse(stockController.text) ?? 0;
                                final reorderLevel =
                                    int.tryParse(reorderController.text) ?? 10;

                                setState(() {
                                  item['name'] = nameController.text;
                                  item['category'] = category;
                                  item['stock'] = stock;
                                  item['reorderLevel'] = reorderLevel;
                                  item['unit'] = unitController.text;
                                  item['usageTrend'] = usageTrend;
                                });
                                Navigator.pop(context);
                                _showSnackBar(
                                  '${nameController.text} updated successfully',
                                  successColor,
                                );
                              },
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
    required bool isRequired,
    required bool hasError,
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasError ? errorColor : textPrimary,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? errorColor : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontWeight: FontWeight.w500),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF4A5FCC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _showAddStockBottomSheet,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(
          'Add Stock',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showAddStockBottomSheet() {
    String name = '';
    String category = 'Building Material';
    int stock = 0;
    int reorderLevel = 10;
    String unit = 'units';
    String usageTrend = 'Medium';

    final List<String> categoryOptions = [
      'Structural',
      'Building Material',
      'Construction',
    ];
    final List<String> usageOptions = ['High', 'Medium', 'Low'];

    bool nameError = false;
    bool stockError = false;
    bool reorderError = false;
    bool unitError = false;

    void validateForm(StateSetter setSheetState) {
      setSheetState(() {
        nameError = name.isEmpty;
        stockError = stock == 0;
        reorderError = reorderLevel == 0;
        unitError = unit.isEmpty;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
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
                                  Icons.add_box,
                                  color: primaryColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Add New Material',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Enter material details below',
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
                          _buildEnhancedTextField(
                            controller: TextEditingController(text: name),
                            label: 'Material Name',
                            hint: 'e.g. Cement, Steel Bars',
                            icon: Icons.inventory_2_outlined,
                            isRequired: true,
                            hasError: nameError,
                            onChanged: (value) {
                              name = value;
                              if (value.isNotEmpty && nameError) {
                                setSheetState(() => nameError = false);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedDropdown(
                            value: category,
                            label: 'Category',
                            icon: Icons.category_outlined,
                            items: categoryOptions,
                            onChanged: (val) => category = val!,
                          ),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 600) {
                                return Column(
                                  children: [
                                    _buildEnhancedTextField(
                                      controller: TextEditingController(
                                        text: stock.toString(),
                                      ),
                                      label: 'Current Stock',
                                      hint: 'e.g. 100, 5.5',
                                      icon: Icons.numbers_outlined,
                                      isRequired: true,
                                      hasError: stockError,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        stock = int.tryParse(value) ?? 0;
                                        if (stock > 0 && stockError) {
                                          setSheetState(
                                            () => stockError = false,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _buildEnhancedTextField(
                                      controller: TextEditingController(
                                        text: unit,
                                      ),
                                      label: 'Unit',
                                      hint: 'e.g. Bags, Tons',
                                      icon: Icons.straighten_outlined,
                                      isRequired: true,
                                      hasError: unitError,
                                      onChanged: (value) {
                                        unit = value;
                                        if (value.isNotEmpty && unitError) {
                                          setSheetState(
                                            () => unitError = false,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                );
                              } else {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        controller: TextEditingController(
                                          text: stock.toString(),
                                        ),
                                        label: 'Current Stock',
                                        hint: 'e.g. 100, 5.5',
                                        icon: Icons.numbers_outlined,
                                        isRequired: true,
                                        hasError: stockError,
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          stock = int.tryParse(value) ?? 0;
                                          if (stock > 0 && stockError) {
                                            setSheetState(
                                              () => stockError = false,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        controller: TextEditingController(
                                          text: unit,
                                        ),
                                        label: 'Unit',
                                        hint: 'e.g. Bags, Tons',
                                        icon: Icons.straighten_outlined,
                                        isRequired: true,
                                        hasError: unitError,
                                        onChanged: (value) {
                                          unit = value;
                                          if (value.isNotEmpty && unitError) {
                                            setSheetState(
                                              () => unitError = false,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedTextField(
                            controller: TextEditingController(
                              text: reorderLevel.toString(),
                            ),
                            label: 'Reorder Level',
                            hint: 'e.g. 20, 50',
                            icon: Icons.warning_amber_outlined,
                            isRequired: true,
                            hasError: reorderError,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              reorderLevel = int.tryParse(value) ?? 0;
                              if (reorderLevel > 0 && reorderError) {
                                setSheetState(() => reorderError = false);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedDropdown(
                            value: usageTrend,
                            label: 'Usage Trend',
                            icon: Icons.trending_up_outlined,
                            items: usageOptions,
                            onChanged: (val) => usageTrend = val!,
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
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: const Text(
                                'Add Material',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                validateForm(setSheetState);
                                if (nameError ||
                                    stockError ||
                                    reorderError ||
                                    unitError) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Please fill all required fields',
                                          ),
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

                                setState(() {
                                  _inventory.add({
                                    'name': name,
                                    'category': category,
                                    'stock': stock,
                                    'reorderLevel': reorderLevel,
                                    'unit': unit,
                                    'usageTrend': usageTrend,
                                    'icon': Icons.inventory_2_rounded,
                                  });
                                });
                                Navigator.pop(context);
                                _showSnackBar(
                                  '$name added successfully',
                                  successColor,
                                );
                              },
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

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
