// api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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
      print("� Capacity: $capacity");
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
      print("💰 Updated Hourly Rate: ${hourlyRate ?? 'No change'}");
      print("🌐 Base URL: $amenitiesBaseUrl");

      // Create update data map, only include non-null values
      Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (capacity != null) updateData['capacity'] = capacity;
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
      List<String>? images;
      if (image != null && image.isNotEmpty) {
        images = [image];
        print("✅ Converted single image to array format");
      }

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "images": images, // Changed from "image" to "images" to match backend
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
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to create event card: $e");
    }
  }

  /// Get All Event Cards
  static Future<Map<String, dynamic>> getAllEventCards() async {
    try {
      print("🚀 Fetching all event cards...");
      print("🌐 URL: $eventsBaseUrl");

      final url = Uri.parse(eventsBaseUrl);
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Get All Events Response Status: ${response.statusCode}");
      print("📱 Get All Events Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Event cards fetched successfully!");
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
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to fetch event cards: $e");
    }
  }

  /// Get Event Card by ID
  static Future<Map<String, dynamic>> getEventCardById(String id) async {
    try {
      print("🚀 Fetching event card by ID...");
      print("🆔 Event ID: $id");
      print("🌐 URL: $eventsBaseUrl/$id");

      final url = Uri.parse("$eventsBaseUrl/$id");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Get Event Response Status: ${response.statusCode}");
      print("📱 Get Event Response Body: ${response.body}");

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
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
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
      print("🌐 URL: $eventsBaseUrl/$id");

      final Map<String, dynamic> updateData = {"adminId": adminId};

      if (image != null) updateData["image"] = image;
      if (name != null) updateData["name"] = name;
      if (startdate != null) updateData["startdate"] = startdate;
      if (enddate != null) updateData["enddate"] = enddate;
      if (description != null) updateData["description"] = description;
      if (targetamount != null) updateData["targetamount"] = targetamount;
      if (eventdetails != null) updateData["eventdetails"] = eventdetails;
      if (status != null) updateData["status"] = status;

      final url = Uri.parse("$eventsBaseUrl/$id");
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
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
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          "❌ Cannot connect to server. Please ensure your backend server is running on http://localhost:8080",
        );
      }
      throw Exception("Failed to update event card: $e");
    }
  }

  /// Delete Event Card
  static Future<Map<String, dynamic>> deleteEventCard(String id) async {
    try {
      print("🚀 Deleting event card...");
      print("🆔 Event ID: $id");
      print("🌐 URL: $eventsBaseUrl/$id");

      final url = Uri.parse("$eventsBaseUrl/$id");
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
      print("🌐 URL: $eventsBaseUrl/$id/toggle");

      final url = Uri.parse("$eventsBaseUrl/$id/toggle");
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Toggle Event Status Response Status: ${response.statusCode}");
      print("📱 Toggle Event Status Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Event status toggled successfully!");
        return {
          "success": true,
          "message": body["message"],
          "status": body["status"],
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
}
