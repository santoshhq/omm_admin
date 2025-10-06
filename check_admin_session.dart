import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🔍 Checking Current Admin Session...');
  print('=' * 50);

  try {
    final prefs = await SharedPreferences.getInstance();

    // Check all admin-related stored data
    final adminId = prefs.getString('adminId');
    final adminEmail = prefs.getString('adminEmail');
    final isLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;

    print('📋 Admin Session Data:');
    print('  • Admin ID: ${adminId ?? "NOT SET"}');
    print('  • Admin Email: ${adminEmail ?? "NOT SET"}');
    print('  • Is Logged In: $isLoggedIn');

    if (adminId == null) {
      print('\n❌ NO ADMIN SESSION FOUND!');
      print('💡 You need to login first to create/view events.');
    } else {
      print('\n✅ Admin session found!');

      // Check if this admin has events based on our test results
      if (adminId == "68d664d7d84448fff5dc3a8b") {
        print('🎯 This admin has 3 events in the database');
      } else if (adminId == "675240e8f6e68a8b8c1b9e87") {
        print('⚠️ This admin has 0 events in the database');
        print(
          '💡 Try creating some events first, or login with the admin that has events',
        );
      } else {
        print('❓ Unknown admin - check database for events');
      }
    }

    print('\n' + '=' * 50);
    print('🔧 SOLUTION RECOMMENDATIONS:');

    if (adminId == null) {
      print('1. 🔐 Login to the app first');
      print('2. 🎨 Create some events after login');
    } else if (adminId == "675240e8f6e68a8b8c1b9e87") {
      print('1. 🎨 Create new events with current admin');
      print(
        '2. 🔄 OR login with admin: 68d664d7d84448fff5dc3a8b (has 3 events)',
      );
    } else {
      print('1. 🎨 Create events with current admin');
      print('2. 🔍 Check database for existing events');
    }
  } catch (e) {
    print('❌ Error checking admin session: $e');
  }
}
