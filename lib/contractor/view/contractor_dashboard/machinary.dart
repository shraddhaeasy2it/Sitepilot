import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/admin/models/Allmachinery_model.dart' hide Site;
import 'package:ecoteam_app/admin/models/MachineryCategory_model.dart';
import 'package:ecoteam_app/admin/services/Allmachinery_services.dart';
import 'package:ecoteam_app/admin/services/machineryCategory_services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AllMachineryScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  const AllMachineryScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<AllMachineryScreen> createState() => _MachineryScreenState();
}

class _MachineryScreenState extends State<AllMachineryScreen> {
  final MachineryService _machineryService = MachineryService();
  final MachineryCategoryService _categoryService = MachineryCategoryService();
  List<AllMachinery> _machineries = [];
  List<AllMachinery> _filteredMachineries = [];
  List<MachineryCategory> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedSiteFilter;

  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color backgroundColor = Color.fromARGB(255, 249, 249, 253);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _selectedSiteFilter = widget.selectedSiteId;
    _loadMachineries();
    _loadCategories();
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

  Future<void> _loadMachineries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _machineryService.getMachineries();
      setState(() {
        _machineries = response.data.reversed.toList();
        _filterMachineries();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load machineries: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load categories: $e');
    }
  }

  void _filterMachineries() {
    var filtered = _machineries;

    // Filter by site
    if (_selectedSiteFilter != null && _selectedSiteFilter!.isNotEmpty) {
      filtered = filtered.where((machinery) {
        return machinery.siteId == int.tryParse(_selectedSiteFilter!) ||
            (widget.sites.isNotEmpty &&
                widget.sites.any(
                  (site) =>
                      site.id == _selectedSiteFilter &&
                      site.name == machinery.ownedBy,
                ));
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((machinery) {
        return machinery.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            machinery.vehicleNumber.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            machinery.modelNumber.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            machinery.manufacturer.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    setState(() {
      _filteredMachineries = filtered;
    });
  }

  String _getCategoryName(int categoryId) {
    final category = _categories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => MachineryCategory(
        id: 0,
        name: 'Unknown Category',
        description: '',
        createdBy: 0,
        workspaceId: 0,
        isActive: 1,
        status: '0',
      ),
    );
    return category.name;
  }

  String _getSiteName(int siteId) {
    final site = widget.sites.firstWhere(
      (site) => site.id == siteId.toString(),
      orElse: () => Site(id: '', name: 'Unknown Site', companyId: ''),
    );
    return site.name;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'maintenance':
        return 'Under Maintenance';
      default:
        return status;
    }
  }

  IconData _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('excavator') ||
        lowerCategory.contains('loader')) {
      return Icons.directions_car;
    } else if (lowerCategory.contains('crane') ||
        lowerCategory.contains('lift')) {
      return Icons.height;
    } else if (lowerCategory.contains('mixer') ||
        lowerCategory.contains('concrete')) {
      return Icons.business;
    } else if (lowerCategory.contains('generator') ||
        lowerCategory.contains('power')) {
      return Icons.bolt;
    } else if (lowerCategory.contains('compactor') ||
        lowerCategory.contains('roller')) {
      return Icons.tire_repair;
    } else {
      return Icons.build;
    }
  }

  // Method to show delete confirmation dialog
  void _showDeleteConfirmationDialog(AllMachinery machinery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Machinery'),
        content: Text('Are you sure you want to delete ${machinery.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMachinery(machinery);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Method to handle machinery deletion
  Future<void> _deleteMachinery(AllMachinery machinery) async {
    if (machinery.id == null) return;

    try {
      await _machineryService.deleteMachinery(machinery.id!);
      final index = _machineries.indexOf(machinery);
      setState(() {
        _machineries.remove(machinery);
        _filterMachineries();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete, color: Colors.white),
              const SizedBox(width: 12),
              Text('${machinery.name} deleted successfully'),
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
                _machineries.insert(index, machinery);
                _filterMachineries();
              });
            },
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to delete machinery: $e');
    }
  }

  // Method to show transfer bottom sheet
  void _showTransferSheet(AllMachinery machinery) {
    // Get current site name
    final fromSiteName = _getSiteName(machinery.siteId);
    
    // Initialize date controller with current date
    final transferDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    
    String? selectedToSite;
    List<Site> allSites = [];
    bool isLoadingSites = true;
    String transferError = '';

    // Fetch sites by workspace ID (workspace_id is 3 based on your API docs)
    Future<void> _loadSites() async {
      try {
        // Based on your API documentation, workspace_id is 3
        final response = await http.get(
          Uri.parse('http://sitepilot.easy2it.in/api/general-transfer?site_id=3&workspace_id=3&transfer_type=machinery'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['to_site_id'] != null) {
            final Map<String, dynamic> siteMap = data['to_site_id'];
            allSites = siteMap.entries.map((entry) {
              return Site(
                id: entry.key,
                name: entry.value.toString(),
                companyId: '',
              );
            }).toList();
            
            // Remove current site from the list
            allSites.removeWhere((site) => site.id == machinery.siteId.toString());
          }
        }
      } catch (e) {
        _showErrorSnackBar('Failed to load sites: $e');
      } finally {
        if (mounted) {
          setState(() {
            isLoadingSites = false;
          });
        }
      }
    }

    // Initialize site loading
    _loadSites();

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
                                  Icons.move_to_inbox,
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
                                      'Transfer Machinery',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Transfer ${machinery.name} to another site',
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

                          // Transfer Type (Auto-selected)
                          _buildReadOnlyField(
                            label: 'Transfer Type',
                            value: 'Machinery',
                            icon: Icons.category,
                          ),
                          const SizedBox(height: 20),

                          // Machinery Name (Auto-selected)
                          _buildReadOnlyField(
                            label: 'Machinery',
                            value: machinery.name,
                            icon: Icons.build,
                          ),
                          const SizedBox(height: 20),

                          // From Site (Auto-selected)
                          _buildReadOnlyField(
                            label: 'From Site',
                            value: fromSiteName,
                            icon: Icons.location_on,
                          ),
                          const SizedBox(height: 20),

                          // Transfer Date
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setSheetState(() {
                                  transferDateController.text = DateFormat('yyyy-MM-dd').format(date);
                                });
                              }
                            },
                            child: _buildDateField(
                              controller: transferDateController,
                              label: 'Transfer Date',
                              icon: Icons.calendar_today,
                              hasError: false,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // To Site Dropdown
                          isLoadingSites
                              ? Container(
                                  padding: const EdgeInsets.all(16),
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
                                  child: const Center(
                                    child: CircularProgressIndicator(color: primaryColor),
                                  ),
                                )
                              : _buildSiteDropdown(
                                  value: selectedToSite,
                                  label: 'To Site',
                                  icon: Icons.location_on,
                                  items: allSites,
                                  hasError: transferError.isNotEmpty,
                                  onChanged: (val) {
                                    setSheetState(() {
                                      selectedToSite = val;
                                      transferError = '';
                                    });
                                  },
                                ),
                          
                          if (transferError.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              transferError,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 32),

                          // Transfer Button
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
                                Icons.move_to_inbox,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: const Text(
                                'Transfer Machinery',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () async {
                                if (selectedToSite == null || selectedToSite!.isEmpty) {
                                  setSheetState(() {
                                    transferError = 'Please select a destination site';
                                  });
                                  return;
                                }

                                try {
                                  // Prepare transfer data
                                  final transferData = {
                                    "transfer_type": "machinery",
                                    "machinery_id": machinery.id,
                                    "transfer_date": transferDateController.text,
                                    "from_site_id": machinery.siteId,
                                    "to_site_id": int.parse(selectedToSite!),
                                    "created_by": machinery.createdBy,
                                  };

                                  // Make API call to create transfer
                                  final response = await http.post(
                                    Uri.parse('http://sitepilot.easy2it.in/api/general-transfers'),
                                    headers: {'Content-Type': 'application/json'},
                                    body: json.encode(transferData),
                                  );

                                  if (response.statusCode == 200 || response.statusCode == 201) {
                                    final result = json.decode(response.body);
                                    Navigator.pop(context);
                                    _showSuccessSnackBar('Machinery transferred successfully');
                                    
                                    // Refresh machinery list
                                    await _loadMachineries();
                                  } else {
                                    setSheetState(() {
                                      transferError = 'Transfer failed. Please try again.';
                                    });
                                  }
                                } catch (e) {
                                  setSheetState(() {
                                    transferError = 'Transfer failed: $e';
                                  });
                                }
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

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMachinerySheet({AllMachinery? existingMachinery}) {
    final isEditing = existingMachinery != null;

    // Create controllers with existing values if editing
    final nameController = TextEditingController(
      text: isEditing ? existingMachinery.name : '',
    );
    final vehicleNumberController = TextEditingController(
      text: isEditing ? existingMachinery.vehicleNumber : '',
    );
    final modelNumberController = TextEditingController(
      text: isEditing ? existingMachinery.modelNumber : '',
    );
    final manufacturerController = TextEditingController(
      text: isEditing ? existingMachinery.manufacturer : '',
    );
    final capacityController = TextEditingController(
      text: isEditing ? existingMachinery.capacity : '',
    );
    final purchaseDateController = TextEditingController(
      text: isEditing ? existingMachinery.purchaseDate : '',
    );
    final maintenanceScheduleController = TextEditingController(
      text: isEditing ? existingMachinery.maintenanceSchedule : '',
    );
    final descriptionController = TextEditingController(
      text: isEditing ? (existingMachinery.description ?? '') : '',
    );
    final remarksController = TextEditingController(
      text: isEditing ? (existingMachinery.remarks ?? '') : '',
    );

    // Initialize values
    String? selectedCategory = isEditing && existingMachinery.categoryId != 0
        ? existingMachinery.categoryId.toString()
        : (_categories.isNotEmpty ? _categories.first.id.toString() : null);

    String selectedStatus = isEditing
        ? existingMachinery.operationalStatus
        : 'active';
    String? selectedSite = isEditing && existingMachinery.siteId != 0
        ? existingMachinery.siteId.toString()
        : (widget.sites.isNotEmpty ? widget.sites.first.id : null);

    DateTime? selectedPurchaseDate;
    DateTime? selectedMaintenanceDate;

    // Parse dates if they exist
    if (isEditing && existingMachinery.purchaseDate.isNotEmpty) {
      selectedPurchaseDate = DateTime.tryParse(existingMachinery.purchaseDate);
      if (selectedPurchaseDate != null) {
        purchaseDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedPurchaseDate);
      }
    }

    if (isEditing && existingMachinery.maintenanceSchedule.isNotEmpty) {
      selectedMaintenanceDate = DateTime.tryParse(
        existingMachinery.maintenanceSchedule,
      );
      if (selectedMaintenanceDate != null) {
        maintenanceScheduleController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedMaintenanceDate);
      }
    }

    bool nameError = false;
    bool vehicleNumberError = false;
    bool categoryError = false;
    bool siteError = false;

    void validateForm(StateSetter setSheetState) {
      setSheetState(() {
        nameError = nameController.text.isEmpty;
        vehicleNumberError = vehicleNumberController.text.isEmpty;
        categoryError = selectedCategory == null;
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
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                                          ? 'Edit Machinery'
                                          : 'Add New Machinery',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      isEditing
                                          ? 'Update machinery information'
                                          : 'Enter machinery details below',
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

                          // Name Field
                          _buildEnhancedTextField(
                            controller: nameController,
                            label: 'Machinery Name',
                            hint: 'e.g. Excavator, Crane, Mixer',
                            icon: Icons.build,
                            isRequired: true,
                            hasError: nameError,
                            onChanged: (value) {
                              if (value.isNotEmpty && nameError) {
                                setSheetState(() => nameError = false);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // Category Dropdown
                          _buildCategoryDropdown(
                            value: selectedCategory,
                            label: 'Category',
                            icon: Icons.category_outlined,
                            items: _categories,
                            hasError: categoryError,
                            onChanged: (val) {
                              selectedCategory = val;
                              if (val != null && categoryError) {
                                setSheetState(() => categoryError = false);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // Vehicle Number
                          _buildEnhancedTextField(
                            controller: vehicleNumberController,
                            label: 'Vehicle Number',
                            hint: 'e.g. MH-12-AB-1234',
                            icon: Icons.directions_car,
                            isRequired: true,
                            hasError: vehicleNumberError,
                            onChanged: (value) {
                              if (value.isNotEmpty && vehicleNumberError) {
                                setSheetState(() => vehicleNumberError = false);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // Model Number
                          _buildEnhancedTextField(
                            controller: modelNumberController,
                            label: 'Model Number',
                            hint: 'e.g. CAT-320, JCB-3DX',
                            icon: Icons.tag,
                            isRequired: true,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 20),

                          // Manufacturer
                          _buildEnhancedTextField(
                            controller: manufacturerController,
                            label: 'Manufacturer',
                            hint: 'e.g. Caterpillar, JCB, Volvo',
                            icon: Icons.factory,
                            isRequired: true,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 20),

                          // Purchase Date
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    selectedPurchaseDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setSheetState(() {
                                  selectedPurchaseDate = date;
                                  purchaseDateController.text = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(date);
                                });
                              }
                            },
                            child: _buildDateField(
                              controller: purchaseDateController,
                              label: 'Purchase Date',
                              icon: Icons.calendar_today,
                              hasError: false,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Maintenance Schedule
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    selectedMaintenanceDate ??
                                    DateTime.now().add(
                                      const Duration(days: 30),
                                    ),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setSheetState(() {
                                  selectedMaintenanceDate = date;
                                  maintenanceScheduleController.text =
                                      DateFormat('yyyy-MM-dd').format(date);
                                });
                              }
                            },
                            child: _buildDateField(
                              controller: maintenanceScheduleController,
                              label: 'Maintenance Schedule',
                              icon: Icons.schedule,
                              hasError: false,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Capacity
                          _buildEnhancedTextField(
                            controller: capacityController,
                            label: 'Capacity',
                            hint: 'e.g. 20 Tons, 10 Cubic Meters',
                            icon: Icons.scale,
                            isRequired: true,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 20),

                          // Status Dropdown
                          _buildStatusDropdown(
                            value: selectedStatus,
                            label: 'Operational Status',
                            icon: Icons.info_outline,
                            onChanged: (val) => selectedStatus = val!,
                          ),
                          const SizedBox(height: 20),

                          // Description
                          _buildEnhancedTextField(
                            controller: descriptionController,
                            label: 'Description',
                            hint: 'Additional details about the machinery',
                            icon: Icons.description,
                            isRequired: false,
                            maxLines: 3,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 20),

                          // Remarks
                          _buildEnhancedTextField(
                            controller: remarksController,
                            label: 'Remarks',
                            hint: 'Any special remarks or notes',
                            icon: Icons.note,
                            isRequired: false,
                            maxLines: 2,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 32),

                          // Save Button
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
                                    ? 'Update Machinery'
                                    : 'Add Machinery',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () async {
                                validateForm(setSheetState);
                                if (nameError ||
                                    vehicleNumberError ||
                                    categoryError ||
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

                                try {
                                  final machinery = AllMachinery(
                                    id: isEditing ? existingMachinery.id : null,
                                    name: nameController.text,
                                    categoryId: int.parse(selectedCategory!),
                                    siteId: int.parse(selectedSite!),
                                    modelNumber: modelNumberController.text,
                                    manufacturer: manufacturerController.text,
                                    purchaseDate: purchaseDateController.text,
                                    capacity: capacityController.text,
                                    maintenanceSchedule:
                                        maintenanceScheduleController.text,
                                    remarks: remarksController.text.isNotEmpty
                                        ? remarksController.text
                                        : null,
                                    description:
                                        descriptionController.text.isNotEmpty
                                        ? descriptionController.text
                                        : null,
                                    vehicleNumber: vehicleNumberController.text,
                                    ownedBy: 'self.company',
                                    supplierId: null,
                                    operationalStatus: selectedStatus,
                                    createdBy: 1,
                                    workspaceId: 1,
                                    status: '0',
                                  );

                                  if (isEditing) {
                                    await _machineryService.updateMachinery(
                                      machinery,
                                    );
                                  } else {
                                    await _machineryService.createMachinery(
                                      machinery,
                                    );
                                  }

                                  await _loadMachineries();
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
                                                ? 'Machinery updated successfully'
                                                : 'Machinery added successfully',
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
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Failed to update machinery: $e'
                                            : 'Failed to add machinery: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
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

  Widget _buildCategoryDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<MachineryCategory> items,
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
              (category) => DropdownMenuItem(
                value: category.id.toString(),
                child: Text(category.name),
              ),
            )
            .toList(),
        onChanged: onChanged,
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
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Select Destination Site'),
          ),
          ...items.map(
            (site) => DropdownMenuItem(
              value: site.id,
              child: Text(site.name),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatusDropdown({
    required String value,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    final statusOptions = [
      {'value': 'active', 'label': 'Active'},
      {'value': 'inactive', 'label': 'Inactive'},
      {'value': 'maintenance', 'label': 'Under Maintenance'},
    ];

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
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
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
        items: statusOptions
            .map(
              (status) => DropdownMenuItem(
                value: status['value'],
                child: Text(status['label']!),
              ),
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
    int maxLines = 1,
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
        maxLines: maxLines,
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
            color: hasError
                ? Colors.red
                : const Color.fromARGB(255, 105, 110, 126),
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

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool hasError = false,
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
        readOnly: true,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Select date',
          prefixIcon: Icon(
            icon,
            color: hasError
                ? Colors.red
                : const Color.fromARGB(255, 105, 110, 126),
            size: 20,
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
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
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _filterMachineries();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search machineries...',
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _filterMachineries();
                                  });
                                },
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
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _filterMachineries();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search machineries...',
                          prefixIcon: Icon(Icons.search, color: primaryColor),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _filterMachineries();
                                    });
                                  },
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
                            value: _selectedSiteFilter,
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
                                _selectedSiteFilter = value;
                                _filterMachineries();
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

  Widget _buildMachineryCard(AllMachinery machinery) {
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
              onTap: () => _showMachinerySheet(existingMachinery: machinery),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with icon, name, category, status, transfer and delete buttons
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(
                              _getCategoryName(machinery.categoryId),
                            ),
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
                                machinery.name,
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
                                _getCategoryName(machinery.categoryId),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status, Transfer and Delete buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  machinery.operationalStatus,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(
                                    machinery.operationalStatus,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _getStatusText(machinery.operationalStatus),
                                style: TextStyle(
                                  color: _getStatusColor(
                                    machinery.operationalStatus,
                                  ),
                                  fontSize: isSmallScreen ? 9 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Transfer button
                            GestureDetector(
                              onTap: () {
                                _showTransferSheet(machinery);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.move_to_inbox,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete button
                            GestureDetector(
                              onTap: () {
                                _showDeleteConfirmationDialog(machinery);
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

                    // First row: Vehicle Number and Model side by side
                    Row(
                      children: [
                        Expanded(
                          child: _buildMaterialStyleInfoItem(
                            icon: Icons.directions_car,
                            label: 'Vehicle No',
                            value: machinery.vehicleNumber,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMaterialStyleInfoItem(
                            icon: Icons.tag,
                            label: 'Model',
                            value: machinery.modelNumber,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Second row: Manufacturer and Capacity side by side
                    Row(
                      children: [
                        Expanded(
                          child: _buildMaterialStyleInfoItem(
                            icon: Icons.factory,
                            label: 'Manufacturer',
                            value: machinery.manufacturer,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMaterialStyleInfoItem(
                            icon: Icons.scale,
                            label: 'Capacity',
                            value: machinery.capacity,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Third row: Purchase Date and Maintenance Schedule side by side
                    Row(
                      children: [
                        Expanded(
                          child: machinery.purchaseDate.isNotEmpty
                              ? _buildMaterialStyleInfoItem(
                                  icon: Icons.calendar_today,
                                  label: 'Purchased',
                                  value: DateFormat('MMM yyyy').format(
                                    DateTime.tryParse(machinery.purchaseDate) ??
                                        DateTime.now(),
                                  ),
                                  isSmallScreen: isSmallScreen,
                                )
                              : _buildMaterialStyleInfoItem(
                                  icon: Icons.calendar_today,
                                  label: 'Purchased',
                                  value: 'Not specified',
                                  isSmallScreen: isSmallScreen,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: machinery.maintenanceSchedule.isNotEmpty
                              ? _buildMaterialStyleInfoItem(
                                  icon: Icons.schedule,
                                  label: 'Maintenance',
                                  value: DateFormat('MMM yyyy').format(
                                    DateTime.tryParse(
                                          machinery.maintenanceSchedule,
                                        ) ??
                                        DateTime.now(),
                                  ),
                                  isSmallScreen: isSmallScreen,
                                )
                              : _buildMaterialStyleInfoItem(
                                  icon: Icons.schedule,
                                  label: 'Maintenance',
                                  value: 'Not scheduled',
                                  isSmallScreen: isSmallScreen,
                                ),
                        ),
                      ],
                    ),

                    if (machinery.description != null &&
                        machinery.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.description,
                              size: 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                machinery.description!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method for material-style info items (matches material screen exactly)
  Widget _buildMaterialStyleInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 14 : 16,
            color: const Color.fromARGB(255, 109, 109, 109),
          ),
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
                const SizedBox(height: 2),
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
              child: Icon(Icons.build, size: 64, color: primaryColor),
            ),
            const SizedBox(height: 24),
            const Text(
              'No machinery found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty && _selectedSiteFilter == null
                  ? 'Start by adding your first machinery'
                  : 'Try adjusting your search criteria',
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Machinery Management',
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
          IconButton(onPressed: _showMachinerySheet, icon: Icon(Icons.add)),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMachineries,
            tooltip: 'Refresh',
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
      body: _isLoading
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
                  child: _filteredMachineries.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadMachineries,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: _filteredMachineries.length,
                            itemBuilder: (context, index) {
                              final machinery = _filteredMachineries[index];
                              return _buildMachineryCard(machinery);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}