import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecoteam_app/admin/services/employee_services.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecoteam_app/admin/models/employee_model.dart';
import 'package:ecoteam_app/admin/services/transfer_employee_services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/contractor/view/widgets/notification_actions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/read_only_employee_view.dart';

class EmployeePage extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String)? onSiteChanged;
  final List<Site>? sites;
  final String? selectedSiteName;
  final int workspaceId;

  const EmployeePage({
    super.key,
    this.selectedSiteName,
    this.selectedSiteId,
    this.onSiteChanged,
    this.sites,
    required this.workspaceId,
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
  int? _currentUserId;

  Future<int> _resolveWorkspaceId() async {
    int workspaceId = widget.workspaceId;
    print('🔍 _resolveWorkspaceId: Initial workspaceId = $workspaceId');

    // 1. Try to resolve from Selected Site
    if (widget.selectedSiteId != null) {
      print(
        '🔍 _resolveWorkspaceId: selectedSiteId = ${widget.selectedSiteId}',
      );
      try {
        final provider = Provider.of<CompanySiteProvider>(
          context,
          listen: false,
        );

        // Debug: Print available sites
        // print('🔍 _resolveWorkspaceId: provider.allSites count = ${provider.allSites.length}');
        // print('🔍 _resolveWorkspaceId: widget.sites count = ${widget.sites?.length}');

        // Check provider allSites first
        final site = provider.allSites.firstWhere(
          (s) => s.id == widget.selectedSiteId,
          orElse: () =>
              widget.sites?.firstWhere((s) => s.id == widget.selectedSiteId) ??
              Site(id: '', name: '', companyId: ''),
        );

        if (site.companyId.isNotEmpty) {
          print(
            '🔍 _resolveWorkspaceId: Found site ${site.name} with companyId = ${site.companyId}',
          );
          final parsed = int.tryParse(site.companyId);
          if (parsed != null && parsed != 0) {
            print('✅ _resolveWorkspaceId: Resolved from Site -> $parsed');
            return parsed;
          }
        } else {
          print(
            '⚠️ _resolveWorkspaceId: Site found but companyId is empty or site not found (dummy)',
          );
        }
      } catch (e) {
        print('❌ Error resolving workspace from site: $e');
      }
    } else {
      print('🔍 _resolveWorkspaceId: selectedSiteId is NULL');
    }

    // 2. Try Provider Selected Company
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);
    if (provider.selectedCompanyId != null) {
      print(
        '🔍 _resolveWorkspaceId: provider.selectedCompanyId = ${provider.selectedCompanyId}',
      );
      final parsed = int.tryParse(provider.selectedCompanyId!);
      if (parsed != null && parsed != 0) {
        print('✅ _resolveWorkspaceId: Resolved from Provider -> $parsed');
        return parsed;
      }
    } else {
      print('🔍 _resolveWorkspaceId: provider.selectedCompanyId is NULL');
    }

    // 3. Fallback to SharedPreferences if default/0
    if (workspaceId == 0 || workspaceId == 3) {
      print('🔍 _resolveWorkspaceId: Attempting SharedPreferences fallback...');
      try {
        final prefs = await SharedPreferences.getInstance();
        final userDataStr = prefs.getString('user_data');
        if (userDataStr != null) {
          final userData = json.decode(userDataStr);
          print('🔍 _resolveWorkspaceId: user_data found');
          if (userData['workspace_id'] != null) {
            final parsed = int.tryParse(userData['workspace_id'].toString());
            if (parsed != null && parsed != 0) {
              print(
                '✅ _resolveWorkspaceId: Resolved from Prefs (root) -> $parsed',
              );
              return parsed;
            }
          } else if (userData['user'] != null &&
              userData['user']['workspace_id'] != null) {
            final parsed = int.tryParse(
              userData['user']['workspace_id'].toString(),
            );
            if (parsed != null && parsed != 0) {
              print(
                '✅ _resolveWorkspaceId: Resolved from Prefs (nested) -> $parsed',
              );
              return parsed;
            }
          }
        } else {
          print('⚠️ _resolveWorkspaceId: user_data is NULL');
        }
      } catch (e) {
        print('❌ Error resolving workspace from prefs: $e');
      }
    }

    print('⚠️ _resolveWorkspaceId: Returning default/initial -> $workspaceId');
    return workspaceId;
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // Chains to _loadCreationData
    _loadEmployees();
    searchController.addListener(_filterEmployees);
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = json.decode(
          userDataString,
        ); // requires import dart:convert
        setState(() {
          if (userData['user'] != null && userData['user']['id'] != null) {
            _currentUserId = userData['user']['id'];
          } else if (userData['id'] != null) {
            _currentUserId = userData['id'];
          }
        });
      }

      // Load creation data after user is loaded
      await _loadCreationData();
    } catch (e) {
      print('Error loading user ID: $e');
      // Even if user load fails, try loading creation data
      await _loadCreationData();
    }
  }

  Future<void> _loadCreationData() async {
    try {
      // Safe parsing of site ID
      int? siteIdInt;
      if (widget.selectedSiteId != null) {
        siteIdInt = int.tryParse(widget.selectedSiteId!);
      }

      final provider = Provider.of<CompanySiteProvider>(context, listen: false);
      int workspaceId = await _resolveWorkspaceId();

      final data = await ApiService.fetchEmployeeCreationData(
        workspaceId: workspaceId,
        siteId: siteIdInt,
        createdBy: _currentUserId ?? 9,
      );
      setState(() {
        creationDataEmployee = data;
      });
    } catch (e) {
      print('Error loading creation data: $e');
    }
  }

  Future<void> _loadEmployees({bool showLoading = true}) async {
    if (showLoading) setState(() => isLoading = true);

    try {
      // Safe parsing of site ID
      int? siteIdInt;
      if (widget.selectedSiteId != null) {
        siteIdInt = int.tryParse(widget.selectedSiteId!);
      }

      final provider = Provider.of<CompanySiteProvider>(context, listen: false);
      int workspaceId = await _resolveWorkspaceId();

      final fetchedEmployees = await ApiService.fetchEmployees(
        workspaceId: workspaceId,
        siteId: siteIdInt,
      );

      setState(() {
        employees = fetchedEmployees;
        filteredEmployees = fetchedEmployees;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load employees',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);
    int workspaceId = await _resolveWorkspaceId();
    print('🚀 _addEmployee: Validated Workspace ID to use: $workspaceId');

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return EmployeeBottomSheet(
              creationData: creationDataEmployee,
              workspaceId: workspaceId,
              userId: _currentUserId,
              onSave: (employee, avatarFile, documentFiles) async {
                try {
                  // FORCE the resolved workspaceId
                  print(
                    '🚀 _addEmployee: Forcing workspaceId $workspaceId before API call',
                  );
                  final employeeToSend = employee.copyWith(
                    workspace: workspaceId,
                  );

                  final newEmployee = await ApiService.addEmployee(
                    employeeToSend,
                    avatarFile: avatarFile,
                    documentFiles: documentFiles,
                  );
                  return newEmployee;
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add employee')),
                  );
                  return null;
                }
              },
              siteId: widget.selectedSiteId != null
                  ? int.tryParse(widget.selectedSiteId!)
                  : null,
            );
          },
        ),
      ),
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Employee added successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadEmployees();
    }
  }

  Future<void> _editEmployee(Employee employee) async {
    final provider = Provider.of<CompanySiteProvider>(context, listen: false);
    int workspaceId = await _resolveWorkspaceId();

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return EmployeeBottomSheet(
              employee: employee,
              creationData: creationDataEmployee,
              workspaceId: workspaceId,
              userId: _currentUserId,
              onSave: (updatedEmployee, avatarFile, documentFiles) async {
                try {
                  // FORCE the resolved workspaceId
                  print(
                    '🚀 _editEmployee: Forcing workspaceId $workspaceId before API call',
                  );
                  final employeeToSend = updatedEmployee.copyWith(
                    workspace: workspaceId,
                  );

                  final savedEmployee = await ApiService.updateEmployee(
                    employeeToSend,
                    avatarFile: avatarFile,
                    documentFiles: documentFiles,
                  );
                  return savedEmployee;
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update employee')),
                  );
                  return null;
                }
              },
              siteId: widget.selectedSiteId != null
                  ? int.tryParse(widget.selectedSiteId!)
                  : null,
            );
          },
        ),
      ),
    );

    if (result != null) {
      _loadEmployees();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Employee updated successfully')));
    }
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color Iconcolor,
    required String title,
    Color? backgroundColor,
    required VoidCallback onTap,
    Color color = const Color(0xFF2D3748),
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF6f88e2).withOpacity(0.1),
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

  void _showEmployeeOptionsBottomSheet(Employee employee) {
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
            if (provider.hasPermission('employee show'))
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
                  _showEmployeeDetailsBottomSheet(employee);
                },
              ),
            // if (provider.hasPermission('employee transfer'))
            _buildOptionTile(
              icon: Icons.swap_horiz,
              title: 'Transfer Employee',
              Iconcolor: Colors.orange,
              backgroundColor: Colors.orange.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                _showEmployeeTransferSheet(employee);
              },
            ),
            if (provider.hasPermission('employee edit'))
              _buildOptionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Employee',
                Iconcolor: Colors.blue,
                backgroundColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _editEmployee(employee);
                },
              ),
            if (provider.hasPermission('employee delete'))
              _buildOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Employee',
                color: Colors.red,
                Iconcolor: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    _deleteEmployee(employee);
                  });
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _getSiteName(int? siteId) {
    if (siteId == null || widget.sites == null || widget.sites!.isEmpty) {
      return 'N/A';
    }
    try {
      final site = widget.sites!.firstWhere(
        (site) => site.id == siteId.toString(),
        orElse: () => Site(id: '', name: 'Unknown Site', companyId: ''),
      );
      return site.name;
    } catch (e) {
      return 'Unknown Site';
    }
  }

  void _showEmployeeDetailsBottomSheet(Employee employee) async {
    final workspaceId = await _resolveWorkspaceId();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReadOnlyEmployeeBottomSheet(
        employee: employee.copyWith(workspace: workspaceId),
      ),
    );
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
          setState(() {
            employees.removeWhere((e) => e.id == employee.id);
            _filterEmployees();
          });
          _loadEmployees(showLoading: false);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete employee')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CompanySiteProvider>(context);
    final canCreate = provider.hasPermission('employee create');
    final canShow = provider.hasPermission('employee show');

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
        actions: buildNotificationActions(
          context: context,
          selectedSiteId: widget.selectedSiteId,
          sites: widget.sites ?? [],
          currentCompany: provider.selectedCompanyName ?? '',
          workspaceId: widget.workspaceId,
        ),
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
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _addEmployee,
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: const Color.fromRGBO(42, 67, 160, 1),
            )
          : null,
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
                          padding: EdgeInsets.only(bottom: 80),
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = filteredEmployees[index];
                            return EmployeeCard(
                              employee: employee,
                              onMenuPressed: () =>
                                  _showEmployeeOptionsBottomSheet(employee),
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
                final provider = Provider.of<CompanySiteProvider>(
                  context,
                  listen: false,
                );
                int workspaceId = 3;
                if (provider.selectedCompanyId != null) {
                  workspaceId = int.tryParse(provider.selectedCompanyId!) ?? 3;
                }

                final result = await EmployeeTransferServices.fetchToSites(
                  siteId:
                      employee.siteId ??
                      int.tryParse(widget.selectedSiteId ?? '0') ??
                      0,
                  workspaceId: workspaceId,
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
                  error = 'Failed to load sites';
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
                  color: const Color.fromARGB(255, 253, 253, 255),
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
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                    await EmployeeTransferServices.createTransfer({
                                      'transfer_type': 'employee',
                                      // User request interpretation: Swap/Map corresponding IDs
                                      // "use user id to employee id" -> Set employee_id = userId
                                      'employee_id': employee.userId ?? 0,
                                      // "use employee id = userid" (sic, context suggests swapping) -> Set user_id = employee.id
                                      'user_id': int.tryParse(employee.id) ?? 0,
                                      'transfer_date':
                                          transferDateController.text,
                                      'from_site_id':
                                          int.tryParse(
                                            (employee.siteId ??
                                                    widget.selectedSiteId)
                                                .toString(),
                                          ) ??
                                          0,
                                      'to_site_id':
                                          int.tryParse(selectedToSite!) ?? 0,
                                      'created_by': _currentUserId ?? 9,
                                    });

                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Employee transferred successfully',
                                        ),
                                      ),
                                    );
                                    setState(() {
                                      employees.removeWhere(
                                        (e) => e.id == employee.id,
                                      );
                                      _filterEmployees();
                                    });
                                    _loadEmployees(showLoading: false);
                                  } catch (e) {
                                    print('Transfer Error: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Transfer failed: ${e.toString().replaceAll("Exception: ", "")}',
                                        ),
                                        backgroundColor: Colors.red,
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
          fillColor: const Color.fromARGB(255, 253, 253, 255),
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
          fillColor: const Color.fromARGB(255, 253, 253, 255),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onMenuPressed;
  final bool isSmallScreen;

  const EmployeeCard({
    Key? key,
    required this.employee,
    required this.onMenuPressed,
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
                                'https://app.ecoteamsolar.com/${employee.avatar}',
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
                          const SizedBox(height: 4),
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
                    // Status, and More Options button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (employee.dateOfJoining != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                        const SizedBox(width: 8),

                        // More Options Button
                        if (Provider.of<CompanySiteProvider>(
                              context,
                            ).hasPermission('employee show') ||
                            //Provider.of<CompanySiteProvider>(context).hasPermission('employee transfer') ||
                            Provider.of<CompanySiteProvider>(
                              context,
                            ).hasPermission('employee edit') ||
                            Provider.of<CompanySiteProvider>(
                              context,
                            ).hasPermission('employee delete'))
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: onMenuPressed,
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
                    if ((employee.phone != null &&
                            employee.phone!.isNotEmpty) ||
                        (employee.branchName.isNotEmpty &&
                            employee.branchName != 'N/A'))
                      const SizedBox(height: 8),

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

                    if ((employee.departmentName.isNotEmpty &&
                            employee.departmentName != 'N/A') ||
                        (employee.designationName.isNotEmpty &&
                            employee.designationName != 'N/A'))
                      const SizedBox(height: 8),
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
    return Row(
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
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}

class EmployeeBottomSheet extends StatefulWidget {
  final Employee? employee;
  final Employee? creationData;
  final Future<Employee?> Function(Employee, File?, Map<String, File>?) onSave;
  final int? siteId;
  final int workspaceId;
  final int? userId;

  const EmployeeBottomSheet({
    Key? key,
    this.employee,
    this.creationData,
    required this.onSave,
    this.siteId,
    this.workspaceId = 3,
    this.userId,
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
  bool _isLoadingCreationData = false;
  bool _isLoadingDepartments = false;
  bool _isLoadingDesignations = false;
  File? _avatarFile;
  Map<String, File> _documentFiles = {};

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
          workspace: widget.workspaceId,
          createdBy: widget.userId ?? 9,
          siteId: widget.siteId,

          employeesId: '#EMP00000001',
        );

    print(
      '🛠️ EmployeeBottomSheet initialized with workspaceId: ${widget.workspaceId}',
    );
    print(
      '🛠️ Employee model initialized with workspace: ${_employee.workspace}',
    );

    // Initialize with creation data if available
    if (widget.creationData != null) {
      _applyCreationData(widget.creationData!);
    } else {
      _loadCreationDataFallback();
    }

    _tabController = TabController(length: 4, vsync: this);
  }

  void _applyCreationData(Employee data) {
    print(
      'Applying creation data: ${data.branches?.length} branches, ${data.departments?.length} depts, ${data.designations?.length} desigs',
    );
    setState(() {
      _employee = _employee.copyWith(
        employeesId: data.employeesId, // Use fetched ID
        departments: data.departments,
        designations: data.designations,
        branches: data.branches,
        roles: data.roles,
        locationTypes: data.locationTypes,
        assignProjects: data.assignProjects, // Ensure this is copied
        documentList: data.documentList,
        // Also copy IDs if the creation data has defaults?
        // Usually creation data just has metadata, but if it has defaults:
        workspace: data.workspace,
      );
    });
  }

  Future<void> _loadCreationDataFallback() async {
    setState(() => _isLoadingCreationData = true);
    try {
      final provider = Provider.of<CompanySiteProvider>(context, listen: false);
      final createdBy = provider.currentUserId ?? 9;

      final data = await ApiService.fetchEmployeeCreationData(
        workspaceId: widget.workspaceId,
        siteId: widget.siteId,
        createdBy: createdBy,
      );
      _applyCreationData(data);
    } catch (e) {
      print('Error loading creation data fallback: $e');
    } finally {
      setState(() => _isLoadingCreationData = false);
    }
  }

  Future<void> _loadDepartments(int branchId) async {
    setState(() => _isLoadingDepartments = true);

    try {
      final departments = await ApiService.fetchDepartments(
        branchId: branchId,
        workspaceId: widget.workspaceId,
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

  Future<void> _loadDesignations(int departmentId) async {
    setState(() => _isLoadingDesignations = true);

    try {
      final designations = await ApiService.fetchDesignations(
        departmentId: departmentId,
        workspaceId: widget.workspaceId,
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
  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Icon + Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF2a43a0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.employee == null ? Icons.person_add : Icons.edit,
                    color: Color(0xFF2a43a0),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employee == null
                            ? 'Add Employee'
                            : 'Edit Employee',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        widget.employee == null
                            ? 'Enter employee details below'
                            : 'Update employee information',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Color(0xFF2a43a0),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2a43a0),
            tabs: [
              Tab(text: 'Personal'),
              Tab(text: 'Company'),
              Tab(text: 'Bank'),
              Tab(text: 'Additional'),
            ],
          ),

          Divider(height: 1, color: Colors.grey[300]),

          // Form Content
          Expanded(
            child: Form(
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
                      final oldBranchId = _employee.branchId;
                      final oldDeptId = _employee.departmentId;

                      setState(() => _employee = employee);

                      // Load departments when branch changes
                      if (employee.branchId != null &&
                          employee.branchId != oldBranchId) {
                        _loadDepartments(employee.branchId!);
                      }
                      // Load designations when department changes
                      if (employee.departmentId != null &&
                          employee.departmentId != oldDeptId) {
                        _loadDesignations(employee.departmentId!);
                      }
                    },
                    isLoadingDepartments: _isLoadingDepartments,
                    isLoadingDesignations: _isLoadingDesignations,
                    isLoadingCreationData: _isLoadingCreationData,
                    documentFiles: _documentFiles,
                    onDocumentFileChanged: (id, file) {
                      setState(() => _documentFiles[id] = file);
                    },
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
          ),

          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveEmployee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2a43a0),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
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
    );
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      try {
        final savedEmployee = await widget.onSave(
          _employee,
          _avatarFile,
          _documentFiles,
        );
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
    } else {
      HapticFeedback.vibrate();
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
                            'https://app.ecoteamsolar.com/${widget.employee.avatar}',
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
          _buildTextField(
            'Name',
            _nameController,
            (value) {
              widget.onChanged(widget.employee.copyWith(name: value));
            },
            isRequired: true,
            hint: 'Enter full name',
          ),

          _buildTextField(
            'Email',
            _emailController,
            (value) {
              widget.onChanged(widget.employee.copyWith(email: value));
            },
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            hint: 'example@company.com',
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
              hint: 'Minimum 8 characters',
            ),

          _buildDateField('Date of Birth', _dobController.text, (date) {
            widget.onChanged(widget.employee.copyWith(dob: date));
          }, isRequired: true),

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

          _buildTextField(
            'Phone',
            _phoneController,
            (value) {
              widget.onChanged(widget.employee.copyWith(phone: value));
            },
            isRequired: true,
            keyboardType: TextInputType.phone,
            hint: '10-digit mobile number',
            prefixText: '+91 ',
          ),

          _buildTextField(
            'Address',
            _addressController,
            (value) {
              widget.onChanged(widget.employee.copyWith(address: value));
            },
            isRequired: true,
            maxLines: 3,
            hint: 'Street, City, State, ZIP code',
          ),
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
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          hintText: hint,
          prefixText: prefixText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 37, 62, 151),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          // Center the floating label
          alignLabelWithHint: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,

          // Additional styling for better appearance
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    Function(String) onDateSelected, {
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: FormField<String>(
        validator: isRequired && currentValue.isEmpty
            ? (val) => 'Required'
            : null,
        builder: (FormFieldState<String> state) {
          return InkWell(
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
                final dateStr = selectedDate.toIso8601String().split('T')[0];
                onDateSelected(dateStr);
                state.didChange(dateStr);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label + (isRequired ? '*' : ''),
                errorText: state.errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentValue.isNotEmpty ? currentValue : 'Select date',
                    style: TextStyle(
                      color: currentValue.isNotEmpty
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 20),
                ],
              ),
            ),
          );
        },
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
  final bool isLoadingCreationData;
  final Map<String, File> documentFiles;
  final Function(String, File) onDocumentFileChanged;

  const _CompanyDetailsTab({
    Key? key,
    required this.employee,
    required this.onChanged,
    this.isLoadingDepartments = false,
    this.isLoadingDesignations = false,
    this.isLoadingCreationData = false,
    required this.documentFiles,
    required this.onDocumentFileChanged,
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
          _buildTextField('Employees ID', _employeesIdController, (value) {
            widget.onChanged(widget.employee.copyWith(employeesId: value));
          }),

          // Branch dropdown
          if (widget.isLoadingCreationData)
            _buildLoadingField('Loading branches...')
          else
            _buildDynamicDropdownField(
              'Branch',
              widget.employee.branches ?? {},
              widget.employee.branchId?.toString(),
              (value) {
                final newEmployee = widget.employee.copyWith(
                  branchId: int.tryParse(value ?? ''),
                );
                // Manually reset downstream fields because copyWith ignores nulls
                newEmployee.departmentId = null;
                newEmployee.designationId = null;
                widget.onChanged(newEmployee);
              },
              isRequired: true,
            ),

          // Department dropdown
          if (widget.isLoadingDepartments || widget.isLoadingCreationData)
            _buildLoadingField('Loading departments...')
          else
            _buildDynamicDropdownField(
              'Department',
              widget.employee.departments ?? {},
              widget.employee.departmentId?.toString(),
              (value) {
                final newEmployee = widget.employee.copyWith(
                  departmentId: int.tryParse(value ?? ''),
                );
                // Manually reset downstream fields
                newEmployee.designationId = null;
                widget.onChanged(newEmployee);
              },
              isRequired: true,
              isDisabled: widget.employee.branchId == null,
            ),

          // Designation dropdown
          if (widget.isLoadingDesignations || widget.isLoadingCreationData)
            _buildLoadingField('Loading designations...')
          else
            _buildDynamicDropdownField(
              'Designation',
              widget.employee.designations ?? {},
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
            ),

          // Role dropdown
          if (widget.isLoadingCreationData)
            _buildLoadingField('Loading roles...')
          else if (widget.employee.roles != null &&
              widget.employee.roles!.isNotEmpty)
            _buildDynamicDropdownField(
              'Role',
              widget.employee.roles!,
              widget.employee.roleId?.toString(),
              (value) {
                widget.onChanged(
                  widget.employee.copyWith(roleId: int.tryParse(value ?? '')),
                );
              },
              isRequired: true,
            )
          else if (widget.employee.roles == null ||
              widget.employee.roles!.isEmpty)
            _buildTextField(
              'Role ID',
              TextEditingController(
                text: widget.employee.roleId?.toString() ?? '',
              ),
              (value) {
                widget.onChanged(
                  widget.employee.copyWith(roleId: int.tryParse(value)),
                );
              },
              keyboardType: TextInputType.number,
              hint: 'Enter Role ID manually',
            ),

          // Assign Site Dropdown
          if (widget.employee.assignProjects != null &&
              widget.employee.assignProjects!.isNotEmpty)
            _buildDynamicDropdownField(
              'Assign Site(s) / Project(s)',
              widget.employee.assignProjects!,
              widget.employee.siteId?.toString(),
              (value) {
                widget.onChanged(
                  widget.employee.copyWith(siteId: int.tryParse(value ?? '')),
                );
              },
            ),

          _buildDateField('Date of Joining', _companyDojController.text, (
            date,
          ) {
            widget.onChanged(widget.employee.copyWith(companyDoj: date));
          }, isRequired: true),

          // Documents uploaders if available
          // Documents section: upload in Add mode, view in Edit mode
          if (widget.employee.documentList != null &&
              widget.employee.documentList!.isNotEmpty)
            _buildDocumentUploaders(),
        ],
      ),
    );
  }

  // ─── ADD mode: upload slots ───────────────────────────────────────────────
  Widget _buildDocumentUploaders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Documents',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: Colors.grey[200]),
        const SizedBox(height: 20),
        ...widget.employee.documentList!.map((doc) {
          // Both creation-data and edit-mode documents handled here
          final docId = (doc['document_id'] ?? doc['id'] ?? '').toString();
          final docName =
              doc['document_type']?['name']?.toString() ??
              doc['name']?.toString() ??
              'Document $docId';
          return _buildSingleDocumentUploader(docId, docName);
        }).toList(),
      ],
    );
  }

  Widget _buildSingleDocumentUploader(String docId, String docName) {
    final file = widget.documentFiles[docId];
    final existingPath = widget.employee.documentUrls?[docId];
    final String fullUrl = 'https://app.ecoteamsolar.com/$existingPath';
    final String fileName = existingPath?.split('/').last ?? 'document';
    final bool isPdf = fileName.toLowerCase().endsWith('.pdf');
    final bool isImage =
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.webp');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            docName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => _pickDocument(docId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  bottomLeft: Radius.circular(6),
                                ),
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Choose File',
                                style: TextStyle(
                                  color: Color(0xFF4A5568),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                file != null
                                    ? file.path.split('/').last
                                    : (existingPath != null
                                          ? 'Existing: $fileName'
                                          : 'No file chosen'),
                                style: TextStyle(
                                  color: file != null || existingPath != null
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (existingPath != null && file == null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _TinyActionButton(
                            icon: Icons.visibility_outlined,
                            label: 'View',
                            color: Colors.blue,
                            onTap: () {
                              if (isImage) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _EmpFullScreenImageViewer(
                                      url: fullUrl,
                                      fileName: fileName,
                                    ),
                                  ),
                                );
                              } else {
                                launchUrl(
                                  Uri.parse(fullUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _TinyActionButton(
                            icon: Icons.download_rounded,
                            label: 'Download',
                            color: Colors.green,
                            onTap: () {
                              // We have _EmpDocViewCard logic for downloading
                              // but since we are in a different widget, we'll
                              // just use a simple downloader or trigger it.
                              // For now, let's keep it simple.
                              launchUrl(
                                Uri.parse(fullUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (file != null)
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else if (existingPath != null)
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.description, color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocument(String docId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      widget.onDocumentFileChanged(docId, File(image.path));
    }
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      child: FormField<String>(
        validator: isRequired && currentValue.isEmpty
            ? (val) => 'Required'
            : null,
        builder: (FormFieldState<String> state) {
          return InkWell(
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
                final dateStr = selectedDate.toIso8601String().split('T')[0];
                onDateSelected(dateStr);
                state.didChange(dateStr);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label + (isRequired ? '*' : ''),
                errorText: state.errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentValue.isNotEmpty ? currentValue : 'Select date',
                    style: TextStyle(
                      color: currentValue.isNotEmpty
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 20),
                ],
              ),
            ),
          );
        },
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
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        value: effectiveValue,
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('Select $label', overflow: TextOverflow.ellipsis),
          ),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          _buildTextField(
            'Account Holder Name',
            _accountHolderNameController,
            (value) {
              widget.onChanged(
                widget.employee.copyWith(accountHolderName: value),
              );
            },
            hint: 'Name exactly as in bank records',
          ),

          _buildTextField(
            'Account Number',
            _accountNumberController,
            (value) {
              widget.onChanged(widget.employee.copyWith(accountNumber: value));
            },
            keyboardType: TextInputType.number,
            hint: 'Enter account number',
          ),

          _buildTextField('Bank Name', _bankNameController, (value) {
            widget.onChanged(widget.employee.copyWith(bankName: value));
          }, hint: 'e.g., State Bank of India'),

          _buildTextField(
            'Bank Identifier Code (BIC/SWIFT)',
            _bankIdentifierCodeController,
            (value) {
              widget.onChanged(
                widget.employee.copyWith(bankIdentifierCode: value),
              );
            },
            hint: '11-character SWIFT code',
          ),

          _buildTextField(
            'Branch Location',
            _branchLocationController,
            (value) {
              widget.onChanged(widget.employee.copyWith(branchLocation: value));
            },
            hint: 'City and branch name',
          ),

          _buildTextField('Tax Payer ID', _taxPayerIdController, (value) {
            widget.onChanged(widget.employee.copyWith(taxPayerId: value));
          }, hint: 'PAN, TIN, or equivalent'),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    TextInputType keyboardType = TextInputType.text,
    String? hint, // Added hint parameter
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint, // Added hint text
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 37, 62, 151),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          // Floating label configuration
          floatingLabelBehavior: FloatingLabelBehavior.always,
          // Additional styling
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    Function(String?) onChanged, {
    String? hint, // Optional hint parameter for dropdown
  }) {
    // Validation: Ensure value exists in options
    final effectiveValue = (value != null && options.containsKey(value))
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint, // Added hint text
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 37, 62, 151),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          // Floating label configuration
          floatingLabelBehavior: FloatingLabelBehavior.always,
          // Additional styling
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        value: effectiveValue,
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('Select $label', style: TextStyle(color: Colors.grey)),
          ),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ],
        onChanged: onChanged,
        // Style for the dropdown button
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
        iconSize: 24,
        dropdownColor: Colors.white,
        style: TextStyle(fontSize: 16, color: Colors.black87),
        borderRadius: BorderRadius.circular(12),
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
          }, hint: 'e.g., India'),

          _buildTextField('State', _stateController, (value) {
            widget.onChanged(widget.employee.copyWith(state: value));
          }, hint: 'e.g., Maharashtra'),

          _buildTextField('City', _cityController, (value) {
            widget.onChanged(widget.employee.copyWith(city: value));
          }, hint: 'e.g., Mumbai'),

          _buildTextField(
            'Zipcode',
            _zipcodeController,
            (value) {
              widget.onChanged(widget.employee.copyWith(zipcode: value));
            },
            keyboardType: TextInputType.number,
            hint: 'Postal code',
          ),

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
            hint: 'Default: ORG-A',
          ),

          _buildTextField(
            'Provident Fund No.',
            _providentFundNoController,
            (value) {
              widget.onChanged(
                widget.employee.copyWith(providentFundNo: value),
              );
            },
            hint: 'PF account number',
          ),

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
            hint: 'Contact number in emergency',
          ),

          _buildTextField(
            'Emergency Address',
            _emergencyAddressController,
            (value) {
              widget.onChanged(
                widget.employee.copyWith(emergencyAddress: value),
              );
            },
            maxLines: 2,
            hint: 'Full address for emergency',
          ),

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

          _buildTextField(
            'Salary',
            _salaryController,
            (value) {
              widget.onChanged(widget.employee.copyWith(salary: value));
            },
            keyboardType: TextInputType.number,
            hint: 'Basic salary amount',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    double fontSize = 16,
    bool showDivider = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider)
          Divider(thickness: 1, color: Colors.grey[300], height: 20),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: fontSize + 4,
                decoration: BoxDecoration(
                  color: Color(0xFF2a43a0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2a43a0),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) SizedBox(height: 4),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
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
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 37, 62, 151),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 12 : 16,
          ),
          alignLabelWithHint: maxLines > 1,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: obscureText,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDynamicDropdownField(
    String label,
    Map<String, String> options,
    String? value,
    Function(String?) onChanged, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 37, 62, 151),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        value: value,
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('Select $label', style: TextStyle(color: Colors.grey)),
          ),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ],
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
        iconSize: 24,
        dropdownColor: Colors.white,
        style: TextStyle(fontSize: 16, color: Colors.black87),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    Map<String, String> options,
    String? value,
    Function(String?) onChanged, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 37, 62, 151),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        value: value,
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('Select $label', style: TextStyle(color: Colors.grey)),
          ),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ],
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
        iconSize: 24,
        dropdownColor: Colors.white,
        style: TextStyle(fontSize: 16, color: Colors.black87),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ─── Document view card used in Edit mode of Company tab ─────────────────────
