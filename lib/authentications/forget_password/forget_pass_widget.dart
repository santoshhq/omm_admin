// forget_password_page.dart
import 'package:flutter/material.dart';
import 'package:omm_admin/authentications/forget_password/forgetpass_otp_widget.dart';
import 'package:omm_admin/config/api_config.dart';
// ✅ Use your ApiService

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  /// 🔹 Handle Send OTP Button
  Future<void> _handleSendOtp() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();

      // Show loading snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sending OTP...")));

      try {
        final res = await ApiService.forgotPassword(email);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "OTP sent successfully")),
        );

        // Navigate to OTP Verification Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgetPassOtpFlow(initialEmail: email),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to send OTP: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔹 Top image
            Image.asset(
              'assets/gifs/images/loginimage.png',
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            const Text(
              "Forget Password",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Don’t worry it happens. Please enter the address\nassociated with your account",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // 🔹 Email Form
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: "Email address",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter email address" : null,
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Send OTP Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF455A64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _handleSendOtp, // ✅ call API
                child: const Text(
                  "Send OTP",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
