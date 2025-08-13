import 'package:ecoteam_app/view/auth/login.dart';
import 'package:ecoteam_app/view/auth/otp.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoginSelectorPage extends StatefulWidget {
  const LoginSelectorPage({super.key});

  @override
  State<LoginSelectorPage> createState() => _LoginSelectorPageState();
}

class _LoginSelectorPageState extends State<LoginSelectorPage> {
  int _selectedTab = 0; // 0 for phone, 1 for email
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 118, 143, 231),
              Color(0xFF5a73d1),
              Color.fromARGB(255, 60, 88, 192),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animation
                SizedBox(
                  height: 200,
                  child: Lottie.asset(
                    'assets/loginanimation.json',
                    repeat: true,
                    animate: true,
                  ),
                ),
                  SizedBox(height: 10,),                // Login Card
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Title
                          Text(
                            'SitePilot',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: const Color.fromARGB(255, 63, 63, 63),
                                ),
                          ),
                          const SizedBox(height: 20),

                          // Segmented control
                          Row(
                            
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Phone Login'),
                                  selected: _selectedTab == 0,
                                  onSelected: (selected) {
                                    setState(() => _selectedTab = 0);
                                    _pageController.animateToPage(
                                      0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  selectedColor: Color(0xFF6F88E2),
                                  labelStyle: TextStyle(
                                    color: _selectedTab == 0
                                        ? Colors.white
                                        : theme.textTheme.bodyLarge?.color,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Email Login'),
                                  selected: _selectedTab == 1,
                                  onSelected: (selected) {
                                    setState(() => _selectedTab = 1);
                                    _pageController.animateToPage(
                                      1,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  selectedColor: const Color(0xFF6F88E2),
                                  labelStyle: TextStyle(
                                    color: _selectedTab == 1
                                        ? Colors.white
                                        : theme.textTheme.bodyLarge?.color,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // PageView for login forms
                          SizedBox(
                            height: 330,
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: const [
                                OtpScreen(), // Phone login
                                LoginScreenemail(), // Email login
                              ],
                            ),
                          ),
                          //const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Sign up prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "New to User?",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to sign up
                      },
                      child: Text(
                        'Create Account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
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
}
