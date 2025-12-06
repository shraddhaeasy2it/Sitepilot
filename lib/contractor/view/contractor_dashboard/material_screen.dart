import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/services/report_services.dart';

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
  final String siteId;
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
    required this.siteId,
  });
}

class MaterialUsage {
  final String id;
  final String materialId;
  final double quantityUsed;
  final String purpose;
  final String site;
  final DateTime date;

  MaterialUsage({
    required this.id,
    required this.materialId,
    required this.quantityUsed,
    required this.purpose,
    required this.site,
    required this.date,
  });
}

class _MaterialScreenState extends State<MaterialScreen> {
  List<MaterialItem> materials = [];
  List<MaterialUsage> materialUsages = [];
  late ValueNotifier<List<MaterialUsage>> materialUsagesNotifier;
  bool isLoading = false;
  String searchQuery = '';
  String? selectedSiteFilter;
  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color backgroundColor = Color.fromARGB(255, 249, 249, 253);
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
    selectedSiteFilter = widget.selectedSiteId;
    materialUsagesNotifier = ValueNotifier(materialUsages);
    _loadMaterials();
  }

  // Helper method to get the current site name
  String _getCurrentSiteName() {
    if (widget.selectedSiteId == null) {
      return 'All Sites';
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () =>
          Site(id: '', name: 'Unknown Site', companyId: ''),
    );
    return site.name;
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
            siteId: widget.sites.isNotEmpty ? widget.sites.first.id : '',
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
            siteId: widget.sites.isNotEmpty ? widget.sites.first.id : '',
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
            siteId: widget.sites.length > 1 ? widget.sites[1].id : '',
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
            siteId: widget.sites.length > 1 ? widget.sites[1].id : '',
          ),
        ];
        isLoading = false;
      });
    });
  }

  List<MaterialItem> get filteredMaterials {
    var filtered = materials;
    if (selectedSiteFilter != null) {
      filtered = filtered
          .where((material) => material.siteId == selectedSiteFilter)
          .toList();
    }
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (material) =>
                material.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                material.category.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                material.supplier.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }
    return filtered;
  }

  void _showMaterialSheet({MaterialItem? existingMaterial}) {
    final isEditing = existingMaterial != null;
    final nameController = TextEditingController(
      text: isEditing ? existingMaterial.name : '',
    );
    final quantityController = TextEditingController(
      text: isEditing ? existingMaterial.quantity.toString() : '',
    );
    final unitController = TextEditingController(
      text: isEditing ? existingMaterial.unit : '',
    );
    final costController = TextEditingController(
      text: isEditing ? existingMaterial.cost.toString() : '',
    );
    String selectedCategory = isEditing
        ? existingMaterial.category
        : categoryList.first;
    String selectedSupplier = isEditing
        ? existingMaterial.supplier
        : supplierList.first;
    String selectedStatus = isEditing ? existingMaterial.status : 'In Stock';
    String? selectedSite = isEditing
        ? existingMaterial.siteId
        : (widget.sites.isNotEmpty ? widget.sites.first.id : null);

    bool nameError = false;
    bool quantityError = false;
    bool unitError = false;
    bool costError = false;
    bool siteError = false;

    void validateForm(StateSetter setSheetState) {
      setSheetState(() {
        nameError = nameController.text.isEmpty;
        quantityError = quantityController.text.isEmpty;
        unitError = unitController.text.isEmpty;
        costError = costController.text.isEmpty;
        siteError = selectedSite == null;
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 600) {
                                return Column(
                                  children: [
                                    _buildEnhancedTextField(
                                      controller: quantityController,
                                      label: 'Quantity',
                                      hint: 'e.g. 100, 5.5',
                                      icon: Icons.numbers_outlined,
                                      isRequired: true,
                                      hasError: quantityError,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        if (value.isNotEmpty && quantityError) {
                                          setSheetState(
                                            () => quantityError = false,
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
                                        controller: quantityController,
                                        label: 'Quantity',
                                        hint: 'e.g. 100, 5.5',
                                        icon: Icons.numbers_outlined,
                                        isRequired: true,
                                        hasError: quantityError,
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          if (value.isNotEmpty &&
                                              quantityError) {
                                            setSheetState(
                                              () => quantityError = false,
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
                              'On Order',
                            ],
                            onChanged: (val) => selectedStatus = val!,
                          ),
                          const SizedBox(height: 20),
                          _buildSiteDropdown(
                            value: selectedSite,
                            label: 'Site',
                            icon: Icons.construction,
                            items: widget.sites,
                            hasError: siteError,
                            onChanged: (val) {
                              selectedSite = val;
                              if (val != null && siteError) {
                                setSheetState(() => siteError = false);
                              }
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
                                isEditing ? 'Update Material' : 'Add Material',
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
                                    costError ||
                                    siteError) {
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
                                final material = MaterialItem(
                                  id: isEditing
                                      ? existingMaterial.id
                                      : DateTime.now().millisecondsSinceEpoch
                                            .toString(),
                                  name: nameController.text,
                                  category: selectedCategory,
                                  quantity:
                                      double.tryParse(
                                        quantityController.text,
                                      ) ??
                                      0,
                                  unit: unitController.text,
                                  supplier: selectedSupplier,
                                  cost:
                                      double.tryParse(costController.text) ?? 0,
                                  status: selectedStatus,
                                  lastUpdated: DateTime.now(),
                                  siteId: selectedSite!,
                                );
                                setState(() {
                                  if (isEditing) {
                                    final index = materials.indexWhere(
                                      (m) => m.id == existingMaterial.id,
                                    );
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
                                          isEditing
                                              ? Icons.check_circle
                                              : Icons.add_circle,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          isEditing
                                              ? 'Material updated successfully'
                                              : 'Material added successfully',
                                        ),
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
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSiteDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<Site> items,
    required bool hasError,
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
          errorText: hasError ? 'Required' : null,
          prefixIcon: Icon(
            icon,
            color: hasError ? Colors.red : primaryColor,
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
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: TextStyle(
            color: hasError ? Colors.red : textSecondary,
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
            .map(
              (site) =>
                  DropdownMenuItem(value: site.id, child: Text(site.name)),
            )
            .toList(),
        onChanged: onChanged,
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
            color: hasError ? Colors.red : const Color.fromARGB(255, 105, 110, 126),
            size: 20,
          ),
          errorText: hasError ? 'Required' : null,
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
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
            borderSide: const BorderSide(color: Colors.red, width: 1),
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
          prefixIcon: Icon(icon, color: const Color.fromARGB(255, 95, 100, 122), size: 20),
          filled: true,
          fillColor: cardColor,
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
        dropdownColor: cardColor,
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

  String getSiteName(String siteId) {
    return widget.sites
        .firstWhere(
          (site) => site.id == siteId,
          orElse: () =>
              Site(id: '', name: 'Unknown Site', companyId: ''),
        )
        .name;
  }

  // Method to show delete confirmation dialog
  void _showDeleteConfirmationDialog(MaterialItem material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete ${material.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMaterial(material);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Method to handle material deletion
  void _deleteMaterial(MaterialItem material) {
    final index = materials.indexOf(material);
    setState(() {
      materials.remove(material);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 12),
            Text('${material.name} deleted successfully'),
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
              materials.insert(index, material);
            });
          },
        ),
      ),
    );
  }

  // Responsive search and filter bar
  Widget _buildSearchBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return Container(
          margin: const EdgeInsets.all(16),
          child: isSmallScreen
              ? Column(
                  children: [
                    // Search field
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search materials...',
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => searchQuery = ''),
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
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search materials...',
                          prefixIcon: Icon(Icons.search, color: primaryColor),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => searchQuery = ''),
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
                    ),
                    if (widget.sites.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: selectedSiteFilter,
                            hint: const Text('All Sites'),
                            isExpanded: true,
                            icon: Icon(Icons.filter_list, color: primaryColor),
                            underline: Container(),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Sites'),
                              ),
                              ...widget.sites.map(
                                (site) => DropdownMenuItem(
                                  value: site.id,
                                  child: Text(site.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedSiteFilter = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMaterialCard(MaterialItem material) {
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
              onTap: () => _showMaterialSheet(existingMaterial: material),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with icon, name, category, status, and delete button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            getCategoryIcon(material.category),
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
                                material.name,
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
                                material.category,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
                                  fontSize: isSmallScreen ? 9 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete button
                            GestureDetector(
                              onTap: () {
                                _showDeleteConfirmationDialog(material);
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
                    
                    // First row: Site and Quantity side by side
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfoItem(
                            Icons.construction,
                            'Site',
                            getSiteName(material.siteId),
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCompactInfoItem(
                            Icons.inventory,
                            'Quantity',
                            '${material.quantity} ${material.unit}',
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Second row: Supplier and Cost side by side
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfoItem(
                            Icons.business,
                            'Supplier',
                            material.supplier,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCompactInfoItem(
                            Icons.currency_rupee,
                            'Cost',
                            '₹${material.cost}',
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Last updated row
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Last updated ${DateFormat('MMM dd, yyyy').format(material.lastUpdated)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
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
      },
    );
  }

  // New helper method for compact info items
  Widget _buildCompactInfoItem(IconData icon, String label, String value, {bool isSmallScreen = false}) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Icon(
          //   icon,
          //   size: isSmallScreen ? 14 : 16,
          //   color: const Color.fromARGB(255, 109, 109, 109),
          // ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 10,
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
              searchQuery.isEmpty && selectedSiteFilter == null
                  ? 'Start by adding your first material'
                  : 'Try adjusting your search criteria',
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMaterialUsageBottomSheet(BuildContext context, List<MaterialItem> materials, Function(MaterialUsage) onUsageAdded, Function(MaterialItem) onMaterialUpdated) {
    MaterialItem? selectedMaterial;
    final quantityController = TextEditingController();
    final purposeController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
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
                                  Icons.inventory,
                                  color: primaryColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mark Material Usage',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    Text(
                                      'Select material and enter usage details',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF718096),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          DropdownButtonFormField<MaterialItem>(
                            value: selectedMaterial,
                            decoration: InputDecoration(
                              labelText: 'Select Material',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              prefixIcon: Icon(Icons.inventory_2, color: primaryColor),
                              filled: true,
                              fillColor: cardColor,
                            ),
                            items: filteredMaterials.map((material) {
                              return DropdownMenuItem(
                                value: material,
                                child: Text('${material.name} (${material.quantity} ${material.unit})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setSheetState(() => selectedMaterial = value);
                            },
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: quantityController,
                            decoration: InputDecoration(
                              labelText: 'Quantity Used',
                              hintText: selectedMaterial != null ? 'Max: ${selectedMaterial!.quantity}' : 'Enter quantity',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              prefixIcon: Icon(Icons.numbers, color: primaryColor),
                              filled: true,
                              fillColor: cardColor,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: purposeController,
                            decoration: InputDecoration(
                              labelText: 'Purpose',
                              hintText: 'e.g. Foundation work, Wall construction',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              prefixIcon: Icon(Icons.description, color: primaryColor),
                              filled: true,
                              fillColor: cardColor,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            title: const Text('Date'),
                            subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setSheetState(() => selectedDate = date);
                              }
                            },
                          ),
                          const SizedBox(height: 32),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
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
                                Icons.inventory,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: const Text(
                                'Mark Usage',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                if (selectedMaterial == null ||
                                    quantityController.text.isEmpty ||
                                    purposeController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please fill all fields'),
                                    ),
                                  );
                                  return;
                                }

                                final quantityUsed = double.tryParse(quantityController.text) ?? 0;
                                if (quantityUsed <= 0 || quantityUsed > selectedMaterial!.quantity) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Invalid quantity. Available: ${selectedMaterial!.quantity} ${selectedMaterial!.unit}',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Add usage record
                                final usage = MaterialUsage(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  materialId: selectedMaterial!.id,
                                  quantityUsed: quantityUsed,
                                  purpose: purposeController.text.trim(),
                                  site: getSiteName(selectedMaterial!.siteId),
                                  date: selectedDate,
                                );
                                onUsageAdded(usage);

                                // Update material quantity
                                final updatedMaterial = MaterialItem(
                                  id: selectedMaterial!.id,
                                  name: selectedMaterial!.name,
                                  category: selectedMaterial!.category,
                                  quantity: selectedMaterial!.quantity - quantityUsed,
                                  unit: selectedMaterial!.unit,
                                  supplier: selectedMaterial!.supplier,
                                  cost: selectedMaterial!.cost,
                                  status: selectedMaterial!.quantity - quantityUsed <= 0
                                      ? 'Out of Stock'
                                      : selectedMaterial!.quantity - quantityUsed < 10
                                          ? 'Low Stock'
                                          : 'In Stock',
                                  lastUpdated: DateTime.now(),
                                  siteId: selectedMaterial!.siteId,
                                );
                                onMaterialUpdated(updatedMaterial);

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${quantityUsed} ${selectedMaterial!.unit} of ${selectedMaterial!.name} marked as used',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80.h,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Materials - ',
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
            icon: const Icon(FontAwesomeIcons.boxOpen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MaterialUsageScreen(
                    materialUsagesNotifier: materialUsagesNotifier,
                    materials: materials,
                    onUsageAdded: (usage) {
                      materialUsages.add(usage);
                      materialUsagesNotifier.value = List.from(materialUsages);
                    },
                    onUsageDeleted: (usage) {
                      materialUsages.remove(usage);
                      materialUsagesNotifier.value = List.from(materialUsages);
                    },
                    onShowUsageBottomSheet: () => _showMaterialUsageBottomSheet(
                      context,
                      materials,
                      (usage) {
                        materialUsages.add(usage);
                        materialUsagesNotifier.value = List.from(materialUsages);
                      },
                      (updatedMaterial) {
                        setState(() {
                          final index = materials.indexWhere((m) => m.id == updatedMaterial.id);
                          if (index != -1) materials[index] = updatedMaterial;
                        });
                      },
                    ),
                  ),
                ),
              );
            },
            tooltip: 'Material Usage',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
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
                            final material = filteredMaterials[index];
                            return _buildMaterialCard(material);
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
          backgroundColor: const Color.fromARGB(255, 69, 96, 194),
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Material',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// Material Usage Screen
class MaterialUsageScreen extends StatefulWidget {
  final ValueNotifier<List<MaterialUsage>> materialUsagesNotifier;
  final List<MaterialItem> materials;
  final Function(MaterialUsage) onUsageAdded;
  final Function(MaterialUsage) onUsageDeleted;
  final VoidCallback onShowUsageBottomSheet;

  const MaterialUsageScreen({
    super.key,
    required this.materialUsagesNotifier,
    required this.materials,
    required this.onUsageAdded,
    required this.onUsageDeleted,
    required this.onShowUsageBottomSheet,
  });

  @override
  State<MaterialUsageScreen> createState() => _MaterialUsageScreenState();
}

class _MaterialUsageScreenState extends State<MaterialUsageScreen> {
  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color backgroundColor = Color.fromARGB(255, 249, 249, 253);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  String? selectedCategoryForReport;
  DateTime? startDateForReport;
  DateTime? endDateForReport;
  String? selectedSiteForReport;
  String? selectedMaterialForReport;

  final List<String> categoryList = [
    'Construction',
    'Reinforcement',
    'Masonry',
    'Aggregates',
    'Electrical',
    'Plumbing',
  ];

  String getMaterialName(String materialId) {
    final material = widget.materials.firstWhere(
      (m) => m.id == materialId,
      orElse: () => MaterialItem(
        id: '',
        name: 'Unknown Material',
        category: '',
        quantity: 0,
        unit: '',
        supplier: '',
        cost: 0,
        status: '',
        lastUpdated: DateTime.now(),
        siteId: '',
      ),
    );
    return material.name;
  }

  List<String> _getUniqueSitesFromUsage() {
    final usages = widget.materialUsagesNotifier.value;
    return usages.map((usage) => usage.site).toSet().toList();
  }

  void _showPdfFilterDialog(BuildContext context) {
    // Create local variables for the dialog
    String? tempCategory = selectedCategoryForReport;
    DateTime? tempStartDate = startDateForReport;
    DateTime? tempEndDate = endDateForReport;
    String? tempSite = selectedSiteForReport;
    String? tempMaterial = selectedMaterialForReport;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with drag handle
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

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6f88e2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          color: Color(0xFF6f88e2),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Filter PDF Report',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Filter
                          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: DropdownButton<String>(
                              value: tempCategory,
                              hint: const Text('All Categories'),
                              isExpanded: true,
                              underline: Container(),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Categories'),
                                ),
                                ...categoryList.map((category) => DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                )),
                              ],
                              onChanged: (value) {
                                setSheetState(() => tempCategory = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Date Range
                          const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: tempStartDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setSheetState(() => tempStartDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Start Date',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tempStartDate != null
                                              ? DateFormat('MMM dd, yyyy').format(tempStartDate!)
                                              : 'Select date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: tempStartDate != null ? Colors.black : Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: tempEndDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setSheetState(() => tempEndDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'End Date',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tempEndDate != null
                                              ? DateFormat('MMM dd, yyyy').format(tempEndDate!)
                                              : 'Select date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: tempEndDate != null ? Colors.black : Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Site Filter
                          const Text('Site', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: DropdownButton<String>(
                              value: tempSite,
                              hint: const Text('All Sites'),
                              isExpanded: true,
                              underline: Container(),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Sites'),
                                ),
                                ..._getUniqueSitesFromUsage().map((siteName) => DropdownMenuItem<String>(
                                  value: siteName,
                                  child: Text(siteName),
                                )),
                              ],
                              onChanged: (value) {
                                setSheetState(() => tempSite = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Material Filter
                          const Text('Material', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: DropdownButton<String>(
                              value: tempMaterial,
                              hint: const Text('All Materials'),
                              isExpanded: true,
                              underline: Container(),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Materials'),
                                ),
                                ...widget.materials.map((material) => DropdownMenuItem<String>(
                                  value: material.id,
                                  child: Text(material.name),
                                )),
                              ],
                              onChanged: (value) {
                                setSheetState(() => tempMaterial = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedCategoryForReport = tempCategory;
                                startDateForReport = tempStartDate;
                                endDateForReport = tempEndDate;
                                selectedSiteForReport = tempSite;
                                selectedMaterialForReport = tempMaterial;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6f88e2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPdfFilterAndDownload(BuildContext context) async {
    // Create local variables for the dialog
    String? tempCategory = selectedCategoryForReport;
    DateTime? tempStartDate = startDateForReport;
    DateTime? tempEndDate = endDateForReport;
    String? tempSite = selectedSiteForReport;
    String? tempMaterial = selectedMaterialForReport;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with drag handle
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

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6f88e2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          color: Color(0xFF6f88e2),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Filter PDF Report',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Filter
                          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: DropdownButton<String>(
                              value: tempCategory,
                              hint: const Text('All Categories'),
                              isExpanded: true,
                              underline: Container(),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Categories'),
                                ),
                                ...categoryList.map((category) => DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                )),
                              ],
                              onChanged: (value) {
                                setSheetState(() => tempCategory = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Date Range
                          const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: tempStartDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setSheetState(() => tempStartDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Start Date',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tempStartDate != null
                                              ? DateFormat('MMM dd, yyyy').format(tempStartDate!)
                                              : 'Select date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: tempStartDate != null ? Colors.black : Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: tempEndDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setSheetState(() => tempEndDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'End Date',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tempEndDate != null
                                              ? DateFormat('MMM dd, yyyy').format(tempEndDate!)
                                              : 'Select date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: tempEndDate != null ? Colors.black : Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Site Filter
                          const Text('Site', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: DropdownButton<String>(
                              value: tempSite,
                              hint: const Text('All Sites'),
                              isExpanded: true,
                              underline: Container(),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Sites'),
                                ),
                                ..._getUniqueSitesFromUsage().map((siteName) => DropdownMenuItem<String>(
                                  value: siteName,
                                  child: Text(siteName),
                                )),
                              ],
                              onChanged: (value) {
                                setSheetState(() => tempSite = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Material Filter
                          const Text('Material', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: DropdownButton<String>(
                              value: tempMaterial,
                              hint: const Text('All Materials'),
                              isExpanded: true,
                              underline: Container(),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Materials'),
                                ),
                                ...widget.materials.map((material) => DropdownMenuItem<String>(
                                  value: material.id,
                                  child: Text(material.name),
                                )),
                              ],
                              onChanged: (value) {
                                setSheetState(() => tempMaterial = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Apply filters and download PDF
                              setState(() {
                                selectedCategoryForReport = tempCategory;
                                startDateForReport = tempStartDate;
                                endDateForReport = tempEndDate;
                                selectedSiteForReport = tempSite;
                                selectedMaterialForReport = tempMaterial;
                              });
                              Navigator.pop(context);

                              // Now download the PDF with applied filters
                              final usages = widget.materialUsagesNotifier.value;
                              if (usages.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No usage data to export')),
                                );
                                return;
                              }

                              // Apply all filters
                              List<MaterialUsage> filteredUsages = usages;

                              // Date range filter
                              if (startDateForReport != null || endDateForReport != null) {
                                filteredUsages = filteredUsages.where((usage) {
                                  final usageDate = DateTime(usage.date.year, usage.date.month, usage.date.day);
                                  bool matches = true;

                                  if (startDateForReport != null) {
                                    final start = DateTime(startDateForReport!.year, startDateForReport!.month, startDateForReport!.day);
                                    matches = matches && usageDate.isAfter(start.subtract(const Duration(days: 1)));
                                  }

                                  if (endDateForReport != null) {
                                    final end = DateTime(endDateForReport!.year, endDateForReport!.month, endDateForReport!.day);
                                    matches = matches && usageDate.isBefore(end.add(const Duration(days: 1)));
                                  }

                                  return matches;
                                }).toList();
                              }

                              // Site filter
                              if (selectedSiteForReport != null) {
                                filteredUsages = filteredUsages.where((usage) => usage.site == selectedSiteForReport).toList();
                              }

                              // Material filter
                              if (selectedMaterialForReport != null) {
                                filteredUsages = filteredUsages.where((usage) => usage.materialId == selectedMaterialForReport).toList();
                              }

                              // Category filter
                              if (selectedCategoryForReport != null) {
                                filteredUsages = filteredUsages.where((usage) {
                                  final material = widget.materials.firstWhere(
                                    (m) => m.id == usage.materialId,
                                    orElse: () => MaterialItem(
                                      id: '',
                                      name: '',
                                      category: '',
                                      quantity: 0,
                                      unit: '',
                                      supplier: '',
                                      cost: 0,
                                      status: '',
                                      lastUpdated: DateTime.now(),
                                      siteId: '',
                                    ),
                                  );
                                  return material.category == selectedCategoryForReport;
                                }).toList();
                              }

                              if (filteredUsages.isEmpty) {
                                String filterDescription = 'No usage data found';
                                List<String> appliedFilters = [];

                                if (startDateForReport != null || endDateForReport != null) {
                                  appliedFilters.add('date range');
                                }
                                if (selectedSiteForReport != null) {
                                  appliedFilters.add('site');
                                }
                                if (selectedMaterialForReport != null) {
                                  appliedFilters.add('material');
                                }
                                if (selectedCategoryForReport != null) {
                                  appliedFilters.add('category');
                                }

                                if (appliedFilters.isNotEmpty) {
                                  filterDescription += ' for the selected ${appliedFilters.join(', ')}';
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(filterDescription),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              try {
                                final usageData = filteredUsages.map((usage) => {
                                  'materialName': getMaterialName(usage.materialId),
                                  'quantityUsed': usage.quantityUsed,
                                  'purpose': usage.purpose,
                                  'site': usage.site,
                                  'date': DateFormat('yyyy-MM-dd').format(usage.date),
                                }).toList();

                                // Generate dynamic report title based on applied filters
                                String reportTitle = 'Material Usage Report';
                                List<String> titleParts = [];

                                if (selectedCategoryForReport != null) {
                                  titleParts.add('$selectedCategoryForReport Materials');
                                }

                                if (startDateForReport != null || endDateForReport != null) {
                                  String dateRange = '';
                                  if (startDateForReport != null) {
                                    dateRange += DateFormat('MMM dd').format(startDateForReport!);
                                  }
                                  if (endDateForReport != null) {
                                    if (dateRange.isNotEmpty) dateRange += ' - ';
                                    dateRange += DateFormat('MMM dd, yyyy').format(endDateForReport!);
                                  }
                                  titleParts.add(dateRange);
                                }

                                if (selectedSiteForReport != null) {
                                  titleParts.add(selectedSiteForReport!);
                                }

                                if (selectedMaterialForReport != null) {
                                  final material = widget.materials.firstWhere(
                                    (m) => m.id == selectedMaterialForReport,
                                    orElse: () => MaterialItem(
                                      id: '',
                                      name: 'Unknown Material',
                                      category: '',
                                      quantity: 0,
                                      unit: '',
                                      supplier: '',
                                      cost: 0,
                                      status: '',
                                      lastUpdated: DateTime.now(),
                                      siteId: '',
                                    ),
                                  );
                                  titleParts.add(material.name);
                                }

                                if (titleParts.isNotEmpty) {
                                  reportTitle = '${titleParts.join(' - ')} Usage Report';
                                }

                                final siteName = selectedSiteForReport ?? (filteredUsages.isNotEmpty ? filteredUsages.first.site : 'All Sites');

                                final path = await ReportService.generateMaterialUsagePDF(usageData, siteName, customTitle: reportTitle);
                                await ReportService.openFile(path);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('PDF report saved successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error generating PDF: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6f88e2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Download PDF',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteUsage(MaterialUsage usage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material Usage'),
        content: const Text('Are you sure you want to delete this usage record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onUsageDeleted(usage);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usage deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
        title: const Text(
          'Material Usage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_outlined),
            onPressed: widget.onShowUsageBottomSheet,
            tooltip: 'Mark Usage',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showPdfFilterAndDownload(context),
            tooltip: 'Download PDF Report',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryColor, primaryDark, const Color(0xFF2a43a0)],
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
      body: ValueListenableBuilder<List<MaterialUsage>>(
        valueListenable: widget.materialUsagesNotifier,
        builder: (context, usages, child) {
          return usages.isEmpty
              ? Center(
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
                          'No material usage yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Mark usage to track material consumption',
                          style: TextStyle(fontSize: 16, color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: usages.length,
                  itemBuilder: (context, index) {
                    final usage = usages[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory,
                            color: primaryColor,
                          ),
                        ),
                        title: Text(
                          'Material Usage',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${usage.quantityUsed} used from ${getMaterialName(usage.materialId)}'),
                            const SizedBox(height: 4),
                            Text('Site: ${usage.site}'),
                            const SizedBox(height: 4),
                            Text('Purpose: ${usage.purpose}'),
                            const SizedBox(height: 4),
                            Text(DateFormat('yyyy-MM-dd').format(usage.date)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUsage(usage),
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}