class _EmpDocViewCard extends StatefulWidget {
  final String docName;
  final String fileName;
  final String fullUrl;
  final bool isPdf;
  final bool isImage;

  const _EmpDocViewCard({
    required this.docName,
    required this.fileName,
    required this.fullUrl,
    required this.isPdf,
    required this.isImage,
  });

  @override
  State<_EmpDocViewCard> createState() => _EmpDocViewCardState();
}

class _EmpDocViewCardState extends State<_EmpDocViewCard> {
  bool _downloading = false;
  double _progress = 0;

  Future<void> _download() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/${widget.fileName}';
      await Dio().download(
        widget.fullUrl,
        savePath,
        onReceiveProgress: (recv, total) {
          if (total > 0 && mounted) setState(() => _progress = recv / total);
        },
      );
      if (mounted) {
        setState(() => _downloading = false);
        await OpenFile.open(savePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _view() async {
    if (widget.isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _EmpFullScreenImageViewer(
            url: widget.fullUrl,
            fileName: widget.fileName,
          ),
        ),
      );
    } else {
      final uri = Uri.parse(widget.fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _view,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.isImage
                    ? Image.network(
                        widget.fullUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _icon(),
                      )
                    : _icon(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.docName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.fileName,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_downloading) ...[
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blue,
                    ),
                    Text(
                      _progress > 0
                          ? '${(_progress * 100).toStringAsFixed(0)}%'
                          : 'Downloading...',
                      style: const TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _btn(Icons.visibility_rounded, 'View', Colors.blue, _view),
                const SizedBox(height: 6),
                _downloading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _btn(
                        Icons.download_rounded,
                        'Save',
                        Colors.green,
                        _download,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon() => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: widget.isPdf ? Colors.red[50] : Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      widget.isPdf
          ? Icons.picture_as_pdf_rounded
          : Icons.insert_drive_file_rounded,
      size: 32,
      color: widget.isPdf ? Colors.red : Colors.blueGrey,
    ),
  );

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmpFullScreenImageViewer extends StatelessWidget {
  final String url;
  final String fileName;
  const _EmpFullScreenImageViewer({required this.url, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          fileName,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey, size: 64),
                  SizedBox(height: 8),
                  Text(
                    'Could not load image',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TinyActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
