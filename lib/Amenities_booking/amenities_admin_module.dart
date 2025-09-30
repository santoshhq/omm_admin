import 'package:flutter/material.dart';

class AmenityModel {
  String id;
  String name;
  List<String> imagePaths; // Changed to support multiple images
  String description; // Added description field
  int capacity;
  bool active;
  String location;
  double hourlyRate;
  List<String> features;

  AmenityModel({
    required this.id,
    required this.name,
    required this.imagePaths,
    required this.description,
    required this.capacity,
    this.active = true,
    this.location = '',
    this.hourlyRate = 0.0,
    this.features = const [],
  });

  // Helper getter for backward compatibility
  String get imagePath => imagePaths.isNotEmpty ? imagePaths.first : '';
}

class AmenitiesAdminModule extends ChangeNotifier {
  final List<AmenityModel> amenities = [];

  void addAmenity(AmenityModel a) {
    amenities.add(a);
    notifyListeners();
  }

  void updateAmenity(int index, AmenityModel a) {
    amenities[index] = a;
    notifyListeners();
  }

  void removeAmenity(int index) {
    amenities.removeAt(index);
    notifyListeners();
  }

  void clearAmenities() {
    amenities.clear();
    notifyListeners();
  }
}

final AmenitiesAdminModule amenitiesAdminModule = AmenitiesAdminModule();
