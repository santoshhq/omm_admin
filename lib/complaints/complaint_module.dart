class Complaint {
  final String title;
  final String description;
  final String reporter;
  final DateTime createdAt;

  Complaint({
    required this.title,
    required this.description,
    this.reporter = 'Anonymous',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
