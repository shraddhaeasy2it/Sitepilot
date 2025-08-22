import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  bool _isExpanded = false;
  String _currentOrg = 'Future Build Contracting';
  final List<String> _organizations = [
    'Future Build Contracting',
    'ACD Construction',
    'Al Engineering'
  ];
  final bool _notificationsEnabled = true;
  final String _language = 'English';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController(text: 'John Deo');
  final TextEditingController _positionController = TextEditingController(text: 'Construction Site Manager');
  final TextEditingController _emailController = TextEditingController(text: 'John@example.com');
  final TextEditingController _phoneController = TextEditingController(text: '+966501234567');
  final TextEditingController _departmentController = TextEditingController(text: 'Project Management');
  final TextEditingController _projectsController = TextEditingController(text: 'Site A');
  final TextEditingController _skillsController = TextEditingController(text: 'Site Management, Planning, Safety');
  final TextEditingController _experienceController = TextEditingController(text: '10 years');
  String? _profileImageUrl = 'assets/avtar.jpg'; // Default profile image
  
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
    _slideAnimation = Tween<Offset>(begin: Offset(0, -0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    
    // Calculate Sunday credits (example logic)
    _calculateSundayCredits();
  }

  void _calculateSundayCredits() {
    // In a real app, this would calculate actual Sundays worked
    setState(() {
      _sundayCredits = 4; // Example value
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _projectsController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
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
                        _buildOrganizationCard(),
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
  Widget _buildSettingsCard() {
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
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            
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
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_outlined, color: Color(0xFFEF4444)),
              ),
              SizedBox(width: 12),
              Text('Confirm Logout', 
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
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
                onPressed: () {
                  Navigator.pop(context);
                  _showSnackBar('Signed out successfully');
                  // Add actual logout logic here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }
 Widget _buildSettingItem(IconData icon, String label, Widget trailing) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Color(0xFF475569)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
  Widget _buildOrganizationCard() {
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
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(
                //       colors: [Color.fromARGB(255, 128, 148, 238),
                // Color.fromARGB(255, 87, 104, 179),],
                //     ),
                //     borderRadius: BorderRadius.circular(16),
                //   ),
                  child: Icon(Icons.business, color: const Color.fromARGB(255, 32, 32, 32), size: 24),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Organization',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color.fromARGB(255, 116, 133, 156),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _currentOrg,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_organizations.length > 1)
                  Container(
                    height: 33,
                    width: 65,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF667EEA)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: _showOrganizationDialog,
                      child: Text(
                        'Switch',
                        style: TextStyle(
                          color: Color(0xFF667EEA),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // SizedBox(height: 10),
            // Container(
            //   height: 1,
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [
            //         Colors.transparent,
            //         Color(0xFF667EEA).withOpacity(0.3),
            //         Colors.transparent,
            //       ],
            //     ),
            //   ),
            // ),
            SizedBox(height: 20),
            _buildOutlineButton(
              onPressed: _showOrganizationManagementDialog,
              text: 'Manage Organizations',
              icon: Icons.settings_outlined,
              
            ),
          ],
        ),
      ),
    );
  }
   void _showOrganizationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(237, 255, 255, 255),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Select Organization', 
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _organizations
                .map((org) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _currentOrg == org ? Colors.blue.shade800.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(org, style: TextStyle(fontWeight: FontWeight.w500)),
                        trailing: _currentOrg == org
                            ? Icon(Icons.check_circle, color: Color.fromARGB(255, 97, 97, 97))
                            : null,
                        onTap: () {
                          setState(() {
                            _currentOrg = org;
                          });
                          Navigator.pop(context);
                          _showSnackBar('Switched to $org');
                        },
                      ),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Color.fromARGB(255, 81, 81, 82))),
            ),
          ],
        );
      },
    );
  }

  void _showOrganizationManagementDialog() {
    final TextEditingController newOrgController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Manage Organizations', 
            style: TextStyle(fontWeight: FontWeight.w700, color: Color.fromARGB(255, 63, 66, 71))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _currentOrg,
                    decoration: InputDecoration(
                      labelText: 'Current Organization',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _organizations.map((org) {
                      return DropdownMenuItem(
                        value: org,
                        child: Text(org),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _currentOrg = value!;
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: newOrgController,
                  decoration: InputDecoration(
                    labelText: 'Add New Organization',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF8FAFC),
                    suffixIcon: Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color.fromARGB(255, 82, 82, 177), Color.fromARGB(255, 98, 110, 221)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          if (newOrgController.text.isNotEmpty) {
                            setState(() {
                              _organizations.add(newOrgController.text);
                              newOrgController.clear();
                            });
                            _showSnackBar('Organization added');
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Color(0xFF4a63c0))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
       iconTheme: const IconThemeData(
          color: Colors.white, // Back arrow white
        ),
      expandedHeight: 90,
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
                  Color(0xFF6f88e2),
                  Color(0xFF5a73d1),
                  Color(0xFF4a63c0),
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
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
    );
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
                    onTap: _showImagePickerDialog,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade800,
                            Colors.blue.shade800,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(255, 85, 84, 84).withOpacity(0.3),
                            blurRadius: 13,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(1.5),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: _profileImageUrl != null 
                            ? AssetImage(_profileImageUrl!)
                            : null,
                        backgroundColor: Colors.white,
                        child: _profileImageUrl == null 
                            ? Icon(Icons.person, size: 35, color: Color(0xFF667EEA))
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
                        _positionController.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Container(
                      //   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      //   decoration: BoxDecoration(
                      //     gradient: LinearGradient(
                      //       colors: [Color.fromARGB(255, 87, 116, 221),
                      //         Color.fromARGB(255, 85, 113, 214),],
                      //     ),
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   child: Text(
                      //     'Active',
                      //     style: TextStyle(
                      //       color: Colors.white,
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ),
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
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    text: _isExpanded ? 'Hide Details' : 'View Details',
                    icon: _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isExpanded ? null : 0,
              child: _isExpanded ? Column(
                children: [
                  SizedBox(height: 24),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFF667EEA).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ...[
                    _buildDetailItem(Icons.email_outlined, 'Email', _emailController.text),
                    _buildDetailItem(Icons.phone_outlined, 'Phone', _phoneController.text),
                    _buildDetailItem(Icons.business_outlined, 'Department', _departmentController.text),
                    _buildDetailItem(Icons.assignment_outlined, 'Assigned Projects', _projectsController.text),
                    _buildDetailItem(Icons.build_outlined, 'Skills', _skillsController.text),
                    _buildDetailItem(Icons.work_outline, 'Experience', _experienceController.text),
                  ],
                  SizedBox(height: 24),
                  _buildGradientButton(
                    onPressed: () {
                      _showSnackBar('Profile shared successfully');
                    },
                    text: 'Share Profile',
                    icon: Icons.share_outlined,
                    isPrimary: true,
                  ),
                ],
              ) : null,
            ),
          ],
        ),
      ),
    );
  }
   void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Update Profile Picture', 
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                  () {
                    setState(() {
                      _profileImageUrl = null;
                    });
                    Navigator.pop(context);
                    _showSnackBar('Profile photo removed');
                  },
                  isDestructive: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
