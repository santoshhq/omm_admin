import 'package:flutter/material.dart';
import 'package:omm_admin/authentications/forget_password/forgetpass_otp_module.dart';
import 'package:omm_admin/admin_info/admin_info_form_widget.dart';
import 'package:omm_admin/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A small reusable OTP verification screen for the signup flow.
///
/// Usage:
/// Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyOtpForSignup(email: 'a@b.com', onVerified: () { /* continue */ }));
class VerifyOtpForSignup extends StatefulWidget {
  final String email;
  final String? userId;
  final VoidCallback? onVerified;

  const VerifyOtpForSignup({
    super.key,
    required this.email,
    this.userId,
    this.onVerified,
  });

  @override
  State<VerifyOtpForSignup> createState() => _VerifyOtpForSignupState();
}

class _VerifyOtpForSignupState extends State<VerifyOtpForSignup> {
  final ForgetPassOtpModel _model = ForgetPassOtpModel();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _model.emailController.text = widget.email.trim();
    // Auto-send OTP for the provided email
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _loading = true);
      await _model.sendOtp(_model.emailController.text.trim());
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OTP sent')));
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _showSnack(String msg, [Color? color]) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Widget _otpBox(int idx) {
    return SizedBox(
      width: 56,
      child: TextField(
        controller: _model.otpControllers[idx],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: '',
          border: OutlineInputBorder(),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && idx < 3) FocusScope.of(context).nextFocus();
          if (v.isEmpty && idx > 0) FocusScope.of(context).previousFocus();
        },
      ),
    );
  }

  // Make sure your ApiService has verifyOtp for signup

  Future<void> _onVerifyOtp() async {
    final entered = _model.otpControllers.map((c) => c.text.trim()).join();

    if (entered.length != 4) {
      _showSnack('Enter the 4 digit code');
      return;
    }

    // Use the entered OTP directly (4-digit)
    String otpToVerify = entered;

    setState(() => _loading = true);

    // ✅ Use widget.email, not widget.initialEmail
    final ok = await ApiService.verifyOtp(widget.email, otpToVerify);

    setState(() => _loading = false);

    if (ok) {
      _showSnack('OTP verified', Colors.green);

      // ✅ Save login state, user email, and user ID after signup OTP verification
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user_email', widget.email);
        if (widget.userId != null && widget.userId!.isNotEmpty) {
          await prefs.setString('user_id', widget.userId!);
        }
      } catch (e) {
        debugPrint("SharedPreferences error in OTP verification: $e");
        // Continue navigation even if saving fails
      }

      // ✅ Navigate to main app page (AdminInfoFormPage or BottumNavigation)
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminInfoFormPage()),
      );
    } else {
      _showSnack('Invalid OTP', Colors.red);
      _model.clearOtpFields();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/gifs/images/loginimage.png',
                height: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                'Verify OTP',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'OTP sent to ${_model.emailController.text}',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              // Developer helper: show the generated OTP for easier testing
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) => _otpBox(i)),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF455A64,
                    ), // ✅ match other buttons
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify & Continue',
                          style: TextStyle(
                            fontSize: 18, // ✅ consistent style
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        await _model.sendOtp(
                          _model.emailController.text.trim(),
                        );
                        setState(() => _loading = false);
                        _showSnack('OTP resent', Colors.green);
                      },
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
