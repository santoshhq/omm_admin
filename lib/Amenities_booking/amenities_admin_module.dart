import 'package:flutter/material.dart';

class AmenityModel {
  String id;
  String createdByAdminId;
  String name;
  String bookingType; // 'shared' or 'exclusive'
  Map<String, WeeklyDay> weeklySchedule; // Weekly schedule
  List<String> imagePaths;
  String description;
  int capacity;
  bool active;
  String location;
  double hourlyRate;
  List<String> features;
  DateTime? createdAt;
  DateTime? updatedAt;

  AmenityModel({
    required this.id,
    this.createdByAdminId = '',
    required this.name,
    this.bookingType = 'shared',
    Map<String, WeeklyDay>? weeklySchedule,
    required this.imagePaths,
    required this.description,
    required this.capacity,
    this.active = true,
    this.location = '',
    this.hourlyRate = 0.0,
    this.features = const [],
    this.createdAt,
    this.updatedAt,
  }) : weeklySchedule = weeklySchedule ?? {};

  // Helper getter for backward compatibility
  String get imagePath => imagePaths.isNotEmpty ? imagePaths.first : '';

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() => {
    'name': name,
    'bookingType': bookingType,
    'weeklySchedule': weeklySchedule.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'imagePaths': imagePaths,
    'description': description,
    'capacity': capacity,
    'location': location,
    'hourlyRate': hourlyRate,
    'features': features,
    'active': active,
  };

  // Create from JSON response
  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    Map<String, WeeklyDay> schedule = {};
    if (json['weeklySchedule'] != null) {
      final scheduleData = json['weeklySchedule'] as Map<String, dynamic>;
      schedule = scheduleData.map(
        (key, value) =>
            MapEntry(key, WeeklyDay.fromJson(value as Map<String, dynamic>)),
      );
    }

    // Only use the schedule data from the JSON, don't provide defaults here
    // Defaults should only be provided in the UI layer when creating new amenities

    // Handle MongoDB ObjectId format and regular string format
    String parseId(dynamic idField) {
      if (idField == null) return '';
      if (idField is String) return idField;
      if (idField is Map && idField.containsKey('\$oid')) {
        return idField['\$oid'].toString();
      }
      return idField.toString();
    }

    // Handle MongoDB date format
    DateTime? parseDate(dynamic dateField) {
      if (dateField == null) return null;
      if (dateField is String) return DateTime.parse(dateField);
      if (dateField is Map && dateField.containsKey('\$date')) {
        return DateTime.parse(dateField['\$date'].toString());
      }
      return null;
    }

    // Handle createdByAdminId (could be ObjectId or string)
    String createdByAdminId = '';
    if (json['createdByAdminId'] != null) {
      createdByAdminId = parseId(json['createdByAdminId']);
    }

    final bookingType = json['bookingType'] ?? 'shared';

    return AmenityModel(
      id: parseId(json['_id'] ?? json['id']),
      createdByAdminId: createdByAdminId,
      name: json['name']?.toString() ?? '',
      bookingType: bookingType.toString(),
      weeklySchedule: schedule,
      imagePaths: List<String>.from(json['images'] ?? json['imagePaths'] ?? []),
      description: json['description']?.toString() ?? '',
      capacity: (json['capacity'] ?? 0) is int
          ? json['capacity']
          : int.tryParse(json['capacity'].toString()) ?? 0,
      active: json['active'] ?? true,
      location: json['location']?.toString() ?? '',
      hourlyRate: (json['hourlyRate'] ?? 0.0) is double
          ? json['hourlyRate']
          : double.tryParse(json['hourlyRate'].toString()) ?? 0.0,
      features: List<String>.from(json['features'] ?? []),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

// Weekly Day Schedule Model
class WeeklyDay {
  String open; // HH:mm format
  String close; // HH:mm format
  bool closed; // true if closed

  WeeklyDay({required this.open, required this.close, required this.closed});

  Map<String, dynamic> toJson() => {
    'open': open,
    'close': close,
    'closed': closed,
  };

  factory WeeklyDay.fromJson(Map<String, dynamic> json) => WeeklyDay(
    open: json['open'] ?? '09:00',
    close: json['close'] ?? '18:00',
    closed: json['closed'] ?? false,
  );
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
