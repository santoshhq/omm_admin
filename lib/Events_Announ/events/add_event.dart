import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'modules.dart';

class AddEventPage extends StatefulWidget {
  final Festival? existingEvent;

  const AddEventPage({super.key, this.existingEvent});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  File? _eventImage;
  final List<TextEditingController> _detailControllers = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _eventImage = File(pickedFile.path);
      });
    }
  }

  void _addDetailField() {
    setState(() {
      _detailControllers.add(TextEditingController());
    });
  }

  // _selectedDate and _pickDate removed - not used in current UI

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.deepOrange;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Add Event",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20), // curved edges
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar + Event Title in one row
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _eventImage != null
                              ? FileImage(_eventImage!)
                              : null,
                          child: _eventImage == null
                              ? const Icon(
                                  Icons.celebration,
                                  size: 40,
                                  color: Colors.deepOrange,
                                )
                              : null,
                        ),
                        // Upload button inside avatar
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: themeColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.upload,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Event Title beside icon
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: "Event Title",
                          prefixIcon: const Icon(
                            Icons.star_border,
                            color: Colors.deepOrange,
                          ),
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter event title" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Event Start Date Picker

                // Start Date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _startDate ?? DateTime.now(), // default selected date
                      firstDate: DateTime.now(), // ✅ disables all past days
                      lastDate: DateTime(2100), // future limit
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors
                                  .deepOrange, // header & selected date color
                              onPrimary:
                                  Colors.white, // text color on selected date
                              onSurface: Colors.black, // default text color
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Colors.deepOrange, // buttons (OK/CANCEL)
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      setState(() {
                        _startDate = picked; // store the picked date
                      });
                    }
                  },

                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Event Start Date",
                      prefixIcon: const Icon(
                        Icons.event_note,
                        color: Colors.deepOrange,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _startDate == null
                          ? "Pick a date"
                          : "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: _startDate == null
                            ? const Color.fromARGB(255, 94, 94, 94)
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // End Date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                      firstDate: DateTime.now(), // ✅ disables past days
                      lastDate: DateTime(2100), // allow far future
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary:
                                  Colors.deepOrange, // header & selected date
                              onPrimary:
                                  Colors.white, // text color on selected date
                              onSurface: Colors.black, // default text color
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Colors.deepOrange, // OK/CANCEL buttons
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },

                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Event End Date",
                      prefixIcon: const Icon(
                        Icons.event_note,
                        color: Colors.deepOrange,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _endDate == null
                          ? "Pick a date"
                          : "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: _endDate == null
                            ? const Color.fromARGB(255, 91, 90, 90)
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Description",
                    prefixIcon: const Icon(
                      Icons.description,
                      color: Colors.deepOrange,
                    ),
                    alignLabelWithHint: true,
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter description" : null,
                ),
                const SizedBox(height: 16),

                // Target Amount
                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Target Amount (₹)",
                    prefixIcon: const Icon(
                      Icons.currency_rupee,
                      color: Colors.deepOrange,
                    ),
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter target amount" : null,
                ),
                const SizedBox(height: 24),

                // Event Details Section
                // Event Details Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Event Details",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepOrange.shade700,
                      ),
                    ),
                    IconButton(
                      onPressed: _addDetailField,
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Column(
                  children: _detailControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    TextEditingController controller = entry.value;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          // Expanded text field
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: "Detail",
                                prefixIcon: const Icon(
                                  Icons.label_important,
                                  color: Colors.deepOrange,
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Remove button
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                _detailControllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Festival newEvent = Festival(
                          name: _titleController.text,
                          description: _descriptionController.text,
                          targetAmount: double.parse(_targetController.text),
                          collectedAmount: 0,
                          donations: [],
                          imageUrl: _eventImage?.path,
                          startDate: _startDate,
                          endDate: _endDate,
                        );

                        Navigator.pop(context, newEvent);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, size: 22, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          "Add Event",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
