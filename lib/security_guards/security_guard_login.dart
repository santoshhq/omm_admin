import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:omm_admin/security_guards/visitorapprovalpage.dart';
import 'package:omm_admin/services/security_guard_auth_service.dart';
import 'package:omm_admin/security_guards/security_guard_profile.dart';
import 'package:omm_admin/config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'visitor_approval_page.dart';

class SecurityGuardLoginPage extends StatefulWidget {
  const SecurityGuardLoginPage({Key? key}) : super(key: key);

  @override
  State<SecurityGuardLoginPage> createState() => _SecurityGuardLoginPageState();
}

class _SecurityGuardLoginPageState extends State<SecurityGuardLoginPage> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSecurityLogin() async {
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    if (mobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter mobile number and password"),
        ),
      );
      return;
    }

    // Basic mobile number validation
    if (mobile.length != 10 || !RegExp(r'^\d{10}$').hasMatch(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 10-digit mobile number"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await SecurityGuardAuthService.login(
        mobile,
        password,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        print('✅ Login successful, showing snackbar');
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            duration: Duration(seconds: 2),
          ),
        );

        print('⏳ Waiting for SharedPreferences to save...');
        // Small delay to ensure SharedPreferences is saved
        await Future.delayed(const Duration(milliseconds: 1000));

        print('🚀 Starting navigation to VisitorApprovalPage...');
        // Navigate to visitor approval page
        if (mounted) {
          try {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  try {
                    print('🏗️ Creating VisitorApprovalPage...');
                    return const VisitorApprovalPage();
                  } catch (e) {
                    print('❌ Error creating VisitorApprovalPage: $e');
                    throw e;
                  }
                },
              ),
            );
            print('✅ Navigation pushReplacement completed successfully');
          } catch (e) {
            print('❌ Navigation failed with error: $e');
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Navigation failed: $e')));
            }
          }
        } else {
          print('❌ Widget not mounted, cannot navigate');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Login failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Security Guard Login',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Security Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF455A64).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  size: 80,
                  color: Color(0xFF455A64),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Security Login",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your mobile number & password",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Mobile Number field
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone),
                  hintText: "Mobile Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
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
              const SizedBox(height: 16),

              // Remember Me checkbox
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                    activeColor: const Color(0xFF455A64),
                  ),
                  const Text(
                    "Remember me for 30 days",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF455A64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _handleSecurityLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Login",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Back to Admin Login
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Back to Admin Login",
                  style: TextStyle(color: Color(0xFF455A64), fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
