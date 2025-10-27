import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class SecurityGuardAuthService {
  static const String _isLoggedInKey = 'security_guard_logged_in';
  static const String _tokenKey =
      'security_guard_token'; // NEW: Store JWT token
  static const String _guardDataKey = 'security_guard_data';
  static const String _loginTimeKey = 'security_guard_login_time';
  static const String _mobileKey = 'security_guard_mobile';
  static const String _passwordKey = 'security_guard_password';

  // API Configuration
  static String get _baseUrl => ApiService.securityBaseUrl;
  static const String _loginEndpoint = '/login';

  /// Login the security guard with backend API
  static Future<Map<String, dynamic>> login(
    String mobile,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      // Basic validation
      if (mobile.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Mobile number and password are required',
        };
      }

      // Mobile number validation
      if (mobile.length != 10 || !RegExp(r'^\d{10}$').hasMatch(mobile)) {
        return {
          'success': false,
          'message': 'Please enter a valid 10-digit mobile number',
        };
      }

      // Make API call to backend
      final response = await http.post(
        Uri.parse('$_baseUrl$_loginEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobilenumber': mobile, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == true) {
          // Backend returns 'status', not 'success'
          // Login successful
          final guardData = responseData['data'];
          final token = responseData['token']; // NEW: Get JWT token
          final now = DateTime.now().millisecondsSinceEpoch;

          debugPrint(
            '💾 Saving login data - token: ${token != null && token is String && token.length > 20 ? token.substring(0, 20) + "..." : (token?.toString() ?? "<no-token>")}, guardData: $guardData',
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_isLoggedInKey, true);
          await prefs.setString(_tokenKey, token); // NEW: Store JWT token
          await prefs.setString(_guardDataKey, jsonEncode(guardData));
          await prefs.setInt(_loginTimeKey, now);
          await prefs.setString(_mobileKey, mobile); // NEW: Store mobile
          await prefs.setString(_passwordKey, password); // NEW: Store password

          debugPrint('✅ Login data saved successfully');

          return {
            'success': true,
            'message': 'Login successful',
            'data': guardData,
            'token': token, // Return token to caller
          };
        } else {
          // Login failed
          return {
            'success': false,
            'message': responseData['message'] ?? 'Login failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  /// Logout the security guard
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all security guard session data
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_tokenKey); // NEW: Remove token
    await prefs.remove(_guardDataKey);
    await prefs.remove(_loginTimeKey);
    await prefs.remove(_mobileKey); // NEW: Remove mobile
    await prefs.remove(_passwordKey); // NEW: Remove password
  }

  /// Check if security guard is logged in (by checking token validity)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    final token = prefs.getString(_tokenKey);

    if (!isLoggedIn || token == null) {
      return false;
    }

    // You could optionally validate token with backend here
    // For now, just check if token exists
    return true;
  }

  /// Get JWT token for API calls
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get logged in security guard's data
  static Future<Map<String, dynamic>?> getLoggedInGuardData() async {
    final prefs = await SharedPreferences.getInstance();
    final guardDataString = prefs.getString(_guardDataKey);

    if (guardDataString != null) {
      try {
        return jsonDecode(guardDataString);
      } catch (e) {
        debugPrint('❌ Error decoding guard data: $e');
        return null;
      }
    }
    return null;
  }

  /// Get stored mobile number
  static Future<String?> getStoredMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileKey);
  }

  /// Get stored password
  static Future<String?> getStoredPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  /// Make authenticated API call with JWT token
  static Future<Map<String, dynamic>> authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // NEW: JWT Bearer token
    };

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default: // GET
          response = await http.get(url, headers: headers);
      }

      if (response.statusCode == 401) {
        // Token expired, logout user
        await logout();
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      }

      final responseData = jsonDecode(response.body);
      return {
        'success':
            response.statusCode == 200 && responseData['success'] != false,
        'data': responseData,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get pending visitors (authenticated call)
  static Future<Map<String, dynamic>> getPendingVisitors() async {
    return await authenticatedRequest('/visitors');
  }

  /// Get login timestamp
  static Future<DateTime?> getLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_loginTimeKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }
}
