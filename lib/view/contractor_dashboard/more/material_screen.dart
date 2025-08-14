import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MaterialScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const MaterialScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class MaterialItem {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final String supplier;
  final double cost;
  final String status;
  final DateTime lastUpdated;

  MaterialItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.supplier,
    required this.cost,
    required this.status,
    required this.lastUpdated,
  });
}

class _MaterialScreenState extends State<MaterialScreen> {
  List<MaterialItem> materials = [];
  bool isLoading = false;
  String searchQuery = '';

  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryLight = Color(0xFF8fa4e8);
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  final List<String> categoryList = [
    'Construction',
    'Reinforcement',
    'Masonry',
    'Aggregates',
    'Electrical',
    'Plumbing',
  ];

  final List<String> supplierList = [
    'ABC Suppliers',
    'XYZ Steel Co.',
    'Brick Masters',
    'Sand & Gravel Co.',
  ];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  void _loadMaterials() {
    setState(() => isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        materials = [
          MaterialItem(
            id: '1',
            name: 'Cement',
            category: 'Construction',
            quantity: 500,
            unit: 'Bags',
            supplier: 'ABC Suppliers',
            cost: 25.0,
            status: 'In Stock',
            lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
          ),
          MaterialItem(
            id: '2',
            name: 'Steel Bars',
            category: 'Reinforcement',
            quantity: 200,
            unit: 'Tons',
            supplier: 'XYZ Steel Co.',
            cost: 1200.0,
            status: 'Low Stock',
            lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
          ),
          MaterialItem(
            id: '3',
            name: 'Bricks',
            category: 'Masonry',
            quantity: 1000,
            unit: 'Pieces',
            supplier: 'Brick Masters',
            cost: 8.0,
            status: 'In Stock',
            lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
          ),
          MaterialItem(
            id: '4',
            name: 'Sand',
            category: 'Aggregates',
            quantity: 50,
            unit: 'Tons',
            supplier: 'Sand & Gravel Co.',
            cost: 45.0,
            status: 'Out of Stock',
            lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ];
        isLoading = false;
      });
    });
  }

  List<MaterialItem> get filteredMaterials {
    if (searchQuery.isEmpty) return materials;
    return materials
        .where((material) =>
            material.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            material.category
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            material.supplier
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();
  }

  void _showMaterialSheet({MaterialItem? existingMaterial}) {
    final isEditing = existingMaterial != null;

    final nameController =
        TextEditingController(text: isEditing ? existingMaterial!.name : '');
    final quantityController = TextEditingController(
        text: isEditing ? existingMaterial!.quantity.toString() : '');
    final unitController =
        TextEditingController(text: isEditing ? existingMaterial!.unit : '');
    final costController = TextEditingController(
        text: isEditing ? existingMaterial!.cost.toString() : '');

    String selectedCategory =
        isEditing ? existingMaterial!.category : categoryList.first;
    String selectedSupplier =
        isEditing ? existingMaterial!.supplier : supplierList.first;
    String selectedStatus =
        isEditing ? existingMaterial!.status : 'In Stock';

    bool nameError = false;
    bool quantityError = false;
    bool unitError = false;
    bool costError = false;

    void validateForm(StateSetter setSheetState) {
      setSheetState(() {
        nameError = nameController.text.isEmpty;
        quantityError = quantityController.text.isEmpty;
        unitError = unitController.text.isEmpty;
        costError = costController.text.isEmpty;
      });
    }

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
                            isEditing ? Icons.edit : Icons.add_box,
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
                                    ? 'Edit Material'
                                    : 'Add New Material',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                isEditing
                                    ? 'Update material information'
                                    : 'Enter material details below',
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
                      value: selectedCategory,
                      label: 'Category',
                      icon: Icons.category_outlined,
                      items: categoryList,
                      onChanged: (val) => selectedCategory = val!,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedTextField(
                            controller: quantityController,
                            label: 'Quantity',
                            hint: 'e.g. 100, 5.5',
                            icon: Icons.numbers_outlined,
                            isRequired: true,
                            hasError: quantityError,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if (value.isNotEmpty && quantityError) {
                                setSheetState(() => quantityError = false);
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
                                setSheetState(() => unitError = false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildEnhancedDropdown(
                      value: selectedSupplier,
                      label: 'Supplier',
                      icon: Icons.business_outlined,
                      items: supplierList,
                      onChanged: (val) => selectedSupplier = val!,
                    ),
                    const SizedBox(height: 20),
                    _buildEnhancedTextField(
                      controller: costController,
                      label: 'Cost per Unit',
                      hint: 'e.g. 25.50, 1200',
                      icon: Icons.currency_rupee_outlined,
                      isRequired: true,
                      hasError: costError,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty && costError) {
                          setSheetState(() => costError = false);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildEnhancedDropdown(
                      value: selectedStatus,
                      label: 'Status',
                      icon: Icons.info_outline,
                      items: [
                        'In Stock',
                        'Low Stock',
                        'Out of Stock',
                        'On Order'
                      ],
                      onChanged: (val) => selectedStatus = val!,
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
                          isEditing
                              ? 'Update Material'
                              : 'Add Material',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          validateForm(setSheetState);
                          if (nameError ||
                              quantityError ||
                              unitError ||
                              costError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Please fill all required fields'),
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
                          final material = MaterialItem(
                            id: isEditing
                                ? existingMaterial!.id
                                : DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                            name: nameController.text,
                            category: selectedCategory,
                            quantity: double.tryParse(
                                    quantityController.text) ??
                                0,
                            unit: unitController.text,
                            supplier: selectedSupplier,
                            cost: double.tryParse(
                                    costController.text) ??
                                0,
                            status: selectedStatus,
                            lastUpdated: DateTime.now(),
                          );
                          setState(() {
                            if (isEditing) {
                              final index = materials.indexWhere(
                                  (m) => m.id == existingMaterial!.id);
                              materials[index] = material;
                            } else {
                              materials.add(material);
                            }
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    isEditing ? Icons.check_circle : Icons.add_circle,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(isEditing
                                      ? 'Material updated successfully'
                                      : 'Material added successfully'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
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

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool hasError = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
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
        onChanged: onChanged,
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
            color: hasError ? Colors.red : primaryColor,
            size: 22,
          ),
          errorText: hasError ? 'Required' : null,
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1,
            ),
          ),
          labelStyle: TextStyle(
            color: hasError ? Colors.red : textSecondary,
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
        color: cardColor,
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
          prefixIcon: Icon(
            icon,
            color: primaryColor,
            size: 22,
          ),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          labelStyle: TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        dropdownColor: cardColor,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'In Stock':
        return Colors.green;
      case 'Low Stock':
        return Colors.orange;
      case 'Out of Stock':
        return Colors.red;
      case 'On Order':
        return primaryColor;
      default:
        return Colors.grey;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Construction':
        return Icons.construction;
      case 'Reinforcement':
        return Icons.foundation;
      case 'Masonry':
        return Icons.layers;
      case 'Aggregates':
        return Icons.scatter_plot;
      case 'Electrical':
        return Icons.electrical_services;
      case 'Plumbing':
        return Icons.plumbing;
      default:
        return Icons.category;
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search materials...',
          prefixIcon: Icon(
            Icons.search,
            color: primaryColor,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => searchQuery = ''),
                  color: textSecondary,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardColor,
          hintStyle: TextStyle(
            color: textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialCard(MaterialItem material) {
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
          onTap: () => _showMaterialSheet(existingMaterial: material),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        getCategoryIcon(material.category),
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            material.category,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getStatusColor(material.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: getStatusColor(material.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        material.status,
                        style: TextStyle(
                          color: getStatusColor(material.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.inventory,
                        'Quantity',
                        '${material.quantity} ${material.unit}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.currency_rupee,
                        'Cost',
                        '₹${material.cost}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoChip(
                  Icons.business,
                  'Supplier',
                  material.supplier,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last updated ${DateFormat('MMM dd, yyyy').format(material.lastUpdated)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
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

  Widget _buildInfoChip(IconData icon, String label, String value, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
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
                Icons.inventory_2_outlined,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No materials found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              searchQuery.isEmpty
                  ? 'Start by adding your first material'
                  : 'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
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
        toolbarHeight: 90,
        title: const Text(
          'Material Management',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6f88e2), Color(0xFF5a73d1), Color(0xFF4a63c0)],
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3,
              ),
            )
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: filteredMaterials.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: filteredMaterials.length,
                          itemBuilder: (context, index) {
                            return _buildMaterialCard(filteredMaterials[index]);
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
          onPressed: () => _showMaterialSheet(),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Material',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}