import 'package:ecoteam_app/models/birthday_model.dart';
import 'package:ecoteam_app/models/meeting_model.dart';
import 'package:ecoteam_app/provider/fuel_usage_provider.dart';
import 'package:ecoteam_app/provider/worker_provider.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';
import 'package:ecoteam_app/view/contractor_dashboard/dashboard_page.dart';
import 'package:ecoteam_app/view/contractor_dashboard/home_page.dart';
import 'package:ecoteam_app/view/contractor_dashboard/more/machinary.dart';
import 'package:ecoteam_app/view/landing_page/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ✅ Responsive Helper
class Responsive {
  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isMedium(BuildContext context) =>
      MediaQuery.of(context).size.width >= 360 &&
      MediaQuery.of(context).size.width < 600;

  static bool isLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isExtraLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WorkerProvider()),
        ChangeNotifierProvider(
            create: (_) => CompanySiteProvider()..loadCompanies()),
        ChangeNotifierProvider(create: (_) => MachineProvider()),
        ChangeNotifierProvider(create: (_) => FuelEntryProvider()),
        ChangeNotifierProvider(create: (_) => RentalEntryProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => BirthdayProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        ChangeNotifierProvider(create: (_) => FuelUsageProvider()),
        ChangeNotifierProvider<SiteProvider>(
          create: (context) {
            final companySiteProvider =
                Provider.of<CompanySiteProvider>(context, listen: false);
            final siteProvider = SiteProvider();
            siteProvider.initialize(companySiteProvider);
            return siteProvider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(410, 890), // Base design: medium phone
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Construction Manager',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          builder: (context, widget) {
            ScreenUtil.ensureScreenSize();

            final screenWidth = MediaQuery.of(context).size.width;
            double scaleFactor = 1.0;
            double maxWidth = screenWidth;

            // ✅ Text scaling based on device size
            if (Responsive.isSmall(context)) {
              scaleFactor = 0.85; // very small phones
              maxWidth = 360; // constrain layout width
            } else if (Responsive.isMedium(context)) {
              scaleFactor = 1.0; // normal phones
              maxWidth = 410; // design width
            } else if (Responsive.isLarge(context)) {
              scaleFactor = 1.1; // large phones / small tablets
              maxWidth = 600;
            } else if (Responsive.isExtraLarge(context)) {
              scaleFactor = 1.2; // tablets & web
              maxWidth = 1024;
            }

            // ✅ Apply constraints for wide screens (tablet / web)
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaleFactor: scaleFactor,
                  ),
                  child: widget!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
