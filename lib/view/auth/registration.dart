
import 'package:ecoteam_app/view/contractor_dashboard/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManconRegistration extends StatefulWidget {
  const ManconRegistration({super.key});

  @override
  _ManconRegistrationState createState() => _ManconRegistrationState();
}

class _ManconRegistrationState extends State<ManconRegistration>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _roleController = TextEditingController(
    text: 'Manager/Contractor',
  );

  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _headerAnimation;

  // Green theme colors - matching login screen
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeInOut),
    );

    // Start animations with delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _projectController.dispose();
    _licenseController.dispose();
    _employeeIdController.dispose();
    _roleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Animate button press
    _scaleController.reverse().then((_) {
      _scaleController.forward();
    });

    try {
      // TODO: Replace with your actual API URL
      const String apiUrl = 'https://your-api-endpoint.com/register';
      
      // Simulate API call for registration
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock API response - replace with actual API call
      bool isRegistrationSuccessful = await _registerUser(
        _fullNameController.text,
        _emailController.text,
        _projectController.text,
        _licenseController.text,
        _employeeIdController.text,
        _roleController.text,
        apiUrl,
      );

      if (isRegistrationSuccessful) {
        // Store registration data
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isRegistered', true);
        await prefs.setString('fullName', _fullNameController.text);
        await prefs.setString('email', _emailController.text);
        await prefs.setString('project', _projectController.text);
        await prefs.setString('license', _licenseController.text);
        await prefs.setString('employeeId', _employeeIdController.text);
        await prefs.setString('role', _roleController.text);

        // Navigate to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );

        Fluttertoast.showToast(
          msg: 'Registration successful!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: lightGreen,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Registration failed. Please try again.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Registration failed. Please check your connection.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TODO: Implement actual API call for user registration
  Future<bool> _registerUser(
    String fullName,
    String email,
    String project,
    String license,
    String employeeId,
    String role,
    String apiUrl,
  ) async {
    // This is a placeholder for the actual API call
    // Replace this with your PHP API integration
    
    // Mock validation logic - replace with actual API call
    if (fullName.isNotEmpty && email.isNotEmpty && project.isNotEmpty) {
      // Simulate API call
      // final response = await http.post(
      //   Uri.parse(apiUrl),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({
      //     'fullName': fullName,
      //     'email': email,
      //     'project': project,
      //     'license': license,
      //     'employeeId': employeeId,
      //     'role': role,
      //   }),
      // );
      
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   return data['success'] == true;
      // }
      
      // For now, return true for demo purposes
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryGreen.withOpacity(0.1),
              Colors.white,
              lightGreen.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildRegistrationForm(),
                  const SizedBox(height: 40),
                  _buildRegisterButton(),
                  const SizedBox(height: 30),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lightGreen, accentGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: accentGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_add,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Complete Registration',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: darkGreen,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide your details to complete registration',
              style: TextStyle(
                fontSize: 16,
                color: primaryGreen.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        _buildAnimatedTextField(
          controller: _fullNameController,
          label: 'Full Name',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        _buildAnimatedTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        _buildAnimatedTextField(
          controller: _projectController,
          label: 'Project Name',
          icon: Icons.work,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter project name';
            }
            return null;
          },
        ),
        _buildAnimatedTextField(
          controller: _licenseController,
          label: 'License Number',
          icon: Icons.badge,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter license number';
            }
            return null;
          },
        ),
        _buildAnimatedTextField(
          controller: _employeeIdController,
          label: 'Employee ID',
          icon: Icons.credit_card,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter employee ID';
            }
            return null;
          },
        ),
        _buildAnimatedTextField(
          controller: _roleController,
          label: 'Role',
          icon: Icons.work_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your role';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(dynamic)? onChanged,
  }) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: accentGreen.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                onChanged: onChanged,
                validator: validator,
                style: TextStyle(color: darkGreen, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(color: primaryGreen),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: lightGreen, width: 2),
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [lightGreen, accentGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white),
                  ),
                  suffixIcon: suffixIcon,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lightGreen, accentGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: accentGreen.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Complete Registration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Text(
            'Construction Management System',
            style: TextStyle(
              fontSize: 14,
              color: primaryGreen.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: primaryGreen.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
