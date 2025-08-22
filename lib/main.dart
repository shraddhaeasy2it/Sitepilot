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
        // Breakpoints
        if (constraints.maxWidth >= 900) {
          // Desktop
          return const DesktopHomePage();
        } else if (constraints.maxWidth >= 600) {
          // Tablet
          return const TabletHomePage();
        } else {
          // Mobile
          return Scaffold(
            
            body: SplashScreen(), // Your contractor dashboard home
          );
        }
      },
    );
  }
}

// Example Pages
class DesktopHomePage extends StatelessWidget {
  const DesktopHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              
              child: const Center(child: Text("Sidebar / Menu")),
            ),
          ),
          Expanded(
            flex: 5,
            child: HomePageApp(), // Your contractor dashboard home
          ),
        ],
      ),
    );
  }
}

class TabletHomePage extends StatelessWidget {
  const TabletHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tablet View")),
      body: HomePageApp(),
    );
  }
}
