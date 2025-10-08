import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'security_module.dart';
import '../services/admin_session_service.dart';
import '../config/api_config.dart';

class SecurityFormPage extends StatefulWidget {
  final SecurityGuardModel? guard;
  const SecurityFormPage({Key? key, this.guard}) : super(key: key);

  @override
  State<SecurityFormPage> createState() => _SecurityFormPageState();
}

class _SecurityFormPageState extends State<SecurityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _age = TextEditingController();
  final _mobile = TextEditingController();
  String? _gate;
  String? _gender;
  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.guard != null) {
      _first.text = widget.guard!.firstName;
      _last.text = widget.guard!.lastName;
      _age.text = widget.guard!.age.toString();
      _mobile.text = widget.guard!.mobile;
      _gate = widget.guard!.assignedGate;
      // Map backend gender value to display value
      final g = widget.guard!.gender.trim().toLowerCase();
      if (g == 'male') {
        _gender = 'Male';
      } else if (g == 'female') {
        _gender = 'Female';
      } else if (g == 'other') {
        _gender = 'Other';
      } else {
        _gender = null;
      }
      _existingImageUrl = widget.guard!.imageUrl;
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _age.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF455A64)),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF455A64),
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String? adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin session not found. Please log in again.'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      final isEdit = widget.guard != null && widget.guard!.id != null;
      final guard = SecurityGuardModel(
        id: isEdit ? widget.guard!.id : null,
        adminId: adminId,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        age: int.parse(_age.text.trim()),
        mobile: _mobile.text.trim(),
        assignedGate: _gate!,
        gender: (_gender ?? 'Male').toLowerCase(),
        imageUrl: _imageFile?.path ?? _existingImageUrl,
      );
      Map<String, dynamic> result;
      if (isEdit) {
        result = await ApiService.updateSecurityGuard(
          guardId: guard.id!,
          updatedGuard: guard,
          imageFile: _imageFile,
        );
      } else {
        result = await ApiService.createSecurityGuard(
          adminId: adminId,
          guard: guard,
          imageFile: _imageFile,
        );
      }
      print('Guard API result:');
      print(result);
      if (result['status'] == false || result['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Failed to save guard.',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Security guard updated successfully!'
                : 'Security guard added successfully!',
          ),
        ),
      );
      Navigator.pop(context, guard);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF455A64), width: 2),
      ),
    );
  }

  Widget _buildGenderOption(String value, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF455A64) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF455A64) : Colors.grey.shade400,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGateOption(String gate) {
    final selected = _gate == gate;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gate = gate),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF455A64) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF455A64) : Colors.grey.shade400,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF455A64).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              gate,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Security Guard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Avatar with camera
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_existingImageUrl != null &&
                                _existingImageUrl!.isNotEmpty)
                          ? (_existingImageUrl!.startsWith('data:image/')
                                ? MemoryImage(
                                    base64Decode(
                                      _existingImageUrl!.split(',').last,
                                    ),
                                  )
                                : NetworkImage(_existingImageUrl!)
                                      as ImageProvider)
                          : null,
                      child:
                          (_imageFile == null &&
                              (_existingImageUrl == null ||
                                  _existingImageUrl!.isEmpty))
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
                                size: 55,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF455A64),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // First Name
              TextFormField(
                controller: _first,
                decoration: _inputDecoration("First Name"),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _last,
                decoration: _inputDecoration("Last Name"),
              ),
              const SizedBox(height: 16),

              // Age
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Age"),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final a = int.tryParse(v);
                  if (a == null || a < 18) return 'Must be 18+';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mobile
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration("Mobile", prefix: "+91 "),
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // optional
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) {
                    return 'Enter 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Gate Selection (Enhanced - 6 options in a row)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Assigned Gate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildGateOption('G1'),
                  _buildGateOption('G2'),
                  _buildGateOption('G3'),
                  _buildGateOption('G4'),
                  _buildGateOption('G5'),
                  _buildGateOption('G6'),
                ],
              ),
              if (_gate == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Select gate',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Gender Selection
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Gender',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildGenderOption('Male', Icons.male),
                  const SizedBox(width: 12),
                  _buildGenderOption('Female', Icons.female),
                ],
              ),
              if (_gender == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Select gender',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 32),

              // Add/Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      const Color(0xFF455A64),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
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
                      : Text(
                          widget.guard != null ? 'Update' : 'Add',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
