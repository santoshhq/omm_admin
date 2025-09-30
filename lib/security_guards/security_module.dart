import 'package:flutter/material.dart';

class SecurityGuardModel {
  String firstName;
  String lastName;
  int age;
  String mobile;
  String assignedGate;
  String? imageUrl;
  String gender;

  SecurityGuardModel({
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.mobile,
    required this.assignedGate,
    this.imageUrl,
    required this.gender,
  });
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
  SecurityGuardModel(
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
  ),
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
