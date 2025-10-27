import 'package:flutter/material.dart';

// lib/models/security_guard_model.dart

class SecurityGuardModel {
  String? id;
  String adminId;
  String firstName;
  String lastName;
  int age;
  String mobile;
  String assignedGate;
  String gender;
  String? imageUrl;
  String password; // Added password field

  SecurityGuardModel({
    this.id,
    required this.adminId,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.mobile,
    required this.assignedGate,
    required this.gender,
    this.imageUrl,
    required this.password, // Added password parameter
  });

  factory SecurityGuardModel.fromJson(Map<String, dynamic> json) {
    return SecurityGuardModel(
      id: json['_id'],
      adminId: json['adminId'] is Map
          ? json['adminId']['_id']
          : json['adminId'],

      firstName: json['firstname'],
      lastName: json['lastname'],
      age: json['age'],
      mobile: json['mobilenumber'],
      assignedGate: json['assigngates'],
      gender: json['gender'],
      imageUrl: json['guardimage'],
      password: json['password'] ?? '', // Added password from JSON
    );
  }

  Map<String, dynamic> toJson(String adminId) {
    return {
      "adminId": adminId,
      "guardimage": imageUrl,
      "firstname": firstName,
      "lastname": lastName,
      "mobilenumber": mobile,
      "age": age,
      "assigngates": assignedGate,
      "gender": gender.toLowerCase(),
      "password": password, // Added password to JSON
    };
  }
}

class MaidModel {
  String id; // MongoDB _id
  String adminId;
  String firstName;
  String lastName;
  int age;
  List<String> assignFloors;
  String timings;
  String? mobile;
  String? imageUrl;
  String gender;

  MaidModel({
    required this.id,
    required this.adminId,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.assignFloors,
    required this.timings,
    this.mobile,
    this.imageUrl,
    required this.gender,
  });

  // Convert JSON to MaidModel
  factory MaidModel.fromJson(Map<String, dynamic> json) {
    return MaidModel(
      id: json['_id'] ?? '',
      adminId: json['adminId'] ?? '',
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      age: json['age'] ?? 0,
      assignFloors: List<String>.from(json['assignfloors'] ?? []),
      timings: json['timings'] ?? '',
      mobile: json['mobilenumber'],
      imageUrl: json['personimage'],
      gender: json['gender'] ?? 'other',
    );
  }

  // Convert MaidModel to JSON (for POST/PUT requests)
  Map<String, dynamic> toJson() {
    return {
      'adminId': adminId,
      'firstname': firstName,
      'lastname': lastName,
      'age': age,
      'assignfloors': assignFloors,
      'timings': timings,
      if (mobile != null) 'mobilenumber': mobile,
      if (imageUrl != null) 'personimage': imageUrl,
      'gender': gender,
    };
  }
}

// Dummy data for testing
List<SecurityGuardModel> dummySecurityGuards = [
  /* SecurityGuardModel(
    firstName: "John",
    lastName: "Doe",
    age: 30,
    mobile: "9876543210",
    assignedGate: "G1",
    gender: 'Male',
  ),
  SecurityGuardModel(
    firstName: "Jane",
    lastName: "Smith",
    age: 28,
    mobile: "9876543211",
    assignedGate: "G2",
    gender: 'Female',
  ),*/
];

List<MaidModel> dummyMaids = [
  /* MaidModel(
    firstName: 'Sita',
    lastName: 'Kumari',
    age: 32,
    workingFlats: 'Flats: 101,102',
    timings: '9am-5pm',
    mobile: '9876500000',
    gender: 'Female',*/
  //),
];

class SecurityModuleModel extends ChangeNotifier {
  final List<SecurityGuardModel> securityGuards = List.from(
    dummySecurityGuards,
  );
  final List<MaidModel> maids = List.from(dummyMaids);

  void addGuard(SecurityGuardModel g) {
    securityGuards.add(g);
    notifyListeners();
  }

  void addMaid(MaidModel m) {
    maids.add(m);
    notifyListeners();
  }
}

final SecurityModuleModel securityModule = SecurityModuleModel();
