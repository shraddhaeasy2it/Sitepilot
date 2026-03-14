import 'dart:async';

import 'package:ecoteam_app/contractor/view/landing_page/landing_page.dart';
import 'package:flutter/material.dart';

// Your existing LandingPages import assumed here or in same file

import 'package:ecoteam_app/contractor/services/app_pusher_services.dart';
import 'package:ecoteam_app/contractor/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/home_page.dart'; // Ensure this import is correct based on your project structure

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Start minimum timer
    final minTimer = Future.delayed(const Duration(milliseconds: 2800));

    // Initialize Services concurrently
    try {
      print("🚀 SplashScreen: Initializing Services...");
      await Future.wait([
        AppPusherManager().initializeAppConnection(),
        NotificationService.requestPermission(),
      ]);
      print("✅ SplashScreen: Services Initialized");
    } catch (e) {
      print("❌ SplashScreen: Error initializing services: $e");
    }

    // Wait for the rest of the timer
    await minTimer;

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        // Token exists, navigate to Home
         Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePagescreen()),
        );
      } else {
        // No token, navigate to Landing
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LandingPages()),
        );
      }
    } catch (e) {
      // Fallback in case of error
      if (mounted) {
         Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LandingPages()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6f88e2), // Your app primary color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/giphy.gif", width: 170, height: 170), // Your splash screen image
            // Your splash screen logo or image here
            // Icon(
            //   Icons.construction,
            //   size: 100,
            //   color: Colors.white,
            // ),

            SizedBox(height: 20),

            Text(
              "Construction App",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),

            SizedBox(height: 8),

            Text(
              "Building your future",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}