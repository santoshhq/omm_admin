import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
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
  String? _existingImageUrl; // Track existing image URL
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

      // Set existing image URL if available
      if (event.imagePaths.isNotEmpty) {
        final imagePath = event.imagePaths.first;
        if (imagePath.startsWith('data:image')) {
          _existingImageUrl = imagePath; // Base64 image
        } else {
          _existingImageUrl = imagePath.startsWith('http')
              ? imagePath
              : '${ApiService.baseUrl}/$imagePath';
        }
      }

      for (final detail in event.eventDetails) {
        final controller = TextEditingController(text: detail);
        _detailControllers.add(controller);
      }

      if (_detailControllers.isEmpty) {
        _detailControllers.add(TextEditingController());
      }
    } else {
      _detailControllers.add(TextEditingController());
    }
  }

  /// Check if we have any image (new or existing)
  bool get _hasImage => _eventImage != null || _existingImageUrl != null;

  /// Get the current image to display
  Widget _buildImageWidget() {
    if (_eventImage != null) {
      // Show newly picked image
      return ClipOval(
        child: Image.file(
          _eventImage!,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      );
    } else if (_existingImageUrl != null) {
      // Show existing image from server
      if (_existingImageUrl!.startsWith('data:image')) {
        // Base64 image
        final base64Str = _existingImageUrl!.split(',').last;
        return ClipOval(
          child: Image.memory(
            base64Decode(base64Str),
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          ),
        );
      } else {
        // Network image
        return ClipOval(
          child: Image.network(
            _existingImageUrl!,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 40,
                  color: Colors.deepOrange,
                ),
              );
            },
          ),
        );
      }
    } else {
      // No image - show celebration icon
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.celebration,
          size: 40,
          color: Colors.deepOrange,
        ),
      );
    }
  }

  Future<String?> _getAdminId() async {
    String? adminId = await AdminSessionService.getAdminId();
    print('🔍 AdminSessionService admin ID: $adminId');

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

    setState(() => _isSubmitting = true);

    try {
      final eventDetails = _detailControllers
          .map((c) => c.text.trim())
          .where((d) => d.isNotEmpty)
          .toList();

      String? imageToSend;
      if (_eventImage != null) {
        imageToSend = await _getImageAsBase64();
        if (imageToSend != null) {
          print('🖼️ Image ready for upload, length: ${imageToSend.length}');
        } else {
          print('⚠️ Image conversion failed, sending null');
        }
      }

      Map<String, dynamic> response;

      if (widget.existingEvent != null) {
        response = await ApiService.updateEventCard(
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

        final updatedEvent = Festival.fromJson(response['data']['event']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, updatedEvent);
        }
      } else {
        response = await ApiService.createEventCard(
          image: imageToSend,
          name: _titleController.text.trim(),
          startdate: _startDate!.toUtc().toIso8601String(),
          enddate: _endDate!.toUtc().toIso8601String(),
          description: _descriptionController.text.trim(),
          targetamount: double.parse(_targetController.text),
          eventdetails: eventDetails,
          adminId: adminId,
        );

        final newEvent = Festival.fromJson(response['data']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, newEvent);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _eventImage = File(pickedFile.path);
        _existingImageUrl = null; // Clear existing image when new one is picked
      });
    }
  }

  Future<String?> _getImageAsBase64() async {
    if (_eventImage == null) return null;

    final originalBytes = await _eventImage!.readAsBytes();
    final img.Image? image = img.decodeImage(originalBytes);
    if (image == null) return null;

    final maxWidth = 1280;
    final maxHeight = 720;
    img.Image resizedImage = image;

    if (image.width > maxWidth || image.height > maxHeight) {
      double aspectRatio = image.width / image.height;
      int newWidth, newHeight;

      if (aspectRatio > 1) {
        newWidth = maxWidth;
        newHeight = (maxWidth / aspectRatio).round();
      } else {
        newHeight = maxHeight;
        newWidth = (maxHeight * aspectRatio).round();
      }

      resizedImage = img.copyResize(image, width: newWidth, height: newHeight);
    }

    final compressedBytes = Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: 70),
    );

    final base64String = base64Encode(compressedBytes);
    final extension = _eventImage!.path.split('.').last.toLowerCase();
    return 'data:image/$extension;base64,$base64String';
  }

  void _addDetailField() {
    setState(() => _detailControllers.add(TextEditingController()));
  }

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
            borderRadius: BorderRadius.circular(20),
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
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildImageWidget(),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: !_hasImage
                                    ? themeColor
                                    : Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                !_hasImage ? Icons.upload : Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
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
                // Start Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.deepOrange,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.deepOrange,
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => _startDate = picked);
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
                // End Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.deepOrange,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.deepOrange,
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => _endDate = picked);
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
                // Event Details
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
                  height: 55,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.black45,
                        elevation: 8,
                        padding: EdgeInsets.zero,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isSubmitting
                                ? [
                                    themeColor.withOpacity(0.6),
                                    themeColor.withOpacity(0.8),
                                  ]
                                : [themeColor, themeColor.withOpacity(0.9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        key: ValueKey("loader"),
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.save_alt_rounded,
                                        key: ValueKey("icon"),
                                        size: 24,
                                        color: Colors.white,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: Text(
                                  _isSubmitting
                                      ? "Saving..."
                                      : widget.existingEvent != null
                                      ? "Update Event"
                                      : "Add Event",
                                  key: ValueKey(
                                    _isSubmitting
                                        ? "saving"
                                        : widget.existingEvent != null
                                        ? "update"
                                        : "add",
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
