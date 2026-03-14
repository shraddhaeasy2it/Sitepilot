import 'dart:convert';
import 'dart:io';
import 'package:ecoteam_app/contractor/services/profile_service.dart';
import 'package:ecoteam_app/contractor/utils/responsive_utils.dart';
import 'package:ecoteam_app/contractor/view/auth/login_selector.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/help.dart';
import 'package:ecoteam_app/contractor/widgets/responsive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecoteam_app/admin/models/employee_model.dart';
import 'package:ecoteam_app/admin/services/employee_services.dart';

import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/read_only_employee_view.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/employee_screen.dart';
import 'package:ecoteam_app/contractor/models/leave_model.dart';
import 'package:ecoteam_app/contractor/services/leave_service.dart';
// Removed self-import
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/leave_type_bottom_sheet.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/all_leave_requests_bottom_sheet.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/leave_request_dialog.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Profile/change_password_bottom_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final int? passedUserId;
  final int? passedWorkspaceId;
  final int? passedSiteId;

  const ProfileScreen({
    super.key,
    this.passedUserId,
    this.passedWorkspaceId,
    this.passedSiteId,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  String _userType = '';
  String _phone = '';

  DateTime? _selectedBirthdate;
  String? _profileImageUrl = 'assets/avtar.jpg';
  Employee? _employee;
  Employee? _creationData;
  bool _isLoadingEmployee = false;

  // Leave Management Variables
  int _availableLeaves = 21;
  int _sundayCredits = 4;
  List<Leave> _leaveRequests = [];
  bool _isLoadingLeaves = false;

  // Form controllers for leave application
  final TextEditingController _leaveTypeController = TextEditingController();
  final TextEditingController _leaveReasonController = TextEditingController();
  final TextEditingController _leaveRemarkController = TextEditingController();
  DateTime? _leaveStartDate;
  DateTime? _leaveEndDate;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // State variables for IDs to ensure consistency
  int _userId = 10;
  int _workspaceId = 3;
  int _siteId = 3;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, -0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
    
    // Initialize IDs from passed values if available
    if (widget.passedUserId != null) _userId = widget.passedUserId!;
    if (widget.passedWorkspaceId != null) _workspaceId = widget.passedWorkspaceId!;
    if (widget.passedSiteId != null) _siteId = widget.passedSiteId!;


    // Load user data from SharedPreferences
    _loadUserData();
    _loadLeaveRequests();

    _calculateSundayCredits();
  }
  
  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.passedSiteId != oldWidget.passedSiteId ||
        widget.passedWorkspaceId != oldWidget.passedWorkspaceId ||
        widget.passedUserId != oldWidget.passedUserId) {
        
        setState(() {
          if (widget.passedUserId != null) _userId = widget.passedUserId!;
          if (widget.passedWorkspaceId != null) _workspaceId = widget.passedWorkspaceId!;
          if (widget.passedSiteId != null) _siteId = widget.passedSiteId!;
        });
        _loadLeaveRequests();
    }
  }

  Future<void> _loadLeaveRequests() async {
    setState(() => _isLoadingLeaves = true);
    try {
      // If IDs were not passed, try to load from loading User Data
      // But _loadUserData runs in parallel.
      // We'll rely on _userId, _workspaceId being set either by Constructor or _loadUserData
      
      final leaves = await LeaveService.fetchLeaves(
        userId: _userId,
        workspaceId: _workspaceId,
        siteId: _siteId,
      );

      setState(() {
        _leaveRequests = leaves;
      });
    } catch (e) {
      print('Error loading leaves: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLeaves = false);
    }
  }

  void _showChangePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChangePasswordBottomSheet(),
    );
  }

  Future<void> _shareProfile() async {
    try {
      await ProfileService.shareProfile(
        name: _nameController.text,
        email: _emailController.text,
      );
      _showSnackBar('Profile shared successfully');
    } catch (e) {
      _showSnackBar('Failed to share profile');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      // Load profile image
      _profileImageUrl = prefs.getString('profile_image') ?? 'assets/avtar.jpg';

      if (userDataString != null) {
        final userData = jsonDecode(userDataString);

          setState(() {
            _nameController.text = userData['name'] ?? 'John Deo';
            _emailController.text = userData['email'] ?? 'John@example.com';
            _userType = userData['type'] ?? 'Site / Project Manager';
            _phone = userData['phone']?.toString() ??
                userData['mobile_no']?.toString() ??
                userData['phone_number']?.toString() ??
                '';
            
            if (widget.passedUserId == null) {
               _userId = int.tryParse(userData['id'].toString()) ?? 10;
            }
            if (widget.passedWorkspaceId == null) {
               _workspaceId = int.tryParse(userData['active_workspace'].toString()) ?? 3;
            }
          });

        // Load full employee details from login response cache
        // This already has rich nested data (branch, department, designation, documents)
        final employeeDataString = prefs.getString('employee_data');
        Employee? cachedEmployee;
        if (employeeDataString != null) {
          try {
            print('DEBUG ProfilePage: Loading employee data from login cache...');
            final employeeJson = jsonDecode(employeeDataString);
            cachedEmployee = Employee.fromJson(employeeJson);
            setState(() {
              _employee = cachedEmployee;
            });
            print('DEBUG ProfilePage: Cached employee loaded — id=${cachedEmployee?.id}, name=${cachedEmployee?.name}');
          } catch (e) {
            print('DEBUG ProfilePage: Error parsing cached employee data: $e');
          }
        }

        // Only fetch fresh employee data from API if:
        // (a) we have no cached employee, OR
        // (b) the cached employee has no id (incomplete data)
        // This avoids overwriting the rich login-response data with a less-complete fetch.
        final bool hasCachedEmployee =
            cachedEmployee != null && cachedEmployee.id.isNotEmpty;

        if (!hasCachedEmployee && _userId != 0) {
          print('DEBUG ProfilePage: No cached employee — fetching from API...');
          _fetchEmployeeData(_userId, _workspaceId);
        } else if (hasCachedEmployee) {
          // Fetch fresh data silently in the background so the UI still
          // shows the cached data immediately, while the refresh happens.
          print('DEBUG ProfilePage: Cached employee found — refreshing in background...');
          _fetchEmployeeData(_userId, _workspaceId);
        }
      } else {
        setState(() {
          _nameController.text = 'John Deo';
          _emailController.text = 'John@example.com';
          _userType = 'Site / Project Manager';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _nameController.text = 'John Deo';
        _emailController.text = 'John@example.com';
      });
    }
  }

  Future<void> _fetchEmployeeData(int userId, int workspaceId) async {
    setState(() => _isLoadingEmployee = true);
    try {
      // Use the employee id from the cached employee (set from login response).
      // The login response employee JSON has 'id' as the numeric employee id.
      final String? cachedEmployeeId = _employee?.id.isNotEmpty == true
          ? _employee!.id
          : null;

      if (cachedEmployeeId != null) {
        // Fast path: fetch by employee id directly (richest response with nested data)
        print('DEBUG _fetchEmployeeData: Fetching by employee id=$cachedEmployeeId');
        try {
          final freshEmployee =
              await ApiService.getEmployeeById(cachedEmployeeId);

          // Preserve document list from the login cache if the API returns none
          List<Map<String, dynamic>>? mergedDocs = freshEmployee.documentList;
          if ((mergedDocs == null || mergedDocs.isEmpty) &&
              _employee?.documentList != null) {
            mergedDocs = _employee!.documentList;
          }

          // Also preserve nested name data from login cache if not in fresh response
          final String? branchName = freshEmployee.branchName.isNotEmpty &&
                  freshEmployee.branchName != 'N/A'
              ? null // use fresh value (null means copyWith keeps freshEmployee's)
              : (_employee?.branchName != 'N/A' ? _employee?.branchName : null);
          final String? deptName = freshEmployee.departmentName.isNotEmpty &&
                  freshEmployee.departmentName != 'N/A'
              ? null
              : (_employee?.departmentName != 'N/A' ? _employee?.departmentName : null);
          final String? desigName = freshEmployee.designationName.isNotEmpty &&
                  freshEmployee.designationName != 'N/A'
              ? null
              : (_employee?.designationName != 'N/A' ? _employee?.designationName : null);

          if (mounted) {
            setState(() {
              _employee = freshEmployee.copyWith(
                documentList: mergedDocs ?? freshEmployee.documentList,
                branchName: branchName,
                departmentName: deptName,
                designationName: desigName,
              );
            });
          }
          print('DEBUG _fetchEmployeeData: Fresh employee loaded — ${freshEmployee.name}');
          return; // done, no need for bulk fetch
        } catch (e) {
          print('DEBUG _fetchEmployeeData: getEmployeeById failed: $e — falling back to bulk fetch');
        }
      }

      // Fallback: bulk fetch (slow, only used if we have no employee id)
      print('DEBUG _fetchEmployeeData: Fallback — fetching all employees for workspace $workspaceId');
      final creationData = await ApiService.fetchEmployeeCreationData(
        workspaceId: workspaceId,
        createdBy: userId,
      );
      setState(() => _creationData = creationData);

      final employees = await ApiService.fetchEmployees(
        workspaceId: workspaceId,
      );
      final employee = employees.firstWhere(
        (e) => e.userId == userId,
        orElse: () => Employee(
          id: '',
          name: _nameController.text,
          email: _emailController.text,
          gender: 'male',
          workspace: workspaceId,
        ),
      );

      if (mounted) {
        setState(() {
          if (employee.id.isNotEmpty) {
            List<Map<String, dynamic>>? mergedDocs = employee.documentList;
            if ((mergedDocs == null || mergedDocs.isEmpty) &&
                _employee?.documentList != null) {
              mergedDocs = _employee!.documentList;
            }
            _employee = employee.copyWith(
              departments: creationData.departments,
              designations: creationData.designations,
              branches: creationData.branches,
              roles: creationData.roles,
              locationTypes: creationData.locationTypes,
              documentList: mergedDocs ?? creationData.documentList,
            );
          }
        });
      }
    } catch (e) {
      print('Error fetching employee data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingEmployee = false);
    }
  }

  void _calculateSundayCredits() {
    setState(() {
      _sundayCredits = 4;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();

    _leaveTypeController.dispose();
    _leaveReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 250, 251, 252),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildUserCard(),
                SizedBox(height: 16),
                _buildLeaveManagementCard(),
                SizedBox(height: 16),
                _buildSettingsCard(),
                SizedBox(height: 45),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... [Rest of the code remains exactly the same until the end of the file]
  // All other methods (buildSettingsCard, buildSliverAppBar, buildUserCard, etc.)
  // remain completely unchanged

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Title
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text(
                "Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ),

            // ✅ Help Section
            _buildSettingItem(
              Icons.help_outline,
              'Help & Support',
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              },
              // implement this
            ),

            Divider(color: Colors.grey.shade200, thickness: 1, height: 20),

            // ✅ Change Password Section
            _buildSettingItem(
              Icons.lock_reset,
              'Change Password',
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
              onTap: _showChangePassword,
            ),

            Divider(color: Colors.grey.shade200, thickness: 1, height: 20),

            // ✅ Logout Section
            _buildSettingItem(
              Icons.logout_outlined,
              'Sign Out',
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.logout, color: Color(0xFFEF4444)),
                  onPressed: _showLogoutConfirmation,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable item widget
  Widget _buildSettingItem(
    IconData icon,
    String title,
    Widget trailing, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Color(0xFF4F46E5)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111827),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_outlined,
                  color: Color(0xFFEF4444),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to sign out? You will need to log in again to access your account.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  // await prefs.clear(); // Changed to specific removals to preserve other settings if needed
                  await prefs.remove('auth_token');
                  await prefs.remove('isLoggedIn');
                  await prefs.remove('user_data');
                  await prefs.remove('email');
                  await prefs.remove('userType');
                  await prefs.remove('employee_data');
                  await prefs.remove('stored_workspaces');
                  await prefs.remove('stored_sites');
                  await prefs.remove('profile_image');
                  await prefs.remove('fcm_token');
                  
                  if (context.mounted) {
                    _showSnackBar('Signed out successfully');
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginSelectorPage(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      toolbarHeight: 74.h,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: Container(
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
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
        ),
      ),
      title: const Text(
        'Profile',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 25,
        ),
      ),
      centerTitle: true,
    );
  }

  ImageProvider? _getAvatarImageProvider() {
    // 1. Prioritize Employee object's avatar (fetched from API)
    if (_employee != null &&
        _employee!.avatar != null &&
        _employee!.avatar!.isNotEmpty) {
      return NetworkImage('https://app.ecoteamsolar.com/${_employee!.avatar!}');
    }

    // 2. Fallback to locally stored/selected profile image
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      if (_profileImageUrl!.startsWith('assets/')) {
        return AssetImage(_profileImageUrl!);
      } else {
        return FileImage(File(_profileImageUrl!));
      }
    }

    // 3. No image available
    return null;
  }

  Widget _buildUserCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'profile_avatar',
                  child: GestureDetector(
                    //onTap: _showImagePickerDialog,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade800, Colors.blue.shade800],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(
                              255,
                              85,
                              84,
                              84,
                            ).withOpacity(0.3),
                            blurRadius: 13,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(1.5),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: _getAvatarImageProvider(),
                        backgroundColor: Colors.white,
                        child: _getAvatarImageProvider() == null
                            ? Icon(
                                Icons.person,
                                size: 35,
                                color: Color(0xFF667EEA),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        _userType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 75, 85, 100),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_employee == null) ...[
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(Icons.email_outlined,
                                size: 14.sp, color: const Color(0xFF64748B)),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _emailController.text,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_phone.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 14.sp, color: const Color(0xFF64748B)),
                              SizedBox(width: 8.w),
                              Text(
                                _phone,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),

            if (_employee != null)
              Center(
                child: Expanded(
                  child: _buildGradientButton(
                    onPressed: _showEmployeeDetails,
                    text: 'View Details',
                    icon: Icons.visibility,
                    isPrimary: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEmployeeDetails() {
    if (_employee == null) {
      if (_isLoadingEmployee) {
        _showSnackBar('Still loading employee data...');
      } else {
        _showSnackBar('Employee data not available. Please try again later.');
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReadOnlyEmployeeBottomSheet(employee: _employee),
    );
  }

  void _showEditProfileDialog() {
    if (_employee == null) {
      if (_isLoadingEmployee) {
        _showSnackBar('Still loading employee data...');
      } else {
        _showSnackBar('Employee data not available. Please try again later.');
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors
          .transparent, // Important for rounded corners if not set by sheet
      builder: (context) => EmployeeBottomSheet(
        employee: _employee,
        creationData: _creationData,
        onSave: (updatedEmployee, avatarFile, documentFiles) async {
          try {
            final saved = await ApiService.updateEmployee(
              updatedEmployee,
              avatarFile: avatarFile,
              documentFiles: documentFiles,
            );
            setState(() {
              _employee = saved;
              // Update local controllers
              _nameController.text = saved.name;
              _emailController.text = saved.email;
            });
            return saved;
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
            return null;
          }
        },
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 5,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Profile Picture',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(),
              Expanded(
                child: Scrollbar(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      _buildImagePickerOption(
                        Icons.camera_alt_outlined,
                        'Take Photo',
                        () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      SizedBox(height: 8),
                      _buildImagePickerOption(
                        Icons.photo_library_outlined,
                        'Choose from Gallery',
                        () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                      if (_profileImageUrl != null) ...[
                        SizedBox(height: 8),
                        _buildImagePickerOption(
                          Icons.delete_outline,
                          'Remove Photo',
                          () async {
                            setState(() {
                              _profileImageUrl = null;
                            });

                            // Clear from SharedPreferences
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('profile_image');

                            Navigator.pop(context);
                            _showSnackBar('Profile photo removed');
                          },
                          isDestructive: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDestructive ? Color(0xFFFEF2F2) : Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive ? Color(0xFFFECACA) : Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Color(0xFFEF4444) : Color(0xFF6f88e2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Color(0xFFEF4444) : Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImageUrl = pickedFile.path;
        });

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', pickedFile.path);

        _showSnackBar('Profile picture updated');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Widget _buildOutlineButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
  }) {
    return SizedBox(
      height: 37,
      width: 204,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: const Color.fromARGB(255, 52, 52, 53),
          size: 20,
        ),
        label: Text(
          text,
          style: TextStyle(
            color: Color.fromARGB(255, 64, 64, 65),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Color.fromARGB(255, 130, 131, 131), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        floatingLabelStyle: TextStyle(color: Color(0xFF6f88e2), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF6f88e2), width: 1),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (label.contains('Name') || label.contains('Email')) {
          if (value == null || value.isEmpty) {
            return 'Please enter your ${label.toLowerCase()}';
          }
          if (label.contains('Email') && !value.contains('@')) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: Color.fromARGB(255, 59, 59, 59)),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    bool isPrimary = false,
  }) {
    return Container(
      height: 38,
      width: 148,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [Color(0xFF4a63c0), Color(0xFF3a53b0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Color(0xFF4a63c0).withOpacity(0.3),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isPrimary ? Colors.white : Color(0xFF4a63c0),
          size: 20,
        ),
        label: Text(
          text,
          style: TextStyle(
            color: isPrimary ? Colors.white : Color(0xFF4a63c0),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveManagementCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(5),
                  child: Icon(
                    Icons.calendar_month,
                    color: Color.fromARGB(255, 32, 32, 32),
                    size: 22,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Leave Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),

            // Apply Leave Button
            Row(
              children: [
                _buildGradientButton(
                  onPressed: _showApplyLeaveDialog,
                  text: 'Add Leave',
                  icon: Icons.add,
                  isPrimary: true,
                ),
                SizedBox(width: 10,),
                // SizedBox(
                //   width: 150,
                //   child: _buildOutlineButton(
                //     onPressed: () {
                //       showModalBottomSheet(
                //         context: context,
                //         isScrollControlled: true,
                //         backgroundColor: Colors.transparent,
                //         builder: (context) => const LeaveTypeBottomSheet(),
                //       );
                //     },
                //     text: 'Leave Types',
                //     icon: Icons.settings,
                //   ),
                // ),ch
              ],
            ),
            SizedBox(height: 12),

            // Leave Requests Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Leaves',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all leave requests
                    _showAllLeaveRequests();
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF4a63c0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),

            // Recent Leave Requests
            Column(
              children: _leaveRequests
                  .take(2)
                  .map((request) => _buildLeaveRequestItem(request))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveRequestItem(Leave request) {
    Color statusColor;
    switch (request.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
    }

    DateTime? start;
    DateTime? end;
    try {
      start = DateTime.tryParse(request.startDate);
      end = DateTime.tryParse(request.endDate);
    } catch (e) {
      // ignore
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.leaveType?.title ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            '${start != null ? DateFormat('MMM dd, yyyy').format(start) : request.startDate} - ${end != null ? DateFormat('MMM dd, yyyy').format(end) : request.endDate}',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          SizedBox(height: 5),
          if (request.leaveReason.isNotEmpty)
            Text(
              'Reason: ${request.leaveReason}',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
        ],
      ),
    );
  }

  void _showApplyLeaveDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LeaveRequestDialog(
        userId: _userId,
        workspaceId: _workspaceId,
        siteId: _siteId,
        onSuccess: () {
          _loadLeaveRequests();
        },
      ),
    );
  }
 

  void _showAllLeaveRequests() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AllLeaveRequestsBottomSheet(
        passedUserId: _userId,
        passedWorkspaceId: _workspaceId,
        passedSiteId: _siteId,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Color(0xFF667EEA),
          onPressed: () {},
        ),
      ),
    );
  }
}
