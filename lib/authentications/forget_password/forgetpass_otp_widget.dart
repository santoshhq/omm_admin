import 'package:flutter/material.dart';
import 'forgetpass_otp_module.dart';

enum _ForgetStep { enterEmail, verifyOtp, setNewPassword }

class ForgetPassOtpFlow extends StatefulWidget {
  final String? initialEmail;
  final bool startAtVerify;

  const ForgetPassOtpFlow({
    super.key,
    this.initialEmail,
    this.startAtVerify = false,
  });

  @override
  State<ForgetPassOtpFlow> createState() => _ForgetPassOtpFlowState();
}

class _ForgetPassOtpFlowState extends State<ForgetPassOtpFlow> {
  final ForgetPassOtpModel _model = ForgetPassOtpModel();
  _ForgetStep _step = _ForgetStep.enterEmail;
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }

    // If caller wants to start at verify, send OTP automatically and switch step
    if (widget.startAtVerify && _emailController.text.isNotEmpty) {
      // copy into model and send OTP
      _model.emailController.text = _emailController.text.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        setState(() => _loading = true);
        await _model.sendOtp(_model.emailController.text.trim());
        setState(() {
          _loading = false;
          _step = _ForgetStep.verifyOtp;
        });
      });
    }
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

  Widget _buildTopImage() {
    return Image.asset(
      'assets/gifs/images/loginimage.png',
      height: 160,
      fit: BoxFit.contain,
    );
  }

  Future<void> _onSendOtp() async {
    // Validate form first
    if (_formKey.currentState?.validate() != true) {
      _showSnack('Please enter a valid email');
      return;
    }

    // Read the email from the form controller and copy it to the model
    final email = _emailController.text.trim();
    _model.emailController.text = email;

    setState(() => _loading = true);
    final ok = await _model.sendOtp(email);
    setState(() => _loading = false);
    if (ok) {
      setState(() => _step = _ForgetStep.verifyOtp);
      _showSnack('OTP sent to $email', Colors.green);
    } else {
      _showSnack('Failed to send OTP');
    }
  }

  Future<void> _onVerifyOtp() async {
    final entered = _model.otpControllers.map((c) => c.text.trim()).join();
    if (entered.length != 4) {
      _showSnack('Enter the 4 digit code');
      return;
    }
    setState(() => _loading = true);
    final ok = await _model.verifyOtp(entered);
    setState(() => _loading = false);
    if (ok) {
      setState(() => _step = _ForgetStep.setNewPassword);
      _showSnack('OTP verified', Colors.green);
    } else {
      _showSnack('Invalid OTP', Colors.red);
      _model.clearOtpFields();
    }
  }

  Future<void> _onConfirmPassword() async {
    final newp = _model.newPasswordController.text.trim();
    final conf = _model.confirmPasswordController.text.trim();
    if (newp.length < 6) {
      _showSnack('Password should be at least 6 characters');
      return;
    }
    if (newp != conf) {
      _showSnack('Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    final ok = await _model.resetPassword(
      _model.emailController.text.trim(),
      newp,
    );
    setState(() => _loading = false);
    if (ok) {
      _showSnack('Password reset successful', Colors.green);
      Navigator.of(context).pop();
    } else {
      _showSnack('Failed to reset password');
    }
  }

  Widget _buildEmailStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🔹 Replace this with your own image
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

        // 🔹 Form
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
            validator: (value) => value!.isEmpty ? "Enter email address" : null,
          ),
        ),
        const SizedBox(height: 20),

        // 🔹 Send OTP Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF455A64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _loading ? null : _onSendOtp,
            child: const Text(
              "Send OTP",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
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
          if (v.isNotEmpty && idx < 3) {
            FocusScope.of(context).nextFocus();
          }
          if (v.isEmpty && idx > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopImage(),
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
              backgroundColor: const Color(0xFF455A64), // ✅ same as Send OTP
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 18, // ✅ match Send OTP font size
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
                  // Resend OTP
                  setState(() => _loading = true);
                  await _model.sendOtp(_model.emailController.text.trim());
                  setState(() => _loading = false);
                  _showSnack('OTP resent', Colors.green);
                },
          child: const Text('Resend OTP'),
        ),
      ],
    );
  }

  Widget _buildSetPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopImage(),
        const SizedBox(height: 12),
        const Text(
          'Set New Password',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your new password below',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _model.newPasswordController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            hintText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _model.confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            hintText: 'Re-enter password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _onConfirmPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF455A64), // ✅ same as Send OTP
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 18, // ✅ consistent text style
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_step) {
      case _ForgetStep.enterEmail:
        content = _buildEmailStep();
        break;
      case _ForgetStep.verifyOtp:
        content = _buildVerifyStep();
        break;
      case _ForgetStep.setNewPassword:
        content = _buildSetPasswordStep();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [content],
          ),
        ),
      ),
    );
  }
}
