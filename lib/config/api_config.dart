// api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:omm_admin/security_guards/security_module.dart';
import '../services/admin_session_service.dart';

class ApiService {
  // Dynamic base URL based on platform
  static String get baseUrl {
    if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2 to access host machine
      return "http://10.0.2.2:8080/api/auth";
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost or your machine's IP
      return "http://localhost:8080/api/auth";
    } else {
      // For web/desktop development
      return "http://localhost:8080/api/auth";
    }
  }

  // Dynamic base URL for admin profiles based on platform
  static String get adminProfileBaseUrl {
    if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2 to access host machine
      return "http://10.0.2.2:8080/api/admin-profiles";
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost or your machine's IP
      return "http://localhost:8080/api/admin-profiles";
    } else {
      // For web/desktop development
      return "http://localhost:8080/api/admin-profiles";
    }
  }

  // Dynamic base URL for admin members based on platform
  static String get adminMemberBaseUrl {
    if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2 to access host machine
      return "http://10.0.2.2:8080/api/admin-members";
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost or your machine's IP
      return "http://localhost:8080/api/admin-members";
    } else {
      // For web/desktop development
      return "http://localhost:8080/api/admin-members";
    }
  }

  // Dynamic base URL for amenities based on platform
  static String get amenitiesBaseUrl {
    if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2 to access host machine
      return "http://10.0.2.2:8080/api/amenities";
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost or your machine's IP
      return "http://localhost:8080/api/amenities";
    } else {
      // For web/desktop development
      return "http://localhost:8080/api/amenities";
    }
  }

  // Dynamic base URL for events based on platform
  static String get eventsBaseUrl {
    if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2 to access host machine
      return "http://10.0.2.2:8080/api/events";
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost or your machine's IP
      return "http://localhost:8080/api/events";
    } else {
      // For web/desktop development
      return "http://localhost:8080/api/events";
    }
  }

  // Dynamic base URL for announcements based on platform
  static String get announcementsBaseUrl {
    if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2 to access host machine
      return "http://10.0.2.2:8080/api/announcements";
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost or your machine's IP
      return "http://localhost:8080/api/announcements";
    } else {
      // For web/desktop development
      return "http://localhost:8080/api/announcements";
    }
  }

  /// Retry logic for handling connection issues
  static Future<Map<String, dynamic>> _retryRequest(
    Future<Map<String, dynamic>> Function() request, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        attempts++;
        print("🔄 Attempt $attempts of $maxRetries");

        final result = await request();
        print("✅ Request successful on attempt $attempts");
        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        print("❌ Attempt $attempts failed: $e");

        // Don't retry for certain types of errors
        if (e.toString().contains('404') ||
            e.toString().contains('401') ||
            e.toString().contains('403')) {
          print("🚫 Non-retryable error, throwing immediately");
          throw lastException;
        }

        // If this was the last attempt, throw the error
        if (attempts >= maxRetries) {
          print("🚫 Max retries ($maxRetries) reached");
          break;
        }

        // Wait before retrying (exponential backoff)
        final waitTime = Duration(seconds: attempts * 2);
        print("⏳ Waiting ${waitTime.inSeconds} seconds before retry...");
        await Future.delayed(waitTime);
      }
    }

    throw lastException ??
        Exception("Unknown error after $maxRetries attempts");
  }

  /// Signup
  static Future<Map<String, dynamic>> signup(
    String email,
    String password,
  ) async {
    try {
      print("🚀 Starting signup process...");
      print("📧 Email: $email");
      print("🌐 Platform: ${Platform.operatingSystem}");
      print("🔗 Base URL: $baseUrl");
      print("� Full URL: $baseUrl/signup");

      final url = Uri.parse("$baseUrl/signup");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("📱 Response Status: ${response.statusCode}");
      print("📱 Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 && body["status"] == true) {
        print("✅ Signup successful!");
        // Convert backend response to frontend expected format
        return {
          "success": true,
          "message": body["message"],
          "email": email,
          "otp": body["data"]["otp"], // For development - OTP from backend
          "userId":
              body["data"]["userId"] ??
              body["data"]["id"], // User ID from backend
        };
      } else {
        print("❌ Signup failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Signup failed");
      }
    } catch (e) {
      print("🔥 Error in signup: $e");
      // Check if it's a network error (backend not running)
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      // Re-throw other errors
      throw Exception("Signup failed: $e");
    }
  }

  /// Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["status"] == true) {
        print("✅ Login successful!");
        // Convert backend response to frontend expected format
        return {
          "success": true,
          "message": body["message"],
          "token":
              "auth_token_${body["data"]["id"]}", // Generate token based on user ID
          "user": {
            "email": body["data"]["email"],
            "id": body["data"]["id"],
            "isProfile":
                body["data"]["isProfile"] ??
                false, // Profile completion status from backend
          },
        };
      } else {
        print("❌ Login failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Login failed");
      }
    } catch (e) {
      print("🔥 Error in login: $e");
      // Check if it's a network error (backend not running)
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      // Re-throw other errors
      throw Exception("Login failed: $e");
    }
  }

  /// Verify OTP (for signup flow)
  static Future<bool> verifyOtp(String email, String otp) async {
    try {
      final url = Uri.parse("$baseUrl/verify-otp");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      );

      print("📱 OTP Verify Response Status: ${response.statusCode}");
      print("📱 OTP Verify Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["status"] == true) {
        print("✅ OTP verification successful!");
        return true;
      } else {
        print("❌ OTP verification failed: ${body["message"]}");
        return false;
      }
    } catch (e) {
      print("🔥 Error in OTP verification: $e");
      // Check if it's a network error (backend not running)
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      // Re-throw other errors
      throw Exception("OTP verification failed: $e");
    }
  }

  /// Forgot Password (send OTP to email)
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final url = Uri.parse("$baseUrl/forgot-password");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["status"] == true) {
        // Convert backend response to frontend expected format
        return {
          "success": true,
          "message": body["message"],
          "otp": body["data"]["otp"], // For development - OTP from backend
        };
      } else {
        throw Exception(body["message"] ?? "Forgot password failed");
      }
    } catch (e) {
      // Mock forgot password for development when backend is unavailable
      await Future.delayed(const Duration(seconds: 1));
      return {
        "success": true,
        "message": "OTP sent to your email address",
        "otp": "123456", // Mock OTP for development
      };
    }
  }

  /// Reset Password
  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
    String otp,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/reset-password");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "newPassword": newPassword,
          "otp": otp,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["status"] == true) {
        // Convert backend response to frontend expected format
        return {"success": true, "message": body["message"]};
      } else {
        throw Exception(body["message"] ?? "Reset password failed");
      }
    } catch (e) {
      // Mock response for development when backend is unavailable
      await Future.delayed(Duration(seconds: 1));

      // Validate OTP (accept any 6-digit code or "123456" for testing)
      if (otp.length == 6 &&
          (RegExp(r'^\d{6}$').hasMatch(otp) || otp == "123456")) {
        return {
          "success": true,
          "message":
              "Password reset successfully! You can now login with your new password.",
        };
      } else {
        throw Exception("Invalid OTP. Please check and try again.");
      }
    }
  }

  // ===== ADMIN PROFILE API METHODS =====

  /// Create Admin Profile
  static Future<Map<String, dynamic>> createAdminProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String apartment,
    required String phone,
    required String address,
    String? imagePath,
  }) async {
    try {
      print("🚀 Creating admin profile...");
      print("👤 User ID: $userId");
      print("📧 Email: $email");
      print("🌐 Platform: ${Platform.operatingSystem}");
      print("🔗 Admin Profile Base URL: $adminProfileBaseUrl");

      final url = Uri.parse(adminProfileBaseUrl);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "apartment": apartment,
          "phone": phone,
          "address": address,
          "imagePath": imagePath,
        }),
      );

      print("📱 Create Profile Response Status: ${response.statusCode}");
      print("📱 Create Profile Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 && body["status"] == true) {
        print("✅ Admin profile created successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Create profile failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to create admin profile");
      }
    } catch (e) {
      print("🔥 Error creating admin profile: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to create admin profile: $e");
    }
  }

  /// Get Admin Profile by User ID (get current user's profile)
  static Future<Map<String, dynamic>> getAdminProfileByUserId(
    String userId,
  ) async {
    try {
      print("🔍 Fetching admin profile for user: $userId");
      print("🔗 Admin Profile Base URL: $adminProfileBaseUrl");

      // Use the correct endpoint from your backend: /api/admin-profiles/user/:userId
      final url = Uri.parse("$adminProfileBaseUrl/user/$userId");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Get Profile Response Status: ${response.statusCode}");
      print("📱 Get Profile Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["status"] == true) {
        print("✅ Admin profile fetched successfully!");
        print("🔍 Profile data: ${body["data"]}");
        return {"success": true, "data": body["data"]};
      } else {
        print("❌ Get profile failed: ${body["message"]}");
        print("🔍 Full response body: $body");
        return {
          "success": false,
          "message": body["message"] ?? "Failed to fetch admin profile",
        };
      }
    } catch (e) {
      print("🔥 Error fetching admin profile: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch admin profile: $e");
    }
  }

  /// Get All Admin Profiles
  static Future<Map<String, dynamic>> getAllAdminProfiles() async {
    try {
      print("🔍 Fetching all admin profiles...");
      print("🔗 Admin Profile Base URL: $adminProfileBaseUrl");

      final url = Uri.parse(adminProfileBaseUrl);
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Get All Profiles Response Status: ${response.statusCode}");
      print("📱 Get All Profiles Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["status"] == true) {
        print("✅ All admin profiles fetched successfully!");
        return {"success": true, "data": body["data"]};
      } else {
        print("❌ Get all profiles failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch admin profiles");
      }
    } catch (e) {
      print("🔥 Error fetching all admin profiles: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch admin profiles: $e");
    }
  }

  /// Update Admin Profile
  static Future<Map<String, dynamic>> updateAdminProfile({
    required String profileId,
    required String firstName,
    required String lastName,
    required String email,
    required String apartment,
    required String phone,
    required String address,
    String? imagePath,
  }) async {
    try {
      print("🔄 Updating admin profile: $profileId");
      print("🔗 Admin Profile Base URL: $adminProfileBaseUrl");

      final url = Uri.parse("$adminProfileBaseUrl/$profileId");
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "apartment": apartment,
          "phone": phone,
          "address": address,
          "imagePath": imagePath,
        }),
      );

      print("📱 Update Profile Response Status: ${response.statusCode}");
      print("📱 Update Profile Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["status"] == true) {
        print("✅ Admin profile updated successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Update profile failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to update admin profile");
      }
    } catch (e) {
      print("🔥 Error updating admin profile: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to update admin profile: $e");
    }
  }

  /// Update user's isProfile status in signup collection
  static Future<Map<String, dynamic>> updateProfileStatus({
    required String userId,
    required bool isProfile,
  }) async {
    try {
      print("🔄 Updating profile status for user: $userId to $isProfile");

      final url = Uri.parse("$baseUrl/update-profile-status");
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "isProfile": isProfile}),
      );

      print("📱 Update Profile Status Response Status: ${response.statusCode}");
      print("📱 Update Profile Status Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["status"] == true) {
        print("✅ Profile status updated successfully!");
        return {"success": true, "message": body["message"]};
      } else {
        print("❌ Update profile status failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to update profile status");
      }
    } catch (e) {
      print("🔥 Error updating profile status: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to update profile status: $e");
    }
  }

  // ===== ADMIN MEMBER MANAGEMENT APIs =====

  /// Admin Creates Member
  static Future<Map<String, dynamic>> adminCreateMember({
    required String adminId,
    required String userId,
    required String password,
    String? profileImage,
    required String firstName,
    required String lastName,
    required String mobile,
    required String email,
    required String floor,
    required String flatNo,
    String? paymentStatus,
    String? parkingArea,
    String? parkingSlot,
    required String govtIdType,
    required String govtIdImage,
  }) async {
    try {
      print("🚀 Starting admin create member process...");
      print("🔑 Admin ID: $adminId");
      print("🆔 User ID: $userId");
      print("👤 Member: $firstName $lastName");
      print("📧 Email: $email");
      print("📱 Mobile: $mobile");
      print("🏢 Flat: Floor $floor, Flat $flatNo");
      print(
        "🅿️ Parking: ${parkingArea ?? 'Not Assigned'}-${parkingSlot ?? 'Not Assigned'}",
      );
      print("🌐 Base URL: $adminMemberBaseUrl");

      final url = Uri.parse("$adminMemberBaseUrl/create");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "adminId": adminId,
          "userId": userId,
          "password": password,
          "profileImage": profileImage,
          "firstName": firstName,
          "lastName": lastName,
          "mobile": mobile,
          "email": email,
          "floor": floor,
          "flatNo": flatNo,
          "paymentStatus": paymentStatus ?? "Available",
          "parkingArea": parkingArea ?? "Not Assigned",
          "parkingSlot": parkingSlot ?? "Not Assigned",
          "govtIdType": govtIdType,
          "govtIdImage": govtIdImage,
        }),
      );

      print("📱 Create Member Response Status: ${response.statusCode}");
      print("📱 Create Member Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 && body["success"] == true) {
        print("✅ Member created successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Create member failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to create member");
      }
    } catch (e) {
      print("🔥 Error creating member: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to create member: $e");
    }
  }

  /// Get Members Created by Admin
  static Future<Map<String, dynamic>> getAdminMembers(String adminId) async {
    try {
      print("🔍 Fetching members for admin: $adminId");
      print("🌐 Base URL: $adminMemberBaseUrl");

      final url = Uri.parse("$adminMemberBaseUrl/admin/$adminId");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Get Members Response Status: ${response.statusCode}");
      print("📱 Get Members Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Members fetched successfully! Count: ${body["count"]}");
        return {"success": true, "count": body["count"], "data": body["data"]};
      } else {
        print("❌ Fetch members failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch members");
      }
    } catch (e) {
      print("🔥 Error fetching members: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch members: $e");
    }
  }

  /// Member Login with Admin-Created Credentials
  static Future<Map<String, dynamic>> memberLogin({
    required String userId,
    required String password,
  }) async {
    try {
      print("🔐 Starting member login process...");
      print("👤 User ID: $userId");
      print("🌐 Base URL: $adminMemberBaseUrl");

      final url = Uri.parse("$adminMemberBaseUrl/member-login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "password": password}),
      );

      print("📱 Member Login Response Status: ${response.statusCode}");
      print("📱 Member Login Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Member login successful!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Member login failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to login");
      }
    } catch (e) {
      print("🔥 Error during member login: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to login: $e");
    }
  }

  /// Admin Updates Member
  static Future<Map<String, dynamic>> adminUpdateMember({
    required String adminId,
    required String memberId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      print("✏️ Starting admin update member process...");
      print("🔑 Admin ID: $adminId");
      print("👤 Member ID: $memberId");
      print("📝 Update Data: $updateData");
      print("🌐 Base URL: $adminMemberBaseUrl");

      final url = Uri.parse(
        "$adminMemberBaseUrl/admin/$adminId/member/$memberId",
      );
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
      );

      print("📱 Update Member Response Status: ${response.statusCode}");
      print("📱 Update Member Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Member updated successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Update member failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to update member");
      }
    } catch (e) {
      print("🔥 Error updating member: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to update member: $e");
    }
  }

  /// Admin Deletes Member
  static Future<Map<String, dynamic>> adminDeleteMember({
    required String adminId,
    required String memberId,
  }) async {
    try {
      print("🗑️ Starting admin delete member process...");
      print("🔑 Admin ID: $adminId");
      print("👤 Member ID: $memberId");
      print("🌐 Base URL: $adminMemberBaseUrl");

      final url = Uri.parse(
        "$adminMemberBaseUrl/admin/$adminId/member/$memberId",
      );
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Delete Member Response Status: ${response.statusCode}");
      print("📱 Delete Member Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Member deleted successfully!");
        return {"success": true, "message": body["message"]};
      } else {
        print("❌ Delete member failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to delete member");
      }
    } catch (e) {
      print("🔥 Error deleting member: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to delete member: $e");
    }
  }

  // ========================= AMENITIES API METHODS =========================

  /// Create Amenity
  static Future<Map<String, dynamic>> createAmenity({
    required String createdByAdminId,
    required String name,
    required String description,
    required int capacity,
    required String bookingType,
    required Map<String, dynamic> weeklySchedule,
    required List<String> imagePaths,
    String? location,
    double? hourlyRate,
    List<String>? features,
    bool? active,
  }) async {
    try {
      print("🚀 Starting create amenity process...");
      print("🔑 Admin ID: $createdByAdminId");
      print("🏊 Amenity: $name");
      print("📝 Description: $description");
      print("👥 Capacity: $capacity");
      print("🎯 Booking Type: $bookingType");
      print("📅 Weekly Schedule: $weeklySchedule");
      print("💰 Hourly Rate: ${hourlyRate ?? 0.0}");
      print("📸 Images: ${imagePaths.length} images");
      print("🌐 Base URL: $amenitiesBaseUrl");

      final url = Uri.parse("$amenitiesBaseUrl/admin/$createdByAdminId");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "description": description,
          "capacity": capacity,
          "bookingType": bookingType,
          "weeklySchedule": weeklySchedule,
          "imagePaths": imagePaths,
          "location": location ?? "",
          "hourlyRate": hourlyRate ?? 0.0,
          "features": features ?? [],
          "active": active ?? true,
        }),
      );

      print("📱 Create Amenity Response Status: ${response.statusCode}");
      print("📱 Create Amenity Response Body: ${response.body}");

      // Check if response is HTML (404 error page) instead of JSON
      if (response.statusCode == 404) {
        print("❌ Create amenity API endpoint not found (404)");
        print(
          "💡 Backend routes are not registered. Please integrate amenities routes.",
        );
        throw Exception(
          "Amenities API not available. Please integrate the amenities routes in your backend server. See QUICK_FIX_SUMMARY.md for instructions.",
        );
      }

      // Try to parse JSON, handle non-JSON responses gracefully
      late Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        print("❌ Invalid JSON response from server");
        print("🔥 Response was: ${response.body.substring(0, 200)}...");
        throw Exception(
          "Server returned invalid response. Expected JSON but got HTML. Please check if amenities routes are properly registered in your backend.",
        );
      }

      if (response.statusCode == 201 && body["success"] == true) {
        print("✅ Amenity created successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Create amenity failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to create amenity");
      }
    } catch (e) {
      print("🔥 Error creating amenity: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to create amenity: $e");
    }
  }

  /// Get All Amenities for Admin
  static Future<Map<String, dynamic>> getAllAmenities({
    required String adminId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      print("🚀 Fetching all amenities...");
      print("🔑 Admin ID: $adminId");
      print("🔍 Filters: ${filters ?? 'None'}");
      print("🌐 Base URL: $amenitiesBaseUrl");

      // Build query parameters
      String queryString = "";
      if (filters != null && filters.isNotEmpty) {
        final queryParams = <String>[];
        filters.forEach((key, value) {
          if (value != null) {
            queryParams.add("$key=${Uri.encodeComponent(value.toString())}");
          }
        });
        if (queryParams.isNotEmpty) {
          queryString = "?${queryParams.join('&')}";
        }
      }

      final url = Uri.parse("$amenitiesBaseUrl/admin/$adminId$queryString");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Get All Amenities Response Status: ${response.statusCode}");
      print("📱 Get All Amenities Response Body: ${response.body}");

      // Check if response is HTML (404 error page) instead of JSON
      if (response.statusCode == 404) {
        print("❌ Amenities API endpoint not found (404)");
        print(
          "💡 Backend routes are not registered. Please integrate amenities routes.",
        );
        throw Exception(
          "Amenities API not available. Please integrate the amenities routes in your backend server. See QUICK_FIX_SUMMARY.md for instructions.",
        );
      }

      // Try to parse JSON, handle non-JSON responses gracefully
      late Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        print("❌ Invalid JSON response from server");
        print("🔥 Response was: ${response.body.substring(0, 200)}...");
        throw Exception(
          "Server returned invalid response. Expected JSON but got HTML. Please check if amenities routes are properly registered in your backend.",
        );
      }

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Amenities fetched successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"]["amenities"] ?? [],
          "totalAmenities": body["data"]["totalAmenities"] ?? 0,
        };
      } else {
        print("❌ Get amenities failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch amenities");
      }
    } catch (e) {
      print("🔥 Error fetching amenities: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch amenities: $e");
    }
  }

  /// Get Amenity by ID
  static Future<Map<String, dynamic>> getAmenityById({
    required String adminId,
    required String amenityId,
  }) async {
    try {
      print("🚀 Fetching amenity by ID: $amenityId");
      print("🔑 Admin ID: $adminId");
      print("🌐 Base URL: $amenitiesBaseUrl");

      final url = Uri.parse(
        "$amenitiesBaseUrl/admin/$adminId/amenity/$amenityId",
      );
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Get Amenity Response Status: ${response.statusCode}");
      print("📱 Get Amenity Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Amenity fetched successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"]["amenity"],
        };
      } else {
        print("❌ Get amenity failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch amenity");
      }
    } catch (e) {
      print("🔥 Error fetching amenity: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch amenity: $e");
    }
  }

  /// Update Amenity
  static Future<Map<String, dynamic>> updateAmenity({
    required String adminId,
    required String amenityId,
    String? name,
    String? description,
    int? capacity,
    String? bookingType,
    Map<String, dynamic>? weeklySchedule,
    List<String>? imagePaths,
    String? location,
    double? hourlyRate,
    List<String>? features,
    bool? active,
  }) async {
    try {
      print("🚀 Starting update amenity process...");
      print("🔑 Admin ID: $adminId");
      print("🆔 Amenity ID: $amenityId");
      print("🏊 Updated Name: ${name ?? 'No change'}");
      print("🎯 Updated Booking Type: ${bookingType ?? 'No change'}");
      print(
        "� Updated Weekly Schedule: ${weeklySchedule != null ? 'Updated' : 'No change'}",
      );
      print("�💰 Updated Hourly Rate: ${hourlyRate ?? 'No change'}");
      print("🌐 Base URL: $amenitiesBaseUrl");

      // Create update data map, only include non-null values
      Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (capacity != null) updateData['capacity'] = capacity;
      if (bookingType != null) updateData['bookingType'] = bookingType;
      if (weeklySchedule != null) updateData['weeklySchedule'] = weeklySchedule;
      if (imagePaths != null) updateData['imagePaths'] = imagePaths;
      if (location != null) updateData['location'] = location;
      if (hourlyRate != null) updateData['hourlyRate'] = hourlyRate;
      if (features != null) updateData['features'] = features;
      if (active != null) updateData['active'] = active;

      final url = Uri.parse(
        "$amenitiesBaseUrl/admin/$adminId/amenity/$amenityId",
      );
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
      );

      print("📱 Update Amenity Response Status: ${response.statusCode}");
      print("📱 Update Amenity Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Amenity updated successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"]["amenity"],
        };
      } else {
        print("❌ Update amenity failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to update amenity");
      }
    } catch (e) {
      print("🔥 Error updating amenity: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to update amenity: $e");
    }
  }

  /// Delete Amenity (Soft Delete by default)
  static Future<Map<String, dynamic>> deleteAmenity({
    required String adminId,
    required String amenityId,
    bool hardDelete = false,
  }) async {
    try {
      print("🚀 Starting delete amenity process...");
      print("🔑 Admin ID: $adminId");
      print("🆔 Amenity ID: $amenityId");
      print("💥 Hard Delete: $hardDelete");
      print("🌐 Base URL: $amenitiesBaseUrl");

      String queryString = hardDelete ? "?hardDelete=true" : "";
      final url = Uri.parse(
        "$amenitiesBaseUrl/admin/$adminId/amenity/$amenityId$queryString",
      );
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Delete Amenity Response Status: ${response.statusCode}");
      print("📱 Delete Amenity Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Amenity deleted successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Delete amenity failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to delete amenity");
      }
    } catch (e) {
      print("🔥 Error deleting amenity: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to delete amenity: $e");
    }
  }

  /// Toggle Amenity Status (Active/Inactive)
  static Future<Map<String, dynamic>> toggleAmenityStatus({
    required String adminId,
    required String amenityId,
  }) async {
    try {
      print("🚀 Starting toggle amenity status process...");
      print("🔑 Admin ID: $adminId");
      print("🆔 Amenity ID: $amenityId");
      print("🌐 Base URL: $amenitiesBaseUrl");

      final url = Uri.parse(
        "$amenitiesBaseUrl/admin/$adminId/amenity/$amenityId/toggle-status",
      );
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Toggle Status Response Status: ${response.statusCode}");
      print("📱 Toggle Status Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Amenity status toggled successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"]["amenity"],
        };
      } else {
        print("❌ Toggle status failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to toggle amenity status");
      }
    } catch (e) {
      print("🔥 Error toggling amenity status: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to toggle amenity status: $e");
    }
  }

  // ==================== EVENT CARD API METHODS ====================

  /// Create Event Card
  static Future<Map<String, dynamic>> createEventCard({
    String? image,
    required String name,
    required String startdate,
    required String enddate,
    required String description,
    required double targetamount,
    List<String>? eventdetails,
    required String adminId,
  }) async {
    try {
      print("🚀 Creating event card...");
      print("📅 Event: $name");
      print("🖼️ Image data length: ${image?.length ?? 0} characters");
      print("🌐 URL: $eventsBaseUrl");

      final url = Uri.parse(eventsBaseUrl);

      // Convert single image to array format that backend expects
      List<String> images = [];
      if (image != null && image.isNotEmpty) {
        images.add(image);
      }

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Connection": "keep-alive",
        },
        body: jsonEncode({
          "images": images, // always an array
          "name": name,
          "startdate": startdate,
          "enddate": enddate,
          "description": description,
          "targetamount": targetamount,
          "eventdetails": eventdetails ?? [],
          "adminId": adminId,
        }),
      );

      print("📱 Create Event Response Status: ${response.statusCode}");
      print("📱 Create Event Response Body: ${response.body}");

      // Check if response is HTML (error page) instead of JSON
      if (response.statusCode == 404) {
        print("❌ Create event API endpoint not found (404)");
        throw Exception(
          "Events API endpoint not found. Please check your backend server routes.",
        );
      }

      if (response.statusCode >= 500) {
        print("❌ Server error (${response.statusCode})");
        if (response.body.contains('<!DOCTYPE html>') ||
            response.body.contains('<html>')) {
          throw Exception(
            "Server error occurred while processing the image. Please check your backend server logs.",
          );
        }
      }

      // Try to parse JSON, handle non-JSON responses gracefully
      late Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        print("❌ Invalid JSON response from server");
        final maxLength = response.body.length > 200
            ? 200
            : response.body.length;
        print("🔥 Response was: ${response.body.substring(0, maxLength)}...");
        if (response.body.contains('<!DOCTYPE html>') ||
            response.body.contains('<html>')) {
          throw Exception(
            "Server returned HTML error page instead of JSON. This usually means there's an error processing the image data on the backend.",
          );
        }
        final previewLength = response.body.length > 100
            ? 100
            : response.body.length;
        throw Exception(
          "Server returned invalid response. Expected JSON but got: ${response.body.substring(0, previewLength)}",
        );
      }

      if (response.statusCode == 201 && body["success"] == true) {
        print("✅ Event card created successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Create event failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to create event card");
      }
    } catch (e) {
      print("🔥 Error creating event card: $e");

      // Handle specific connection issues
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      } else if (e.toString().contains(
        'Connection closed while receiving data',
      )) {
        throw Exception(
          "❌ Connection lost while creating event. This is usually caused by:\n"
          "• Large image files (>5MB)\n"
          "• Server timeout settings too low\n"
          "• Network instability\n\n"
          "Solutions:\n"
          "• Use smaller images (<2MB)\n"
          "• Increase server payload limit to 50mb\n"
          "• Increase server timeout to 120 seconds\n"
          "• Check your network connection",
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception(
          "❌ Request timeout. The server is taking too long to respond. Please try again or use a smaller image.",
        );
      }

      throw Exception("Failed to create event card: $e");
    }
  }

  /// Get All Event Cards
  static Future<Map<String, dynamic>> getAllEventCards() async {
    try {
      // First try the normal request with retry logic
      return await _retryRequest(
        () => _getAllEventCardsInternal(),
        maxRetries: 2,
      );
    } catch (e) {
      print("🔄 Normal fetch failed, trying lightweight fetch...");

      // If normal fetch fails, try to get lightweight data (without images)
      try {
        return await _getAllEventCardsLightweight();
      } catch (lightweightError) {
        print("❌ Both normal and lightweight fetch failed");

        // If it's specifically a connection issue, provide helpful guidance
        if (e.toString().contains('Connection closed while receiving data')) {
          throw Exception(
            "❌ Cannot fetch events due to large image data causing connection timeouts.\n\n"
            "🔧 IMMEDIATE SOLUTIONS:\n"
            "1. Backend: Add a lightweight endpoint (/api/events?lightweight=true) that returns events without images\n"
            "2. Backend: Increase server timeout to 120+ seconds\n"
            "3. Backend: Increase payload limit to 50MB+\n"
            "4. Database: Consider storing image URLs instead of base64 data\n\n"
            "⚡ QUICK FIX: Clear all events with large images from your database and recreate with smaller images (<500KB each)\n\n"
            "🏗️ Original error: ${e.toString()}",
          );
        }

        // Return the original error since it's more detailed
        throw e;
      }
    }
  }

  /// Get Event Cards by Admin ID - Admin-specific filtering (with lightweight fallback)
  static Future<Map<String, dynamic>> getEventCardsByAdminId(
    String adminId,
  ) async {
    try {
      print("🚀 Fetching event cards for admin: $adminId");
      print("🌐 Primary URL: $eventsBaseUrl/admin/$adminId");

      final url = Uri.parse("$eventsBaseUrl/admin/$adminId");
      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "Connection": "close",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("📱 Primary Response Status: ${response.statusCode}");

      // ✅ Primary endpoint success
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body["success"] == true) {
          final eventCount = body["data"] is List ? body["data"].length : 0;
          print("✅ Admin events fetched successfully (primary)!");
          print("📊 Events: $eventCount");

          return {
            "success": true,
            "message": "Admin events fetched successfully",
            "data": body["data"],
          };
        } else {
          print("❌ Primary returned success: false -> ${body["message"]}");
          throw Exception(body["message"] ?? "Failed to fetch admin events");
        }
      } else {
        print("❌ Primary endpoint failed: ${response.statusCode}");
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Primary endpoint error: $e");
      print("🔄 Trying fallback to lightweight legacy route...");

      try {
        // ✅ Lightweight fallback (no images)
        final fallbackUrl = Uri.parse(
          "$eventsBaseUrl?adminId=$adminId&lightweight=true",
        );
        print("🌐 Fallback URL: $fallbackUrl");

        final fallbackResponse = await http
            .get(
              fallbackUrl,
              headers: {
                "Content-Type": "application/json",
                "Connection": "close",
              },
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception("Fallback request timeout after 30 seconds");
              },
            );

        print("📱 Fallback Response Status: ${fallbackResponse.statusCode}");

        if (fallbackResponse.statusCode != 200) {
          throw Exception(
            "Fallback server error: ${fallbackResponse.statusCode}",
          );
        }

        // ✅ Parse safely
        late Map<String, dynamic> body;
        try {
          body = jsonDecode(fallbackResponse.body);
        } catch (decodeError) {
          print("❌ Invalid JSON from fallback: $decodeError");
          throw Exception("Server returned invalid JSON in fallback mode");
        }

        if (body["success"] != true) {
          throw Exception(body["message"] ?? "Fallback failed");
        }

        // ✅ Data extraction & admin filtering
        final List<dynamic> allEvents = body['data'] ?? [];
        print("📊 Fallback total events received: ${allEvents.length}");

        final adminEvents = allEvents.where((eventJson) {
          final eventAdminId = eventJson['adminId'];
          String? adminIdFromEvent;

          if (eventAdminId is Map<String, dynamic>) {
            adminIdFromEvent = eventAdminId['_id']?.toString();
            print("🔍 Event adminId object format -> ID: $adminIdFromEvent");
          } else {
            adminIdFromEvent = eventAdminId?.toString();
            print("🔍 Event adminId string format: $adminIdFromEvent");
          }

          final match = adminIdFromEvent == adminId;
          print("🔍 Match check: $adminIdFromEvent == $adminId => $match");
          return match;
        }).toList();

        print(
          "✅ Fallback filtering done! Admin-specific events: ${adminEvents.length}",
        );

        return {
          "success": true,
          "message": "Admin events fetched successfully (lightweight fallback)",
          "data": adminEvents,
        };
      } catch (fallbackError) {
        print("🔥 Fallback also failed: $fallbackError");
        throw Exception(
          "Failed to fetch admin-specific events (both endpoints failed): $fallbackError",
        );
      }
    }
  }

  /// Get All Event Cards (Lightweight - without images)
  static Future<Map<String, dynamic>> _getAllEventCardsLightweight() async {
    print("🚀 Fetching event cards (lightweight mode)...");
    print("🌐 URL: $eventsBaseUrl?lightweight=true");

    final url = Uri.parse("$eventsBaseUrl?lightweight=true");
    final response = await http
        .get(
          url,
          headers: {
            "Content-Type": "application/json",
            "Connection":
                "close", // Close connection immediately after response
          },
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception("Lightweight request timeout after 30 seconds");
          },
        );

    print("📱 Lightweight Response Status: ${response.statusCode}");

    if (response.statusCode == 404) {
      // If lightweight endpoint doesn't exist, throw error to fallback to original
      throw Exception("Lightweight endpoint not available");
    }

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["success"] == true) {
      print("✅ Event cards fetched successfully (lightweight)!");
      final eventCount = body["data"] is List ? body["data"].length : 0;
      print("📊 Events fetched: $eventCount (without images)");

      // Add a flag to indicate this is lightweight data
      return {
        "success": true,
        "message":
            "Event cards fetched successfully (lightweight mode - images not included)",
        "data": body["data"],
        "isLightweight": true,
      };
    } else {
      throw Exception(
        body["message"] ?? "Failed to fetch event cards (lightweight)",
      );
    }
  }

  /// Internal method for getting all event cards with retry logic
  static Future<Map<String, dynamic>> _getAllEventCardsInternal() async {
    print("🚀 Fetching all event cards...");
    print("🌐 URL: $eventsBaseUrl");

    final url = Uri.parse(eventsBaseUrl);

    // Create HTTP client with custom settings
    final client = http.Client();

    try {
      final request = http.Request('GET', url);
      request.headers.addAll({
        "Content-Type": "application/json",
        "Connection": "keep-alive",
        "Accept-Encoding": "gzip, deflate",
        "Cache-Control": "no-cache",
      });

      // Send request with streaming response to handle large data better
      final streamedResponse = await client
          .send(request)
          .timeout(
            const Duration(seconds: 90), // Extended timeout
            onTimeout: () {
              throw Exception(
                "Request timeout after 90 seconds. The server might be returning large image data.",
              );
            },
          );

      // Convert streamed response to regular response
      final response = await http.Response.fromStream(streamedResponse);

      print("📱 Get All Events Response Status: ${response.statusCode}");

      // Log response size to help debug large payloads
      final responseSizeMB = (response.body.length / 1024 / 1024);
      print("📊 Response size: ${responseSizeMB.toStringAsFixed(2)} MB");

      if (responseSizeMB > 10) {
        print(
          "⚠️ Large response detected. Consider implementing pagination or reducing image sizes.",
        );
      }

      // Only log response body if it's not too large
      if (response.body.length < 1000) {
        print("📱 Get All Events Response Body: ${response.body}");
      } else {
        print(
          "📱 Get All Events Response Body: [Large response - ${response.body.length} characters]",
        );
      }

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Event cards fetched successfully!");
        final eventCount = body["data"] is List ? body["data"].length : 0;
        print("📊 Events fetched: $eventCount");
        return {
          "success": true,
          "message": "Event cards fetched successfully",
          "data": body["data"],
        };
      } else {
        print("❌ Fetch events failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch event cards");
      }
    } catch (e) {
      print("🔥 Error fetching event cards: $e");

      // Handle specific connection issues with detailed solutions
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      } else if (e.toString().contains(
        'Connection closed while receiving data',
      )) {
        throw Exception(
          "❌ Connection lost while fetching events. This is usually caused by:\n"
          "• Large response with multiple high-resolution images\n"
          "• Server timeout settings too low\n"
          "• Network instability\n\n"
          "Solutions:\n"
          "• Implement pagination for events\n"
          "• Reduce image sizes in stored events\n"
          "• Increase server response timeout to 120 seconds\n"
          "• Consider returning image thumbnails instead of full images",
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception(
          "❌ Request timeout. The server is taking too long to respond. This might be due to large image data in events.",
        );
      }

      throw Exception("Failed to fetch event cards: $e");
    } finally {
      client.close();
    }
  }

  /// Test server connectivity without fetching large data
  static Future<bool> testServerConnection() async {
    try {
      print("🔍 Testing server connection...");
      final baseUrl = eventsBaseUrl.replaceAll('/api/events', '');
      final response = await http
          .get(
            Uri.parse("$baseUrl/api/health"), // Try health check endpoint
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 10));

      print("📱 Health check response: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Server connection test failed: $e");
      return false;
    }
  }

  /// Get Event Card by ID
  static Future<Map<String, dynamic>> getEventCardById({
    required String id,
    required String adminId,
  }) async {
    try {
      print("🚀 Fetching event card by ID...");
      print("🆔 Event ID: $id");
      print("👤 Admin ID: $adminId");
      print("🌐 URL: $eventsBaseUrl/admin/$adminId/event/$id");

      final url = Uri.parse("$eventsBaseUrl/admin/$adminId/event/$id");
      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "Connection": "keep-alive",
            },
          )
          .timeout(
            const Duration(seconds: 30), // Timeout for single event
            onTimeout: () {
              throw Exception(
                "Request timeout after 30 seconds. The event might contain large image data.",
              );
            },
          );

      print("📱 Get Event Response Status: ${response.statusCode}");

      // Log response size for debugging
      final responseSizeMB = (response.body.length / 1024 / 1024);
      if (responseSizeMB > 1) {
        print("📊 Response size: ${responseSizeMB.toStringAsFixed(2)} MB");
      }

      // Only log full response if it's not too large
      if (response.body.length < 500) {
        print("📱 Get Event Response Body: ${response.body}");
      } else {
        print(
          "📱 Get Event Response Body: [Large response - ${response.body.length} characters]",
        );
      }

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Event card fetched successfully!");
        return {
          "success": true,
          "message": "Event card fetched successfully",
          "data": body["data"],
        };
      } else {
        print("❌ Fetch event failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch event card");
      }
    } catch (e) {
      print("🔥 Error fetching event card: $e");

      // Handle specific connection issues
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      } else if (e.toString().contains(
        'Connection closed while receiving data',
      )) {
        throw Exception(
          "❌ Connection lost while fetching event. This might be due to large image data in the event.",
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception(
          "❌ Request timeout. The event might contain large image data.",
        );
      }

      throw Exception("Failed to fetch event card: $e");
    }
  }

  /// Update Event Card
  static Future<Map<String, dynamic>> updateEventCard({
    required String id,
    required String adminId,
    String? image,
    String? name,
    String? startdate,
    String? enddate,
    String? description,
    double? targetamount,
    List<String>? eventdetails,
    bool? status,
  }) async {
    try {
      print("🚀 Updating event card...");
      print("🆔 Event ID: $id");
      print("👤 Admin ID: $adminId");
      print("🌐 URL: $eventsBaseUrl/admin/$adminId/event/$id");

      final Map<String, dynamic> updateData = {"adminId": adminId};

      if (image != null) {
        // Convert single image to array format that backend expects
        updateData["images"] = [image];
        print("🖼️ Converting single image to array format for backend");
      }
      if (name != null) updateData["name"] = name;
      if (startdate != null) updateData["startdate"] = startdate;
      if (enddate != null) updateData["enddate"] = enddate;
      if (description != null) updateData["description"] = description;
      if (targetamount != null) updateData["targetamount"] = targetamount;
      if (eventdetails != null) updateData["eventdetails"] = eventdetails;
      if (status != null) updateData["status"] = status;

      final url = Uri.parse("$eventsBaseUrl/admin/$adminId/event/$id");

      // Add timeout and better error handling for large payloads
      final response = await http
          .put(
            url,
            headers: {
              "Content-Type": "application/json",
              "Connection": "keep-alive",
            },
            body: jsonEncode(updateData),
          )
          .timeout(
            const Duration(
              seconds: 60,
            ), // Increased timeout for large image uploads
            onTimeout: () {
              throw Exception(
                "Request timeout after 60 seconds. The image might be too large or server is taking too long to respond. Please try with a smaller image.",
              );
            },
          );

      print("📱 Update Event Response Status: ${response.statusCode}");
      print("📱 Update Event Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Event card updated successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Update event failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to update event card");
      }
    } catch (e) {
      print("🔥 Error updating event card: $e");

      // Handle specific connection issues
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      } else if (e.toString().contains(
        'Connection closed while receiving data',
      )) {
        throw Exception(
          "❌ Connection lost while updating event. This is usually caused by:\n"
          "• Large image files (>5MB)\n"
          "• Server timeout settings too low\n"
          "• Network instability\n\n"
          "Solutions:\n"
          "• Use smaller images (<2MB)\n"
          "• Increase server payload limit to 50mb\n"
          "• Increase server timeout to 120 seconds\n"
          "• Check your network connection",
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception(
          "❌ Request timeout. The server is taking too long to respond. Please try again or use a smaller image.",
        );
      }

      throw Exception("Failed to update event card: $e");
    }
  }

  /// Delete Event Card
  static Future<Map<String, dynamic>> deleteEventCard({
    required String id,
    required String adminId,
  }) async {
    try {
      print("🚀 Deleting event card...");
      print("🆔 Event ID: $id");
      print("👤 Admin ID: $adminId");
      print("🌐 URL: $eventsBaseUrl/admin/$adminId/event/$id");

      final url = Uri.parse("$eventsBaseUrl/admin/$adminId/event/$id");
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Delete Event Response Status: ${response.statusCode}");
      print("📱 Delete Event Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Event card deleted successfully!");
        return {"success": true, "message": body["message"]};
      } else {
        print("❌ Delete event failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to delete event card");
      }
    } catch (e) {
      print("🔥 Error deleting event card: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to delete event card: $e");
    }
  }

  /// Add Event Donation
  static Future<Map<String, dynamic>> addEventDonation({
    required String eventId,
    required String userId,
    required double amount,
  }) async {
    try {
      print("🚀 Adding event donation...");
      print("🆔 Event ID: $eventId");
      print("👤 User ID: $userId");
      print("💰 Amount: $amount");
      print("🌐 URL: $eventsBaseUrl/$eventId/donate");

      final url = Uri.parse("$eventsBaseUrl/$eventId/donate");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "amount": amount}),
      );

      print("📱 Add Donation Response Status: ${response.statusCode}");
      print("📱 Add Donation Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Donation added successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Add donation failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to add donation");
      }
    } catch (e) {
      print("🔥 Error adding donation: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to add donation: $e");
    }
  }

  /// Toggle Event Status
  static Future<Map<String, dynamic>> toggleEventStatus(String id) async {
    try {
      print("🚀 Toggling event status...");
      print("🆔 Event ID: $id");

      // Get admin session for the toggle
      String? adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception("Admin not logged in");
      }

      print("🌐 URL: $eventsBaseUrl/admin/$adminId/event/$id/toggle");

      final response = await http.put(
        Uri.parse('$eventsBaseUrl/admin/$adminId/event/$id/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'adminId': adminId}),
      );

      print("📱 Toggle Event Status Response Status: ${response.statusCode}");
      print("📱 Toggle Event Status Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Event status toggled successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Toggle event status failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to toggle event status");
      }
    } catch (e) {
      print("🔥 Error toggling event status: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to toggle event status: $e");
    }
  }

  // ==================== ANNOUNCEMENTS API METHODS ====================

  /// Create a new announcement card
  static Future<Map<String, dynamic>> createAnnouncementCard({
    required String title,
    required String description,
    required String priority,
    required String adminId,
  }) async {
    try {
      print("\n🎯 Creating announcement card...");
      print("📝 Title: $title");
      print("⚡ Priority: $priority");
      print("👤 Admin ID: $adminId");

      // Try admin-specific endpoint first
      final adminUrl = Uri.parse("$announcementsBaseUrl/admin/$adminId");
      print("🌐 Primary URL: $adminUrl");

      final response = await http.post(
        adminUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'priority': priority,
          'adminId': adminId,
        }),
      );

      print("📡 Primary Response Status: ${response.statusCode}");
      print("📄 Primary Response Body: ${response.body}");

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body["success"] == true) {
          print("✅ Announcement created successfully via admin endpoint!");
          return {
            "success": true,
            "message": body["message"],
            "data": body["data"],
          };
        } else {
          print("❌ Admin endpoint returned success: false");
          throw Exception(body["message"] ?? "Failed to create announcement");
        }
      } else if (response.statusCode == 400) {
        // Handle validation errors (like duplicate titles) without fallback
        final body = jsonDecode(response.body);
        print("❌ Admin endpoint validation error: ${body["message"]}");
        throw Exception(body["message"] ?? "Validation error");
      } else {
        print("❌ Admin endpoint returned status: ${response.statusCode}");
        // Try fallback to legacy endpoint for server errors only
        throw Exception(
          "Admin endpoint failed with status: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("🔥 Primary endpoint error: $e");

      // FALLBACK: Try legacy endpoint
      try {
        print("🔄 Trying fallback to legacy endpoint...");
        final legacyUrl = Uri.parse(announcementsBaseUrl);
        print("🌐 Fallback URL: $legacyUrl");

        final fallbackResponse = await http.post(
          legacyUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'description': description,
            'priority': priority,
            'adminId': adminId,
          }),
        );

        print("📡 Fallback Response Status: ${fallbackResponse.statusCode}");
        print("📄 Fallback Response Body: ${fallbackResponse.body}");

        if (fallbackResponse.statusCode == 201) {
          final body = jsonDecode(fallbackResponse.body);
          if (body["success"] == true) {
            print("✅ Announcement created successfully via fallback endpoint!");
            return {
              "success": true,
              "message": body["message"],
              "data": body["data"],
            };
          } else {
            print("❌ Fallback returned success: false");
            throw Exception(body["message"] ?? "Failed to create announcement");
          }
        } else {
          print("❌ Fallback returned status: ${fallbackResponse.statusCode}");
          final body = jsonDecode(fallbackResponse.body);
          throw Exception(
            body["message"] ?? "Failed to create announcement via fallback",
          );
        }
      } catch (fallbackError) {
        print("🔥 Fallback also failed: $fallbackError");

        if (fallbackError.toString().contains('SocketException') ||
            fallbackError.toString().contains('Connection refused') ||
            fallbackError.toString().contains('Failed host lookup')) {
          throw Exception(
            "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
          );
        }
      }

      throw Exception("Failed to create announcement: $e");
    }
  }

  /// Get all announcement cards
  static Future<Map<String, dynamic>> getAllAnnouncementCards({
    bool? activeOnly,
    String? adminId,
    String? priority,
  }) async {
    try {
      print("\n📋 Fetching all announcements...");

      final queryParams = <String, String>{};
      if (activeOnly != null) queryParams['activeOnly'] = activeOnly.toString();
      if (adminId != null) queryParams['adminId'] = adminId;
      if (priority != null) queryParams['priority'] = priority;

      final uri = Uri.parse(
        announcementsBaseUrl,
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body length: ${response.body.length}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print(
          "✅ Announcements fetched successfully! Count: ${body["data"]?.length ?? 0}",
        );
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"] ?? [],
        };
      } else {
        print("❌ Fetch announcements failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch announcements");
      }
    } catch (e) {
      print("🔥 Error fetching announcements: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch announcements: $e");
    }
  }

  /// Get announcement cards by admin ID (admin-specific filtering)
  static Future<Map<String, dynamic>> getAnnouncementCardsByAdminId(
    String adminId,
  ) async {
    try {
      print("\n📋 Fetching announcements for admin ID: $adminId");
      print("🌐 Primary URL: $announcementsBaseUrl/admin/$adminId");

      // PRIMARY: Try the new admin-specific endpoint
      final url = Uri.parse("$announcementsBaseUrl/admin/$adminId");
      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "Connection": "close",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("📱 Primary Response Status: ${response.statusCode}");
      print("📄 Primary Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body["success"] == true) {
          print(
            "✅ Admin announcements fetched successfully from primary endpoint!",
          );
          final announcementCount = body["data"] is List
              ? body["data"].length
              : 0;
          print("📊 Primary endpoint announcements: $announcementCount");
          return {
            "success": true,
            "message": "Admin announcements fetched successfully",
            "data": body["data"],
          };
        } else {
          print("❌ Primary endpoint returned success: false");
          throw Exception(
            body["message"] ?? "Failed to fetch admin announcements",
          );
        }
      } else {
        print("❌ Primary endpoint returned status: ${response.statusCode}");
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Primary endpoint error: $e");

      // FALLBACK: Try legacy route with adminId query parameter
      print(
        "🔄 Trying fallback to legacy route with adminId query parameter...",
      );
      try {
        final fallbackUrl = Uri.parse("$announcementsBaseUrl?adminId=$adminId");
        print("🌐 Fallback URL: $fallbackUrl");

        final fallbackResponse = await http
            .get(
              fallbackUrl,
              headers: {
                "Content-Type": "application/json",
                "Connection": "close",
              },
            )
            .timeout(const Duration(seconds: 30));

        print("📱 Fallback Response Status: ${fallbackResponse.statusCode}");
        print("📄 Fallback Response Body: ${fallbackResponse.body}");

        if (fallbackResponse.statusCode == 200) {
          final body = jsonDecode(fallbackResponse.body);
          if (body["success"] == true) {
            final List<dynamic> allAnnouncements = body['data'] ?? [];
            print(
              "📊 Fallback total announcements received: ${allAnnouncements.length}",
            );

            // Additional client-side filtering for safety with object format handling
            final adminAnnouncements = allAnnouncements.where((
              announcementJson,
            ) {
              final announcementAdminId = announcementJson['adminId'];
              String? adminIdFromAnnouncement;

              // Handle both object and string formats
              if (announcementAdminId is Map<String, dynamic>) {
                // Backend returns: {_id: "68d664d7d84448fff5dc3a8b", email: "qwert123@gmail.com"}
                adminIdFromAnnouncement = announcementAdminId['_id']
                    ?.toString();
                print(
                  "🔍 Announcement adminId object format: $announcementAdminId -> extracted ID: $adminIdFromAnnouncement",
                );
              } else {
                // Backend returns simple string
                adminIdFromAnnouncement = announcementAdminId?.toString();
                print(
                  "🔍 Announcement adminId string format: $adminIdFromAnnouncement",
                );
              }

              final matches = adminIdFromAnnouncement == adminId;
              print(
                "🔍 Fallback filter - Announcement adminId: $adminIdFromAnnouncement, Target: $adminId, Match: $matches",
              );
              return matches;
            }).toList();

            print(
              "✅ Fallback filtering completed! Admin-specific announcements: ${adminAnnouncements.length}",
            );

            return {
              "success": true,
              "message": "Admin announcements fetched successfully (fallback)",
              "data": adminAnnouncements,
            };
          } else {
            print("❌ Fallback returned success: false - ${body["message"]}");
            throw Exception(body["message"] ?? "Fallback failed");
          }
        } else {
          throw Exception(
            "Fallback server error: ${fallbackResponse.statusCode}",
          );
        }
      } catch (fallbackError) {
        print("🔥 Fallback also failed: $fallbackError");
      }

      throw Exception("Failed to fetch admin-specific announcements: $e");
    }
  }

  /// Get announcement card by ID
  static Future<Map<String, dynamic>> getAnnouncementCardById(String id) async {
    try {
      print("\n🔍 Fetching announcement by ID: $id");

      final response = await http.get(
        Uri.parse('$announcementsBaseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Announcement fetched successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Fetch announcement failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch announcement");
      }
    } catch (e) {
      print("🔥 Error fetching announcement: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch announcement: $e");
    }
  }

  /// Update announcement card
  static Future<Map<String, dynamic>> updateAnnouncementCard({
    required String id,
    required String adminId,
    String? title,
    String? description,
    String? priority,
    bool? isActive,
  }) async {
    try {
      print("\n✏️ Updating announcement ID: $id");
      print("👤 Admin ID: $adminId");
      print("🌐 URL: $announcementsBaseUrl/admin/$adminId/announcement/$id");

      final updateData = <String, dynamic>{'adminId': adminId};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (priority != null) updateData['priority'] = priority;
      if (isActive != null) updateData['isActive'] = isActive;

      final response = await http.put(
        Uri.parse('$announcementsBaseUrl/admin/$adminId/announcement/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Announcement updated successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Update announcement failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to update announcement");
      }
    } catch (e) {
      print("🔥 Error updating announcement: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to update announcement: $e");
    }
  }

  /// Delete announcement card
  static Future<Map<String, dynamic>> deleteAnnouncementCard({
    required String id,
    required String adminId,
  }) async {
    try {
      print("\n🗑️ Deleting announcement ID: $id");

      final response = await http.delete(
        Uri.parse('$announcementsBaseUrl/admin/$adminId/announcement/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'adminId': adminId}),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Announcement deleted successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Delete announcement failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to delete announcement");
      }
    } catch (e) {
      print("🔥 Error deleting announcement: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to delete announcement: $e");
    }
  }

  /// Toggle announcement status (active/inactive)
  static Future<Map<String, dynamic>> toggleAnnouncementStatus({
    required String id,
    required String adminId,
  }) async {
    try {
      print("\n🔄 Toggling announcement status for ID: $id");

      final response = await http.put(
        Uri.parse(
          '$announcementsBaseUrl/admin/$adminId/announcement/$id/toggle',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'adminId': adminId}),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Announcement status toggled successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Toggle announcement status failed: ${body["message"]}");
        throw Exception(
          body["message"] ?? "Failed to toggle announcement status",
        );
      }
    } catch (e) {
      print("🔥 Error toggling announcement status: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to toggle announcement status: $e");
    }
  }

  /// Get announcements by priority (High/Medium/Low)
  static Future<Map<String, dynamic>> getAnnouncementsByPriority(
    String priority,
  ) async {
    try {
      print("\n🏷️ Fetching announcements by priority: $priority");

      final response = await http.get(
        Uri.parse('$announcementsBaseUrl/priority/$priority'),
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print(
          "✅ Announcements by priority fetched successfully! Count: ${body["data"]?.length ?? 0}",
        );
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"] ?? [],
        };
      } else {
        print("❌ Fetch announcements by priority failed: ${body["message"]}");
        throw Exception(
          body["message"] ?? "Failed to fetch announcements by priority",
        );
      }
    } catch (e) {
      print("🔥 Error fetching announcements by priority: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch announcements by priority: $e");
    }
  }

  // ===== COMPLAINTS API METHODS =====

  /// Dynamic base URL for complaints based on platform
  static String get complaintsBaseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8080/api/complaints";
    } else if (Platform.isIOS) {
      return "http://localhost:8080/api/complaints";
    } else {
      return "http://localhost:8080/api/complaints";
    }
  }

  /// Create a new complaint
  static Future<Map<String, dynamic>> createComplaint({
    required String userId,
    required String createdByadmin,
    required String title,
    required String description,
  }) async {
    try {
      print("\n📝 Creating new complaint...");
      print("👤 User ID: $userId");
      print("🔑 Admin ID: $createdByadmin");
      print("📋 Title: $title");

      final response = await http.post(
        Uri.parse('$complaintsBaseUrl/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": userId,
          "createdByadmin": createdByadmin,
          "title": title,
          "description": description,
        }),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 && body["success"] == true) {
        print("✅ Complaint created successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Create complaint failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to create complaint");
      }
    } catch (e) {
      print("🔥 Error creating complaint: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to create complaint: $e");
    }
  }

  /// Get all complaints for an admin
  static Future<Map<String, dynamic>> getAdminComplaints(
    String adminId, {
    String? status,
  }) async {
    try {
      print("\n📋 Fetching admin complaints...");
      print("🔑 Admin ID: $adminId");
      print("🔍 Status filter: $status");

      String url = '$complaintsBaseUrl/admin/$adminId';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print(
          "✅ Admin complaints fetched successfully! Count: ${body["data"]?.length ?? 0}",
        );
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"] ?? [],
          "count": body["count"] ?? 0,
        };
      } else {
        print("❌ Fetch admin complaints failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch admin complaints");
      }
    } catch (e) {
      print("🔥 Error fetching admin complaints: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch admin complaints: $e");
    }
  }

  /// Get complaint details with messages
  static Future<Map<String, dynamic>> getComplaintDetails(
    String complaintId,
  ) async {
    try {
      print("\n🔍 Fetching complaint details...");
      print("📝 Complaint ID: $complaintId");

      final response = await http.get(
        Uri.parse('$complaintsBaseUrl/$complaintId'),
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Complaint details fetched successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Fetch complaint details failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch complaint details");
      }
    } catch (e) {
      print("🔥 Error fetching complaint details: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch complaint details: $e");
    }
  }

  /// Update complaint status
  static Future<Map<String, dynamic>> updateComplaintStatus({
    required String complaintId,
    required String status,
    required String adminId,
  }) async {
    try {
      print("\n✏️ Updating complaint status...");
      print("📝 Complaint ID: $complaintId");
      print("📊 New Status: $status");
      print("🔑 Admin ID: $adminId");

      final response = await http.put(
        Uri.parse('$complaintsBaseUrl/status/$complaintId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"status": status, "adminId": adminId}),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Complaint status updated successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Update complaint status failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to update complaint status");
      }
    } catch (e) {
      print("🔥 Error updating complaint status: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to update complaint status: $e");
    }
  }

  /// Delete complaint
  static Future<Map<String, dynamic>> deleteComplaint(
    String complaintId,
  ) async {
    try {
      print("\n🗑️ Deleting complaint...");
      print("📝 Complaint ID: $complaintId");

      final response = await http.delete(
        Uri.parse('$complaintsBaseUrl/$complaintId'),
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Complaint deleted successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Delete complaint failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to delete complaint");
      }
    } catch (e) {
      print("🔥 Error deleting complaint: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to delete complaint: $e");
    }
  }

  // ===== MESSAGES API METHODS =====

  /// Dynamic base URL for messages based on platform
  static String get messagesBaseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8080/api/messages";
    } else if (Platform.isIOS) {
      return "http://localhost:8080/api/messages";
    } else {
      return "http://localhost:8080/api/messages";
    }
  }

  /// Send a message to a complaint
  static Future<Map<String, dynamic>> sendMessage({
    required String complaintId,
    required String senderId,
    required String message,
  }) async {
    try {
      print("\n💬 Sending message...");
      print("📝 Complaint ID: $complaintId");
      print("👤 Sender ID: $senderId");
      print(
        "💬 Message: ${message.substring(0, message.length > 50 ? 50 : message.length)}...",
      );

      final response = await http.post(
        Uri.parse('$messagesBaseUrl/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "complaintId": complaintId,
          "senderId": senderId,
          "message": message,
        }),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 && body["success"] == true) {
        print("✅ Message sent successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Send message failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to send message");
      }
    } catch (e) {
      print("🔥 Error sending message: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to send message: $e");
    }
  }

  /// Get messages for a complaint
  static Future<Map<String, dynamic>> getMessagesByComplaint(
    String complaintId,
  ) async {
    try {
      print("\n📨 Fetching messages for complaint: $complaintId");

      final response = await http.get(
        Uri.parse('$messagesBaseUrl/complaint/$complaintId'),
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print(
          "✅ Messages fetched successfully! Count: ${body["data"]?.length ?? 0}",
        );
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"] ?? [],
        };
      } else {
        print("❌ Fetch messages failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to fetch messages");
      }
    } catch (e) {
      print("🔥 Error fetching messages: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch messages: $e");
    }
  }

  /// Delete a message
  static Future<Map<String, dynamic>> deleteMessage({
    required String messageId,
    required String adminId,
    required bool deleteForEveryone,
  }) async {
    try {
      print("\n🗑️ Deleting message...");
      print("📝 Message ID: $messageId");
      print("👤 Admin ID: $adminId");
      print("🌍 Delete for everyone: $deleteForEveryone");

      final response = await http.delete(
        Uri.parse('$messagesBaseUrl/$messageId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "adminId": adminId,
          "deleteForEveryone": deleteForEveryone,
        }),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Message deleted successfully!");
        return {
          "success": true,
          "message": body["message"],
          "data": body["data"],
        };
      } else {
        print("❌ Delete message failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to delete message");
      }
    } catch (e) {
      print("🔥 Error deleting message: $e");
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to delete message: $e");
    }
  }

  // 🔹 Dynamic base URL based on platform
  static String get securitybaseUrl {
    if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2 to access host machine
      return "http://10.0.2.2:8080/api/security-guards";
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost or your machine's IP
      return "http://localhost:8080/api/security-guards";
    } else {
      // For web/desktop development
      return "http://localhost:8080/api/security-guards";
    }
  }

  /// Convert image file to base64 string
  static Future<String?> convertImageToBase64(File? imageFile) async {
    if (imageFile == null) return null;
    final bytes = await imageFile.readAsBytes();
    return "data:image/jpeg;base64,${base64Encode(bytes)}";
  }

  /// ✅ Create a new Security Guard
  static Future<Map<String, dynamic>> createSecurityGuard({
    required String adminId,
    required SecurityGuardModel guard,
    File? imageFile,
  }) async {
    try {
      String? base64Image = await convertImageToBase64(imageFile);

      final body = guard.toJson(adminId);
      if (base64Image != null) body['guardimage'] = base64Image;

      final response = await http.post(
        Uri.parse("$securitybaseUrl/admin/$adminId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  /// ✅ Fetch all Security Guards by adminId
  static Future<List<SecurityGuardModel>> getAllGuards(String adminId) async {
    try {
      final response = await http.get(
        Uri.parse("$securitybaseUrl/admin/$adminId"),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> list = jsonData['data'];
        return list.map((e) => SecurityGuardModel.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// ✅ Update an existing Security Guard
  static Future<Map<String, dynamic>> updateSecurityGuard({
    required String guardId,
    required SecurityGuardModel updatedGuard,
    File? imageFile,
  }) async {
    try {
      String? base64Image = await convertImageToBase64(imageFile);

      // Build body to match backend schema
      final body = {
        'firstname': updatedGuard.firstName,
        'lastname': updatedGuard.lastName,
        'mobilenumber': updatedGuard.mobile,
        'age': updatedGuard.age,
        'assigngates': updatedGuard.assignedGate,
        'gender': updatedGuard.gender,
        if (base64Image != null) 'guardimage': base64Image,
      };

      final response = await http.put(
        Uri.parse("$securitybaseUrl/admin/${updatedGuard.adminId}/$guardId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  /// ✅ Delete a Security Guard
  static Future<Map<String, dynamic>> deleteSecurityGuard(
    String adminId,
    String guardId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse("$securitybaseUrl/admin/$adminId/$guardId"),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }
}
