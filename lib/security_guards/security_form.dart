import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'security_module.dart';

class SecurityFormPage extends StatefulWidget {
  const SecurityFormPage({super.key});

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

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _age.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _onAdd() {
    if (!_formKey.currentState!.validate()) return;
    final guard = SecurityGuardModel(
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      age: int.parse(_age.text.trim()),
      mobile: _mobile.text.trim(),
      assignedGate: _gate!,
      gender: _gender ?? 'Male',
    );
    Navigator.pop(context, guard);
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
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF455A64) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.blueAccent : Colors.grey.shade400,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
                          : null,
                      child: _imageFile == null
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
                        onTap: _pickImage,
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
              const SizedBox(height: 16),

              // Gate Dropdown
              DropdownButtonFormField<String>(
                value: _gate,
                items: ['G1', 'G2', 'G3', 'G4', 'G5', 'G6']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gate = v),
                decoration: _inputDecoration("Assigned Gate"),
                validator: (v) => v == null ? 'Select gate' : null,
              ),
              const SizedBox(height: 24),

              // Gender Selection (Enhanced)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGenderOption('Male', Icons.male),
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
              const SizedBox(height: 24),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF455A64),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _onAdd,
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
