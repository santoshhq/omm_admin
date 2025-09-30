import 'package:flutter/material.dart';

import 'package:omm_admin/config/api_config.dart';

class ForgetPassOtpModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String _lastSentOtp = '';

  String get lastSentOtp => _lastSentOtp;

  /// Send OTP via API
  Future<bool> sendOtp(String email) async {
    try {
      final res = await ApiService.forgotPassword(email);
      _lastSentOtp = res["otp"] ?? ''; // ⚠️ only for debugging, remove in prod
      return true;
    } catch (e) {
      debugPrint("Send OTP error: $e");
      return false;
    }
  }

  /// Verify OTP locally (backend will also check during reset)
  Future<bool> verifyOtp(String enteredOtp) async {
    return enteredOtp == _lastSentOtp || enteredOtp.isNotEmpty;
  }

  /// Reset Password via API
  Future<bool> resetPassword(String email, String newPassword) async {
    final otp = otpControllers.map((c) => c.text.trim()).join();
    try {
      final res = await ApiService.resetPassword(email, newPassword, otp);
      return res["success"] == true;
    } catch (e) {
      debugPrint("Reset Password error: $e");
      return false;
    }
  }

  void clearOtpFields() {
    for (final c in otpControllers) {
      c.clear();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    for (final c in otpControllers) {
      c.dispose();
    }
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
