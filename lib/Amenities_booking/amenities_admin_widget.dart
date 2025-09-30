import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';
import 'amenities_admin_module.dart';
import '../config/api_config.dart';
import '../services/admin_session_service.dart';

class AmenitiesAdminPage extends StatefulWidget {
  const AmenitiesAdminPage({super.key});

  @override
  State<AmenitiesAdminPage> createState() => _AmenitiesAdminPageState();
}

class _AmenitiesAdminPageState extends State<AmenitiesAdminPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    amenitiesAdminModule.addListener(_onModuleChanged);
    _loadAmenitiesFromBackend();
  }

  /// Load amenities from backend
  void _loadAmenitiesFromBackend() async {
    setState(() => _isLoading = true);
    try {
      // Get admin ID from session
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception('Admin not logged in');
      }

      final response = await ApiService.getAllAmenities(adminId: adminId);
      if (response['success'] == true) {
        // Clear existing amenities and load from backend
        amenitiesAdminModule.clearAmenities();
        final List<dynamic> amenitiesData = response['data'] ?? [];

        for (var amenityData in amenitiesData) {
          final amenity = AmenityModel(
            id: amenityData['id'] ?? amenityData['_id'] ?? '',
            name: amenityData['name'] ?? '',
            description: amenityData['description'] ?? '',
            imagePaths: List<String>.from(
              amenityData['images'] ?? amenityData['imagePaths'] ?? [],
            ),
            location: amenityData['location'] ?? '',
            capacity: amenityData['capacity'] ?? 0,
            hourlyRate: (amenityData['hourlyRate'] ?? 0.0).toDouble(),
            features: List<String>.from(amenityData['features'] ?? []),
            active: amenityData['active'] ?? true,
          );
          amenitiesAdminModule.addAmenity(amenity);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            content: Text(
              '✅ Loaded ${amenitiesData.length} amenities from backend',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            '❌ Failed to load amenities: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    amenitiesAdminModule.removeListener(_onModuleChanged);
    super.dispose();
  }

  void _onModuleChanged() => setState(() {});

  void _openAdd() async {
    final newAmenity = await Navigator.push<AmenityModel?>(
      context,
      MaterialPageRoute(builder: (_) => const AddAmenityPage()),
    );
    if (newAmenity != null) {
      amenitiesAdminModule.addAmenity(newAmenity);
    }
  }

  void _editAmenity(int index) async {
    final amenity = amenitiesAdminModule.amenities[index];
    final updatedAmenity = await Navigator.push<AmenityModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => EditAmenityPage(amenity: amenity, index: index),
      ),
    );
    if (updatedAmenity != null) {
      amenitiesAdminModule.updateAmenity(index, updatedAmenity);
    }
  }

  void _deleteAmenity(int index) async {
    final amenity = amenitiesAdminModule.amenities[index];

    // Show confirmation dialog with hard delete and soft delete options
    String? deleteType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Amenity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What would you like to do with "${amenity.name}"?'),
              const SizedBox(height: 16),
              const Text(
                '• Deactivate: Hide from users (can be restored later)\n• Permanently Delete: Remove completely from database',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('soft'),
              child: const Text(
                'Deactivate',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('hard'),
              child: const Text(
                'Delete Permanently',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (deleteType == null) return;

    setState(() => _isLoading = true);
    try {
      print('🗑️ Attempting to delete amenity: ${amenity.name}');
      print('🆔 Amenity ID: ${amenity.id}');

      if (amenity.id.isNotEmpty) {
        // Delete from backend if it has an ID
        final adminId = await AdminSessionService.getAdminId();
        if (adminId == null) {
          throw Exception('Admin not logged in');
        }

        print('🔑 Admin ID: $adminId');
        print('🌐 Making delete request to backend...');

        final response = await ApiService.deleteAmenity(
          adminId: adminId,
          amenityId: amenity.id,
          hardDelete:
              deleteType ==
              'hard', // Use hard delete if user chose permanent deletion
        );

        print('📤 Delete response: $response');

        if (response['success'] == true) {
          if (deleteType == 'hard') {
            // For hard delete, remove from local list completely
            amenitiesAdminModule.removeAmenity(index);
            print('✅ Amenity permanently deleted and removed from local list');
          } else {
            // For soft delete, update the amenity status to inactive
            final updatedAmenity = AmenityModel(
              id: amenity.id,
              name: amenity.name,
              description: amenity.description,
              capacity: amenity.capacity,
              imagePaths: amenity.imagePaths,
              location: amenity.location,
              hourlyRate: amenity.hourlyRate,
              features: amenity.features,
              active: false, // Mark as inactive
            );
            amenitiesAdminModule.updateAmenity(index, updatedAmenity);
            print('✅ Amenity deactivated in local list');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              content: Text(
                deleteType == 'hard'
                    ? '✅ ${amenity.name} permanently deleted'
                    : '✅ ${amenity.name} deactivated successfully',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        } else {
          throw Exception(
            response['message'] ?? 'Failed to delete amenity from backend',
          );
        }
      } else {
        // Remove from local list if no backend ID
        amenitiesAdminModule.removeAmenity(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
            content: Text(
              '⚠️ ${amenity.name} removed from local list',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      print('🔥 Error in delete amenity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            '❌ Failed to delete amenity: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Toggle amenity active status and sync with backend
  void _toggleAmenityStatus(int index, bool newStatus) async {
    final amenity = amenitiesAdminModule.amenities[index];

    setState(() => _isLoading = true);
    try {
      if (amenity.id.isNotEmpty) {
        // Update in backend if it has an ID
        final adminId = await AdminSessionService.getAdminId();
        if (adminId == null) {
          throw Exception('Admin not logged in');
        }

        final response = await ApiService.updateAmenity(
          adminId: adminId,
          amenityId: amenity.id,
          active: newStatus,
        );

        if (response['success'] == true) {
          // Update local model
          final updated = AmenityModel(
            id: amenity.id,
            name: amenity.name,
            imagePaths: amenity.imagePaths,
            description: amenity.description,
            capacity: amenity.capacity,
            active: newStatus,
            location: amenity.location,
            hourlyRate: amenity.hourlyRate,
            features: amenity.features,
          );
          amenitiesAdminModule.updateAmenity(index, updated);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              content: Text(
                '✅ ${amenity.name} ${newStatus ? 'activated' : 'deactivated'}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      } else {
        // Update local model only if no backend ID
        final updated = AmenityModel(
          id: amenity.id,
          name: amenity.name,
          imagePaths: amenity.imagePaths,
          description: amenity.description,
          capacity: amenity.capacity,
          active: newStatus,
          location: amenity.location,
          hourlyRate: amenity.hourlyRate,
          features: amenity.features,
        );
        amenitiesAdminModule.updateAmenity(index, updated);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            '❌ Failed to update amenity status: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amenities = amenitiesAdminModule.amenities;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Amenities Admin',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadAmenitiesFromBackend,
            tooltip: 'Refresh Amenities',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: _openAdd,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF455A64)),
                  SizedBox(height: 16),
                  Text(
                    "Loading amenities...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : amenities.isEmpty
          ? const Center(
              child: Text(
                "No amenities added yet",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                itemCount: amenities.length,
                itemBuilder: (context, index) {
                  final a = amenities[index];
                  return Slidable(
                    key: ValueKey(a.id),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      extentRatio: 0.4,
                      children: [
                        SlidableAction(
                          onPressed: (context) => _editAmenity(index),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,

                          /// label: 'Edit',
                        ),
                        SlidableAction(
                          onPressed: (context) => _deleteAmenity(index),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,

                          ///  label: 'Delete',
                        ),
                      ],
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Images (show first image with count indicator)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: a.imagePaths.isNotEmpty
                                      ? _buildAmenityImage(
                                          a.imagePaths.first,
                                          width: 110,
                                          height: 110,
                                        )
                                      : Container(
                                          width: 110,
                                          height: 110,
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.image,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                                // Image count indicator
                                if (a.imagePaths.length > 1)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '+${a.imagePaths.length - 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          a.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Switch(
                                        value: a.active,
                                        onChanged: _isLoading
                                            ? null
                                            : (v) => _toggleAmenityStatus(
                                                index,
                                                v,
                                              ),
                                        activeColor: const Color(0xFF455A64),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Capacity: ${a.capacity}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (a.location.isNotEmpty)
                                    Text(
                                      'Location: ${a.location}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  if (a.description.isNotEmpty)
                                    Text(
                                      a.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (a.hourlyRate > 0)
                                    Text(
                                      'Hourly: ₹${a.hourlyRate.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// Helper function to convert image file to base64 string
Future<String> _imageToBase64(File imageFile) async {
  try {
    final bytes = await imageFile.readAsBytes();
    final base64String = base64Encode(bytes);
    // Add data URL prefix for proper display
    return 'data:image/jpeg;base64,$base64String';
  } catch (e) {
    print('Error converting image to base64: $e');
    return '';
  }
}

// Helper function to convert base64 string back to memory image
Uint8List? _base64ToBytes(String base64String) {
  try {
    // Remove data URL prefix if present
    String cleanBase64 = base64String;
    if (base64String.startsWith('data:image')) {
      cleanBase64 = base64String.split(',')[1];
    }
    return base64Decode(cleanBase64);
  } catch (e) {
    print('Error converting base64 to bytes: $e');
    return null;
  }
}

// Helper widget to display images from different sources
Widget _buildAmenityImage(
  String imagePath, {
  required double width,
  required double height,
}) {
  if (imagePath.startsWith('data:image')) {
    // Base64 image
    final bytes = _base64ToBytes(imagePath);
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                const SizedBox(height: 4),
                Text(
                  'Image\nError',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
      );
    }
  } else if (imagePath.startsWith('http')) {
    // Network image
    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 30, color: Colors.grey),
              const SizedBox(height: 4),
              Text(
                'Image\nUnavailable',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: const Color(0xFF455A64),
            ),
          ),
        );
      },
    );
  } else {
    // File path - try to load as file
    return Image.file(
      File(imagePath),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 30, color: Colors.grey),
              const SizedBox(height: 4),
              Text(
                'File Not\nFound',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fallback if none of the above conditions match
  return Container(
    width: width,
    height: height,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image, size: 40, color: Colors.grey),
  );
}

// ------------------------ Add Amenity Page ------------------------

class AddAmenityPage extends StatefulWidget {
  const AddAmenityPage({super.key});

  @override
  State<AddAmenityPage> createState() => _AddAmenityPageState();
}

class _AddAmenityPageState extends State<AddAmenityPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _capacity = TextEditingController();
  final _location = TextEditingController();
  final _hourly = TextEditingController();
  final List<TextEditingController> _features = [];

  bool _active = true;
  bool _isLoading = false;
  List<File> _imageFiles = [];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _capacity.dispose();
    _location.dispose();
    _hourly.dispose();
    for (final ctrl in _features) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultipleMedia();
    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(picked.map((xFile) => File(xFile.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final features = _features
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Get admin ID from session
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception('Admin not logged in');
      }

      // Convert images to base64 strings for storage
      List<String> imagePaths = [];
      if (_imageFiles.isNotEmpty) {
        for (File imageFile in _imageFiles) {
          try {
            final base64String = await _imageToBase64(imageFile);
            if (base64String.isNotEmpty) {
              imagePaths.add(base64String);
            }
          } catch (e) {
            print('Error processing image: $e');
            // Skip this image if there's an error
          }
        }
      }

      // Call backend API to create amenity
      final response = await ApiService.createAmenity(
        createdByAdminId: adminId,
        name: _name.text.trim(),
        description: _description.text.trim(),
        capacity: int.tryParse(_capacity.text.trim()) ?? 0,
        imagePaths: imagePaths,
        location: _location.text.trim(),
        hourlyRate: double.tryParse(_hourly.text.trim()) ?? 0.0,
        features: features,
        active: _active,
      );

      if (response['success'] == true) {
        // Create local model with backend data
        final backendData = response['data']['amenity'] ?? response['data'];
        final a = AmenityModel(
          id: backendData['id'] ?? backendData['_id'] ?? '',
          name: backendData['name'] ?? _name.text.trim(),
          imagePaths: List<String>.from(
            backendData['images'] ?? backendData['imagePaths'] ?? imagePaths,
          ),
          description: backendData['description'] ?? _description.text.trim(),
          capacity:
              backendData['capacity'] ??
              int.tryParse(_capacity.text.trim()) ??
              0,
          active: backendData['active'] ?? _active,
          location: backendData['location'] ?? _location.text.trim(),
          hourlyRate:
              (backendData['hourlyRate'] ??
                      double.tryParse(_hourly.text.trim()) ??
                      0.0)
                  .toDouble(),
          features: List<String>.from(backendData['features'] ?? features),
        );

        Navigator.pop(context, a);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              content: Text(
                '✅ ${a.name} created successfully!',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Text(
              '❌ Failed to create amenity: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Amenity', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Images Section
              const Text(
                'Images',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Image Grid

              // Image Upload/Display Section
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageFiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Tap to Add Images',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Multiple images supported',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            // Image Carousel
                            PageView.builder(
                              controller: PageController(),
                              itemCount: _imageFiles.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _imageFiles[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    // Delete button for each image
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // Image counter and add more button
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_imageFiles.length} image${_imageFiles.length > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: _pickImages,
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Page indicator dots (if more than 1 image)
                            if (_imageFiles.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _imageFiles.asMap().entries.map((
                                    entry,
                                  ) {
                                    return Container(
                                      width: 6,
                                      height: 6,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Amenity Fields
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Amenity Name',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: 'Describe the amenity features and benefits...',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Enter numbers only';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _hourly,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Hourly rate (₹ / hr)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Features',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              ..._features.asMap().entries.map((e) {
                final idx = e.key;
                final ctrl = e.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            hintText: "Enter feature",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _features.removeAt(idx);
                          });
                        },
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _features.add(TextEditingController()));
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add feature',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF455A64),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_features.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _features.clear());
                      },
                      child: const Text('Clear all'),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Save button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF455A64),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _onSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Save Amenity',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------ Edit Amenity Page ------------------------

class EditAmenityPage extends StatefulWidget {
  final AmenityModel amenity;
  final int index;

  const EditAmenityPage({
    super.key,
    required this.amenity,
    required this.index,
  });

  @override
  State<EditAmenityPage> createState() => _EditAmenityPageState();
}

class _EditAmenityPageState extends State<EditAmenityPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _capacity;
  late TextEditingController _location;
  late TextEditingController _hourly;
  late List<TextEditingController> _features;

  late bool _active;
  bool _isLoading = false;
  List<File> _imageFiles = [];
  List<String> _existingImagePaths = [];

  @override
  void initState() {
    super.initState();
    // Initialize form fields with existing amenity data
    _name = TextEditingController(text: widget.amenity.name);
    _description = TextEditingController(text: widget.amenity.description);
    _capacity = TextEditingController(text: widget.amenity.capacity.toString());
    _location = TextEditingController(text: widget.amenity.location);
    _hourly = TextEditingController(text: widget.amenity.hourlyRate.toString());

    // Initialize features
    _features = widget.amenity.features
        .map((feature) => TextEditingController(text: feature))
        .toList();

    _active = widget.amenity.active;
    _existingImagePaths = List<String>.from(widget.amenity.imagePaths);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _capacity.dispose();
    _location.dispose();
    _hourly.dispose();
    for (final ctrl in _features) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultipleMedia();
    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(picked.map((xFile) => File(xFile.path)));
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImagePaths.removeAt(index);
    });
  }

  void _onUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Prepare features list
      final features = _features
          .map((ctrl) => ctrl.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // Handle images - combine existing paths with new files (if any)
      List<String> allImagePaths = List<String>.from(_existingImagePaths);

      // Convert new images to base64 and add to the list
      if (_imageFiles.isNotEmpty) {
        for (File imageFile in _imageFiles) {
          try {
            final base64String = await _imageToBase64(imageFile);
            if (base64String.isNotEmpty) {
              allImagePaths.add(base64String);
            }
          } catch (e) {
            print('Error processing new image: $e');
            // Skip this image if there's an error
          }
        }
      }

      if (widget.amenity.id.isNotEmpty) {
        // Update in backend
        final adminId = await AdminSessionService.getAdminId();
        if (adminId == null) {
          throw Exception('Admin not logged in');
        }

        final response = await ApiService.updateAmenity(
          adminId: adminId,
          amenityId: widget.amenity.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          capacity: int.parse(_capacity.text),
          location: _location.text.trim(),
          hourlyRate: double.parse(_hourly.text),
          imagePaths: allImagePaths,
          features: features,
          active: _active,
        );

        if (response['success'] == true) {
          final updatedAmenity = AmenityModel(
            id: widget.amenity.id,
            name: _name.text.trim(),
            description: _description.text.trim(),
            capacity: int.parse(_capacity.text),
            imagePaths: allImagePaths,
            location: _location.text.trim(),
            hourlyRate: double.parse(_hourly.text),
            features: features,
            active: _active,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              content: const Text(
                '✅ Amenity updated successfully!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );

          Navigator.pop(context, updatedAmenity);
        }
      } else {
        // Update local model only
        final updatedAmenity = AmenityModel(
          id: widget.amenity.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          capacity: int.parse(_capacity.text),
          imagePaths: allImagePaths,
          location: _location.text.trim(),
          hourlyRate: double.parse(_hourly.text),
          features: features,
          active: _active,
        );

        Navigator.pop(context, updatedAmenity);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            '❌ Failed to update amenity: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine existing and new images for display
    List<dynamic> allImages = [];
    allImages.addAll(
      _existingImagePaths.map((path) => {'type': 'existing', 'path': path}),
    );
    allImages.addAll(_imageFiles.map((file) => {'type': 'new', 'file': file}));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Amenity',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Images Section
              const Text(
                'Images',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Image Upload/Display Section
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: allImages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Tap to Add Images',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Multiple images supported',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            // Image Carousel
                            PageView.builder(
                              controller: PageController(),
                              itemCount: allImages.length,
                              itemBuilder: (context, index) {
                                final imageData = allImages[index];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: imageData['type'] == 'existing'
                                          ? _buildAmenityImage(
                                              imageData['path'],
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          : Image.file(
                                              imageData['file'],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      color:
                                                          Colors.grey.shade300,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const Icon(
                                                            Icons.broken_image,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'File Error',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                            ),
                                    ),
                                    // Delete button for each image
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (imageData['type'] == 'existing') {
                                            _removeExistingImage(
                                              _existingImagePaths.indexOf(
                                                imageData['path'],
                                              ),
                                            );
                                          } else {
                                            _removeNewImage(
                                              _imageFiles.indexOf(
                                                imageData['file'],
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            // Image counter and add more button
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${allImages.length} image${allImages.length > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: _pickImages,
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Page indicator dots (if more than 1 image)
                            if (allImages.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: allImages.asMap().entries.map((
                                    entry,
                                  ) {
                                    return Container(
                                      width: 6,
                                      height: 6,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Amenity Fields
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Amenity Name',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: 'Describe the amenity features and benefits...',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Enter numbers only';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _hourly,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Hourly rate (₹ / hr)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Status Section (Enhanced UI for edit mode)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      _active ? Icons.check_circle : Icons.cancel,
                      color: _active ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _active
                                ? 'Active - Visible to users'
                                : 'Inactive - Hidden from users',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                      activeColor: const Color(0xFF455A64),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Features',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              ..._features.asMap().entries.map((e) {
                final idx = e.key;
                final ctrl = e.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            hintText: "Enter feature",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            ctrl.dispose();
                            _features.removeAt(idx);
                          });
                        },
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _features.add(TextEditingController()));
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add feature',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF455A64),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_features.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (final ctrl in _features) {
                            ctrl.dispose();
                          }
                          _features.clear();
                        });
                      },
                      child: const Text('Clear all'),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Update button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF455A64),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _onUpdate,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Update Amenity',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
