import 'package:ecoteam_app/view/contractor_dashboard/dashboard_page.dart';
import 'package:flutter/material.dart';

class AppNavigationWrapper extends StatefulWidget {
  const AppNavigationWrapper({super.key});

  @override
  State<AppNavigationWrapper> createState() => _AppNavigationWrapperState();
}

class _AppNavigationWrapperState extends State<AppNavigationWrapper> {
  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}