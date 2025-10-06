import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';
import 'amenities_admin_module.dart';
import '../config/api_config.dart';
import '../services/admin_session_service.dart';
import '../services/image_compression_service.dart';

class AmenitiesAdminPage extends StatefulWidget {
  const AmenitiesAdminPage({super.key});

  @override
  State<AmenitiesAdminPage> createState() => _AmenitiesAdminPageState();
}

class _AmenitiesAdminPageState extends State<AmenitiesAdminPage> {
  bool _isLoading = false;
  final Set<int> _togglingAmenities =
      <int>{}; // Track which amenities are being toggled

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

      // Add timestamp to force fresh data (cache busting)
      final response = await ApiService.getAllAmenities(
        adminId: adminId,
        filters: {'_t': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      if (response['success'] == true) {
        // Clear existing amenities and load from backend
        amenitiesAdminModule.clearAmenities();
        final List<dynamic> amenitiesData = response['data'] ?? [];

        for (var amenityData in amenitiesData) {
          print('🔍 LOADING: Raw amenity data from backend: $amenityData');
          print(
            '🔍 LOADING: Raw weeklySchedule: ${amenityData['weeklySchedule']}',
          );

          final amenity = AmenityModel.fromJson(amenityData);

          print('🔍 LOADING: Parsed amenity weekly schedule:');
          amenity.weeklySchedule.forEach((day, schedule) {
            print(
              '🔍   $day: ${schedule.open}-${schedule.close} (closed: ${schedule.closed})',
            );
          });

          amenitiesAdminModule.addAmenity(amenity);
        }
        /* ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            content: Text(
              '✅ Loaded ${amenitiesData.length} amenities from backend',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );*/
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

  /// Silently refresh amenities from backend without showing loading indicator
  void _silentRefreshAmenities() async {
    // Small delay to avoid too frequent API calls and improve perceived performance
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Get admin ID from session
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception('Admin not logged in');
      }

      // Add timestamp to force fresh data (cache busting)
      final response = await ApiService.getAllAmenities(
        adminId: adminId,
        filters: {'_t': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      if (response['success'] == true) {
        // Clear existing amenities and load from backend silently
        amenitiesAdminModule.clearAmenities();
        final List<dynamic> amenitiesData = response['data'] ?? [];

        for (var amenityData in amenitiesData) {
          final amenity = AmenityModel.fromJson(amenityData);
          amenitiesAdminModule.addAmenity(amenity);
        }
        print('🔄 Silent refresh completed successfully');
      }
    } catch (e) {
      // Silent refresh - don't show error to user for better UX
      print('🔍 Silent refresh failed: $e');
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
      // Refresh from backend instead of just adding locally to ensure data consistency
      _loadAmenitiesFromBackend();

      // Show success message
      /*  ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Text(
            '✅ New amenity added and refreshed successfully!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );*/
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
      // Instead of just updating local list, refresh from backend to get the latest data
      _loadAmenitiesFromBackend();

      // Show success message
      /* ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Text(
            '✅ Amenity updated and refreshed successfully!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );*/
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
          // Refresh from backend instead of manual local updates to ensure data consistency
          _loadAmenitiesFromBackend();
          print('✅ Amenity deleted and refreshed from backend');

          /*  ScaffoldMessenger.of(context).showSnackBar(
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
          );*/
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

  /// Toggle amenity active status and sync with backend - Smooth UX
  void _toggleAmenityStatus(int index, bool newStatus) async {
    final amenity = amenitiesAdminModule.amenities[index];

    // Optimistic update - update UI immediately for instant feedback
    final optimisticUpdate = AmenityModel(
      id: amenity.id,
      createdByAdminId: amenity.createdByAdminId,
      name: amenity.name,
      bookingType: amenity.bookingType,
      weeklySchedule: amenity.weeklySchedule,
      imagePaths: amenity.imagePaths,
      description: amenity.description,
      capacity: amenity.capacity,
      active: newStatus,
      location: amenity.location,
      hourlyRate: amenity.hourlyRate,
      features: amenity.features,
      createdAt: amenity.createdAt,
      updatedAt: amenity.updatedAt,
    );
    amenitiesAdminModule.updateAmenity(index, optimisticUpdate);

    try {
      if (amenity.id.isNotEmpty) {
        // Update in backend
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
          // Silent background refresh to sync with backend data
          _silentRefreshAmenities();

          /*  ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              content: Text(
                '✅ ${amenity.name} ${newStatus ? 'activated' : 'deactivated'}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );*/
        } else {
          // Revert optimistic update on failure
          amenitiesAdminModule.updateAmenity(index, amenity);
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      amenitiesAdminModule.updateAmenity(index, amenity);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final amenities = amenitiesAdminModule.amenities;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.villa, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amenities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage facilities',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF455A64),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF455A64), Color(0xFF607D8B)],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: _isLoading ? null : _loadAmenitiesFromBackend,
              tooltip: 'Refresh Amenities',
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF607D8B).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _openAdd,
              tooltip: 'Add New Amenity',
            ),
          ),
          const SizedBox(width: 8),
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.villa_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "No Amenities Yet",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add your first facility to get started",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _openAdd,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add First Amenity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF455A64),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF455A64).withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            )
          : SlidableAutoCloseBehavior(
              child: Column(
                children: [
                  // Professional spacing from AppBar
                  const SizedBox(height: 16),

                  // Statistics Row

                  // Amenities List
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 16,
                        ), // Professional spacing
                        itemCount: amenities.length,
                        itemBuilder: (context, index) {
                          final a = amenities[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ), // Space between cards
                            child: Slidable(
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
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                    ),

                                    /// label: 'Edit',
                                  ),
                                  SlidableAction(
                                    onPressed: (context) =>
                                        _deleteAmenity(index),
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,

                                    ///  label: 'Delete',
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Colors.grey.shade50],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Image and Status Header
                                      Container(
                                        height: 160,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              const Color(
                                                0xFF455A64,
                                              ).withOpacity(0.1),
                                              const Color(
                                                0xFF455A64,
                                              ).withOpacity(0.05),
                                            ],
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Background Image
                                            Positioned.fill(
                                              child: a.imagePaths.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                  20,
                                                                ),
                                                            topRight:
                                                                Radius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                      child: _buildAmenityImage(
                                                        a.imagePaths.first,
                                                        width: double.infinity,
                                                        height: 160,
                                                      ),
                                                    )
                                                  : Container(
                                                      decoration: const BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.only(
                                                              topLeft:
                                                                  Radius.circular(
                                                                    20,
                                                                  ),
                                                              topRight:
                                                                  Radius.circular(
                                                                    20,
                                                                  ),
                                                            ),
                                                        gradient:
                                                            LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                Color(
                                                                  0xFF455A64,
                                                                ),
                                                                Color(
                                                                  0xFF607D8B,
                                                                ),
                                                              ],
                                                            ),
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.villa,
                                                          size: 50,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                            // Gradient Overlay
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(20),
                                                        topRight:
                                                            Radius.circular(20),
                                                      ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black.withOpacity(
                                                        0.7,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Status and Image Count
                                            Positioned(
                                              top: 12,
                                              left: 12,
                                              child: Row(
                                                children: [
                                                  // Active Status Badge
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: a.active
                                                          ? Colors.green
                                                                .withOpacity(
                                                                  0.9,
                                                                )
                                                          : Colors.red
                                                                .withOpacity(
                                                                  0.9,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              (a.active
                                                                      ? Colors
                                                                            .green
                                                                      : Colors
                                                                            .red)
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                          blurRadius: 8,
                                                          spreadRadius: 0,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          a.active
                                                              ? Icons
                                                                    .check_circle
                                                              : Icons.cancel,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          a.active
                                                              ? 'Active'
                                                              : 'Inactive',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Image Count and Switch
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Row(
                                                children: [
                                                  if (a.imagePaths.length > 1)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.7),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${a.imagePaths.length} photos',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child:
                                                        _togglingAmenities
                                                            .contains(index)
                                                        ? Transform.scale(
                                                            scale: 0.6,
                                                            child: const CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    Colors.blue,
                                                                  ),
                                                            ),
                                                          )
                                                        : Transform.scale(
                                                            scale: 0.8,
                                                            child: Switch(
                                                              value: a.active,
                                                              onChanged: (v) =>
                                                                  _toggleAmenityStatus(
                                                                    index,
                                                                    v,
                                                                  ),
                                                              activeColor:
                                                                  Colors.green,
                                                              inactiveThumbColor:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Amenity Name
                                            Positioned(
                                              bottom: 12,
                                              left: 12,
                                              right: 12,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    a.name,
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      shadows: [
                                                        Shadow(
                                                          offset: Offset(0, 1),
                                                          blurRadius: 3,
                                                          color: Colors.black26,
                                                        ),
                                                      ],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (a.location.isNotEmpty)
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.location_on,
                                                          size: 14,
                                                          color: Colors.white70,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            a.location,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .white70,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Content Section
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Booking Type and Capacity Row
                                            Row(
                                              children: [
                                                // Booking Type Badge
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        a.bookingType ==
                                                            'shared'
                                                        ? Colors.blue.shade50
                                                        : Colors.orange.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          a.bookingType ==
                                                              'shared'
                                                          ? Colors.blue.shade200
                                                          : Colors
                                                                .orange
                                                                .shade200,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        a.bookingType ==
                                                                'shared'
                                                            ? Icons.group
                                                            : Icons.person,
                                                        size: 16,
                                                        color:
                                                            a.bookingType ==
                                                                'shared'
                                                            ? Colors
                                                                  .blue
                                                                  .shade600
                                                            : Colors
                                                                  .orange
                                                                  .shade600,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            a.bookingType ==
                                                                    'shared'
                                                                ? 'Shared'
                                                                : 'Exclusive',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  a.bookingType ==
                                                                      'shared'
                                                                  ? Colors
                                                                        .blue
                                                                        .shade700
                                                                  : Colors
                                                                        .orange
                                                                        .shade700,
                                                            ),
                                                          ),

                                                          // Debug: Show raw value
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Spacer(),
                                                // Capacity
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.people_outline,
                                                        size: 16,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '${a.capacity}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .grey
                                                              .shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // Description
                                            if (a.description.isNotEmpty)
                                              Text(
                                                a.description,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                  height: 1.4,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (a.description.isNotEmpty)
                                              const SizedBox(height: 12),
                                            // Features Row
                                            if (a.features.isNotEmpty)
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: a.features.take(3).map((
                                                  feature,
                                                ) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF455A64,
                                                      ).withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      feature,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: const Color(
                                                          0xFF455A64,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            if (a.features.isNotEmpty)
                                              const SizedBox(height: 12),
                                            // Price Row
                                            if (a.hourlyRate > 0)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.currency_rupee,
                                                    size: 20,
                                                    color:
                                                        Colors.green.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${a.hourlyRate.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.green.shade600,
                                                    ),
                                                  ),
                                                  Text(
                                                    '/hour',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Helper function to convert image file to base64 string
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

  // New fields for backend compatibility
  String _bookingType = 'shared'; // 'shared' or 'exclusive'
  Map<String, WeeklyDay> _weeklySchedule = {
    'monday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
    'tuesday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
    'wednesday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
    'thursday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
    'friday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
    'saturday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
    'sunday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
  };

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

  // Time picker for weekly schedule
  Future<void> _selectTime(String day, bool isOpenTime) async {
    final currentSchedule = _weeklySchedule[day]!;
    final currentTime = isOpenTime
        ? currentSchedule.open
        : currentSchedule.close;

    // Parse current time
    final timeParts = currentTime.split(':');
    final currentTimeOfDay = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTimeOfDay,
      helpText: isOpenTime ? 'Select Opening Time' : 'Select Closing Time',
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      setState(() {
        _weeklySchedule[day] = WeeklyDay(
          open: isOpenTime ? formattedTime : currentSchedule.open,
          close: isOpenTime ? currentSchedule.close : formattedTime,
          closed: currentSchedule.closed,
        );
      });
    }
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

      // Convert images to base64 strings using compression service
      List<String> imagePaths = [];
      if (_imageFiles.isNotEmpty) {
        final compressedImages =
            await ImageCompressionService.compressMultipleImages(
              imageFiles: _imageFiles,
              maxWidth: 1280,
              maxHeight: 720,
              quality: 70,
              onProgress: (current, total) {
                print('Compressing image $current/$total');
              },
            );
        imagePaths = compressedImages;
      }

      // Convert weekly schedule to JSON format
      final weeklyScheduleJson = _weeklySchedule.map(
        (key, value) => MapEntry(key, value.toJson()),
      );

      // Debug: Print what we're sending to the backend
      print('🔍 ADD: Sending weekly schedule to backend:');
      _weeklySchedule.forEach((day, schedule) {
        print(
          '🔍   $day: ${schedule.open}-${schedule.close} (closed: ${schedule.closed})',
        );
      });

      // Also print the JSON format
      print('🔍 ADD: Weekly schedule JSON format:');
      weeklyScheduleJson.forEach((day, scheduleJson) {
        print('🔍   $day JSON: $scheduleJson');
      });

      // Call backend API to create amenity
      final response = await ApiService.createAmenity(
        createdByAdminId: adminId,
        name: _name.text.trim(),
        description: _description.text.trim(),
        capacity: int.tryParse(_capacity.text.trim()) ?? 0,
        bookingType: _bookingType,
        weeklySchedule: weeklyScheduleJson,
        imagePaths: imagePaths,
        location: _location.text.trim(),
        hourlyRate: double.tryParse(_hourly.text.trim()) ?? 0.0,
        features: features,
        active: _active,
      );

      if (response['success'] == true) {
        // Create local model with backend data
        final backendData = response['data']['amenity'] ?? response['data'];
        final a = AmenityModel.fromJson(backendData);

        Navigator.pop(context, a);
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

              // Booking Type Dropdown
              const Text(
                'Booking Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _bookingType,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'shared',
                        child: Row(
                          children: const [
                            Icon(Icons.group, color: Colors.blue, size: 20),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Shared',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Multiple users can book simultaneously',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'exclusive',
                        child: Row(
                          children: const [
                            Icon(Icons.person, color: Colors.orange, size: 20),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Exclusive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Only one booking at a time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _bookingType = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Weekly Schedule Section
              const Text(
                'Weekly Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children:
                      [
                        'monday',
                        'tuesday',
                        'wednesday',
                        'thursday',
                        'friday',
                        'saturday',
                        'sunday',
                      ].where((day) => _weeklySchedule.containsKey(day)).map((
                        day,
                      ) {
                        final schedule = _weeklySchedule[day]!;
                        final dayName = day[0].toUpperCase() + day.substring(1);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: Text(
                                  dayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: schedule.closed
                                    ? const Text(
                                        'Closed',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          InkWell(
                                            onTap: () => _selectTime(day, true),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                border: Border.all(
                                                  color: Colors.blue.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                schedule.open,
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                            child: Text(
                                              'to',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () =>
                                                _selectTime(day, false),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                border: Border.all(
                                                  color: Colors.blue.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                schedule.close,
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              Switch(
                                value: !schedule.closed,
                                activeColor: Colors.green,
                                onChanged: (value) {
                                  setState(() {
                                    _weeklySchedule[day] = WeeklyDay(
                                      open: schedule.open,
                                      close: schedule.close,
                                      closed: !value,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

  // New fields for backend compatibility
  late String _bookingType;
  late Map<String, WeeklyDay> _weeklySchedule;

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

    // Initialize new fields
    _bookingType = widget.amenity.bookingType;

    // Debug: Print amenity data
    print('🔍 EditAmenityPage - Initializing with amenity:');
    print('   Name: ${widget.amenity.name}');
    print('   Booking Type: ${widget.amenity.bookingType}');
    print('   Weekly Schedule: ${widget.amenity.weeklySchedule}');
    print('   Schedule Keys: ${widget.amenity.weeklySchedule.keys.toList()}');

    // Initialize weekly schedule with proper validation
    if (widget.amenity.weeklySchedule.isNotEmpty) {
      _weeklySchedule = Map<String, WeeklyDay>.from(
        widget.amenity.weeklySchedule,
      );
      print('✅ Using existing weekly schedule');
    } else {
      // Provide default schedule if empty
      _weeklySchedule = {
        'monday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
        'tuesday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
        'wednesday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
        'thursday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
        'friday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
        'saturday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
        'sunday': WeeklyDay(open: '06:00', close: '22:00', closed: false),
      };
      print('⚠️ Using default weekly schedule');
    }

    print(
      '📅 Final weekly schedule for edit: ${_weeklySchedule.keys.toList()}',
    );
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

  // Time picker for weekly schedule in edit mode
  Future<void> _selectTime(String day, bool isOpenTime) async {
    final currentSchedule = _weeklySchedule[day]!;
    final currentTime = isOpenTime
        ? currentSchedule.open
        : currentSchedule.close;

    // Parse current time
    final timeParts = currentTime.split(':');
    final currentTimeOfDay = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTimeOfDay,
      helpText: isOpenTime ? 'Select Opening Time' : 'Select Closing Time',
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      setState(() {
        _weeklySchedule[day] = WeeklyDay(
          open: isOpenTime ? formattedTime : currentSchedule.open,
          close: isOpenTime ? currentSchedule.close : formattedTime,
          closed: currentSchedule.closed,
        );
      });
    }
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

      // Convert new images to base64 using compression service and add to the list
      if (_imageFiles.isNotEmpty) {
        final compressedImages =
            await ImageCompressionService.compressMultipleImages(
              imageFiles: _imageFiles,
              maxWidth: 1280,
              maxHeight: 720,
              quality: 70,
              onProgress: (current, total) {
                print('Compressing image $current/$total for update');
              },
            );
        allImagePaths.addAll(compressedImages);
      }

      if (widget.amenity.id.isNotEmpty) {
        // Update in backend
        final adminId = await AdminSessionService.getAdminId();
        if (adminId == null) {
          throw Exception('Admin not logged in');
        }

        // Convert weekly schedule to JSON format
        final weeklyScheduleJson = _weeklySchedule.map(
          (key, value) => MapEntry(key, value.toJson()),
        );

        // Debug: Print what we're sending to the backend
        print('🔍 UPDATE: Sending weekly schedule to backend:');
        _weeklySchedule.forEach((day, schedule) {
          print(
            '🔍   $day: ${schedule.open}-${schedule.close} (closed: ${schedule.closed})',
          );
        });

        // Also print the JSON format
        print('🔍 UPDATE: Weekly schedule JSON format:');
        weeklyScheduleJson.forEach((day, scheduleJson) {
          print('🔍   $day JSON: $scheduleJson');
        });

        final response = await ApiService.updateAmenity(
          adminId: adminId,
          amenityId: widget.amenity.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          capacity: int.parse(_capacity.text),
          bookingType: _bookingType,
          weeklySchedule: weeklyScheduleJson,
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

              // Booking Type Dropdown for Edit
              const Text(
                'Booking Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _bookingType,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'shared',
                        child: Row(
                          children: const [
                            Icon(Icons.group, color: Colors.blue, size: 20),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Shared',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Multiple users can book simultaneously',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'exclusive',
                        child: Row(
                          children: const [
                            Icon(Icons.person, color: Colors.orange, size: 20),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Exclusive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Only one booking at a time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _bookingType = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Weekly Schedule Section for Edit
              const Text(
                'Weekly Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children:
                      [
                        'monday',
                        'tuesday',
                        'wednesday',
                        'thursday',
                        'friday',
                        'saturday',
                        'sunday',
                      ].where((day) => _weeklySchedule.containsKey(day)).map((
                        day,
                      ) {
                        final schedule = _weeklySchedule[day]!;
                        final dayName = day[0].toUpperCase() + day.substring(1);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: Text(
                                  dayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: schedule.closed
                                    ? const Text(
                                        'Closed',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          InkWell(
                                            onTap: () => _selectTime(day, true),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                border: Border.all(
                                                  color: Colors.blue.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                schedule.open,
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                            child: Text(
                                              'to',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () =>
                                                _selectTime(day, false),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                border: Border.all(
                                                  color: Colors.blue.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                schedule.close,
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              Switch(
                                value: !schedule.closed,
                                activeColor: Colors.green,
                                onChanged: (value) {
                                  setState(() {
                                    _weeklySchedule[day] = WeeklyDay(
                                      open: schedule.open,
                                      close: schedule.close,
                                      closed: !value,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
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
