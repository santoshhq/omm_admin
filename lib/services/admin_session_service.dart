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
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }

  /// Check if admin session has expired (optional - based on time)
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

  /// Get admin session info for debugging
  static Future<Map<String, dynamic>> getSessionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'adminId': prefs.getString(_adminIdKey),
        'adminEmail': prefs.getString(_adminEmailKey),
        'isLoggedIn': prefs.getBool(_isLoggedInKey) ?? false,
        'loginTime': prefs.getString(_loginTimeKey),
      };
    } catch (e) {
      print('❌ Error getting session info: $e');
      return {};
    }
  }

  /// Update admin session without changing login status
  static Future<bool> updateAdminSession({
    String? adminId,
    String? adminEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (adminId != null) {
        await prefs.setString(_adminIdKey, adminId);
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
}
