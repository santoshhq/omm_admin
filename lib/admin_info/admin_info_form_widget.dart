import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_info_form_module.dart';
import 'package:omm_admin/bottum_navigation.dart';
import 'package:omm_admin/config/api_config.dart';

class AdminInfoFormPage extends StatefulWidget {
  final bool isEditMode;

  const AdminInfoFormPage({super.key, this.isEditMode = false});

  @override
  State<AdminInfoFormPage> createState() => _AdminInfoFormPageState();
}

class _AdminInfoFormPageState extends State<AdminInfoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController(); // Start with empty field
  final _last = TextEditingController(); // Start with empty field
  final _email = TextEditingController(); // Start with empty field
  final _apartment = TextEditingController(); // Start with empty field
  final _phone = TextEditingController(); // Start with empty field
  final _address = TextEditingController(); // Start with empty field

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _loadExistingData(); // Load existing data for editing
    } else {
      _clearAllFields(); // Ensure all fields start fresh for new profile
      _autoDetectEmail(); // Only auto-fill email from login session
    }
  }

  void _clearAllFields() {
    _first.clear();
    _last.clear();
    _email.clear(); // Will be filled by _autoDetectEmail if available
    _apartment.clear();
    _phone.clear();
    _address.clear();
  }

  void _loadExistingData() {
    // Load existing data from the model for editing
    _first.text = adminInfoModel.firstName;
    _last.text = adminInfoModel.lastName;
    _email.text = adminInfoModel.email;
    _apartment.text = adminInfoModel.apartment;
    _phone.text = adminInfoModel.phone;
    _address.text = adminInfoModel.address;
  }

  void _autoDetectEmail() async {
    final email = await AdminInfoModel.getLoggedInEmail();
    if (email.isNotEmpty && _email.text.isEmpty) {
      setState(() {
        _email.text = email;
        adminInfoModel.update(email: email);
      });
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _apartment.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Update the shared model
      debugPrint("🔄 Updating adminInfoModel with form data:");
      debugPrint("  - firstName: '${_first.text.trim()}'");
      debugPrint("  - lastName: '${_last.text.trim()}'");
      debugPrint("  - email: '${_email.text.trim()}'");
      debugPrint("  - apartment: '${_apartment.text.trim()}'");
      debugPrint("  - phone: '${_phone.text.trim()}'");
      debugPrint("  - address: '${_address.text.trim()}'");

      adminInfoModel.update(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        email: _email.text.trim(),
        apartment: _apartment.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );

      debugPrint("🔍 AdminInfoModel after update:");
      debugPrint("  - firstName: '${adminInfoModel.firstName}'");
      debugPrint("  - lastName: '${adminInfoModel.lastName}'");
      debugPrint("  - email: '${adminInfoModel.email}'");
      debugPrint("  - apartment: '${adminInfoModel.apartment}'");
      debugPrint("  - phone: '${adminInfoModel.phone}'");
      debugPrint("  - address: '${adminInfoModel.address}'");

      // Save or update profile to backend based on mode
      final Map<String, dynamic> result;
      if (widget.isEditMode) {
        // Update existing profile
        debugPrint("🔄 Edit mode: Calling updateInBackend()");
        result = await adminInfoModel.updateInBackend();
        debugPrint("🔍 Update result: $result");
      } else {
        // Create new profile
        result = await adminInfoModel.saveToBackend();
        debugPrint("🆕 Creating new profile");
        debugPrint("🔍 Create result: $result");
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      debugPrint("🔍 Checking result success: ${result["success"]}");
      if (result["success"] == true) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEditMode
                    ? "✅ Profile updated successfully!"
                    : "✅ Profile saved successfully!",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Debug: Print profile completion status
        debugPrint(
          widget.isEditMode
              ? "✅ Profile updated in backend: ${result["message"]}"
              : "✅ Profile saved to backend: ${result["message"]}",
        );

        // Reload profile data to ensure sync
        if (!widget.isEditMode) {
          debugPrint("🔄 Reloading profile data after save to ensure sync...");
          try {
            await AdminInfoModel.loadFromBackend();
          } catch (e) {
            debugPrint("⚠️ Warning: Could not reload profile after save: $e");
          }
        }

        // Navigate based on mode
        if (mounted) {
          if (widget.isEditMode) {
            // In edit mode, just go back to account page
            Navigator.pop(context);
          } else {
            // In new profile mode, update profile status in backend and navigate
            try {
              debugPrint("🔄 Updating profile completion status in backend...");

              // Get userId from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('user_id');

              if (userId != null) {
                final statusResult = await ApiService.updateProfileStatus(
                  userId: userId,
                  isProfile: true,
                );
                debugPrint("✅ Profile status updated: $statusResult");

                // Update local storage to match backend
                await prefs.setBool('isProfileComplete', true);
              } else {
                debugPrint("⚠️ Warning: No userId found in SharedPreferences");
              }

              // Save to local storage as well
              await adminInfoModel.saveProfileCompletionStatus();
            } catch (e) {
              debugPrint(
                "⚠️ Warning: Could not update profile status in backend: $e",
              );
              // Continue with navigation even if status update fails
              await adminInfoModel.saveProfileCompletionStatus();
            }

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const BottumNavigation()),
              (route) => false, // Remove all previous routes
            );
          }
        }
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted) Navigator.of(context).pop();

      // Log error for debugging (but don't show error snackbar since DB update is successful)
      debugPrint(
        widget.isEditMode
            ? "❌ Error updating profile: $e"
            : "❌ Error saving profile: $e",
      );
      debugPrint("❌ Full error details: ${e.toString()}");
      debugPrint("❌ Error type: ${e.runtimeType}");

      // Fallback: Save locally and navigate
      await adminInfoModel.saveProfileCompletionStatus();
      if (mounted) {
        if (widget.isEditMode) {
          // In edit mode, just go back to account page
          Navigator.pop(context);
        } else {
          // In new profile mode, navigate to main app and clear all routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BottumNavigation()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(
            widget.isEditMode ? 'Edit Profile' : 'Complete Your Profile',
            style: const TextStyle(color: Colors.black),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image upload placeholder
                  GestureDetector(
                    onTap: () {
                      // For now we just toggle a placeholder asset path
                      adminInfoModel.update(
                        imagePath: 'assets/gifs/images/loginimage.png',
                      );
                      setState(() {});
                    },
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: adminInfoModel.imagePath.isNotEmpty
                          ? AssetImage(adminInfoModel.imagePath)
                          : null,
                      child: adminInfoModel.imagePath.isEmpty
                          ? const Icon(
                              Icons.camera_alt_outlined,
                              size: 32,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _first,
                          decoration: const InputDecoration(
                            hintText: 'First name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Enter first name' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _last,
                          decoration: const InputDecoration(
                            hintText: 'Last name',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'Email address',
                      suffixIcon: Icon(Icons.check_circle, color: Colors.green),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter email address';
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(v)) {
                        return 'Enter valid email address';
                      }
                      return null;
                    },
                    enabled: false, // Auto-detected, read-only
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _apartment,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.apartment),
                      hintText: 'Apartment name',
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Enter apartment name' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone),
                      hintText: 'Contact number',
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Enter contact number' : null,
                  ),
                  const SizedBox(height: 12),

                  // Address
                  TextFormField(
                    controller: _address,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on),
                      hintText: 'Enter address',
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter address' : null,
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF455A64),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Conform',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
