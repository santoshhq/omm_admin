import 'package:flutter/material.dart';
import 'package:omm_admin/authentications/login_page/login_page_widget.dart';
import 'package:omm_admin/bottum_navigation.dart';
import 'package:omm_admin/admin_info/admin_info_form_widget.dart';
import 'package:omm_admin/admin_info/admin_info_form_module.dart';
import 'package:omm_admin/complaints/complaint_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Add small delay to ensure platform channels are ready
  await Future.delayed(const Duration(milliseconds: 100));

  // Suppress Flutter framework keyboard errors (known Flutter bug)
  FlutterError.onError = (FlutterErrorDetails details) {
    // Ignore specific keyboard hardware key assertions
    if (details.exception.toString().contains('_pressedKeys.containsKey') ||
        details.exception.toString().contains('KeyUpEvent') ||
        details.exception.toString().contains('hardware_keyboard.dart')) {
      // Silently ignore these known Flutter framework bugs
      return;
    }
    // Report other errors normally
    FlutterError.presentError(details);
  };

  // Wrap in try/catch to avoid platform channel errors with retry
  bool isLoggedIn = false;
  bool isProfileComplete = false;

  for (int i = 0; i < 3; i++) {
    try {
      final prefs = await SharedPreferences.getInstance();
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      isProfileComplete = prefs.getBool('isProfileComplete') ?? false;

      // Load saved profile data if available
      if (isLoggedIn && isProfileComplete) {
        await AdminInfoModel.loadSavedProfile();
      }

      break; // Success, exit retry loop
    } catch (e) {
      debugPrint("SharedPreferences error (attempt ${i + 1}): $e");
      if (i < 2) {
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
      }
    }
  }

  // Initialize auto-cleanup for solved complaints
  if (isLoggedIn) {
    ComplaintService.initializeAutoCleanup();
  }

  runApp(MyApp(isLoggedIn: isLoggedIn, isProfileComplete: isProfileComplete));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isProfileComplete;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.isProfileComplete,
  });

  @override
  Widget build(BuildContext context) {
    Widget homePage;

    debugPrint(
      "🚀 App Init - isLoggedIn: $isLoggedIn, isProfileComplete: $isProfileComplete",
    );

    if (!isLoggedIn) {
      // User not logged in - show login page
      debugPrint("📱 Showing login page");
      homePage = const LoginPage();
    } else if (!isProfileComplete) {
      // User logged in but profile not complete - show admin info form
      debugPrint("📝 Showing admin info form");
      homePage = const AdminInfoFormPage();
    } else {
      // User logged in and profile complete - show main app
      debugPrint("🏠 Showing main app");
      homePage = const BottumNavigation();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: homePage,
      routes: {
        '/login': (context) => const LoginPage(),
        '/admin-info': (context) => const AdminInfoFormPage(),
        '/main': (context) => const BottumNavigation(),
      },
    );
  }
}
