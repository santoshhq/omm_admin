// Module contains the Announcement data model used by the widget.

class Announcement {
  final String title;
  final String description;
  final String priority;
  final DateTime createdAt;
  bool isActive;

  Announcement({
    required this.title,
    required this.description,
    this.priority = 'Medium',
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Announcement copyWith({
    String? title,
    String? description,
    String? priority,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Announcement(
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
