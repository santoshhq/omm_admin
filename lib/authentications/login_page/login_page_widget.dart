import 'package:flutter/material.dart';

import 'package:omm_admin/authentications/forget_password/forgetpass_otp_widget.dart';
import 'package:omm_admin/authentications/login_page/login_page_module.dart';
import 'package:omm_admin/authentications/singup_page/signup_widget.dart';
import 'package:omm_admin/bottum_navigation.dart';
import 'package:omm_admin/admin_info/admin_info_form_widget.dart';
import 'package:omm_admin/admin_info/admin_info_form_module.dart';
import 'package:omm_admin/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omm_admin/services/admin_session_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginModel _model = LoginModel();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _model.usernameController.text.trim();
    final password = _model.passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter email & password")));
      return;
    }

    try {
      final res = await ApiService.login(email, password);

      if (res["success"] == true) {
        // ✅ Save admin session using AdminSessionService
        bool isProfileComplete = false;
        try {
          // Save traditional session data for backward compatibility
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          if (res["user"] != null) {
            final userEmail = res["user"]["email"];
            final userId = res["user"]["id"];

            if (userEmail != null) {
              await prefs.setString('user_email', userEmail);
            }
            if (userId != null) {
              await prefs.setString('user_id', userId);

              // ✅ Save admin session using AdminSessionService
              await AdminSessionService.saveAdminSession(
                adminId: userId,
                adminEmail: userEmail ?? email,
              );
            }

            // ✅ Save backend isProfile status
            if (res["user"]["isProfile"] != null) {
              isProfileComplete = res["user"]["isProfile"];
              await prefs.setBool('isProfileComplete', isProfileComplete);
            }
          }
        } catch (e) {
          debugPrint("SharedPreferences error in login: $e");
          // Continue navigation even if saving fails
        }

        debugPrint(
          "🔍 Login - Backend profile complete status: $isProfileComplete",
        );

        if (!mounted) return;

        if (isProfileComplete) {
          // Profile complete - load from backend and navigate to main app
          debugPrint(
            "✅ Profile complete - loading from backend and navigating to main app",
          );
          await AdminInfoModel.loadFromBackend();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BottumNavigation()),
          );
        } else {
          // Profile not complete - navigate to admin info form
          debugPrint("📝 Profile incomplete - navigating to admin form");
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminInfoFormPage()),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Login failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 🔹 Your uploaded image on top
              Image.asset(
                'assets/gifs/images/loginimage.png',
                height: 200,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 24),

              const Text(
                "Sign In",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter valid email & password to continue",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              /// Username field
              TextField(
                controller: _model.usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// Password field
              TextField(
                controller: _model.passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "Password",
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgetPassOtpFlow(),
                      ),
                    );
                  },
                  child: const Text("Forget password"),
                ),
              ),
              const SizedBox(height: 12),

              /// Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF455A64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _handleLogin,
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// Social login button (Google only)
              const Text("Or Continue with"),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.g_mobiledata,
                    color: Color(0xFF455A64),
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 16, color: Color(0xFF455A64)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// Signup text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Haven’t any account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (Previously had a helper for multiple social buttons; now using a single Google button inline.)
}
