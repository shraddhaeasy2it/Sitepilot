import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:ecoteam_app/view/contractor_dashboard/home_page.dart';
import 'package:ecoteam_app/view/landing_page/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompanySiteProvider()..loadCompanies(),
      child: MaterialApp(
        title: 'Construction Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const ResponsiveWrapper(),
      ),
    );
  }
}

class ResponsiveWrapper extends StatelessWidget {
  const ResponsiveWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;

        if (width >= 400) {
          // 📱 Large Mobile (big phones)
          return const LargeMobilePage();
        } else {
          // 📱 Small Mobile (compact layout)
          return const SmallMobilePage();
        }
      },
    );
  }
}

/// ---------------------------
/// Different Mobile Views
/// ---------------------------

/// Large Mobile (like iPhone Pro Max, Pixel 7 Pro, etc.)
class LargeMobilePage extends StatelessWidget {
  const LargeMobilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Large Mobile View")),
      body: const HomePagescreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

/// Small Mobile (like older phones, iPhone SE, etc.)
class SmallMobilePage extends StatelessWidget {
  const SmallMobilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const HomePagescreen(), // Or SplashScreen() if you want
    );
  }
}