Widget _buildImagePickerOption(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
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
            color: isDestructive ? Color(0xFFEF4444) : Color(0xFF667EEA),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        icon: Icon(icon, color: Color.fromARGB(255, 52, 52, 53), size: 20),
        label: Text(
          text,
          style: TextStyle(
            color: Color.fromARGB(255, 64, 64, 65),
            fontWeight: FontWeight.w600,
            fontSize: 16,
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

  // Dialog methods remain largely the same but with updated styling
void _showEditProfileDialog() {
  final primaryColor = Color(0xFF4a63c0);
  final accentColor = Color.fromARGB(255, 106, 130, 218);
  final cardColor = Colors.white;
  final borderColor = Colors.grey.shade200;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Important for allowing the sheet to take up most of the screen
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 214, 230, 248),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Color.fromARGB(255, 64, 91, 189),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Update your professional details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Color.fromARGB(255, 59, 85, 180),
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_positionController, 'Position', Icons.work_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'Email', Icons.email_outlined, 
                        keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'Phone', Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildTextField(_departmentController, 'Department', Icons.business_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_projectsController, 'Assigned Projects', Icons.assignment_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_skillsController, 'Skills', Icons.build_outlined, maxLines: 2),
                      const SizedBox(height: 16),
                      _buildTextField(_experienceController, 'Experience', Icons.work_outline),
                      const SizedBox(height: 24),
                      
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                setState(() {});
                                Navigator.pop(context);
                                _showSnackBar('Profile updated successfully');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
  {TextInputType? keyboardType, int maxLines = 1}) {
  final primaryColor = Colors.blue.shade700;
  final borderColor = Colors.grey.shade200;
  
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 13,
      ),
      floatingLabelStyle: TextStyle(color: primaryColor),
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 1),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            // decoration: BoxDecoration(
            //   gradient: LinearGradient(
            //     colors: [Color.fromARGB(255, 128, 148, 238),
            //     Color.fromARGB(255, 87, 104, 179),],
            //   ),
            //   borderRadius: BorderRadius.circular(12),
            // ),
            child: Icon(icon, size: 20, color: const Color.fromARGB(255, 59, 59, 59)),
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
        color: Color.fromARGB(255, 210, 219, 250),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 129, 129, 129).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color.fromARGB(255, 5, 18, 61), size: 20),
        label: Text(
          text,
          style: TextStyle(
            color: const Color.fromARGB(255, 54, 54, 54),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ).copyWith(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
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
                  child: Icon(Icons.calendar_today, color: const Color.fromARGB(255, 32, 32, 32), size: 24),
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
              children: _leaveRequests.take(2).map((request) => _buildLeaveRequestItem(request)).toList(),
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
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          if (request.reason.isNotEmpty)
            Text(
              'Reason: ${request.reason}',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  void _showApplyLeaveDialog() {
    final leaveTypes = ['Annual', 'Sick', 'Emergency', 'Compensation'];
    String? selectedLeaveType;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color.fromARGB(235, 255, 255, 255),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply for Leave',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 15),
                      
                      // Leave Type Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Leave Type',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF8FAFC),
                        ),
                        value: selectedLeaveType,
                        items: leaveTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedLeaveType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select leave type';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      
                      // Date Range Picker
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(Duration(days: 365)),
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
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xFFF8FAFC),
                                ),
                                child: Text(
                                  _leaveStartDate != null 
                                      ? DateFormat('MMM dd, yyyy').format(_leaveStartDate!)
                                      : 'Select date',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                if (_leaveStartDate == null) {
                                  _showSnackBar('Please select start date first');
                                  return;
                                }
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _leaveStartDate!.add(Duration(days: 1)),
                                  firstDate: _leaveStartDate!,
                                  lastDate: DateTime.now().add(Duration(days: 365)),
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
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xFFF8FAFC),
                                ),
                                child: Text(
                                  _leaveEndDate != null 
                                      ? DateFormat('MMM dd, yyyy').format(_leaveEndDate!)
                                      : 'Select date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Reason Text Field
                      TextField(
                        controller: _leaveReasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF8FAFC),
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (selectedLeaveType == null) {
                                _showSnackBar('Please select leave type');
                                return;
                              }
                              if (_leaveStartDate == null || _leaveEndDate == null) {
                                _showSnackBar('Please select date range');
                                return;
                              }
                              if (_leaveReasonController.text.isEmpty) {
                                _showSnackBar('Please enter reason for leave');
                                return;
                              }
                              
                              // Add the new leave request
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
                                  final days = _leaveEndDate!.difference(_leaveStartDate!).inDays + 1;
                                  _availableLeaves -= days;
                                }
                              });
                              
                              // Reset form
                              _leaveStartDate = null;
                              _leaveEndDate = null;
                              _leaveReasonController.clear();
                              
                              Navigator.pop(context);
                              _showSnackBar('Leave request submitted successfully');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 100, 124, 211),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Submit',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
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

  void _showAllLeaveRequests() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(235, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'All Leave Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: double.infinity,
                  child: ListView.builder(
                    itemCount: _leaveRequests.length,
                    itemBuilder: (context, index) {
                      return _buildLeaveRequestItem(_leaveRequests[index]);
                    },
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close',style: TextStyle(color: const Color.fromARGB(255, 64, 105, 219)),),
                ),
              ],
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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