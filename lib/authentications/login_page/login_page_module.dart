import 'package:flutter/material.dart';

class LoginModel extends ChangeNotifier {
  // Controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Example login logic (you can replace with Firebase or API)
  Future<bool> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    // Dummy check
    if (username == "admin" && password == "1234") {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
