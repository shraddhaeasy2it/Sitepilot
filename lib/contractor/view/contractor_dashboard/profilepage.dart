import 'dart:convert';
import 'dart:io';
import 'package:ecoteam_app/contractor/services/profile_service.dart';
import 'package:ecoteam_app/contractor/utils/responsive_utils.dart';
import 'package:ecoteam_app/contractor/view/auth/login_selector.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/help.dart';
import 'package:ecoteam_app/contractor/widgets/responsive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecoteam_app/admin/models/employee_model.dart';
import 'package:ecoteam_app/admin/services/employee_services.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/read_only_employee_view.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/employee_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
 
  DateTime? _selectedBirthdate;
  String? _profileImageUrl = 'assets/avtar.jpg';
  Employee? _employee;
  Employee? _creationData;
  bool _isLoadingEmployee = false;

  // Leave Management Variables
  int _availableLeaves = 21;
  int _sundayCredits = 4;
  final List<LeaveRequest> _leaveRequests = [
    LeaveRequest(
      id: '001',
      type: 'Annual',
      startDate: DateTime.now().subtract(Duration(days: 10)),
      endDate: DateTime.now().subtract(Duration(days: 7)),
      status: 'Approved',
      reason: 'Family vacation',
    ),
    LeaveRequest(
      id: '002',
      type: 'Sick',
      startDate: DateTime.now().subtract(Duration(days: 3)),
      endDate: DateTime.now().subtract(Duration(days: 2)),
      status: 'Approved',
      reason: 'High fever',
    ),
    LeaveRequest(
      id: '003',
      type: 'Emergency',
      startDate: DateTime.now().add(Duration(days: 5)),
      endDate: DateTime.now().add(Duration(days: 7)),
      status: 'Pending',
      reason: 'Medical checkup',
    ),
  ];

  // Form controllers for leave application
  final TextEditingController _leaveTypeController = TextEditingController();
  final TextEditingController _leaveReasonController = TextEditingController();
  DateTime? _leaveStartDate;
  DateTime? _leaveEndDate;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    // Load user data from SharedPreferences
    _loadUserData();

    _calculateSundayCredits();
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
        });
        
        // Fetch employee data
        if (userData['id'] != null) {
           _fetchEmployeeData(userData['id'], userData['active_workspace'] ?? 3);
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
      // Fetch creation data first
      final creationData = await ApiService.fetchEmployeeCreationData(
        workspaceId: workspaceId,
        createdBy: userId, // Assuming current user as creator for context, or just passed
      );
      setState(() => _creationData = creationData);

      // Fetch all employees and find the current one
      final employees = await ApiService.fetchEmployees(workspaceId: workspaceId);
      final employee = employees.firstWhere(
        (e) => e.userId == userId,
        orElse: () => Employee(
          id: '', 
          name: _nameController.text, 
          email: _emailController.text, 
          gender: 'male',
          workspace: workspaceId
        ),
      );
      
      setState(() {
        _employee = employee;
        // Merge creation data metadata if needed to the employee object for easier access
         if (_employee!.id.isNotEmpty) {
             _employee = _employee!.copyWith(
                departments: creationData.departments,
                designations: creationData.designations,
                branches: creationData.branches,
                roles: creationData.roles,
                locationTypes: creationData.locationTypes,
                documentList: creationData.documentList,
             );
         }
      });
      
    } catch (e) {
      print('Error fetching employee data: $e');
    } finally {
      setState(() => _isLoadingEmployee = false);
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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildUserCard(),
                        SizedBox(height: 18),
                        _buildLeaveManagementCard(),
                        SizedBox(height: 18),
                        _buildSettingsCard(),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
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
                  await prefs.clear();

                  _showSnackBar('Signed out successfully');

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginSelectorPage(),
                    ),
                    (Route<dynamic> route) => false,
                  );
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


  Widget _buildSliverAppBar() {
    return SliverAppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      expandedHeight: 70,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
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
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  ImageProvider? _getAvatarImageProvider() {
    // 1. Prioritize Employee object's avatar (fetched from API)
    if (_employee != null && _employee!.avatar != null && _employee!.avatar!.isNotEmpty) {
      return NetworkImage('https://sitepilot.easy2it.in/${_employee!.avatar!}');
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
        padding: EdgeInsets.all(24),
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
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
      
            Row(
              children: [
                Expanded(
                  child: _buildGradientButton(
                    onPressed: _showEmployeeDetails,
                    text: 'View Details',
                    icon: Icons.visibility,
                    isPrimary: true,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildOutlineButton(
                    onPressed: _showEditProfileDialog,
                    text: 'Edit Profile',
                    icon: Icons.edit_outlined,
                  ),
                ),
              ],
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
      builder: (context) => ReadOnlyEmployeeBottomSheet(
        employee: _employee,
      ),
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
      backgroundColor: Colors.transparent, // Important for rounded corners if not set by sheet
      builder: (context) => EmployeeBottomSheet(
        employee: _employee,
        creationData: _creationData,
        onSave: (updatedEmployee, avatarFile) async {
           try {
             final saved = await ApiService.updateEmployee(updatedEmployee, avatarFile: avatarFile);
             setState(() {
               _employee = saved;
               // Update local controllers
               _nameController.text = saved.name;
               _emailController.text = saved.email;
               
             });
             return saved;
           } catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
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
      width: 207,
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
      height: 40,
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
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(5),
                  child: Icon(
                    Icons.calendar_today,
                    color: Color.fromARGB(255, 32, 32, 32),
                    size: 24,
                  ),
                ),
                SizedBox(width: 8),
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

            // Leave Balance Information
            Container(
              width: 220,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        'Available Leaves',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$_availableLeaves days',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Sunday Credits',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$_sundayCredits days',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Apply Leave Button
            _buildGradientButton(
              onPressed: _showApplyLeaveDialog,
              text: 'Apply for Leave',
              icon: Icons.add,
              isPrimary: true,
            ),
            SizedBox(height: 12),

            // Leave Requests Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Leave Requests',
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

  Widget _buildLeaveRequestItem(LeaveRequest request) {
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

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
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
                request.type,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          SizedBox(height: 8),
          Text(
            '${DateFormat('MMM dd, yyyy').format(request.startDate)} - ${DateFormat('MMM dd, yyyy').format(request.endDate)}',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          SizedBox(height: 8),
          if (request.reason.isNotEmpty)
            Text(
              'Reason: ${request.reason}',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
        ],
      ),
    );
  }

  void _showApplyLeaveDialog() {
    final leaveTypes = ['Annual', 'Sick', 'Emergency', 'Compensation'];
    String? selectedLeaveType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                      ResponsiveUtils.responsiveValue(
                        context,
                        smallMobile: 16.0,
                        largeMobile: 18.0,
                        tablet: 20.0,
                      ),
                    ),
                    topRight: Radius.circular(
                      ResponsiveUtils.responsiveValue(
                        context,
                        smallMobile: 16.0,
                        largeMobile: 18.0,
                        tablet: 20.0,
                      ),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Wrap(
                  children: [
                    // drag handle
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 201, 200, 200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Title & Close
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ResponsiveText(
                            'Apply for Leave',
                            smallMobileFontSize: 16,
                            largeMobileFontSize: 18,
                            tabletFontSize: 20,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(),

                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Leave Type
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Leave Type',
                              filled: true,
                              fillColor: Color.fromARGB(255, 255, 255, 255),
                              contentPadding: EdgeInsets.all(16),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: const Color.fromARGB(
                                    255,
                                    216,
                                    216,
                                    216,
                                  ),
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: const Color.fromARGB(
                                    255,
                                    108,
                                    134,
                                    247,
                                  ),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            value: selectedLeaveType,
                            items: leaveTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: ResponsiveText(
                                  type,
                                  smallMobileFontSize: 14,
                                  largeMobileFontSize: 15,
                                  tabletFontSize: 16,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedLeaveType = value;
                              });
                            },
                          ),
                          SizedBox(height: 16),

                          // Date Pickers
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        Duration(days: 365),
                                      ),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _leaveStartDate = date;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Start Date',
                                      filled: true,
                                      fillColor: Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),

                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: const Color.fromARGB(
                                            255,
                                            212,
                                            212,
                                            212,
                                          ),
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: const Color.fromARGB(
                                            255,
                                            108,
                                            134,
                                            247,
                                          ),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: ResponsiveText(
                                      _leaveStartDate != null
                                          ? DateFormat(
                                              'MMM dd, yyyy',
                                            ).format(_leaveStartDate!)
                                          : 'Select date',
                                      smallMobileFontSize: 14,
                                      largeMobileFontSize: 15,
                                      tabletFontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    if (_leaveStartDate == null) {
                                      _showSnackBar(
                                        'Please select start date first',
                                      );
                                      return;
                                    }
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _leaveStartDate!.add(
                                        Duration(days: 1),
                                      ),
                                      firstDate: _leaveStartDate!,
                                      lastDate: DateTime.now().add(
                                        Duration(days: 365),
                                      ),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _leaveEndDate = date;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'End Date',
                                      filled: true,
                                      fillColor: Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),

                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: const Color.fromARGB(
                                            255,
                                            211,
                                            211,
                                            211,
                                          ),
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: const Color.fromARGB(
                                            255,
                                            108,
                                            134,
                                            247,
                                          ),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: ResponsiveText(
                                      _leaveEndDate != null
                                          ? DateFormat(
                                              'MMM dd, yyyy',
                                            ).format(_leaveEndDate!)
                                          : 'Select date',
                                      smallMobileFontSize: 14,
                                      largeMobileFontSize: 15,
                                      tabletFontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Reason
                          TextField(
                            controller: _leaveReasonController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Reason',
                              filled: true,
                              fillColor: Color.fromARGB(255, 255, 255, 255),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: const Color.fromARGB(
                                    255,
                                    216,
                                    216,
                                    216,
                                  ),
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: const Color.fromARGB(
                                    255,
                                    108,
                                    134,
                                    247,
                                  ),
                                  width: 1.0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: ResponsiveText(
                                  'Cancel',
                                  smallMobileFontSize: 14,
                                  largeMobileFontSize: 15,
                                  tabletFontSize: 16,
                                ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (selectedLeaveType == null) {
                                    _showSnackBar('Please select leave type');
                                    return;
                                  }
                                  if (_leaveStartDate == null ||
                                      _leaveEndDate == null) {
                                    _showSnackBar('Please select date range');
                                    return;
                                  }
                                  if (_leaveReasonController.text.isEmpty) {
                                    _showSnackBar(
                                      'Please enter reason for leave',
                                    );
                                    return;
                                  }

                                  final newRequest = LeaveRequest(
                                    id: '00${_leaveRequests.length + 1}',
                                    type: selectedLeaveType!,
                                    startDate: _leaveStartDate!,
                                    endDate: _leaveEndDate!,
                                    status: 'Pending',
                                    reason: _leaveReasonController.text,
                                  );

                                  setState(() {
                                    _leaveRequests.insert(0, newRequest);
                                    if (selectedLeaveType != 'Compensation') {
                                      final days =
                                          _leaveEndDate!
                                              .difference(_leaveStartDate!)
                                              .inDays +
                                          1;
                                      _availableLeaves -= days;
                                    }
                                  });

                                  _leaveStartDate = null;
                                  _leaveEndDate = null;
                                  _leaveReasonController.clear();

                                  Navigator.pop(context);
                                  _showSnackBar(
                                    'Leave request submitted successfully',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF6f88e2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: ResponsiveText(
                                  'Submit',
                                  smallMobileFontSize: 14,
                                  largeMobileFontSize: 15,
                                  tabletFontSize: 16,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  void _showAllLeaveRequests() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                      'All Leave Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(),
              Expanded(
                child: Scrollbar(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _leaveRequests.length,
                    itemBuilder: (context, index) {
                      return _buildLeaveRequestItem(_leaveRequests[index]);
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6f88e2),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

class LeaveRequest {
  final String id;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String reason;

  LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.reason,
  });
}
