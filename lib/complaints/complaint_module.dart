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

class Complaint {
  final String title;
  final String description;
  final String reporter;
  final DateTime createdAt;
  ComplaintStatus status;

  Complaint({
    required this.title,
    required this.description,
    this.reporter = 'Anonymous',
    DateTime? createdAt,
    this.status = ComplaintStatus.pending,
  }) : createdAt = createdAt ?? DateTime.now();

  Complaint copyWith({
    String? title,
    String? description,
    String? reporter,
    DateTime? createdAt,
    ComplaintStatus? status,
  }) {
    return Complaint(
      title: title ?? this.title,
      description: description ?? this.description,
      reporter: reporter ?? this.reporter,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
