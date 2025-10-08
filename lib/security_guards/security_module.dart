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
  });

  factory SecurityGuardModel.fromJson(Map<String, dynamic> json) {
    return SecurityGuardModel(
      id: json['_id'],
      adminId: json['adminId'] ?? '',
      firstName: json['firstname'],
      lastName: json['lastname'],
      age: json['age'],
      mobile: json['mobilenumber'],
      assignedGate: json['assigngates'],
      gender: json['gender'],
      imageUrl: json['guardimage'],
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
    };
  }
}

class MaidModel {
  String firstName;
  String lastName;
  int age;
  String workingFlats; // textual description
  String timings;
  String? mobile;
  String? imageUrl;
  String gender;

  MaidModel({
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.workingFlats,
    required this.timings,
    this.mobile,
    this.imageUrl,
    required this.gender,
  });
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
  MaidModel(
    firstName: 'Sita',
    lastName: 'Kumari',
    age: 32,
    workingFlats: 'Flats: 101,102',
    timings: '9am-5pm',
    mobile: '9876500000',
    gender: 'Female',
  ),
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
