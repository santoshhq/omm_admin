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
  }) : weeklySchedule =
           weeklySchedule ??
           {
             'monday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
             'tuesday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
             'wednesday': WeeklyDay(
               open: '09:00',
               close: '18:00',
               closed: false,
             ),
             'thursday': WeeklyDay(
               open: '09:00',
               close: '18:00',
               closed: false,
             ),
             'friday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
             'saturday': WeeklyDay(
               open: '09:00',
               close: '18:00',
               closed: false,
             ),
             'sunday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
           };

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

    // If schedule is empty, provide default schedule
    if (schedule.isEmpty) {
      schedule = {
        'monday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
        'tuesday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
        'wednesday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
        'thursday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
        'friday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
        'saturday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
        'sunday': WeeklyDay(open: '09:00', close: '18:00', closed: false),
      };
    }

    return AmenityModel(
      id: json['id'] ?? json['_id'] ?? '',
      createdByAdminId: json['createdByAdminId'] ?? '',
      name: json['name'] ?? '',
      bookingType: json['bookingType'] ?? 'shared',
      weeklySchedule: schedule,
      imagePaths: List<String>.from(json['images'] ?? json['imagePaths'] ?? []),
      description: json['description'] ?? '',
      capacity: json['capacity'] ?? 0,
      active: json['active'] ?? true,
      location: json['location'] ?? '',
      hourlyRate: (json['hourlyRate'] ?? 0.0).toDouble(),
      features: List<String>.from(json['features'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
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
