import 'package:shared_preferences/shared_preferences.dart';

class AdminSessionService {
  static const String _adminIdKey = 'admin_id';
  static const String _adminEmailKey = 'admin_email';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _loginTimeKey = 'login_time';

  /// Save admin session after successful login
  static Future<bool> saveAdminSession({
    required String adminId,
    required String adminEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_adminIdKey, adminId);
      await prefs.setString(_adminEmailKey, adminEmail);
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_loginTimeKey, DateTime.now().toIso8601String());

      print('✅ Admin session saved successfully');
      print('🔑 Admin ID: $adminId');
      print('📧 Admin Email: $adminEmail');

      return true;
    } catch (e) {
      print('❌ Error saving admin session: $e');
      return false;
    }
  }

  /// Get current logged-in admin ID
  static Future<String?> getAdminId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (isLoggedIn) {
        return prefs.getString(_adminIdKey);
      }

      return null;
    } catch (e) {
      print('❌ Error getting admin ID: $e');
      return null;
    }
  }

  /// Get current logged-in admin email
  static Future<String?> getAdminEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (isLoggedIn) {
        return prefs.getString(_adminEmailKey);
      }

      return null;
    } catch (e) {
      print('❌ Error getting admin email: $e');
      return null;
    }
  }

  /// Check if admin is currently logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final adminId = prefs.getString(_adminIdKey);

      // Valid session requires both login flag and admin ID
      return isLoggedIn && adminId != null && adminId.isNotEmpty;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }

  /// Get complete admin session info
  static Future<Map<String, dynamic>?> getAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (!isLoggedIn) return null;

      return {
        'adminId': prefs.getString(_adminIdKey),
        'adminEmail': prefs.getString(_adminEmailKey),
        'isLoggedIn': isLoggedIn,
        'loginTime': prefs.getString(_loginTimeKey),
      };
    } catch (e) {
      print('❌ Error getting admin session: $e');
      return null;
    }
  }

  /// Clear admin session (logout)
  static Future<bool> clearAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_adminIdKey);
      await prefs.remove(_adminEmailKey);
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_loginTimeKey);

      print('✅ Admin session cleared successfully');
      return true;
    } catch (e) {
      print('❌ Error clearing admin session: $e');
      return false;
    }
  }

  /// Update admin session (if admin profile changes)
  static Future<bool> updateAdminSession({String? adminEmail}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (!isLoggedIn) {
        print('❌ Cannot update session - admin not logged in');
        return false;
      }

      if (adminEmail != null) {
        await prefs.setString(_adminEmailKey, adminEmail);
      }

      print('✅ Admin session updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating admin session: $e');
      return false;
    }
  }

  /// Check if session is expired (optional - for security)
  static Future<bool> isSessionExpired({int maxHours = 24}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginTimeStr = prefs.getString(_loginTimeKey);

      if (loginTimeStr == null) return true;

      final loginTime = DateTime.parse(loginTimeStr);
      final now = DateTime.now();
      final difference = now.difference(loginTime);

      return difference.inHours > maxHours;
    } catch (e) {
      print('❌ Error checking session expiry: $e');
      return true; // Assume expired on error
    }
  }
}
