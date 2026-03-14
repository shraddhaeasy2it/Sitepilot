

import 'package:ecoteam_app/admin/provider/project_site_provider.dart';
import 'package:ecoteam_app/admin/services/admin_role_provider.dart';
import 'package:ecoteam_app/admin/services/admin_user_provider.dart';
import 'package:ecoteam_app/admin/provider/unit_provider.dart';
import 'package:ecoteam_app/contractor/models/birthday_model.dart';
import 'package:ecoteam_app/contractor/models/meeting_model.dart';
import 'package:ecoteam_app/contractor/provider/activity_provider.dart';
import 'package:ecoteam_app/contractor/provider/fuel_usage_provider.dart';
import 'package:ecoteam_app/contractor/provider/machine_provider.dart';
import 'package:ecoteam_app/admin/provider/material_category_provider.dart';
import 'package:ecoteam_app/contractor/provider/worker_provider.dart';
import 'package:ecoteam_app/contractor/services/app_pusher_services.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/services/pusher_services.dart';
import 'package:ecoteam_app/contractor/services/site_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/attendance_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/home_page.dart';
import 'package:ecoteam_app/contractor/view/landing_page/splash_screen.dart';
import 'package:ecoteam_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/global_chat_listener.dart'; // Add this import
import 'package:ecoteam_app/contractor/services/local_notification_service.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/Dashboard/activity_screen.dart';
import 'package:ecoteam_app/global.dart';

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

void main() async{
   WidgetsFlutterBinding.ensureInitialized();
   await LocalNotificationService.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => MachineProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => UnitProvider()..fetchUnits()),
        ChangeNotifierProvider(create: (_) => CompanySiteProvider()),
        ChangeNotifierProvider(create: (_) => MaterialCategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProjectSiteProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      
        ChangeNotifierProvider<SiteProvider>(
          create: (context) {
            final companySiteProvider =
                Provider.of<CompanySiteProvider>(context, listen: false);
            final siteProvider = SiteProvider();
            siteProvider.initialize(companySiteProvider);
            return siteProvider;
          },),

         // Added this provider
        ChangeNotifierProvider<SiteProvider>(
          create: (context) => SiteProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
Future<void> afterLogin() async {
  // Initialize global Pusher connection
  await AppPusherManager().initializeAppConnection();
}

// On logout:
Future<void> onLogout() async {
  await AppPusherManager().disconnect();
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
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
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
                  child: GlobalChatListener(
                    child: widget!,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// in machinery category screen, in card ,use more_vert icon when click open bottomsheet ,in that edit,delete.
// same like as machinery screen.