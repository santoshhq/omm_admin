// Module contains the Announcement data model used by the widget.

class Announcement {
  final String? id;
  final String title;
  final String description;
  final String priority;
  final String? adminId;
  final DateTime createdDate;
  final DateTime? updatedDate;
  bool isActive;

  Announcement({
    this.id,
    required this.title,
    required this.description,
    this.priority = 'Medium',
    this.adminId,
    DateTime? createdDate,
    this.updatedDate,
    this.isActive = true,
  }) : createdDate = createdDate ?? DateTime.now();

  // Factory constructor to create from JSON (matching backend response)
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium',
      adminId: json['adminId']?.toString(),
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
      updatedDate: json['updatedDate'] != null
          ? DateTime.parse(json['updatedDate'])
          : null,
      isActive: json['status'] == 'active' || json['isActive'] == true,
    );
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'adminId': adminId,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? adminId,
    DateTime? createdDate,
    DateTime? updatedDate,
    bool? isActive,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      adminId: adminId ?? this.adminId,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Announcement(id: $id, title: $title, priority: $priority, isActive: $isActive)';
  }
}
