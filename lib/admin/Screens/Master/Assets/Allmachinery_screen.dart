import 'package:ecoteam_app/admin/models/Allmachinery_model.dart';
import 'package:ecoteam_app/admin/models/MachineryCategory_model.dart';
import 'package:ecoteam_app/admin/models/purchase_model.dart';
import 'package:ecoteam_app/admin/services/Allmachinery_services.dart';
import 'package:ecoteam_app/admin/services/machineryCategory_services.dart';
import 'package:ecoteam_app/admin/services/purchase_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ecoteam_app/admin/services/transfer_machinery_services.dart';

class AdminAllMachineryScreen extends StatefulWidget {
  final String? selectedSiteName;
  final int? selectedSiteId;

  const AdminAllMachineryScreen({
    Key? key,
    this.selectedSiteName,
    this.selectedSiteId,
  }) : super(key: key);

  @override
  State<AdminAllMachineryScreen> createState() => _MachineryScreenState();
}

class _MachineryScreenState extends State<AdminAllMachineryScreen> {
  final MachineryService _machineryService = MachineryService();
  final MachineryCategoryService _categoryService = MachineryCategoryService();
  final TransfermachineryService _transferService = TransfermachineryService();
  List<AllMachinery> _machineries = [];
  List<AllMachinery> _filteredMachineries = [];
  List<MachineryCategory> _categories = [];
  List<SiteModel> _sites = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Transfer related state
  String? _selectedMachinery;
  DateTime? _selectedTransferDate;
  String? _selectedToSite;
  String? _selectedFromSite;
  String? _selectedTransferType;
  bool _isTransferLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMachineries();
    _loadCategories();
    _loadSites();
    // Initialize with current date
    _selectedTransferDate = DateTime.now();
  }

  Future<void> _loadMachineries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _machineryService.getMachineries();
      setState(() {
        _machineries = response.data.reversed.toList();

        if (widget.selectedSiteId != null) {
          _machineries = _machineries
              .where((m) => m.siteId == widget.selectedSiteId)
              .toList();
        }

        _filteredMachineries = _machineries;
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

  Future<void> _loadSites() async {
    try {
      final sites = await ApiServicePurchaseInvoice.getSites();
      setState(() {
        _sites = sites;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load sites: $e');
    }
  }

  void _filterMachineries(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMachineries = _machineries;
      } else {
        _filteredMachineries = _machineries.where((machinery) {
          return machinery.name.toLowerCase().contains(query.toLowerCase()) ||
              machinery.vehicleNumber.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              machinery.modelNumber.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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
            categories: _categories,
            onSave: _addMachinery,
            selectedSiteId: widget.selectedSiteId,
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
            onSave: _updateMachinery,
          ),
        ),
      ),
    );
  }

  // Add this method for transfer functionality
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
                        isExpanded: true,
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
                                    overflow: TextOverflow.ellipsis,
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

  String _getSiteName(int siteId) {
    try {
      final site = _sites.firstWhere(
        (site) => site.id == siteId, // ✅ INT == INT
      );
      return site.name;
    } catch (e) {
      return 'Unknown Site';
    }
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
                child: Icon(Icons.build, color: Colors.grey[600], size: 40),
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
                    _buildDetailRow(
                      'Category',
                      _getCategoryName(machinery.categoryId),
                    ),
                    const Divider(),
                    _buildDetailRow('Vehicle Number', machinery.vehicleNumber),
                    const Divider(),
                    _buildDetailRow('Model Number', machinery.modelNumber),
                    const Divider(),
                    _buildDetailRow('Manufacturer', machinery.manufacturer),
                    const Divider(),
                    _buildDetailRow('Purchase Date', machinery.purchaseDate),
                    const Divider(),
                    _buildDetailRow(
                      'Maintenance Schedule',
                      machinery.maintenanceSchedule,
                    ),
                    const Divider(),
                    _buildDetailRow('Capacity', machinery.capacity),
                    const Divider(),
                    _buildDetailRow(
                      'Operational Status',
                      machinery.operationalStatus == 'active'
                          ? 'Active'
                          : machinery.operationalStatus == 'inactive'
                          ? 'Inactive'
                          : 'Under Maintenance',
                      valueColor: _getStatusColor(machinery.operationalStatus),
                    ),
                    if (machinery.description != null &&
                        machinery.description!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailRow('Description', machinery.description!),
                    ],
                    if (machinery.remarks != null &&
                        machinery.remarks!.isNotEmpty) ...[
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
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'breakdown':
        return Colors.orange;
      case 'scrap':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'All Machinery Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3),
            Text(
              widget.selectedSiteName != null
                  ? 'Site: ${widget.selectedSiteName}'
                  : 'All Sites',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 80.h,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
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
          icon: Icon(Icons.arrow_back, size: 24.sp, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 24.sp, color: Colors.white),
            onPressed: _loadMachineries,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.add, size: 24.sp, color: Colors.white),
            onPressed: _showAddMachinerySheet,
            tooltip: 'Add New Machinery',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(12.w),
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

            // Total Entry Count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total entries: ${_filteredMachineries.length}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Machinery Cards
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMachineries.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No machinery found'
                            : 'No machinery matching your search',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMachineries,
                      child: ListView.builder(
                        itemCount: _filteredMachineries.length,
                        itemBuilder: (context, index) {
                          final machinery = _filteredMachineries[index];
                          return InkWell(
                            onTap: () =>
                                _showMachineryDetailsBottomSheet(machinery),
                            child: Card(
                              margin: EdgeInsets.only(bottom: 9.h),
                              child: Padding(
                                padding: EdgeInsets.all(10.w),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                machinery.name,
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              // Adding Transfer button here
                                              Row(
                                                children: [
                                                  // Transfer Machinery
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _showTransferSheet(
                                                          machinery,
                                                        ),
                                                    child: Tooltip(
                                                      message:
                                                          'Transfer Machinery',
                                                      child: Icon(
                                                        Icons.swap_horiz,
                                                        color:  Color(0xFF2a43a0),
                                                        size: 18.sp,
                                                      ),
                                                    ),
                                                  ),

                                                  SizedBox(width: 8.w),

                                                  // Edit Machinery
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _showEditMachinerySheet(
                                                          machinery,
                                                        ),
                                                    child: Tooltip(
                                                      message: 'Edit Machinery',
                                                      child: Icon(
                                                        Icons.edit,
                                                        color:  Color(0xFF2a43a0),
                                                        size: 18.sp,
                                                      ),
                                                    ),
                                                  ),

                                                  SizedBox(width:8.w),

                                                  // Delete Machinery
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _deleteMachinery(
                                                          machinery.id!,
                                                        ),
                                                    child: Tooltip(
                                                      message:
                                                          'Delete Machinery',
                                                      child: Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size: 18.sp,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
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
                                            'Vehicle Number: ${machinery.vehicleNumber}',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Status: ${_getStatusText(machinery.operationalStatus)}',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: _getStatusColor(
                                                machinery.operationalStatus,
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
  final Function(AllMachinery) onSave;
  final int? selectedSiteId;

  const MachineryFormSheet({
    Key? key,
    this.machinery,
    required this.categories,
    required this.onSave,
    this.selectedSiteId,
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
    {'value': 'breakdown', 'label': 'Breakdown'},
    {'value': 'scrap', 'label': 'Scrap'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final machinery = widget.machinery;
    _nameController = TextEditingController(text: machinery?.name ?? '');
    _modelNumberController = TextEditingController(
      text: machinery?.modelNumber ?? '',
    );
    _manufacturerController = TextEditingController(
      text: machinery?.manufacturer ?? '',
    );
    _purchaseDateController = TextEditingController(
      text: machinery?.purchaseDate ?? '',
    );
    _maintenanceScheduleController = TextEditingController(
      text: machinery?.maintenanceSchedule ?? '',
    );
    _capacityController = TextEditingController(
      text: machinery?.capacity ?? '',
    );
    _descriptionController = TextEditingController(
      text: machinery?.description ?? '',
    );
    _remarksController = TextEditingController(text: machinery?.remarks ?? '');
    _vehicleNumberController = TextEditingController(
      text: machinery?.vehicleNumber ?? '',
    );

    if (machinery != null) {
      _selectedCategory = machinery.categoryId.toString();
      _selectedOperationalStatus = machinery.operationalStatus;

      // Parse dates if they exist
      if (machinery.purchaseDate.isNotEmpty) {
        _selectedPurchaseDate = DateTime.tryParse(machinery.purchaseDate);
      }
      if (machinery.maintenanceSchedule.isNotEmpty) {
        _selectedMaintenanceDate = DateTime.tryParse(
          machinery.maintenanceSchedule,
        );
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
        _maintenanceScheduleController.text = picked.toIso8601String().split(
          'T',
        )[0];
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

      final machinery = AllMachinery(
        id: widget.machinery?.id,
        name: _nameController.text,
        categoryId: int.parse(_selectedCategory),
        modelNumber: _modelNumberController.text,
        manufacturer: _manufacturerController.text,
        purchaseDate: _purchaseDateController.text,
        capacity: _capacityController.text,
        maintenanceSchedule: _maintenanceScheduleController.text,
        remarks: _remarksController.text.isEmpty
            ? null
            : _remarksController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        vehicleNumber: _vehicleNumberController.text,
        ownedBy: 'self.company', // Default value
        supplierId: null,
        operationalStatus: _selectedOperationalStatus,
        siteId: widget.selectedSiteId ?? 3, // Use selected site or default
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                    value: _selectedCategory.isNotEmpty
                        ? _selectedCategory
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    items: widget.categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id.toString(),
                        child: Text(
                          category.name,
                          style: TextStyle(color: Colors.black),
                        ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
