import 'dart:async';

import 'package:ecoteam_app/view/landing_page/landing_page.dart';
import 'package:flutter/material.dart';

// Your existing LandingPages import assumed here or in same file

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait for 3 seconds and then navigate to LandingPages
    Timer(const Duration(milliseconds: 2800), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LandingPages()),
      );
    });
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