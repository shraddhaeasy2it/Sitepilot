import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:flutter/material.dart';
import 'package:ecoteam_app/admin/services/employee_services.dart';
import 'package:ecoteam_app/admin/models/employee_model.dart';
import 'package:ecoteam_app/admin/services/transfer_employee_services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EmployeePage extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String)? onSiteChanged;
  final List<Site>? sites;
  final String? selectedSiteName;

  const EmployeePage({
    super.key,
    this.selectedSiteName,
    this.selectedSiteId,
    this.onSiteChanged,
    this.sites,
  });

  @override
  _EmployeePageState createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  @override
  void didUpdateWidget(covariant EmployeePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedSiteId != widget.selectedSiteId) {
      _loadEmployees();
      _loadCreationData();
    }
  }

  List<Employee> employees = [];
  List<Employee> filteredEmployees = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  Employee? creationDataEmployee;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _loadCreationData();
    searchController.addListener(_filterEmployees);
  }

  Future<void> _loadCreationData() async {
    try {
      // Safe parsing of site ID
      int? siteIdInt;
      if (widget.selectedSiteId != null) {
        siteIdInt = int.tryParse(widget.selectedSiteId!);
      }

      final data = await ApiService.fetchEmployeeCreationData(
        workspaceId: 3,
        siteId: siteIdInt,
        createdBy: 10,
      );
      setState(() {
        creationDataEmployee = data;
      });
    } catch (e) {
      print('Error loading creation data: $e');
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => isLoading = true);

    try {
      // Safe parsing of site ID
      int? siteIdInt;
      if (widget.selectedSiteId != null) {
        siteIdInt = int.tryParse(widget.selectedSiteId!);
      }

      final fetchedEmployees = await ApiService.fetchEmployees(
        workspaceId: 3,
        siteId: siteIdInt,
      );

      setState(() {
        employees = fetchedEmployees;
        filteredEmployees = fetchedEmployees;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load employees: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterEmployees() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredEmployees = employees;
      } else {
        filteredEmployees = employees.where((employee) {
          return employee.name.toLowerCase().contains(query) ||
              employee.email.toLowerCase().contains(query) ||
              employee.displayId.toLowerCase().contains(query) ||
              (employee.phone ?? '').toLowerCase().contains(query) ||
              employee.departmentName.toLowerCase().contains(query) ||
              employee.designationName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      searchController.clear();
      isLoading = true;
    });

    await _loadEmployees();
    await _loadCreationData();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Data refreshed')));
  }

  Future<void> _addEmployee() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmployeeBottomSheet(
        creationData: creationDataEmployee,
        onSave: (employee, avatarFile) async {
          try {
            final newEmployee = await ApiService.addEmployee(
              employee,
              avatarFile: avatarFile,
            );
            return newEmployee;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add employee: $e')),
            );
            return null;
          }
        },
        siteId: widget.selectedSiteId != null
            ? int.tryParse(widget.selectedSiteId!)
            : null,
      ),
    );

    if (result != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Employee added successfully')));
      _loadEmployees();
    }
  }

  Future<void> _editEmployee(Employee employee) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmployeeBottomSheet(
        employee: employee,
        creationData: creationDataEmployee,
        onSave: (updatedEmployee, avatarFile) async {
          try {
            final savedEmployee = await ApiService.updateEmployee(
              updatedEmployee,
              avatarFile: avatarFile,
            );
            return savedEmployee;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update employee: $e')),
            );
            return null;
          }
        },
        siteId: widget.selectedSiteId != null
            ? int.tryParse(widget.selectedSiteId!)
            : null,
      ),
    );

    if (result != null) {
      _loadEmployees();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Employee updated successfully')));
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final idToDelete = employee.userId?.toString() ?? employee.id;
        final success = await ApiService.deleteEmployee(idToDelete);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Employee deleted successfully')),
          );
          _loadEmployees();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete employee: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 255),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Employee Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              "Site: ${_getCurrentSiteName()}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addEmployee,
            tooltip: 'Add Employee',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search employees...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Employees: ${filteredEmployees.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Active: ${filteredEmployees.where((e) => (e.isActive ?? 1) == 1).length}',
                        style: TextStyle(fontSize: 14, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: filteredEmployees.isEmpty
                      ? Center(
                          child: Text(
                            isLoading ? 'Loading...' : 'No employees found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = filteredEmployees[index];
                            return EmployeeCard(
                              employee: employee,
                              onEdit: () => _editEmployee(employee),
                              onDelete: () => _deleteEmployee(employee),
                              onTransfer: () =>
                                  _showEmployeeTransferSheet(employee),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _getCurrentSiteName() {
    if (widget.selectedSiteId == null || widget.selectedSiteId!.isEmpty) {
      return 'All Sites';
    }
    if (widget.sites == null || widget.sites!.isEmpty) {
      return widget.selectedSiteName ?? 'Unknown Site';
    }
    try {
      final site = widget.sites!.firstWhere(
        (site) => site.id == widget.selectedSiteId,
      );
      return site.name;
    } catch (e) {
      return widget.selectedSiteName ?? 'Unknown Site';
    }
  }

  void _showEmployeeTransferSheet(Employee employee) {
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
                final result = await EmployeeTransferServices.fetchToSites(
                  siteId:
                      employee.siteId ??
                      int.tryParse(widget.selectedSiteId ?? '0') ??
                      0,
                  workspaceId: employee.workspace ?? 3,
                  machineryId: int.tryParse(employee.id) ?? 0,
                  userId: 10,
                );

                // remove FROM SITE
                result.remove(
                  (employee.siteId ?? widget.selectedSiteId).toString(),
                );

                setSheetState(() {
                  siteMap = result;
                  loading = false;
                });
              } catch (e) {
                setSheetState(() {
                  loading = false;
                  error = 'Failed to load sites: $e';
                });
              }
            }

            if (loading) loadSites();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Transfer Employee',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// 🔒 TYPE
                      _readOnlyField(
                        label: 'Transfer Type',
                        value: 'Employee',
                        icon: Icons.swap_horiz,
                      ),

                      /// 🔒 EMPLOYEE NAME
                      _readOnlyField(
                        label: 'Employee',
                        value: employee.name,
                        icon: Icons.person,
                      ),

                      /// 🔒 FROM SITE
                      _readOnlyField(
                        label: 'From Site',
                        value: _getCurrentSiteName(),
                        icon: Icons.location_on,
                      ),

                      /// 🔒 DATE
                      _readOnlyTextField(
                        controller: transferDateController,
                        label: 'Transfer Date',
                        icon: Icons.calendar_today,
                      ),

                      const SizedBox(height: 16),

                      /// ✅ TO SITE
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
                            return DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setSheetState(() => selectedToSite = val),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'To Site',
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
                                    await EmployeeTransferServices.createTransfer(
                                      {
                                        'transfer_type': 'employee',
                                        'machinery_id': employee.id.toString(),
                                        'transfer_date':
                                            transferDateController.text,
                                        'from_site_id':
                                            (employee.siteId ??
                                                    widget.selectedSiteId)
                                                .toString(),
                                        'to_site_id': selectedToSite!,
                                        'created_by': '9',
                                      },
                                    );

                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Employee transferred successfully',
                                        ),
                                      ),
                                    );
                                    _loadEmployees();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Transfer failed: $e'),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2a43a0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Transfer'),
                        ),
                      ),
                    ],
                  ),
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
          border: const OutlineInputBorder(),
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
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTransfer;
  final bool isSmallScreen;

  const EmployeeCard({
    Key? key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
    required this.onTransfer,
    this.isSmallScreen = false,
  }) : super(key: key);

  static const Color primaryColor = Color(0xFF6f88e2);
  static const Color primaryDark = Color(0xFF5a73d1);
  static const Color backgroundColor = Color.fromARGB(255, 249, 249, 253);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  @override
  Widget build(BuildContext context) {
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
          onTap: () {
            // You can add onTap functionality if needed
          },
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with avatar, name, email, status and action buttons
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.1),
                      ),
                      child: ClipOval(
                        child:
                            employee.avatar != null &&
                                employee.avatar!.isNotEmpty
                            ? Image.network(
                                'https://sitepilot.easy2it.in/${employee.avatar}',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: primaryColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: primaryColor,
                                      size: 22,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 44,
                                height: 44,
                                color: primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: primaryColor,
                                  size: 22,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
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
                            employee.email,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Status, Edit and Delete buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),

                        /// 🔁 TRANSFER BUTTON
                        GestureDetector(
                          onTap: onTransfer,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFF2a43a0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.swap_horiz,
                              color: Color(0xFF2a43a0),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Edit button
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFF2a43a0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Color(0xFF2a43a0),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete button
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // First row: Phone and Branch side by side
                Row(
                  children: [
                    if (employee.phone != null && employee.phone!.isNotEmpty)
                      Expanded(
                        child: _buildMaterialStyleInfoItem(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: employee.phone!,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    if (employee.phone != null &&
                        employee.phone!.isNotEmpty &&
                        employee.branchName.isNotEmpty &&
                        employee.branchName != 'N/A')
                      const SizedBox(width: 10),
                    if (employee.branchName.isNotEmpty &&
                        employee.branchName != 'N/A')
                      Expanded(
                        child: _buildMaterialStyleInfoItem(
                          icon: Icons.business,
                          label: 'Branch',
                          value: employee.branchName,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                  ],
                ),

                if ((employee.phone != null && employee.phone!.isNotEmpty) ||
                    (employee.branchName.isNotEmpty &&
                        employee.branchName != 'N/A'))
                  const SizedBox(height: 8),

                // Second row: Department and Designation side by side
                Row(
                  children: [
                    if (employee.departmentName.isNotEmpty &&
                        employee.departmentName != 'N/A')
                      Expanded(
                        child: _buildMaterialStyleInfoItem(
                          icon: Icons.group_work,
                          label: 'Department',
                          value: employee.departmentName,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    if (employee.departmentName.isNotEmpty &&
                        employee.departmentName != 'N/A' &&
                        employee.designationName.isNotEmpty &&
                        employee.designationName != 'N/A')
                      const SizedBox(width: 10),
                    if (employee.designationName.isNotEmpty &&
                        employee.designationName != 'N/A')
                      Expanded(
                        child: _buildMaterialStyleInfoItem(
                          icon: Icons.work,
                          label: 'Role',
                          value: employee.designationName,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                  ],
                ),

                if ((employee.departmentName.isNotEmpty &&
                        employee.departmentName != 'N/A') ||
                    (employee.designationName.isNotEmpty &&
                        employee.designationName != 'N/A'))
                  const SizedBox(height: 8),

                // Third row: Joining Date (if available)
                if (employee.dateOfJoining != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildMaterialStyleInfoItem(
                          icon: Icons.calendar_today,
                          label: 'Joined',
                          value: _formatDate(employee.dateOfJoining!),
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ((employee.isActive ?? 1) == 1)
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ((employee.isActive ?? 1) == 1)
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          ((employee.isActive ?? 1) == 1)
                              ? 'Active'
                              : 'Inactive',
                          style: TextStyle(
                            color: ((employee.isActive ?? 1) == 1)
                                ? Colors.green
                                : Colors.red,
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: FontWeight.w600,
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
    );
  }

  // Helper method for material-style info items (matches machinery card exactly)
  Widget _buildMaterialStyleInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 5 : 7),
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}

class EmployeeBottomSheet extends StatefulWidget {
  final Employee? employee;
  final Employee? creationData;
  final Future<Employee?> Function(Employee, File?) onSave;
  final int? siteId;

  const EmployeeBottomSheet({
    Key? key,
    this.employee,
    this.creationData,
    required this.onSave,
    this.siteId,
  }) : super(key: key);

  @override
  _EmployeeBottomSheetState createState() => _EmployeeBottomSheetState();
}

class _EmployeeBottomSheetState extends State<EmployeeBottomSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late Employee _employee;
  late TabController _tabController;
  bool _isSaving = false;
  bool _isLoadingDepartments = false;
  bool _isLoadingDesignations = false;
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _employee =
        widget.employee ??
        Employee(
          id: '',
          name: '',
          email: '',
          gender: 'male',
          workspace: 3,
          createdBy: 9,
          siteId: widget.siteId,
          employeesId: '#EMP00000001',
        );

    // Initialize with creation data if available
    if (widget.creationData != null) {
      _employee = _employee.copyWith(
        departments: widget.creationData!.departments,
        designations: widget.creationData!.designations,
        branches: widget.creationData!.branches,
        roles: widget.creationData!.roles,
        locationTypes: widget.creationData!.locationTypes,
        documentList: widget.creationData!.documentList,
      );
    }

    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> _loadDepartments() async {
    if (_employee.branchId == null) return;

    setState(() => _isLoadingDepartments = true);

    try {
      final departments = await ApiService.fetchDepartments(
        branchId: _employee.branchId!,
        workspaceId: 3,
      );

      setState(() {
        _employee = _employee.copyWith(departments: departments);
      });
    } catch (e) {
      print('Error loading departments: $e');
    } finally {
      setState(() => _isLoadingDepartments = false);
    }
  }

  Future<void> _loadDesignations() async {
    if (_employee.departmentId == null) return;

    setState(() => _isLoadingDesignations = true);

    try {
      final designations = await ApiService.fetchDesignations(
        departmentId: _employee.departmentId!,
        workspaceId: 3,
      );

      setState(() {
        _employee = _employee.copyWith(designations: designations);
      });
    } catch (e) {
      print('Error loading designations: $e');
    } finally {
      setState(() => _isLoadingDesignations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.employee == null ? 'Add Employee' : 'Edit Employee',
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(text: 'Personal'),
              Tab(text: 'Company'),
              Tab(text: 'Bank'),
              Tab(text: 'Additional'),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              _PersonalDetailsTab(
                employee: _employee,
                avatarFile: _avatarFile,
                onChanged: (employee) {
                  setState(() => _employee = employee);
                },
                onAvatarChanged: (file) {
                  setState(() => _avatarFile = file);
                },
              ),
              _CompanyDetailsTab(
                employee: _employee,
                onChanged: (employee) {
                  // Debug prints
                  print('🔄 onChanged triggered');
                  print(
                    '   Current Dept: ${_employee.departmentId}, New Dept: ${employee.departmentId}',
                  );
                  print(
                    '   Current Branch: ${_employee.branchId}, New Branch: ${employee.branchId}',
                  );
                  print(
                    '   Current Designation: ${_employee.designationId}, New Designation: ${employee.designationId}',
                  );

                  // Load departments when branch changes
                  if (employee.branchId != _employee.branchId) {
                    print('   -> Loading Departments');
                    _loadDepartments();
                  }
                  // Load designations when department changes
                  if (employee.departmentId != _employee.departmentId) {
                    print('   -> Loading Designations');
                    _loadDesignations();
                  }
                  setState(() => _employee = employee);
                },
                isLoadingDepartments: _isLoadingDepartments,
                isLoadingDesignations: _isLoadingDesignations,
              ),
              _BankDetailsTab(
                employee: _employee,
                onChanged: (employee) {
                  setState(() => _employee = employee);
                },
              ),
              _AdditionalDetailsTab(
                employee: _employee,
                onChanged: (employee) {
                  setState(() => _employee = employee);
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveEmployee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2a43a0),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      try {
        final savedEmployee = await widget.onSave(_employee, _avatarFile);
        if (savedEmployee != null && context.mounted) {
          Navigator.pop(context, savedEmployee);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }
}

// Personal Details Tab
class _PersonalDetailsTab extends StatefulWidget {
  final Employee employee;
  final Function(Employee) onChanged;
  final File? avatarFile;
  final Function(File?)? onAvatarChanged;

  const _PersonalDetailsTab({
    Key? key,
    required this.employee,
    required this.onChanged,
    this.avatarFile,
    this.onAvatarChanged,
  }) : super(key: key);

  @override
  __PersonalDetailsTabState createState() => __PersonalDetailsTabState();
}

class __PersonalDetailsTabState extends State<_PersonalDetailsTab> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  late TextEditingController _passportController;
  late TextEditingController _passportCountryController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _emailController = TextEditingController(text: widget.employee.email);
    _phoneController = TextEditingController(text: widget.employee.phone ?? '');
    _addressController = TextEditingController(
      text: widget.employee.address ?? '',
    );
    _dobController = TextEditingController(text: widget.employee.dob ?? '');
    _passportController = TextEditingController(
      text: widget.employee.passport ?? '',
    );
    _passportCountryController = TextEditingController(
      text: widget.employee.passportCountry ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.employee.password ?? '',
    );
  }

  @override
  void didUpdateWidget(_PersonalDetailsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.employee != oldWidget.employee) {
      if (_nameController.text != widget.employee.name) {
        _nameController.text = widget.employee.name;
      }
      if (_emailController.text != widget.employee.email) {
        _emailController.text = widget.employee.email;
      }
      if (_phoneController.text != (widget.employee.phone ?? '')) {
        _phoneController.text = widget.employee.phone ?? '';
      }
      if (_addressController.text != (widget.employee.address ?? '')) {
        _addressController.text = widget.employee.address ?? '';
      }
      if (_dobController.text != (widget.employee.dob ?? '')) {
        _dobController.text = widget.employee.dob ?? '';
      }
      if (_passportController.text != (widget.employee.passport ?? '')) {
        _passportController.text = widget.employee.passport ?? '';
      }
      if (_passportCountryController.text !=
          (widget.employee.passportCountry ?? '')) {
        _passportCountryController.text = widget.employee.passportCountry ?? '';
      }
      if (_passwordController.text != (widget.employee.password ?? '')) {
        _passwordController.text = widget.employee.password ?? '';
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      widget.onAvatarChanged?.call(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.avatarFile != null
                        ? Image.file(widget.avatarFile!, fit: BoxFit.cover)
                        : (widget.employee.avatar != null &&
                              widget.employee.avatar!.isNotEmpty)
                        ? Image.network(
                            'https://sitepilot.easy2it.in/${widget.employee.avatar}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF2a43a0),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          _buildTextField('Name', _nameController, (value) {
            widget.onChanged(widget.employee.copyWith(name: value));
          }, isRequired: true),

          _buildTextField(
            'Email',
            _emailController,
            (value) {
              widget.onChanged(widget.employee.copyWith(email: value));
            },
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
          ),

          if (widget.employee.id.isEmpty)
            _buildTextField(
              'Password',
              _passwordController,
              (value) {
                widget.onChanged(widget.employee.copyWith(password: value));
              },
              isRequired: widget.employee.id.isEmpty,
              obscureText: true,
            ),

          _buildDateField('Date of Birth', _dobController.text, (date) {
            widget.onChanged(widget.employee.copyWith(dob: date));
          }),

          _buildDropdownField(
            'Gender',
            {'male': 'Male', 'female': 'Female', 'other': 'Other'},
            widget.employee.gender,
            (value) {
              widget.onChanged(
                widget.employee.copyWith(gender: value ?? 'male'),
              );
            },
            isRequired: true,
          ),

          _buildTextField('Phone', _phoneController, (value) {
            widget.onChanged(widget.employee.copyWith(phone: value));
          }, keyboardType: TextInputType.phone),

          _buildTextField('Address', _addressController, (value) {
            widget.onChanged(widget.employee.copyWith(address: value));
          }, maxLines: 2),

          SizedBox(height: 20),
          Text(
            'Passport Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),

          _buildTextField('Passport Number', _passportController, (value) {
            widget.onChanged(widget.employee.copyWith(passport: value));
          }),

          _buildTextField('Passport Country', _passportCountryController, (
            value,
          ) {
            widget.onChanged(widget.employee.copyWith(passportCountry: value));
          }),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool obscureText = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          hintText: hint,
          border: OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: obscureText,
        validator: isRequired && controller.text.isEmpty
            ? (value) => 'Required'
            : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField(
    String label,
    String currentValue,
    Function(String) onDateSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () async {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: currentValue.isNotEmpty
                ? DateTime.tryParse(currentValue) ?? DateTime.now()
                : DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (selectedDate != null) {
            onDateSelected(selectedDate.toIso8601String().split('T')[0]);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentValue.isNotEmpty ? currentValue : 'Select date',
                style: TextStyle(
                  color: currentValue.isNotEmpty ? Colors.black : Colors.grey,
                ),
              ),
              Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    Map<String, String> options,
    String? value,
    Function(String?) onChanged, {
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          border: OutlineInputBorder(),
        ),
        value: value,
        items: [
          DropdownMenuItem<String>(value: null, child: Text('Select $label')),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ],
        onChanged: onChanged,
        validator: isRequired && value == null
            ? (val) => 'Please select $label'
            : null,
      ),
    );
  }
}

// Company Details Tab
class _CompanyDetailsTab extends StatefulWidget {
  final Employee employee;
  final Function(Employee) onChanged;
  final bool isLoadingDepartments;
  final bool isLoadingDesignations;

  const _CompanyDetailsTab({
    Key? key,
    required this.employee,
    required this.onChanged,
    this.isLoadingDepartments = false,
    this.isLoadingDesignations = false,
  }) : super(key: key);

  @override
  __CompanyDetailsTabState createState() => __CompanyDetailsTabState();
}

class __CompanyDetailsTabState extends State<_CompanyDetailsTab> {
  late TextEditingController _employeeIdController;
  late TextEditingController _employeesIdController;
  late TextEditingController _companyDojController;
  late TextEditingController _documentsController;

  @override
  void initState() {
    super.initState();
    _employeeIdController = TextEditingController(
      text: widget.employee.employeeId ?? '',
    );
    _employeesIdController = TextEditingController(
      text: widget.employee.employeesId ?? '#EMP00000001',
    );
    _companyDojController = TextEditingController(
      text: widget.employee.companyDoj ?? '',
    );
    _documentsController = TextEditingController(
      text: widget.employee.documents ?? '',
    );
  }

  @override
  void didUpdateWidget(_CompanyDetailsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.employee != oldWidget.employee) {
      if (_employeeIdController.text != (widget.employee.employeeId ?? '')) {
        _employeeIdController.text = widget.employee.employeeId ?? '';
      }
      if (_employeesIdController.text != (widget.employee.employeesId ?? '')) {
        _employeesIdController.text = widget.employee.employeesId ?? '';
      }
      if (_companyDojController.text != (widget.employee.companyDoj ?? '')) {
        _companyDojController.text = widget.employee.companyDoj ?? '';
      }
      if (_documentsController.text != (widget.employee.documents ?? '')) {
        _documentsController.text = widget.employee.documents ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField('Employee ID', _employeeIdController, (value) {
            widget.onChanged(widget.employee.copyWith(employeeId: value));
          }),

          _buildTextField('Employees ID', _employeesIdController, (value) {
            widget.onChanged(widget.employee.copyWith(employeesId: value));
          }),

          // Branch dropdown
          if (widget.employee.branches != null &&
              widget.employee.branches!.isNotEmpty)
            _buildDynamicDropdownField(
              'Branch',
              widget.employee.branches!,
              widget.employee.branchId?.toString(),
              (value) {
                widget.onChanged(
                  widget.employee.copyWith(
                    branchId: int.tryParse(value ?? ''),
                    // Reset department and designation when branch changes
                    departmentId: null,
                    designationId: null,
                  ),
                );
              },
              isRequired: true,
            )
          else
            _buildTextField(
              'Branch ID',
              TextEditingController(
                text: widget.employee.branchId?.toString() ?? '',
              ),
              (value) {
                widget.onChanged(
                  widget.employee.copyWith(branchId: int.tryParse(value)),
                );
              },
              keyboardType: TextInputType.number,
            ),

          // Department dropdown
          if (widget.isLoadingDepartments)
            _buildLoadingField('Loading departments...')
          else if (widget.employee.departments != null &&
              widget.employee.departments!.isNotEmpty)
            _buildDynamicDropdownField(
              'Department',
              widget.employee.departments!,
              widget.employee.departmentId?.toString(),
              (value) {
                widget.onChanged(
                  widget.employee.copyWith(
                    departmentId: int.tryParse(value ?? ''),
                    // Reset designation when department changes
                    designationId: null,
                  ),
                );
              },
              isRequired: true,
              isDisabled: widget.employee.branchId == null,
            )
          else
            _buildTextField(
              'Department ID',
              TextEditingController(
                text: widget.employee.departmentId?.toString() ?? '',
              ),
              (value) {
                widget.onChanged(
                  widget.employee.copyWith(departmentId: int.tryParse(value)),
                );
              },
              keyboardType: TextInputType.number,
            ),

          // Designation dropdown
          if (widget.isLoadingDesignations)
            _buildLoadingField('Loading designations...')
          else if (widget.employee.designations != null &&
              widget.employee.designations!.isNotEmpty)
            _buildDynamicDropdownField(
              'Designation',
              widget.employee.designations!,
              widget.employee.designationId?.toString(),
              (value) {
                widget.onChanged(
                  widget.employee.copyWith(
                    designationId: int.tryParse(value ?? ''),
                  ),
                );
              },
              isRequired: true,
              isDisabled: widget.employee.departmentId == null,
            )
          else
            _buildTextField(
              'Designation ID',
              TextEditingController(
                text: widget.employee.designationId?.toString() ?? '',
              ),
              (value) {
                widget.onChanged(
                  widget.employee.copyWith(designationId: int.tryParse(value)),
                );
              },
              keyboardType: TextInputType.number,
            ),

          // Role dropdown
          if (widget.employee.roles != null &&
              widget.employee.roles!.isNotEmpty)
            _buildDynamicDropdownField(
              'Role',
              widget.employee.roles!,
              widget.employee.roleId
                  ?.toString(), // Use roleId instead of designationId
              (value) {
                widget.onChanged(
                  widget.employee.copyWith(
                    roleId: int.tryParse(value ?? ''), // Update roleId
                  ),
                );
              },
            ),

          _buildDateField('Date of Joining', _companyDojController.text, (
            date,
          ) {
            widget.onChanged(widget.employee.copyWith(companyDoj: date));
          }, isRequired: true),

          // Documents dropdown if available
          if (widget.employee.documentList != null &&
              widget.employee.documentList!.isNotEmpty)
            _buildDocumentsDropdown(),

          _buildTextField('Documents', _documentsController, (value) {
            widget.onChanged(widget.employee.copyWith(documents: value));
          }, hint: 'Comma separated document IDs'),

          _buildDropdownField(
            'Status',
            {'1': 'Active', '0': 'Inactive'},
            (widget.employee.isActive ?? 1).toString(),
            (value) {
              widget.onChanged(
                widget.employee.copyWith(
                  isActive: int.tryParse(value ?? '1') ?? 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsDropdown() {
    final documents = widget.employee.documentList ?? [];
    final selectedDocs =
        widget.employee.documents?.split(',').map((e) => e.trim()).toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        title: Text('Documents (${selectedDocs.length} selected)'),
        children: documents.map((doc) {
          final docId = doc['id'].toString();
          final docName = doc['name']?.toString() ?? 'Document $docId';
          final isRequired = doc['is_required'] == "1";

          return CheckboxListTile(
            title: Text('${isRequired ? '* ' : ''}$docName'),
            subtitle: isRequired
                ? Text('Required', style: TextStyle(color: Colors.red))
                : null,
            value: selectedDocs.contains(docId),
            onChanged: (value) {
              final newDocs = List<String>.from(selectedDocs);
              if (value == true) {
                if (!newDocs.contains(docId)) newDocs.add(docId);
              } else {
                newDocs.remove(docId);
              }
              widget.onChanged(
                widget.employee.copyWith(documents: newDocs.join(',')),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingField(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: text,
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            CircularProgressIndicator(value: 16),
            SizedBox(width: 10),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          hintText: hint,
          border: OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: isRequired && controller.text.isEmpty
            ? (value) => 'Required'
            : null,
      ),
    );
  }

  Widget _buildDateField(
    String label,
    String currentValue,
    Function(String) onDateSelected, {
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () async {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: currentValue.isNotEmpty
                ? DateTime.tryParse(currentValue) ?? DateTime.now()
                : DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (selectedDate != null) {
            onDateSelected(selectedDate.toIso8601String().split('T')[0]);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label + (isRequired ? '*' : ''),
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentValue.isNotEmpty ? currentValue : 'Select date',
                style: TextStyle(
                  color: currentValue.isNotEmpty ? Colors.black : Colors.grey,
                ),
              ),
              Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicDropdownField(
    String label,
    Map<String, String> options,
    String? value,
    Function(String?) onChanged, {
    bool isRequired = false,
    bool isDisabled = false,
  }) {
    // Validation: Ensure value exists in options
    final effectiveValue = (value != null && options.containsKey(value))
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          border: OutlineInputBorder(),
        ),
        value: effectiveValue,
        items: [
          DropdownMenuItem<String>(value: null, child: Text('Select $label')),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ],
        onChanged: isDisabled ? null : onChanged,
        validator:
            isRequired && (effectiveValue == null || effectiveValue.isEmpty)
            ? (val) => 'Please select $label'
            : null,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    Map<String, String> options,
    String? value,
    Function(String?) onChanged,
  ) {
    // Validation: Ensure value exists in options
    final effectiveValue = (value != null && options.containsKey(value))
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        value: effectiveValue,
        items: [
          DropdownMenuItem<String>(value: null, child: Text('Select $label')),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// Bank Details Tab (no changes needed)
class _BankDetailsTab extends StatefulWidget {
  final Employee employee;
  final Function(Employee) onChanged;

  const _BankDetailsTab({
    Key? key,
    required this.employee,
    required this.onChanged,
  }) : super(key: key);

  @override
  __BankDetailsTabState createState() => __BankDetailsTabState();
}

class __BankDetailsTabState extends State<_BankDetailsTab> {
  late TextEditingController _accountHolderNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankIdentifierCodeController;
  late TextEditingController _branchLocationController;
  late TextEditingController _taxPayerIdController;

  @override
  void initState() {
    super.initState();
    _accountHolderNameController = TextEditingController(
      text: widget.employee.accountHolderName ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.employee.accountNumber ?? '',
    );
    _bankNameController = TextEditingController(
      text: widget.employee.bankName ?? '',
    );
    _bankIdentifierCodeController = TextEditingController(
      text: widget.employee.bankIdentifierCode ?? '',
    );
    _branchLocationController = TextEditingController(
      text: widget.employee.branchLocation ?? '',
    );
    _taxPayerIdController = TextEditingController(
      text: widget.employee.taxPayerId ?? '',
    );
  }

  @override
  void didUpdateWidget(_BankDetailsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.employee != oldWidget.employee) {
      if (_accountHolderNameController.text !=
          (widget.employee.accountHolderName ?? '')) {
        _accountHolderNameController.text =
            widget.employee.accountHolderName ?? '';
      }
      if (_accountNumberController.text !=
          (widget.employee.accountNumber ?? '')) {
        _accountNumberController.text = widget.employee.accountNumber ?? '';
      }
      if (_bankNameController.text != (widget.employee.bankName ?? '')) {
        _bankNameController.text = widget.employee.bankName ?? '';
      }
      if (_bankIdentifierCodeController.text !=
          (widget.employee.bankIdentifierCode ?? '')) {
        _bankIdentifierCodeController.text =
            widget.employee.bankIdentifierCode ?? '';
      }
      if (_branchLocationController.text !=
          (widget.employee.branchLocation ?? '')) {
        _branchLocationController.text = widget.employee.branchLocation ?? '';
      }
      if (_taxPayerIdController.text != (widget.employee.taxPayerId ?? '')) {
        _taxPayerIdController.text = widget.employee.taxPayerId ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField('Account Holder Name', _accountHolderNameController, (
            value,
          ) {
            widget.onChanged(
              widget.employee.copyWith(accountHolderName: value),
            );
          }),

          _buildTextField(
            'Account Number',
            _accountNumberController,
            (value) {
              widget.onChanged(widget.employee.copyWith(accountNumber: value));
            },
            keyboardType: TextInputType.number,
          ),

          _buildTextField('Bank Name', _bankNameController, (value) {
            widget.onChanged(widget.employee.copyWith(bankName: value));
          }),

          _buildDropdownField(
            'Account Type',
            {'Savings': 'Savings', 'Current': 'Current', 'Salary': 'Salary'},
            widget.employee.accountType,
            (value) {
              widget.onChanged(widget.employee.copyWith(accountType: value));
            },
          ),

          _buildTextField(
            'Bank Identifier Code (BIC/SWIFT)',
            _bankIdentifierCodeController,
            (value) {
              widget.onChanged(
                widget.employee.copyWith(bankIdentifierCode: value),
              );
            },
          ),

          _buildTextField('Branch Location', _branchLocationController, (
            value,
          ) {
            widget.onChanged(widget.employee.copyWith(branchLocation: value));
          }),

          _buildTextField('Tax Payer ID', _taxPayerIdController, (value) {
            widget.onChanged(widget.employee.copyWith(taxPayerId: value));
          }),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    Map<String, String> options,
    String? value,
    Function(String?) onChanged,
  ) {
    // Validation: Ensure value exists in options
    final effectiveValue = (value != null && options.containsKey(value))
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        value: effectiveValue,
        items: [
          DropdownMenuItem<String>(value: null, child: Text('Select $label')),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// Additional Details Tab (no changes needed)
class _AdditionalDetailsTab extends StatefulWidget {
  final Employee employee;
  final Function(Employee) onChanged;

  const _AdditionalDetailsTab({
    Key? key,
    required this.employee,
    required this.onChanged,
  }) : super(key: key);

  @override
  __AdditionalDetailsTabState createState() => __AdditionalDetailsTabState();
}

class __AdditionalDetailsTabState extends State<_AdditionalDetailsTab> {
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late TextEditingController _cityController;
  late TextEditingController _zipcodeController;
  late TextEditingController _organisationSwitchController;
  late TextEditingController _providentFundNoController;
  late TextEditingController _emergencyContactNoController;
  late TextEditingController _emergencyAddressController;
  late TextEditingController _hoursPerDayController;
  late TextEditingController _annualSalaryController;
  late TextEditingController _daysPerWeekController;
  late TextEditingController _fixedSalaryController;
  late TextEditingController _hoursPerMonthController;
  late TextEditingController _ratePerDayController;
  late TextEditingController _daysPerMonthController;
  late TextEditingController _ratePerHourController;
  late TextEditingController _salaryController;

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController(
      text: widget.employee.country ?? '',
    );
    _stateController = TextEditingController(text: widget.employee.state ?? '');
    _cityController = TextEditingController(text: widget.employee.city ?? '');
    _zipcodeController = TextEditingController(
      text: widget.employee.zipcode ?? '',
    );
    _organisationSwitchController = TextEditingController(
      text: widget.employee.organisationSwitch ?? 'ORG-A',
    );
    _providentFundNoController = TextEditingController(
      text: widget.employee.providentFundNo ?? '',
    );
    _emergencyContactNoController = TextEditingController(
      text: widget.employee.emergencyContactNo ?? '',
    );
    _emergencyAddressController = TextEditingController(
      text: widget.employee.emergencyAddress ?? '',
    );
    _hoursPerDayController = TextEditingController(
      text: widget.employee.hoursPerDay ?? '',
    );
    _annualSalaryController = TextEditingController(
      text: widget.employee.annualSalary ?? '',
    );
    _daysPerWeekController = TextEditingController(
      text: widget.employee.daysPerWeek ?? '',
    );
    _fixedSalaryController = TextEditingController(
      text: widget.employee.fixedSalary ?? '',
    );
    _hoursPerMonthController = TextEditingController(
      text: widget.employee.hoursPerMonth ?? '',
    );
    _ratePerDayController = TextEditingController(
      text: widget.employee.ratePerDay ?? '',
    );
    _daysPerMonthController = TextEditingController(
      text: widget.employee.daysPerMonth ?? '',
    );
    _ratePerHourController = TextEditingController(
      text: widget.employee.ratePerHour ?? '',
    );
    _salaryController = TextEditingController(
      text: widget.employee.salary ?? '',
    );
  }

  @override
  void didUpdateWidget(_AdditionalDetailsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.employee != oldWidget.employee) {
      if (_countryController.text != (widget.employee.country ?? '')) {
        _countryController.text = widget.employee.country ?? '';
      }
      if (_stateController.text != (widget.employee.state ?? '')) {
        _stateController.text = widget.employee.state ?? '';
      }
      if (_cityController.text != (widget.employee.city ?? '')) {
        _cityController.text = widget.employee.city ?? '';
      }
      if (_zipcodeController.text != (widget.employee.zipcode ?? '')) {
        _zipcodeController.text = widget.employee.zipcode ?? '';
      }
      if (_organisationSwitchController.text !=
          (widget.employee.organisationSwitch ?? 'ORG-A')) {
        _organisationSwitchController.text =
            widget.employee.organisationSwitch ?? 'ORG-A';
      }
      if (_providentFundNoController.text !=
          (widget.employee.providentFundNo ?? '')) {
        _providentFundNoController.text = widget.employee.providentFundNo ?? '';
      }
      if (_emergencyContactNoController.text !=
          (widget.employee.emergencyContactNo ?? '')) {
        _emergencyContactNoController.text =
            widget.employee.emergencyContactNo ?? '';
      }
      if (_emergencyAddressController.text !=
          (widget.employee.emergencyAddress ?? '')) {
        _emergencyAddressController.text =
            widget.employee.emergencyAddress ?? '';
      }
      if (_hoursPerDayController.text != (widget.employee.hoursPerDay ?? '')) {
        _hoursPerDayController.text = widget.employee.hoursPerDay ?? '';
      }
      if (_annualSalaryController.text !=
          (widget.employee.annualSalary ?? '')) {
        _annualSalaryController.text = widget.employee.annualSalary ?? '';
      }
      if (_daysPerWeekController.text != (widget.employee.daysPerWeek ?? '')) {
        _daysPerWeekController.text = widget.employee.daysPerWeek ?? '';
      }
      if (_fixedSalaryController.text != (widget.employee.fixedSalary ?? '')) {
        _fixedSalaryController.text = widget.employee.fixedSalary ?? '';
      }
      if (_hoursPerMonthController.text !=
          (widget.employee.hoursPerMonth ?? '')) {
        _hoursPerMonthController.text = widget.employee.hoursPerMonth ?? '';
      }
      if (_ratePerDayController.text != (widget.employee.ratePerDay ?? '')) {
        _ratePerDayController.text = widget.employee.ratePerDay ?? '';
      }
      if (_daysPerMonthController.text !=
          (widget.employee.daysPerMonth ?? '')) {
        _daysPerMonthController.text = widget.employee.daysPerMonth ?? '';
      }
      if (_ratePerHourController.text != (widget.employee.ratePerHour ?? '')) {
        _ratePerHourController.text = widget.employee.ratePerHour ?? '';
      }
      if (_salaryController.text != (widget.employee.salary ?? '')) {
        _salaryController.text = widget.employee.salary ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Dynamic location type dropdown
          if (widget.employee.locationTypes != null &&
              widget.employee.locationTypes!.isNotEmpty)
            _buildDynamicDropdownField(
              'Location Type',
              widget.employee.locationTypes!,
              widget.employee.locationType,
              (value) {
                widget.onChanged(widget.employee.copyWith(locationType: value));
              },
            )
          else
            _buildDropdownField(
              'Location Type',
              {
                'residential': 'Residential',
                'postal': 'Postal',
                'work_address': 'Work Address',
                'office': 'Office',
                'remote': 'Remote',
                'hybrid': 'Hybrid',
              },
              widget.employee.locationType,
              (value) {
                widget.onChanged(widget.employee.copyWith(locationType: value));
              },
            ),

          _buildTextField('Country', _countryController, (value) {
            widget.onChanged(widget.employee.copyWith(country: value));
          }),

          _buildTextField('State', _stateController, (value) {
            widget.onChanged(widget.employee.copyWith(state: value));
          }),

          _buildTextField('City', _cityController, (value) {
            widget.onChanged(widget.employee.copyWith(city: value));
          }),

          _buildTextField('Zipcode', _zipcodeController, (value) {
            widget.onChanged(widget.employee.copyWith(zipcode: value));
          }, keyboardType: TextInputType.number),

          SizedBox(height: 20),
          _buildSectionHeader('Organization Details'),
          _buildTextField(
            'Organization Switch',
            _organisationSwitchController,
            (value) {
              widget.onChanged(
                widget.employee.copyWith(organisationSwitch: value),
              );
            },
          ),

          _buildTextField('Provident Fund No.', _providentFundNoController, (
            value,
          ) {
            widget.onChanged(widget.employee.copyWith(providentFundNo: value));
          }),

          SizedBox(height: 20),
          _buildSectionHeader('Emergency Contact'),
          _buildTextField(
            'Emergency Contact No.',
            _emergencyContactNoController,
            (value) {
              widget.onChanged(
                widget.employee.copyWith(emergencyContactNo: value),
              );
            },
            keyboardType: TextInputType.phone,
          ),

          _buildTextField('Emergency Address', _emergencyAddressController, (
            value,
          ) {
            widget.onChanged(widget.employee.copyWith(emergencyAddress: value));
          }, maxLines: 2),

          SizedBox(height: 20),
          _buildSectionHeader('Salary Details'),
          _buildDropdownField(
            'Salary Type',
            {
              'Monthly': 'Monthly',
              'Hourly': 'Hourly',
              'Weekly': 'Weekly',
              'Annual': 'Annual',
              'Fixed': 'Fixed',
            },
            widget.employee.salaryType,
            (value) {
              widget.onChanged(widget.employee.copyWith(salaryType: value));
            },
          ),

          _buildTextField('Salary', _salaryController, (value) {
            widget.onChanged(widget.employee.copyWith(salary: value));
          }, keyboardType: TextInputType.number),

          SwitchListTile(
            title: Text('Payment Requires Work Advice'),
            value: widget.employee.paymentRequiresWorkAdvice == 'on',
            onChanged: (value) {
              widget.onChanged(
                widget.employee.copyWith(
                  paymentRequiresWorkAdvice: value ? 'on' : 'off',
                ),
              );
            },
          ),

          SizedBox(height: 20),
          _buildSectionHeader('Work Hours'),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Hours/Day',
                  _hoursPerDayController,
                  (value) {
                    widget.onChanged(
                      widget.employee.copyWith(hoursPerDay: value),
                    );
                  },
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  'Days/Week',
                  _daysPerWeekController,
                  (value) {
                    widget.onChanged(
                      widget.employee.copyWith(daysPerWeek: value),
                    );
                  },
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Hours/Month',
                  _hoursPerMonthController,
                  (value) {
                    widget.onChanged(
                      widget.employee.copyWith(hoursPerMonth: value),
                    );
                  },
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  'Days/Month',
                  _daysPerMonthController,
                  (value) {
                    widget.onChanged(
                      widget.employee.copyWith(daysPerMonth: value),
                    );
                  },
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),
          _buildSectionHeader('Rates'),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Rate/Hour',
                  _ratePerHourController,
                  (value) {
                    widget.onChanged(
                      widget.employee.copyWith(ratePerHour: value),
                    );
                  },
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  'Rate/Day',
                  _ratePerDayController,
                  (value) {
                    widget.onChanged(
                      widget.employee.copyWith(ratePerDay: value),
                    );
                  },
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          _buildTextField(
            'Annual Salary',
            _annualSalaryController,
            (value) {
              widget.onChanged(widget.employee.copyWith(annualSalary: value));
            },
            keyboardType: TextInputType.number,
          ),

          _buildTextField(
            'Fixed Salary',
            _fixedSalaryController,
            (value) {
              widget.onChanged(widget.employee.copyWith(fixedSalary: value));
            },
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDynamicDropdownField(
    String label,
    Map<String, String> options,
    String? value,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        value: value,
        items: [
          DropdownMenuItem<String>(value: null, child: Text('Select $label')),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    Map<String, String> options,
    String? value,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        value: value,
        items: [
          DropdownMenuItem<String>(value: null, child: Text('Select $label')),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
