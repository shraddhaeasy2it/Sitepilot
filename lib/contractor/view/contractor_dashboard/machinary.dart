import 'package:ecoteam_app/admin/models/Allmachinery_model.dart';
import 'package:ecoteam_app/admin/models/MachineryCategory_model.dart';
import 'package:ecoteam_app/admin/services/Allmachinery_services.dart';
import 'package:ecoteam_app/admin/services/machineryCategory_services.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AllMachineryScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const AllMachineryScreen({
    Key? key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  }) : super(key: key);

  @override
  State<AllMachineryScreen> createState() => _AdminAllMachineryScreenState();
}

class _AdminAllMachineryScreenState extends State<AllMachineryScreen> {
  final MachineryService _machineryService = MachineryService();
  final MachineryCategoryService _categoryService = MachineryCategoryService();
  List<AllMachinery> _machineries = [];
  List<AllMachinery> _filteredMachineries = [];
  List<MachineryCategory> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedSite;

  @override
  void initState() {
    super.initState();
    _selectedSite = _getSelectedSiteName();
    _loadMachineries();
    _loadCategories();
  }

  @override
  void didUpdateWidget(AllMachineryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _selectedSite = _getSelectedSiteName();
      _filterMachineriesBySite();
    }
  }

  String? _getSelectedSiteName() {
    if (widget.selectedSiteId == null || widget.selectedSiteId!.isEmpty) {
      return null;
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () => Site(id: '', name: '', companyId: ''),
    );
    return site.name.isNotEmpty ? site.name : null;
  }

  Future<void> _loadMachineries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _machineryService.getMachineries();
      setState(() {
        _machineries = response.data.reversed.toList();
        _filterMachineriesBySite();
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

  void _filterMachineriesBySite() {
    setState(() {
      if (_selectedSite == null) {
        _filteredMachineries = _machineries;
      } else {
        _filteredMachineries = _machineries.where((machinery) {
          return machinery.siteId == int.tryParse(widget.selectedSiteId ?? '') || 
                 machinery.ownedBy?.contains(_selectedSite ?? '') == true;
        }).toList();
      }
      
      // Apply search filter if exists
      if (_searchQuery.isNotEmpty) {
        _filteredMachineries = _filteredMachineries.where((machinery) {
          return machinery.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              machinery.vehicleNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              machinery.modelNumber.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  void _filterMachineries(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filterMachineriesBySite();
      } else {
        _filteredMachineries = _machineries.where((machinery) {
          // First filter by site if selected
          final siteFilter = _selectedSite == null || 
              machinery.siteId == int.tryParse(widget.selectedSiteId ?? '') || 
              machinery.ownedBy?.contains(_selectedSite ?? '') == true;
          
          // Then filter by search query
          final searchFilter = machinery.name.toLowerCase().contains(query.toLowerCase()) ||
              machinery.vehicleNumber.toLowerCase().contains(query.toLowerCase()) ||
              machinery.modelNumber.toLowerCase().contains(query.toLowerCase());
          
          return siteFilter && searchFilter;
        }).toList();
      }
    });
  }

  void _showSiteSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Site'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.sites.length + 1, // +1 for "All Sites" option
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('All Sites'),
                  leading: const Icon(Icons.all_inclusive),
                  onTap: () {
                    widget.onSiteChanged('');
                    Navigator.pop(context);
                  },
                  tileColor: widget.selectedSiteId == null ? Colors.blue[50] : null,
                );
              }
              final site = widget.sites[index - 1];
              return ListTile(
                title: Text(site.name),
                leading: const Icon(Icons.location_on),
                onTap: () {
                  widget.onSiteChanged(site.id);
                  Navigator.pop(context);
                },
                tileColor: widget.selectedSiteId == site.id ? Colors.blue[50] : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddMachinerySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: MachineryFormSheet(
            machinery: null,
            categories: _categories,
            selectedSiteId: widget.selectedSiteId, // Pass selected site ID
            onSave: _addMachinery,
          ),
        ),
      ),
    );
  }

  void _showEditMachinerySheet(AllMachinery machinery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: MachineryFormSheet(
            machinery: machinery,
            categories: _categories,
            selectedSiteId: widget.selectedSiteId, // Pass selected site ID
            onSave: _updateMachinery,
          ),
        ),
      ),
    );
  }

  void _showMachineryDetailsBottomSheet(AllMachinery machinery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Machinery Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.build,
                  color: Colors.grey[600],
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                machinery.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Category', _getCategoryName(machinery.categoryId)),
                    const Divider(),
                    _buildDetailRow('Site', _getSiteName(machinery.siteId)),
                    const Divider(),
                    _buildDetailRow('Vehicle Number', machinery.vehicleNumber),
                    const Divider(),
                    _buildDetailRow('Model Number', machinery.modelNumber),
                    const Divider(),
                    _buildDetailRow('Manufacturer', machinery.manufacturer),
                    const Divider(),
                    _buildDetailRow('Purchase Date', machinery.purchaseDate),
                    const Divider(),
                    _buildDetailRow('Maintenance Schedule', machinery.maintenanceSchedule),
                    const Divider(),
                    _buildDetailRow('Capacity', machinery.capacity),
                    const Divider(),
                    _buildDetailRow('Operational Status', machinery.operationalStatus == 'active' ? 'Active' : machinery.operationalStatus == 'inactive' ? 'Inactive' : 'Under Maintenance',
                        valueColor: _getStatusColor(machinery.operationalStatus)),
                    if (machinery.description != null && machinery.description!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailRow('Description', machinery.description!),
                    ],
                    if (machinery.remarks != null && machinery.remarks!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailRow('Remarks', machinery.remarks!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditMachinerySheet(machinery);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2a43a0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Future<void> _addMachinery(AllMachinery machinery) async {
    try {
      await _machineryService.createMachinery(machinery);
      _loadMachineries();
      _showSuccessSnackBar('Machinery added successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to add machinery: $e');
    }
  }

  Future<void> _updateMachinery(AllMachinery machinery) async {
    try {
      await _machineryService.updateMachinery(machinery);
      _loadMachineries();
      _showSuccessSnackBar('Machinery updated successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to update machinery: $e');
    }
  }

  Future<void> _deleteMachinery(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Machinery'),
        content: const Text('Are you sure you want to delete this machinery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _machineryService.deleteMachinery(id);
        _loadMachineries();
        _showSuccessSnackBar('Machinery deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete machinery: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
      orElse: () => Site(
        id: '',
        name: 'Unknown Site',
        companyId: '',
      ),
    );
    return site.name;
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Machinery Management - ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: _selectedSite ?? 'All Sites',
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
        toolbarHeight: 80.h,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4a63c0),
                Color(0xFF3a53b0),
                Color(0xFF2a43a0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 24.sp,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: 24.sp,
              color: Colors.white,
            ),
            onPressed: _loadMachineries,
            tooltip: 'Refresh',
          ),
          // IconButton(
          //   icon: Icon(Icons.filter_list, size: 24.sp, color: Colors.white),
          //   onPressed: _showSiteSelectionDialog,
          //   tooltip: 'Filter by Site',
          // ),
          IconButton(
            icon: Icon(Icons.add, size: 24.sp, color: Colors.white),
            onPressed: _showAddMachinerySheet,
            tooltip: 'Add New Machinery',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Search Bar
            TextField(
              onChanged: _filterMachineries,
              decoration: InputDecoration(
                hintText: 'Search by name, vehicle number, or model...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Site Filter Info and Total Entry Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               
                Text(
                  'Total entries: ${_filteredMachineries.length}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Machinery Cards
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMachineries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4a63c0).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.build,
                                  size: 64,
                                  color: const Color(0xFF4a63c0),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _selectedSite == null
                                    ? 'No machinery found'
                                    : 'No machinery at $_selectedSite',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Add new machinery to get started'
                                    : 'No machinery matching your search',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMachineries,
                          child: ListView.builder(
                            itemCount: _filteredMachineries.length,
                            itemBuilder: (context, index) {
                              final machinery = _filteredMachineries[index];
                              return InkWell(
                                onTap: () => _showMachineryDetailsBottomSheet(machinery),
                                child: Card(
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  child: Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24.r,
                                          backgroundColor: Colors.grey[300],
                                          child: Icon(
                                            Icons.build,
                                            color: Colors.grey[600],
                                            size: 24.sp,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                machinery.name,
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                'Category: ${_getCategoryName(machinery.categoryId)}',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                'Site: ${_getSiteName(machinery.siteId)}',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                'Vehicle Number: ${machinery.vehicleNumber}',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                'Status: ${machinery.operationalStatus == 'active' ? 'Active' : machinery.operationalStatus == 'inactive' ? 'Inactive' : 'Under Maintenance'}',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: _getStatusColor(machinery.operationalStatus),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () => _showEditMachinerySheet(machinery),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteMachinery(machinery.id!),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class MachineryFormSheet extends StatefulWidget {
  final AllMachinery? machinery;
  final List<MachineryCategory> categories;
  final String? selectedSiteId;
  final Function(AllMachinery) onSave;

  const MachineryFormSheet({
    Key? key,
    this.machinery,
    required this.categories,
    this.selectedSiteId,
    required this.onSave,
  }) : super(key: key);

  @override
  State<MachineryFormSheet> createState() => _MachineryFormSheetState();
}

class _MachineryFormSheetState extends State<MachineryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _modelNumberController;
  late TextEditingController _manufacturerController;
  late TextEditingController _purchaseDateController;
  late TextEditingController _maintenanceScheduleController;
  late TextEditingController _capacityController;
  late TextEditingController _descriptionController;
  late TextEditingController _remarksController;
  late TextEditingController _vehicleNumberController;

  String _selectedCategory = '';
  String _selectedOperationalStatus = 'active';
  DateTime? _selectedPurchaseDate;
  DateTime? _selectedMaintenanceDate;

  final List<Map<String, String>> operationalStatuses = [
    {'value': 'active', 'label': 'Active'},
    {'value': 'inactive', 'label': 'Inactive'},
    {'value': 'maintenance', 'label': 'Under Maintenance'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final machinery = widget.machinery;
    _nameController = TextEditingController(text: machinery?.name ?? '');
    _modelNumberController = TextEditingController(text: machinery?.modelNumber ?? '');
    _manufacturerController = TextEditingController(text: machinery?.manufacturer ?? '');
    _purchaseDateController = TextEditingController(text: machinery?.purchaseDate ?? '');
    _maintenanceScheduleController = TextEditingController(text: machinery?.maintenanceSchedule ?? '');
    _capacityController = TextEditingController(text: machinery?.capacity ?? '');
    _descriptionController = TextEditingController(text: machinery?.description ?? '');
    _remarksController = TextEditingController(text: machinery?.remarks ?? '');
    _vehicleNumberController = TextEditingController(text: machinery?.vehicleNumber ?? '');

    if (machinery != null) {
      _selectedCategory = machinery.categoryId.toString();
      _selectedOperationalStatus = machinery.operationalStatus;
      
      // Parse dates if they exist
      if (machinery.purchaseDate.isNotEmpty) {
        _selectedPurchaseDate = DateTime.tryParse(machinery.purchaseDate);
      }
      if (machinery.maintenanceSchedule.isNotEmpty) {
        _selectedMaintenanceDate = DateTime.tryParse(machinery.maintenanceSchedule);
      }
    } else {
      // Set default category if available
      if (widget.categories.isNotEmpty) {
        _selectedCategory = widget.categories.first.id.toString();
      }
    }
  }

  Future<void> _selectPurchaseDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPurchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedPurchaseDate = picked;
        _purchaseDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _selectMaintenanceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMaintenanceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedMaintenanceDate = picked;
        _maintenanceScheduleController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  void _saveMachinery() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      // Use selected site from app bar or existing machinery site
      final siteId = widget.machinery != null 
          ? widget.machinery!.siteId 
          : int.tryParse(widget.selectedSiteId ?? '') ?? 1; // Default to 1 if no site selected

      final machinery = AllMachinery(
        id: widget.machinery?.id,
        name: _nameController.text,
        categoryId: int.parse(_selectedCategory),
        siteId: siteId, // Automatically use selected site
        modelNumber: _modelNumberController.text,
        manufacturer: _manufacturerController.text,
        purchaseDate: _purchaseDateController.text,
        capacity: _capacityController.text,
        maintenanceSchedule: _maintenanceScheduleController.text,
        remarks: _remarksController.text.isEmpty ? null : _remarksController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        vehicleNumber: _vehicleNumberController.text,
        ownedBy: 'self.company', // Default value
        supplierId: null,
        operationalStatus: _selectedOperationalStatus,
        createdBy: 1, // Default value
        workspaceId: 1, // Default value
        status: '0',
      );

      widget.onSave(machinery);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          widget.machinery == null ? 'Add Machinery' : 'Edit Machinery',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Machinery Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.build, size: 15),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter machinery name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    items: widget.categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id.toString(),
                        child: Text(category.name, style: const TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: _vehicleNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter vehicle number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _modelNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Model Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter model number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _manufacturerController,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.factory, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter manufacturer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _purchaseDateController,
                    decoration: InputDecoration(
                      labelText: 'Purchase Date',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectPurchaseDate(context),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select purchase date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maintenanceScheduleController,
                    decoration: InputDecoration(
                      labelText: 'Maintenance Schedule',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.schedule, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectMaintenanceDate(context),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select maintenance schedule';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacity',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter capacity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedOperationalStatus,
                    decoration: const InputDecoration(
                      labelText: 'Operational Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    items: operationalStatuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status['value'],
                        child: Text(status['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedOperationalStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: _saveMachinery,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2a43a0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Save', style: TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelNumberController.dispose();
    _manufacturerController.dispose();
    _purchaseDateController.dispose();
    _maintenanceScheduleController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    _remarksController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }
}