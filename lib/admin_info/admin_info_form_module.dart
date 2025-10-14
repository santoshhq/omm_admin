import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_info_module.dart' as base;
import '../config/api_config.dart';

/// Mutable admin info model used by the form and admin page.
class AdminInfoModel extends ChangeNotifier {
  String firstName;
  String lastName;
  String email;
  String apartment;
  String phone;
  String address;
  String imagePath; // can be an asset path or file path

  AdminInfoModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.apartment,
    required this.phone,
    required this.address,
    required this.imagePath,
  });

  factory AdminInfoModel.fromBase() {
    final baseInfo = base.adminInfo;
    final names = baseInfo.name.split(' ');
    final first = names.isNotEmpty ? names.first : '';
    final last = names.length > 1 ? names.sublist(1).join(' ') : '';
    return AdminInfoModel(
      firstName: first,
      lastName: last,
      email: '',
      apartment: baseInfo.apartment,
      phone: baseInfo.phone,
      address: baseInfo.address,
      imagePath: '',
    );
  }

  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

  void update({
    String? firstName,
    String? lastName,
    String? email,
    String? apartment,
    String? phone,
    String? address,
    String? imagePath,
  }) {
    if (firstName != null) this.firstName = firstName;
    if (lastName != null) this.lastName = lastName;
    if (email != null) this.email = email;
    if (apartment != null) this.apartment = apartment;
    if (phone != null) this.phone = phone;
    if (address != null) this.address = address;
    if (imagePath != null) this.imagePath = imagePath;
    notifyListeners();
  }

  /// Reset all fields to empty/default values for new user signup
  Future<void> resetForNewUser() async {
    firstName = '';
    lastName = '';
    email = '';
    apartment = '';
    phone = '';
    address = '';
    imagePath = '';

    // Clear SharedPreferences data for new user
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('admin_image_path');
      await prefs.setBool('isProfileComplete', false);
      debugPrint("🧹 Cleared previous user data from SharedPreferences");
    } catch (e) {
      debugPrint("⚠️ Error clearing SharedPreferences: $e");
    }

    notifyListeners();
  }

  /// Check if admin profile is complete
  bool get isProfileComplete {
    return firstName.trim().isNotEmpty &&
        lastName.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        apartment.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        address.trim().isNotEmpty;
  }

  /// Save profile completion status to SharedPreferences
  Future<void> saveProfileCompletionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      debugPrint("💾 Saving profile completion status: $isProfileComplete");
      debugPrint(
        "💾 Profile data: firstName='$firstName', lastName='$lastName', email='$email', apartment='$apartment', phone='$phone', address='$address', imagePath='$imagePath'",
      );

      await prefs.setBool('isProfileComplete', isProfileComplete);
      if (isProfileComplete) {
        await prefs.setString('admin_firstName', firstName);
        await prefs.setString('admin_lastName', lastName);
        await prefs.setString('admin_email', email);
        await prefs.setString('admin_apartment', apartment);
        await prefs.setString('admin_phone', phone);
        await prefs.setString('admin_address', address);
        await prefs.setString('admin_image_path', imagePath);
        debugPrint("✅ Profile data saved successfully");
      } else {
        debugPrint("❌ Profile incomplete, not saving user data");
      }
    } catch (e) {
      debugPrint("Error saving profile completion status: $e");
    }
  }

  /// Load profile completion status from SharedPreferences
  static Future<bool> isProfileCompleteFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool('isProfileComplete') ?? false;
      debugPrint("🔍 Loading profile completion status: $isComplete");
      return isComplete;
    } catch (e) {
      debugPrint("Error loading profile completion status: $e");
      return false;
    }
  }

  /// Load saved profile data from SharedPreferences
  static Future<void> loadSavedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('isProfileComplete') ?? false) {
        adminInfoModel.update(
          firstName: prefs.getString('admin_firstName') ?? '',
          lastName: prefs.getString('admin_lastName') ?? '',
          email: prefs.getString('admin_email') ?? '',
          apartment: prefs.getString('admin_apartment') ?? '',
          phone: prefs.getString('admin_phone') ?? '',
          address: prefs.getString('admin_address') ?? '',
          imagePath: prefs.getString('admin_image_path') ?? '',
        );
      }
    } catch (e) {
      debugPrint("Error loading saved profile: $e");
    }
  }

  /// Auto-detect and load email from login session
  static Future<String> getLoggedInEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_email') ?? '';
    } catch (e) {
      debugPrint("Error getting logged in email: $e");
      return '';
    }
  }

  /// Clear profile completion status (for testing)
  static Future<void> clearProfileCompletionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isProfileComplete', false);
      debugPrint("🧹 Profile completion status cleared");
    } catch (e) {
      debugPrint("Error clearing profile completion status: $e");
    }
  }

  /// Get logged in user ID
  static Future<String> getLoggedInUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id') ?? '';
    } catch (e) {
      debugPrint("Error getting logged in user ID: $e");
      return '';
    }
  }

  /// Save admin profile to backend
  Future<Map<String, dynamic>> saveToBackend() async {
    try {
      final userId = await getLoggedInUserId();
      if (userId.isEmpty) {
        throw Exception("User ID not found. Please login again.");
      }

      final result = await ApiService.createAdminProfile(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        apartment: apartment,
        phone: phone,
        address: address,
        imagePath: imagePath.isNotEmpty ? imagePath : null,
      );

      if (result["success"] == true) {
        // Save the profile ID from backend response
        final prefs = await SharedPreferences.getInstance();
        if (result["data"] != null && result["data"]["_id"] != null) {
          await prefs.setString('admin_profile_id', result["data"]["_id"]);
        }

        // Also save profile completion status locally
        await saveProfileCompletionStatus();

        return result;
      } else {
        throw Exception(
          result["message"] ?? "Failed to save profile to backend",
        );
      }
    } catch (e) {
      debugPrint("Error saving profile to backend: $e");
      rethrow;
    }
  }

  /// Load admin profile from backend
  static Future<void> loadFromBackend() async {
    try {
      final userId = await getLoggedInUserId();
      debugPrint("🔍 AdminInfoModel.loadFromBackend: userId = '$userId'");

      if (userId.isEmpty) {
        debugPrint("❌ User ID not found, cannot load profile from backend");
        return;
      }

      debugPrint("🔄 Making API call to get admin profile for userId: $userId");
      final result = await ApiService.getAdminProfileByUserId(userId);
      debugPrint("🔍 API Response: $result");

      if (result["success"] == true && result["data"] != null) {
        final profileData = result["data"];
        debugPrint("🔍 Profile data received: $profileData");

        adminInfoModel.update(
          firstName: profileData["firstName"] ?? '',
          lastName: profileData["lastName"] ?? '',
          email: profileData["email"] ?? '',
          apartment: profileData["apartment"] ?? '',
          phone: profileData["phone"] ?? '',
          address: profileData["address"] ?? '',
          imagePath: profileData["imagePath"] ?? '',
        );

        debugPrint("🔍 Updated adminInfoModel with data:");
        debugPrint("  - firstName: ${adminInfoModel.firstName}");
        debugPrint("  - lastName: ${adminInfoModel.lastName}");
        debugPrint("  - email: ${adminInfoModel.email}");
        debugPrint("  - phone: ${adminInfoModel.phone}");
        debugPrint("  - apartment: ${adminInfoModel.apartment}");

        // Save profile ID for future updates - since your backend returns userId, we need to get the actual profile ID
        final prefs = await SharedPreferences.getInstance();
        // Note: Your getUserProfileDetails doesn't return the profile _id, only userId
        // We may need to store this differently or modify the backend to return profile _id
        if (profileData["userId"] != null) {
          await prefs.setString('profile_user_id', profileData["userId"]);
        }

        // Mark profile as complete
        await prefs.setBool('isProfileComplete', true);

        debugPrint("✅ Profile loaded from backend successfully");
      } else {
        debugPrint(
          "❌ Failed to load profile: result not successful or no data",
        );
        debugPrint("   result[\"success\"]: ${result["success"]}");
        debugPrint("   result[\"data\"]: ${result["data"]}");
        debugPrint("   result[\"message\"]: ${result["message"]}");

        // If profile not found in backend, but user should have one, try fallback
        throw Exception(result["message"] ?? "Profile not found in backend");
      }
    } catch (e) {
      debugPrint("❌ Error loading profile from backend: $e");
      debugPrint("🔄 Attempting fallback to local storage...");
      // Fallback to local storage
      await loadSavedProfile();
      debugPrint("🔍 After fallback - adminInfoModel data:");
      debugPrint("  - firstName: ${adminInfoModel.firstName}");
      debugPrint("  - lastName: ${adminInfoModel.lastName}");
      debugPrint("  - email: ${adminInfoModel.email}");
    }
  }

  /// Get profile ID by looking up the profile using userId
  static Future<String?> getProfileIdByUserId() async {
    try {
      final userId = await getLoggedInUserId();
      if (userId.isEmpty) {
        debugPrint("❌ User ID not found");
        return null;
      }

      // Use the get all profiles API and find the one with matching userId
      debugPrint("🔄 Calling getAllAdminProfiles to find profile...");
      final result = await ApiService.getAllAdminProfiles();
      debugPrint("🔍 getAllAdminProfiles result: $result");

      if (result["success"] == true && result["data"] != null) {
        final profiles = result["data"] as List;
        debugPrint(
          "🔍 Found ${profiles.length} profiles, searching for userId: $userId",
        );

        for (var profile in profiles) {
          debugPrint(
            "🔍 Checking profile: userId=${profile["userId"]}, _id=${profile["_id"]}",
          );
          if (profile["userId"] == userId) {
            debugPrint("✅ Found matching profile ID: ${profile["_id"]}");
            // Save it for future use
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('admin_profile_id', profile["_id"]);
            return profile["_id"];
          }
        }
      }
      debugPrint("❌ Profile not found for userId: $userId");
      return null;
    } catch (e) {
      debugPrint("❌ Error getting profile ID: $e");
      return null;
    }
  }

  /// Update existing admin profile in backend
  Future<Map<String, dynamic>> updateInBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? profileId = prefs.getString('admin_profile_id');

      // Debug: Check all stored values
      debugPrint("🔍 Debug SharedPreferences:");
      debugPrint("  - admin_profile_id: $profileId");
      debugPrint("  - user_id: ${prefs.getString('user_id')}");
      debugPrint("  - user_email: ${prefs.getString('user_email')}");
      debugPrint(
        "  - isProfileComplete: ${prefs.getBool('isProfileComplete')}",
      );

      if (profileId == null || profileId.isEmpty) {
        debugPrint(
          "❌ Profile ID not found in SharedPreferences, looking up by userId",
        );
        profileId = await getProfileIdByUserId();
        if (profileId == null || profileId.isEmpty) {
          throw Exception(
            "Profile ID not found. Cannot update profile. Please create profile first.",
          );
        }
      }

      debugPrint("🔄 Calling updateAdminProfile with profileId: $profileId");
      final result = await ApiService.updateAdminProfile(
        profileId: profileId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        apartment: apartment,
        phone: phone,
        address: address,
        imagePath: imagePath.isNotEmpty ? imagePath : null,
      );

      debugPrint("🔍 Update API result: $result");
      debugPrint("🔍 Result success value: ${result["success"]}");
      debugPrint("🔍 Result success type: ${result["success"].runtimeType}");

      if (result["success"] == true) {
        // Also save profile completion status locally
        await saveProfileCompletionStatus();
        debugPrint("✅ Update successful, returning result");
        return result;
      } else {
        debugPrint("❌ Update failed, result success was: ${result["success"]}");
        throw Exception(
          result["message"] ?? "Failed to update profile in backend",
        );
      }
    } catch (e) {
      debugPrint("Error updating profile in backend: $e");
      rethrow;
    }
  }

  /// Get stored profile ID
  static Future<String?> getStoredProfileId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('admin_profile_id');
    } catch (e) {
      debugPrint("Error getting stored profile ID: $e");
      return null;
    }
  }
}

/// Global model instance used across admin pages. Simple and pragmatic.
final AdminInfoModel adminInfoModel = AdminInfoModel.fromBase();
