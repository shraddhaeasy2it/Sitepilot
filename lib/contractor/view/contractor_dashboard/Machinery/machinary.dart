import 'dart:async';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Machinery/DPR_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Machinery/machineryCategory_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecoteam_app/admin/services/transfer_machinery_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/admin/models/Allmachinery_model.dart' hide Site;
import 'package:ecoteam_app/admin/models/MachineryCategory_model.dart';
import 'package:ecoteam_app/admin/services/Allmachinery_services.dart';
import 'package:ecoteam_app/admin/services/machineryCategory_services.dart';
import 'dart:convert';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/profilepage.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';

class AllMachineryScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final int? workspaceId;
  final String? currentCompany;
  final int? userId;

  const AllMachineryScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    this.workspaceId,
    this.currentCompany,
    this.userId,
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
      // Refresh permissions in background
      final companyProvider = Provider.of<CompanySiteProvider>(
        context,
        listen: false,
      );
      companyProvider.refreshPermissions();

      final dynamicWorkspaceId = int.tryParse(
        companyProvider.selectedCompanyId ?? '',
      );
      final dynamicSiteId = int.tryParse(widget.selectedSiteId ?? '0') ?? 0;

      print(
        'DEBUG: Loading Machineries - WorkspaceID: $dynamicWorkspaceId, SiteID: $dynamicSiteId',
      );

      final response = await _machineryService.getMachineries(
        workspaceId: dynamicWorkspaceId,
        siteId: dynamicSiteId,
      );
      setState(() {
        _machineries = response.data.reversed.toList();
        _filterMachineries();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load machineries: $e');
      }
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
        createdBy: 9,
        workspaceId: 3,
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
      case 'breakdown':
        return Colors.orange; // or Colors.amber[700]
      case 'scrap':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'breakdown':
        return 'Breakdown';
      case 'scrap':
        return 'Scrap';
      default:
        return status;
    }
  }

  IconData _getCategoryFaIcon(String category) {
    final lower = category.toLowerCase();

    if (lower.contains('excavator') ||
        lower.contains('digger') ||
        lower.contains('backhoe')) {
      return FontAwesomeIcons.personDigging;
    } else if (lower.contains('loader') ||
        lower.contains('bulldozer') ||
        lower.contains('dozer')) {
      return FontAwesomeIcons.tractor;
    } else if (lower.contains('crane') ||
        lower.contains('lift') ||
        lower.contains('hoist')) {
      return FontAwesomeIcons.towerObservation;
    } else if (lower.contains('mixer') ||
        lower.contains('cement') ||
        lower.contains('concrete')) {
      return FontAwesomeIcons.truckMonster;
    } else if (lower.contains('truck') || lower.contains('dumper')) {
      return FontAwesomeIcons.truckPickup;
    } else if (lower.contains('generator') || lower.contains('power')) {
      return FontAwesomeIcons.boltLightning;
    }

    return FontAwesomeIcons.truckPickup;
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

  void _showTransferSheet(AllMachinery machinery) {
    final TextEditingController transferDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    String? selectedToSite;
    bool loading = true;
    String error = '';
    Map<String, String> siteMap = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> loadSites() async {
              try {
                final result = await TransfermachineryService.fetchToSites(
                  siteId: machinery.siteId,
                  workspaceId: machinery.workspaceId,
                  machineryId: machinery.id!,
                  userId: 10,
                );

                /// ❌ remove FROM SITE
                result.remove(machinery.siteId.toString());

                setSheetState(() {
                  siteMap = result;
                  loading = false;
                });
              } catch (e) {
                setSheetState(() {
                  loading = false;
                  error = 'Failed to load sites';
                });
              }
            }

            if (loading) loadSites();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// 🔹 TITLE
                    const Text(
                      'Transfer Machinery',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// 🔒 TRANSFER TYPE (READ-ONLY)
                    _readOnlyField(
                      label: 'Transfer Type',
                      value: 'Machinery',
                      icon: Icons.swap_horiz,
                    ),

                    /// 🔒 MACHINERY NAME
                    _readOnlyField(
                      label: 'Machinery',
                      value: machinery.name,
                      icon: Icons.build,
                    ),

                    /// 🔒 FROM SITE
                    _readOnlyField(
                      label: 'From Site',
                      value: _getSiteName(machinery.siteId),
                      icon: Icons.location_on,
                    ),

                    /// 🔒 TRANSFER DATE
                    _readOnlyTextField(
                      controller: transferDateController,
                      label: 'Transfer Date',
                      icon: Icons.calendar_today,
                    ),

                    const SizedBox(height: 16),

                    /// ✅ TO SITE (ONLY EDITABLE FIELD)
                    if (loading)
                      const CircularProgressIndicator()
                    else if (error.isNotEmpty)
                      Text(error, style: const TextStyle(color: Colors.red))
                    else
                      DropdownButtonFormField<String>(
                        isExpanded: true, // ⭐ IMPORTANT
                        hint: const Text('Select To Site'),
                        value: selectedToSite,
                        items: siteMap.entries.map((e) {
                          return DropdownMenuItem<String>(
                            value: e.key,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis, // ⭐ FIX
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setSheetState(() {
                            selectedToSite = val;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    /// ✅ SUBMIT
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedToSite == null
                            ? null
                            : () async {
                                try {
                                  await TransfermachineryService.createTransfer(
                                    {
                                      'transfer_type': 'machinery',
                                      'machinery_id': machinery.id.toString(),
                                      'transfer_date':
                                          transferDateController.text,
                                      'from_site_id': machinery.siteId
                                          .toString(),
                                      'to_site_id': selectedToSite!,
                                      'created_by': '1',
                                    },
                                  );

                                  Navigator.pop(context);
                                  _showSuccessSnackBar(
                                    'Machinery transferred successfully',
                                  );
                                  _loadMachineries();
                                } catch (_) {
                                  _showErrorSnackBar('Transfer failed');
                                }
                              },
                        child: const Text('Transfer Machinery'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _readOnlyTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
                  color: Color.fromARGB(255, 255, 255, 255),
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
                          const SizedBox(height: 10),

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
                          const SizedBox(height: 10),

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
                          const SizedBox(height: 10),

                          // Model Number
                          _buildEnhancedTextField(
                            controller: modelNumberController,
                            label: 'Model Number',
                            hint: 'e.g. CAT-320, JCB-3DX',
                            icon: Icons.tag,
                            isRequired: true,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 10),

                          // Manufacturer
                          _buildEnhancedTextField(
                            controller: manufacturerController,
                            label: 'Manufacturer',
                            hint: 'e.g. Caterpillar, JCB, Volvo',
                            icon: Icons.factory,
                            isRequired: true,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 10),

                          // Purchase Date
                          _buildDateField(
                            controller: purchaseDateController,
                            label: 'Purchase Date',
                            icon: Icons.calendar_today,
                            hasError: false,
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
                          ),
                          const SizedBox(height: 10),

                          // Maintenance Schedule
                          _buildDateField(
                            controller: maintenanceScheduleController,
                            label: 'Maintenance Schedule',
                            icon: Icons.schedule,
                            hasError: false,
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
                          ),
                          const SizedBox(height: 10),

                          // Capacity
                          _buildEnhancedTextField(
                            controller: capacityController,
                            label: 'Capacity',
                            hint: 'e.g. 20 Tons, 10 Cubic Meters',
                            icon: Icons.scale,
                            isRequired: true,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 10),

                          // Status Dropdown
                          _buildStatusDropdown(
                            value: selectedStatus,
                            label: 'Operational Status',
                            icon: Icons.info_outline,
                            onChanged: (val) => selectedStatus = val!,
                          ),
                          const SizedBox(height: 10),

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
                          const SizedBox(height: 10),

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

                                final provider =
                                    Provider.of<CompanySiteProvider>(
                                      context,
                                      listen: false,
                                    );

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
                                    createdBy:
                                        widget.userId ??
                                        provider.currentUserId ??
                                        9,
                                    workspaceId:
                                        widget.workspaceId ??
                                        int.tryParse(
                                          provider.selectedCompanyId ?? '0',
                                        ) ??
                                        0,
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
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        errorText: hasError ? 'Required' : null,
        prefixIcon: Icon(
          icon,
          color: hasError ? Colors.red : const Color(0xFF4a63c0),
          size: 22.sp,
        ),
        filled: false,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 214, 215, 216),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: const Color.fromARGB(
              255,
              189,
              190,
              197,
            ), // Different color when focused
            width: 1.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
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
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        errorText: hasError ? 'Required' : null,
        prefixIcon: Icon(
          icon,
          color: hasError ? Colors.red : const Color(0xFF4a63c0),
          size: 22.sp,
        ),
        filled: false,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 214, 215, 216),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: const Color.fromARGB(
              255,
              189,
              190,
              197,
            ), // Different color when focused
            width: 1.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
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
          (site) => DropdownMenuItem(value: site.id, child: Text(site.name)),
        ),
      ],
      onChanged: onChanged,
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
      {'value': 'breakdown', 'label': 'Breakdown'},
      {'value': 'scrap', 'label': 'Scrap'},
    ];

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4a63c0), size: 20.sp),
        filled: false,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 214, 215, 216),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: const Color.fromARGB(
              255,
              189,
              190,
              197,
            ), // Different color when focused
            width: 1.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
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
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(
        color: Color.fromARGB(255, 72, 80, 95),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 214, 215, 216),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: const Color.fromARGB(
              255,
              189,
              190,
              197,
            ), // Different color when focused
            width: 1.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        prefixIcon: Icon(icon, color: const Color(0xFF4a63c0), size: 20.sp),
        errorText: hasError ? 'Required' : null,
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool hasError = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Select date',
        prefixIcon: Icon(icon, color: const Color(0xFF4a63c0), size: 20.sp),
        suffixIcon: const Icon(Icons.calendar_today, size: 20),
        errorText: hasError ? 'Required' : null,
        filled: false,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 214, 215, 216),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: const Color.fromARGB(
              255,
              189,
              190,
              197,
            ), // Different color when focused
            width: 1.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color Iconcolor,
    required String title,
    Color? backgroundColor,
    required VoidCallback onTap,
    Color color = textPrimary,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Iconcolor, size: 20),
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

  void _showMachineryOptionsBottomSheet(AllMachinery machinery) {
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);

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
            _buildOptionTile(
              icon: Icons.visibility_outlined,
              title: 'View Full Details',
              Iconcolor: const Color.fromARGB(255, 37, 49, 158),
              backgroundColor: const Color.fromARGB(
                255,
                37,
                49,
                158,
              ).withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                _showMachineryDetailsBottomSheet(machinery);
              },
            ),
            if (provider.hasPermission('machinery transfer'))
              _buildOptionTile(
                icon: Icons.swap_horiz,
                title: 'Transfer Machinery',
                Iconcolor: Colors.orange,
                backgroundColor: Colors.orange.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _showTransferSheet(machinery);
                },
              ),
            if (provider.hasPermission('machinery edit'))
              _buildOptionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Machinery',
                Iconcolor: Colors.blue,
                backgroundColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _showMachinerySheet(existingMachinery: machinery);
                },
              ),
            if (provider.hasPermission('machinery delete'))
              _buildOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Machinery',
                color: Colors.red,
                Iconcolor: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    _showDeleteConfirmationDialog(machinery);
                  });
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showMachineryDetailsBottomSheet(AllMachinery machinery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Machinery Details',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          machinery.vehicleNumber,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      _getStatusText(machinery.operationalStatus).toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(machinery.operationalStatus),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _buildDetailRowInfo(Icons.build, 'Name', machinery.name),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.category,
                      'Category',
                      _getCategoryName(machinery.categoryId),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.tag,
                      'Model',
                      machinery.modelNumber,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.factory,
                      'Manufacturer',
                      machinery.manufacturer,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.location_on,
                      'Current Site',
                      _getCurrentSiteName(),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.scale,
                      'Capacity',
                      machinery.capacity,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.calendar_today,
                      'Purchase Date',
                      machinery.purchaseDate,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRowInfo(
                      Icons.schedule,
                      'Maintenance',
                      machinery.maintenanceSchedule,
                    ),
                    if (machinery.description != null &&
                        machinery.description!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        machinery.description!,
                        style: TextStyle(color: textSecondary),
                      ),
                    ],
                    if (machinery.remarks != null &&
                        machinery.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Remarks',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        machinery.remarks!,
                        style: TextStyle(color: textSecondary),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRowInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

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
                    if (Provider.of<CompanySiteProvider>(
                      context,
                    ).hasPermission('machinery-dpr manage')) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 37,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color.fromARGB(255, 62, 90, 192),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _showDPRScreen,
                              child: Center(
                                child: Text(
                                  "DPR",
                                  style: TextStyle(
                                    color: const Color.fromARGB(
                                      255,
                                      62,
                                      90,
                                      192,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    if (Provider.of<CompanySiteProvider>(
                      context,
                    ).hasPermission('machinery-dpr manage')) ...[
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.assignment,
                            color: primaryColor,
                          ),
                          tooltip: 'DPR',
                          onPressed: _showDPRScreen,
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
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          child: FaIcon(
                            _getCategoryFaIcon(
                              _getCategoryName(machinery.categoryId),
                            ),
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
                                machinery.name,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 16,
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
                                  fontSize: isSmallScreen ? 11 : 13,
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
                            // Status Badge
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
                                  fontSize: isSmallScreen ? 11 : 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // More Options Button
                            if (Provider.of<CompanySiteProvider>(
                                  context,
                                ).hasPermission('machinery show') ||
                                Provider.of<CompanySiteProvider>(
                                  context,
                                ).hasPermission('machinery transfer') ||
                                Provider.of<CompanySiteProvider>(
                                  context,
                                ).hasPermission('machinery edit') ||
                                Provider.of<CompanySiteProvider>(
                                  context,
                                ).hasPermission('machinery delete'))
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _showMachineryOptionsBottomSheet(
                                    machinery,
                                  ),
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

                    const SizedBox(height: 14),

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
    return Row(
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 14 : 16,
          color: const Color.fromARGB(255, 109, 109, 109),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 8 : 9,
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
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 68, 80, 97),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
        toolbarHeight: 74.h,
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
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "Site: ${_getCurrentSiteName()}",

              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13.sp,
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
            currentCompany: widget.currentCompany,
            workspaceId: widget.workspaceId,
          ),
          if (Provider.of<CompanySiteProvider>(
            context,
          ).hasPermission('machinery-categories manage'))
            GestureDetector(
              onTap: () {
                _showMoreOptionsBottomSheet();
              },
              child: const Icon(Icons.more_vert),
            ),
          SizedBox(width: 10),
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
      floatingActionButton:
          Provider.of<CompanySiteProvider>(
            context,
          ).hasPermission('machinery create')
          ? FloatingActionButton(
              onPressed: _showMachinerySheet,
              child: const Icon(Icons.add, color: Colors.white),
              backgroundColor: const Color.fromRGBO(
                42,
                67,
                160,
                1,
              ), // Any color you want
              tooltip: 'Add New Machinery',
            )
          : null,
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

  void _showMoreOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
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
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.category, color: Colors.blue),
                ),
                title: const Text('Machinery Category'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MachineryCategoriesScreen(
                        siteId: int.tryParse(widget.selectedSiteId ?? ''),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDPRScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        _showErrorSnackBar('Authentication token not found');
        return;
      }

      final provider = Provider.of<CompanySiteProvider>(context, listen: false);
      final userId = provider.currentUserId ?? 10;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DPRScreen(
            selectedSiteId: widget.selectedSiteId,
            onSiteChanged: widget.onSiteChanged,
            sites: widget.sites,
            token: token,
            workspaceId: widget.workspaceId ?? 3,
            createdBy: userId,
            currentCompany: widget.currentCompany,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to open DPR: $e');
    }
  }
}
