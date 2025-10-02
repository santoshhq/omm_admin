import 'package:flutter/material.dart';

enum ComplaintStatus {
  pending('Pending'),
  unsolved('Unsolved'),
  solved('Solved');

  const ComplaintStatus(this.displayName);
  final String displayName;

  Color get color {
    switch (this) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.unsolved:
        return Colors.red;
      case ComplaintStatus.solved:
        return Colors.green;
    }
  }
}

class User {
  final String? id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? mobile;

  User({
    this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.mobile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'],
      email: json['email'],
      mobile: json['mobile'],
    );
  }
}

class Complaint {
  final String? id;
  final String? userId;
  final String name;
  final String flatNo;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdByadmin;
  ComplaintStatus status;
  final User? userDetails;
  final User? adminDetails;

  Complaint({
    this.id,
    this.userId,
    required this.name,
    required this.flatNo,
    required this.title,
    required this.description,
    DateTime? createdAt,
    this.updatedAt,
    this.createdByadmin,
    this.status = ComplaintStatus.pending,
    this.userDetails,
    this.adminDetails,
  }) : createdAt = createdAt ?? DateTime.now();

  // For backward compatibility with existing code
  String get reporter => '$name (Flat $flatNo)';

  factory Complaint.fromJson(Map<String, dynamic> json) {
    try {
      // Parse status
      ComplaintStatus status = ComplaintStatus.pending;
      if (json['status'] != null) {
        switch (json['status'].toString().toLowerCase()) {
          case 'pending':
            status = ComplaintStatus.pending;
            break;
          case 'solved':
            status = ComplaintStatus.solved;
            break;
          case 'unsolved':
            status = ComplaintStatus.unsolved;
            break;
        }
      }

      // Parse dates
      DateTime createdAt = DateTime.now();
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt']);
      } else if (json['timestamp'] != null) {
        createdAt = DateTime.parse(json['timestamp']);
      }

      DateTime? updatedAt;
      if (json['updatedAt'] != null) {
        updatedAt = DateTime.parse(json['updatedAt']);
      }

      // Parse user details if populated
      User? userDetails;
      if (json['userId'] != null && json['userId'] is Map<String, dynamic>) {
        userDetails = User.fromJson(json['userId']);
      }

      // Parse admin details if populated
      User? adminDetails;
      if (json['createdByadmin'] != null &&
          json['createdByadmin'] is Map<String, dynamic>) {
        adminDetails = User.fromJson(json['createdByadmin']);
      }

      return Complaint(
        id: json['_id'] ?? json['id'],
        userId: json['userId'] is String
            ? json['userId']
            : json['userId']?['_id'],
        name: json['name'] ?? '',
        flatNo: json['flatNo'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdByadmin: json['createdByadmin'] is String
            ? json['createdByadmin']
            : json['createdByadmin']?['_id'],
        status: status,
        userDetails: userDetails,
        adminDetails: adminDetails,
      );
    } catch (e) {
      print('❌ Complaint.fromJson Error: $e');
      print('❌ JSON was: $json');
      // Return a fallback complaint with minimal data
      return Complaint(
        id: json['_id'] ?? json['id'],
        name: json['name'] ?? 'Unknown',
        flatNo: json['flatNo'] ?? 'N/A',
        title: json['title'] ?? 'Unknown Title',
        description: json['description'] ?? 'No description available',
      );
    }
  }

  Complaint copyWith({
    String? id,
    String? userId,
    String? name,
    String? flatNo,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByadmin,
    ComplaintStatus? status,
    User? userDetails,
    User? adminDetails,
  }) {
    return Complaint(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      flatNo: flatNo ?? this.flatNo,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByadmin: createdByadmin ?? this.createdByadmin,
      status: status ?? this.status,
      userDetails: userDetails ?? this.userDetails,
      adminDetails: adminDetails ?? this.adminDetails,
    );
  }
}
