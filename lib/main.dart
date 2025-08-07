import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:ecoteam_app/view/auth/login.dart';
import 'package:ecoteam_app/view/contractor_dashboard/home_page.dart';
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
        home:HomePageApp(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}