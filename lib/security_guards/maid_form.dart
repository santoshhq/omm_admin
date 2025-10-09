import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omm_admin/config/api_config.dart';
import 'package:omm_admin/services/admin_session_service.dart';
import 'security_module.dart';
// Import your ApiService for housekeeping
import 'package:collection/collection.dart';

class MaidFormPage extends StatefulWidget {
  final Map<String, dynamic>? maid;
  const MaidFormPage({Key? key, this.maid}) : super(key: key);

  @override
  State<MaidFormPage> createState() => _MaidFormPageState();
}

class _MaidFormPageState extends State<MaidFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _age = TextEditingController();
  final _timings = TextEditingController();
  final _mobile = TextEditingController();

  File? _imageFile;
  String? _gender;
  List<String> _selectedGates = [];

  @override
  void initState() {
    super.initState();
    if (widget.maid != null) {
      final m = widget.maid!;
      _first.text = m['firstname'] ?? '';
      _last.text = m['lastname'] ?? '';
      _age.text = m['age']?.toString() ?? '';
      _mobile.text = m['mobilenumber'] ?? '';
      _gender = (m['gender'] ?? 'Female').toString().capitalize();
      if (m['assignfloors'] is List) {
        _selectedGates = List<String>.from(m['assignfloors']);
      }
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _age.dispose();
    _timings.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      final originalBytes = await File(picked.path).readAsBytes();
      final decoded = img.decodeImage(originalBytes);
      if (decoded != null) {
        final resized = img.copyResize(decoded, width: 600);
        final compressedBytes = img.encodeJpg(resized, quality: 70);
        final tempPath = '${picked.path}_compressed.jpg';
        final compressedFile = await File(
          tempPath,
        ).writeAsBytes(compressedBytes);
        setState(() => _imageFile = compressedFile);
      } else {
        setState(() => _imageFile = File(picked.path));
      }
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

  Future<void> _onAdd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGates.isEmpty) {
      setState(() {}); // Trigger error message
      return;
    }

    String? adminId = await AdminSessionService.getAdminId();
    if (adminId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin session not found.')));
      return;
    }

    Map<String, dynamic> result;

    if (widget.maid != null && widget.maid!['_id'] != null) {
      // Only send changed fields
      final Map<String, dynamic> updateData = {};
      final m = widget.maid!;
      if (_first.text.trim() != (m['firstname'] ?? '')) {
        updateData['firstname'] = _first.text.trim();
      }
      if (_last.text.trim() != (m['lastname'] ?? '')) {
        updateData['lastname'] = _last.text.trim();
      }
      if (_mobile.text.trim() != (m['mobilenumber'] ?? '')) {
        updateData['mobilenumber'] = _mobile.text.trim();
      }
      if (_age.text.trim() != (m['age']?.toString() ?? '')) {
        updateData['age'] = int.parse(_age.text.trim());
      }
      if (!ListEquality().equals(
        _selectedGates,
        (m['assignfloors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      )) {
        updateData['assignfloors'] = _selectedGates;
      }
      if ((_gender ?? 'Female').toLowerCase() !=
          (m['gender'] ?? 'female').toString().toLowerCase()) {
        updateData['gender'] = (_gender ?? 'Female').toLowerCase();
      }

      // Always send at least one field if nothing changed (to avoid empty update)
      if (updateData.isEmpty && _imageFile == null) {
        updateData['firstname'] = _first.text.trim();
      }

      result = await ApiService.updateHousekeepingStaff(
        adminId: adminId,
        staffId: widget.maid!['_id'],
        updateData: updateData,
        imageFile: _imageFile,
      );
    } else {
      result = await ApiService.createHousekeepingStaff(
        adminId: adminId,
        firstname: _first.text.trim(),
        lastname: _last.text.trim(),
        age: int.parse(_age.text.trim()),
        assignfloors: _selectedGates,
        mobilenumber: _mobile.text.trim(),
        gender: (_gender ?? 'Female').toLowerCase(),
        imageFile: _imageFile,
      );
    }

    if (result['status'] == true && result['data'] != null) {
      Navigator.pop(context, result['data']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to save maid')),
      );
    }
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

  Widget _buildGateOption(String gate) {
    final selected = _selectedGates.contains(gate);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedGates.remove(gate);
          } else {
            _selectedGates.add(gate);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF455A64) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF455A64) : Colors.grey.shade400,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          gate,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Staff', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF455A64),
        elevation: 4,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar with previous image support
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (widget.maid != null &&
                                    widget.maid!['personimage'] != null &&
                                    (widget.maid!['personimage'] as String)
                                        .isNotEmpty
                                ? ((widget.maid!['personimage'] as String)
                                          .startsWith('data:image/')
                                      ? MemoryImage(
                                          base64Decode(
                                            (widget.maid!['personimage']
                                                    as String)
                                                .split(',')
                                                .last,
                                          ),
                                        )
                                      : NetworkImage(
                                              widget.maid!['personimage'],
                                            )
                                            as ImageProvider)
                                : null),
                      child:
                          (_imageFile == null &&
                              (widget.maid == null ||
                                  widget.maid!['personimage'] == null ||
                                  (widget.maid!['personimage'] as String)
                                      .isEmpty))
                          ? const Icon(
                              Icons.person,
                              size: 55,
                              color: Colors.white70,
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
                          decoration: const BoxDecoration(
                            color: Color(0xFF455A64),
                            shape: BoxShape.circle,
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
                decoration: InputDecoration(
                  labelText: 'First name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Last Name
              TextFormField(
                controller: _last,
                decoration: InputDecoration(
                  labelText: 'Last name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Age
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final a = int.tryParse(v);
                  if (a == null || a < 16) return 'Enter valid age';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Mobile
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(v))
                    return 'Enter 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Assigned Floors
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Assigned Floors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildGateOption('I'),
                  _buildGateOption('II'),
                  _buildGateOption('III'),
                  _buildGateOption('IV'),
                  _buildGateOption('V'),
                  _buildGateOption('VI'),
                ],
              ),
              if (_selectedGates.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Select at least one floor',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),

              // Gender
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

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF455A64),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _onAdd,
                  child: Text(
                    widget.maid != null ? 'Update ' : 'Add ',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
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

// String capitalization extension
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
