import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
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

  bool _isLoading = false; // Loading state for submit button

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _loadExistingData(); // Load existing data for editing
    } else {
      _initializeForNewUser(); // Clear any previous user data and setup for new user
    }
  }

  Future<void> _initializeForNewUser() async {
    await adminInfoModel.resetForNewUser(); // Clear any previous user data
    _clearAllFields(); // Ensure all fields start fresh for new profile
    _autoDetectEmail(); // Only auto-fill email from login session
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

    setState(() => _isLoading = true);

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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      // Compress and encode the image
                      final String? compressedImage =
                          await _compressAndEncodeImage(image.path);
                      if (compressedImage != null) {
                        adminInfoModel.update(imagePath: compressedImage);
                        await _saveImagePath(compressedImage);
                        setState(() {});
                      } else {
                        // Fallback to original path if compression fails
                        adminInfoModel.update(imagePath: image.path);
                        await _saveImagePath(image.path);
                        setState(() {});
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to capture image'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      // Compress and encode the image
                      final String? compressedImage =
                          await _compressAndEncodeImage(image.path);
                      if (compressedImage != null) {
                        adminInfoModel.update(imagePath: compressedImage);
                        await _saveImagePath(compressedImage);
                        setState(() {});
                      } else {
                        // Fallback to original path if compression fails
                        adminInfoModel.update(imagePath: image.path);
                        await _saveImagePath(image.path);
                        setState(() {});
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to select image'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveImagePath(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_image_path', imagePath);
      debugPrint("💾 Admin image path saved: $imagePath");
    } catch (e) {
      debugPrint("❌ Error saving image path: $e");
    }
  }

  Future<String?> _compressAndEncodeImage(String imagePath) async {
    try {
      // Read the image file
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();

      // Decode the image
      img.Image? originalImage = img.decodeImage(
        Uint8List.fromList(imageBytes),
      );
      if (originalImage == null) {
        debugPrint("❌ Failed to decode image");
        return null;
      }

      // Resize if too large (max 512x512 for better compression)
      int maxSize = 512;
      if (originalImage.width > maxSize || originalImage.height > maxSize) {
        originalImage = img.copyResize(
          originalImage,
          width: originalImage.width > originalImage.height
              ? maxSize
              : (originalImage.width * maxSize ~/ originalImage.height),
          height: originalImage.height > originalImage.width
              ? maxSize
              : (originalImage.height * maxSize ~/ originalImage.width),
        );
      }

      // Compress with JPEG quality 70%
      final List<int> compressedBytes = img.encodeJpg(
        originalImage,
        quality: 70,
      );

      // Convert to base64
      final String base64Image = base64Encode(compressedBytes);
      final String dataUrl = 'data:image/jpeg;base64,$base64Image';

      debugPrint(
        "🖼️ Image compressed from ${imageBytes.length} to ${compressedBytes.length} bytes",
      );
      return dataUrl;
    } catch (e) {
      debugPrint("❌ Error compressing image: $e");
      return null;
    }
  }

  ImageProvider? _getImageProvider() {
    if (adminInfoModel.imagePath.isEmpty) return null;

    if (adminInfoModel.imagePath.startsWith('data:image/')) {
      // Handle base64 images
      try {
        final String base64String = adminInfoModel.imagePath.split(',')[1];
        final Uint8List bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint("❌ Error decoding base64 image: $e");
        return null;
      }
    } else if (adminInfoModel.imagePath.startsWith('assets/')) {
      return AssetImage(adminInfoModel.imagePath);
    } else {
      // Handle file paths
      return FileImage(File(adminInfoModel.imagePath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
          title: Text(
            widget.isEditMode ? 'Edit Profile' : 'Complete Your Profile',
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          widget.isEditMode
                              ? 'Update Your Information'
                              : 'Let\'s Get You Set Up',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isEditMode
                              ? 'Make changes to your profile details'
                              : 'Please fill in your details to continue',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF718096),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Profile Image Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white,
                                  backgroundImage: _getImageProvider(),
                                  child: adminInfoModel.imagePath.isEmpty
                                      ? Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF607D8B),
                                                Color(0xFF455A64),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 32,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF607D8B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          adminInfoModel.imagePath.isEmpty
                              ? 'Tap to add profile picture'
                              : 'Tap to change profile picture',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Fields Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Name Fields Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _first,
                                decoration: InputDecoration(
                                  labelText: 'First Name',
                                  hintText: 'Enter first name',
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF607D8B),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF607D8B),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF7FAFC),
                                ),
                                validator: (v) => v!.isEmpty
                                    ? 'First name is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _last,
                                decoration: InputDecoration(
                                  labelText: 'Last Name',
                                  hintText: 'Enter last name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF607D8B),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF7FAFC),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Email Field
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter email address',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF607D8B),
                            ),
                            suffixIcon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF607D8B),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7FAFC),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Email is required';
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(v)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                          enabled: false, // Auto-detected, read-only
                        ),
                        const SizedBox(height: 20),

                        // Apartment Field
                        TextFormField(
                          controller: _apartment,
                          decoration: InputDecoration(
                            labelText: 'Apartment Name',
                            hintText: 'Enter apartment name',
                            prefixIcon: const Icon(
                              Icons.apartment,
                              color: Color(0xFF607D8B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF607D8B),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7FAFC),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Apartment name is required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Phone Field
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                            hintText: 'Enter contact number',
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: Color(0xFF607D8B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF607D8B),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7FAFC),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Contact number is required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Address Field
                        TextFormField(
                          controller: _address,
                          minLines: 3,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            hintText: 'Enter your full address',
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: Color(0xFF607D8B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF607D8B),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7FAFC),
                            alignLabelWithHint: true,
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Address is required' : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF607D8B), Color(0xFF455A64)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF607D8B).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.isEditMode
                                      ? 'Update Profile'
                                      : 'Complete Profile',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
