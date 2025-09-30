import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'modules.dart';
import '../../config/api_config.dart';
import '../../services/admin_session_service.dart';

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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    for (final c in _detailControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _initializeForm() {
    if (widget.existingEvent != null) {
      final event = widget.existingEvent!;
      _titleController.text = event.name;
      _descriptionController.text = event.description;
      _targetController.text = event.targetAmount.toString();
      _startDate = event.startDate;
      _endDate = event.endDate;

      // Initialize event details
      for (final detail in event.eventDetails) {
        final controller = TextEditingController(text: detail);
        _detailControllers.add(controller);
      }

      // Add empty controller if no details exist
      if (_detailControllers.isEmpty) {
        _detailControllers.add(TextEditingController());
      }
    } else {
      // Add one empty detail field for new events
      _detailControllers.add(TextEditingController());
    }
  }

  Future<String?> _getAdminId() async {
    // Try AdminSessionService first (preferred method)
    String? adminId = await AdminSessionService.getAdminId();
    print('🔍 AdminSessionService admin ID: $adminId');

    // If not found, try alternative keys for backward compatibility
    if (adminId == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        adminId = prefs.getString('user_id') ?? prefs.getString('adminId');
        print('🔍 Fallback admin ID from SharedPreferences: $adminId');
      } catch (e) {
        print('❌ Error getting fallback admin ID: $e');
      }
    }

    final isLoggedIn = await AdminSessionService.isLoggedIn();
    print('🔍 Final admin ID for event creation: $adminId');
    print('🔍 Is logged in: $isLoggedIn');

    return adminId;
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate dates
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final adminId = await _getAdminId();
    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get event details from controllers
      final eventDetails = _detailControllers
          .map((controller) => controller.text.trim())
          .where((detail) => detail.isNotEmpty)
          .toList();

      if (widget.existingEvent != null) {
        // Update existing event
        final imageBase64 = await _getImageAsBase64();
        print(
          '🔄 Updating event with image data: ${imageBase64?.substring(0, 50) ?? "null"}...',
        );

        // Ensure we never send a local file path
        String? imageToSend;
        if (imageBase64 != null && imageBase64.startsWith('data:image/')) {
          imageToSend = imageBase64;
          print('✅ Sending base64 image data');
        } else {
          imageToSend = null;
          print('⚠️ No valid image data, sending null');
        }

        final response = await ApiService.updateEventCard(
          id: widget.existingEvent!.id!,
          adminId: adminId,
          image: imageToSend,
          name: _titleController.text.trim(),
          startdate: _startDate!.toUtc().toIso8601String(),
          enddate: _endDate!.toUtc().toIso8601String(),
          description: _descriptionController.text.trim(),
          targetamount: double.parse(_targetController.text),
          eventdetails: eventDetails,
        );

        final updatedFestival = Festival.fromJson(response['data']['event']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, updatedFestival);
        }
      } else {
        // Create new event
        String? imageToSend;

        // TEMPORARY FIX: Skip image processing to avoid backend HTML error
        if (_eventImage != null) {
          print(
            '🖼️ Image selected but temporarily skipping to avoid backend errors',
          );
          print('Event will be created without image until backend is fixed');

          // Show user notification about image issue
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Note: Event will be created without image. Backend needs to be updated to handle images properly.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }

        final response = await ApiService.createEventCard(
          image: imageToSend,
          name: _titleController.text.trim(),
          startdate: _startDate!.toUtc().toIso8601String(),
          enddate: _endDate!.toUtc().toIso8601String(),
          description: _descriptionController.text.trim(),
          targetamount: double.parse(_targetController.text),
          eventdetails: eventDetails,
          adminId: adminId,
        );

        final newFestival = Festival.fromJson(response['data']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, newFestival);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save event: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _eventImage = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _eventImage = null;
    });
  }

  Future<String?> _getImageAsBase64() async {
    if (_eventImage == null) {
      print('🖼️ No image selected, returning null');
      return null;
    }

    try {
      print('🖼️ Converting image to base64: ${_eventImage!.path}');
      final bytes = await _eventImage!.readAsBytes();
      final base64String = base64Encode(bytes);
      final extension = _eventImage!.path.split('.').last.toLowerCase();
      final result = 'data:image/$extension;base64,$base64String';
      print('🖼️ Base64 conversion successful, length: ${result.length}');
      return result;
    } catch (e) {
      print('❌ Error converting image to base64: $e');
      return null;
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
            widget.existingEvent != null ? "Edit Event" : "Add Event",
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
                        // Upload/Remove button inside avatar
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _eventImage == null
                                ? _pickImage
                                : _removeImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _eventImage == null
                                    ? themeColor
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                _eventImage == null
                                    ? Icons.upload
                                    : Icons.close,
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
                    onPressed: _isSubmitting ? null : _saveEvent,
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
                        if (_isSubmitting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        else
                          const Icon(Icons.save, size: 22, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _isSubmitting
                              ? "Saving..."
                              : widget.existingEvent != null
                              ? "Update Event"
                              : "Add Event",
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
