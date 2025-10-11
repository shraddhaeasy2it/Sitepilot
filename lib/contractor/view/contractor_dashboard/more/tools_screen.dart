import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';

class ToolsScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  const ToolsScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class ToolItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String condition;
  final double cost;
  final String status;
  final DateTime lastUpdated;
  final String siteId;
  ToolItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.condition,
    required this.cost,
    required this.status,
    required this.lastUpdated,
    required this.siteId,
  });
}

class _ToolsScreenState extends State<ToolsScreen> {
  List<ToolItem> tools = [];
  bool isLoading = false;
  String searchQuery = '';
  String? selectedSiteFilter;
  static const Color primaryColor = Color(0xFF2a43a0);
  static const Color primaryDark = Color.fromARGB(255, 53, 86, 206);
  static const Color backgroundColor = Color.fromARGB(255, 249, 249, 253);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  final List<String> categoryList = [
    'Power Tools',
    'Hand Tools',
    'Safety Equipment',
    'Measuring Tools',
    'Heavy Machinery',
  ];

  @override
  void initState() {
    super.initState();
    selectedSiteFilter = widget.selectedSiteId;
    _loadTools();
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

  void _loadTools() {
    setState(() => isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        tools = [
          ToolItem(
            id: '1',
            name: 'Hammer Drill',
            category: 'Power Tools',
            quantity: 5,
            condition: 'Good',
            cost: 150.0,
            status: 'Available',
            lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
            siteId: widget.sites.isNotEmpty ? widget.sites.first.id : '',
          ),
          ToolItem(
            id: '2',
            name: 'Safety Helmets',
            category: 'Safety Equipment',
            quantity: 20,
            condition: 'Excellent',
            cost: 25.0,
            status: 'In Use',
            lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
            siteId: widget.sites.isNotEmpty ? widget.sites.first.id : '',
          ),
          ToolItem(
            id: '3',
            name: 'Measuring Tape',
            category: 'Measuring Tools',
            quantity: 10,
            condition: 'Good',
            cost: 15.0,
            status: 'Available',
            lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
            siteId: widget.sites.length > 1 ? widget.sites[1].id : '',
          ),
        ];
        isLoading = false;
      });
    });
  }

  List<ToolItem> get filteredTools {
    var filtered = tools;
    if (selectedSiteFilter != null) {
      filtered = filtered
          .where((tool) => tool.siteId == selectedSiteFilter)
          .toList();
    }
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (tool) =>
                tool.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                tool.category.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
          )
          .toList();
    }
    return filtered;
  }

  void _showToolSheet({ToolItem? existingTool}) {
    final isEditing = existingTool != null;
    final nameController = TextEditingController(
      text: isEditing ? existingTool.name : '',
    );
    final quantityController = TextEditingController(
      text: isEditing ? existingTool.quantity.toString() : '',
    );
    final costController = TextEditingController(
      text: isEditing ? existingTool.cost.toString() : '',
    );
    String selectedCategory = isEditing
        ? existingTool.category
        : categoryList.first;
    
    String selectedCondition = isEditing ? existingTool.condition : 'Good';
    String selectedStatus = isEditing ? existingTool.status : 'Available';
    String? selectedSite = isEditing
        ? existingTool.siteId
        : (widget.sites.isNotEmpty ? widget.sites.first.id : null);

    bool nameError = false;
    bool quantityError = false;
    bool costError = false;
    bool siteError = false;

    void validateForm(StateSetter setSheetState) {
      setSheetState(() {
        nameError = nameController.text.isEmpty;
        quantityError = quantityController.text.isEmpty;
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
                                  isEditing ? Icons.edit : Icons.build,
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
                                          ? 'Edit Tool'
                                          : 'Add New Tool',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      isEditing
                                          ? 'Update tool information'
                                          : 'Enter tool details below',
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
                            label: 'Tool Name',
                            hint: 'e.g. Hammer Drill, Safety Helmet',
                            icon: Icons.build_outlined,
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
                          _buildEnhancedTextField(
                            controller: quantityController,
                            label: 'Quantity',
                            hint: 'e.g. 5, 10',
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
                          const SizedBox(height: 20),
                          _buildEnhancedDropdown(
                            value: selectedCondition,
                            label: 'Condition',
                            icon: Icons.health_and_safety_outlined,
                            items: ['Excellent', 'Good', 'Fair', 'Poor'],
                            onChanged: (val) => selectedCondition = val!,
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedTextField(
                            controller: costController,
                            label: 'Cost per Unit',
                            hint: 'e.g. 150.00, 25.50',
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
                            items: ['Available', 'In Use', 'Under Maintenance', 'Lost/Damaged'],
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
                                isEditing ? 'Update Tool' : 'Add Tool',
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
                                final tool = ToolItem(
                                  id: isEditing
                                      ? existingTool.id
                                      : DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                  name: nameController.text,
                                  category: selectedCategory,
                                  quantity:
                                      int.tryParse(
                                        quantityController.text,
                                      ) ??
                                      0,
                                  condition: selectedCondition,
                                  cost:
                                      double.tryParse(costController.text) ?? 0,
                                  status: selectedStatus,
                                  lastUpdated: DateTime.now(),
                                  siteId: selectedSite!,
                                );
                                setState(() {
                                  if (isEditing) {
                                    final index = tools.indexWhere(
                                      (t) => t.id == existingTool.id,
                                    );
                                    tools[index] = tool;
                                  } else {
                                    tools.add(tool);
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
                                              ? 'Tool updated successfully'
                                              : 'Tool added successfully',
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
      case 'Available':
        return Colors.green;
      case 'In Use':
        return const Color.fromARGB(255, 23, 121, 201);
      case 'Under Maintenance':
        return Colors.orange;
      case 'Lost/Damaged':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Power Tools':
        return Icons.electrical_services;
      case 'Hand Tools':
        return Icons.build;
      case 'Safety Equipment':
        return Icons.health_and_safety;
      case 'Measuring Tools':
        return Icons.straighten;
      case 'Heavy Machinery':
        return Icons.agriculture;
      default:
        return Icons.build;
    }
  }

  String getSiteName(String siteId) {
    return widget.sites
        .firstWhere(
          (site) => site.id == siteId,
          orElse: () =>
              Site(id: '', name: 'Unknown Site', address: '', companyId: ''),
        )
        .name;
  }

  // Method to show delete confirmation dialog
  void _showDeleteConfirmationDialog(ToolItem tool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tool'),
        content: Text('Are you sure you want to delete ${tool.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTool(tool);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Method to handle tool deletion
  void _deleteTool(ToolItem tool) {
    final index = tools.indexOf(tool);
    setState(() {
      tools.remove(tool);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 12),
            Text('${tool.name} deleted successfully'),
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
              tools.insert(index, tool);
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
                        hintText: 'Search tools...',
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
                          hintText: 'Search tools...',
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

  Widget _buildToolCard(ToolItem tool) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: () => _showToolSheet(existingTool: tool),
                splashColor: primaryColor.withOpacity(0.1),
                highlightColor: Colors.transparent,
                child: Container(
                 
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon and name
                        Row(
                          children: [
                            // Category icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                getCategoryIcon(tool.category),
                                color: primaryColor,
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Tool name and category
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tool.name,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 18 : 20,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tool.category,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: primaryColor.withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(tool.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tool.status,
                                style: TextStyle(
                                  color: getStatusColor(tool.status),
                                  fontSize: isSmallScreen ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),

                        // Info grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: isSmallScreen ? 3.0 : 3.5,
                          children: [
                            // Site
                            _buildInfoItem(
                              Icons.construction,
                              'Site',
                              getSiteName(tool.siteId),
                              primaryColor,
                              isSmallScreen: isSmallScreen,
                            ),
                            
                            // Quantity
                            _buildInfoItem(
                              Icons.inventory_2,
                              'Quantity',
                              '${tool.quantity}',
                              Colors.blue,
                              isSmallScreen: isSmallScreen,
                            ),
                            
                            // Condition
                            _buildInfoItem(
                              Icons.health_and_safety,
                              'Condition',
                              tool.condition,
                              Colors.orange,
                              isSmallScreen: isSmallScreen,
                            ),
                            
                            // Cost
                            _buildInfoItem(
                              Icons.currency_rupee,
                              'Cost',
                              '₹${tool.cost.toStringAsFixed(2)}',
                              Colors.green,
                              isSmallScreen: isSmallScreen,
                            ),
                          ],
                        ),

                        Row(
                     
                          children: [
                            // Last updated
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: isSmallScreen ? 12 : 14,
                                    color: textSecondary.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Updated ${DateFormat('MMM dd, yyyy').format(tool.lastUpdated)}',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 10 : 11,
                                        color: textSecondary.withOpacity(0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Delete button
                            GestureDetector(
                              onTap: () => _showDeleteConfirmationDialog(tool),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: isSmallScreen ? 20 : 22,
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
            ),
          ),
        );
      },
    );
  }

  // Modern info item with clean design
  Widget _buildInfoItem(IconData icon, String label, String value, Color color, {bool isSmallScreen = false}) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 14 : 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 10,
                    color: textSecondary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
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
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    primaryDark.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.build_outlined,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No tools found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              searchQuery.isEmpty && selectedSiteFilter == null
                  ? 'Start by adding your first tool'
                  : 'Try adjusting your search criteria',
              style: TextStyle(fontSize: 16, color: textSecondary),
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
        elevation: 0,
        toolbarHeight: 80.h,
        backgroundColor: Colors.transparent,
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Assets/Tools - ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize:20,
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
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2a43a0),
                strokeWidth: 3,
              ),
            )
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: filteredTools.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: filteredTools.length,
                          itemBuilder: (context, index) {
                            final tool = filteredTools[index];
                            return _buildToolCard(tool);
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
              color: Color(0xFF2a43a0).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showToolSheet(),
          backgroundColor: Color(0xFF2a43a0),
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Tool',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
    );
  }
}