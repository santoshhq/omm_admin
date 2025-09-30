import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omm_admin/security_guards/security_module.dart';

class AddGuardFormPage extends StatefulWidget {
  const AddGuardFormPage({super.key});

  @override
  State<AddGuardFormPage> createState() => _AddGuardFormPageState();
}

class _AddGuardFormPageState extends State<AddGuardFormPage> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final ageController = TextEditingController();
  final mobileController = TextEditingController();
  String? selectedGate;
  String? selectedGender;

  final List<SecurityGuardModel> _guards = [];
  File? _imageFile; // ✅ for storing picked image

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    mobileController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
    ); // 👈 opens camera
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _addGuard() {
    if (_formKey.currentState!.validate()) {
      final newGuard = SecurityGuardModel(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        age: int.parse(ageController.text.trim()),
        mobile: mobileController.text.trim(),
        assignedGate: selectedGate!,
        imageUrl: _imageFile?.path, // 👈 include image
        gender: selectedGender ?? 'Male',
      );

      // 👇 Send guard back to SecurityGuardPage
      Navigator.pop(context, newGuard);

      // ✅ Clear after adding (optional since page will pop anyway)
      firstNameController.clear();
      lastNameController.clear();
      ageController.clear();
      mobileController.clear();
      selectedGate = null;
      _imageFile = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Security Guard",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Avatar with Camera Icon
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : null,
                    child: _imageFile == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white70,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF455A64),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Form
            Form(
              key: _formKey,
              child: Expanded(
                child: ListView(
                  children: [
                    TextFormField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: "First Name",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        labelText: "Last Name",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Age",
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        final age = int.tryParse(val);
                        if (age == null || age < 18 || age > 65) {
                          return "Enter valid age (18-65)";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Mobile Number",
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) {
                          return "Enter valid 10-digit number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedGate,
                      decoration: const InputDecoration(
                        labelText: "Assigned Gate",
                        prefixIcon: Icon(Icons.door_front_door),
                        border: OutlineInputBorder(),
                      ),
                      items: ['G1', 'G2', 'G3', 'G4', 'G5']
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedGate = val),
                      validator: (val) => val == null ? "Select gate" : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      items: ['Male', 'Female']
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedGender = v),
                      decoration: const InputDecoration(labelText: 'Gender'),
                      validator: (v) => v == null ? 'Select gender' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF455A64),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      onPressed: _addGuard,
                      child: const Text(
                        "Add Guard",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Display added guards
            if (_guards.isNotEmpty) ...[
              const Divider(height: 32, thickness: 1),
              const Text(
                "Added Guards",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _guards.length,
                  itemBuilder: (context, index) {
                    final guard = _guards[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(
                          Icons.shield,
                          color: Color(0xFF455A64),
                        ),
                        title: Text("${guard.firstName} ${guard.lastName}"),
                        subtitle: Text(
                          "Age: ${guard.age}, Mobile: ${guard.mobile}, Gate: ${guard.assignedGate}",
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
