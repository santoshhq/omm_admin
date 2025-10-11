class Bill {
  final String id;
  final String billTitle;
  final String billDescription;
  final String
  category; // Should match enum: maintenance, security-services, cleaning, amenities
  final double billAmount;
  final String upiId;
  final DateTime dueDate;
  final String createdByAdminId;
  final bool isPaid; // optional, default false
  final DateTime createdAt;
  final DateTime updatedAt;

  Bill({
    required this.id,
    required this.billTitle,
    required this.billDescription,
    required this.category,
    required this.billAmount,
    required this.upiId,
    required this.dueDate,
    required this.createdByAdminId,
    this.isPaid = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Optional: factory method to parse from JSON (from backend)
  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'] ?? '',
      billTitle: json['billtitle'] ?? '',
      billDescription: json['billdescription'] ?? '',
      category: json['category'] ?? '',
      billAmount: (json['billamount'] ?? 0).toDouble(),
      upiId: json['upiId'] ?? '',
      dueDate: json['duedate'] != null
          ? DateTime.parse(json['duedate'])
          : DateTime.now(),
      createdByAdminId: json['createdByAdminId'] is Map
          ? json['createdByAdminId']['_id'] ?? ''
          : json['createdByAdminId'] ?? '',
      isPaid: json['isPaid'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Optional: toJson for sending to backend
  Map<String, dynamic> toJson() {
    return {
      'billtitle': billTitle,
      'billdescription': billDescription,
      'category': category,
      'billamount': billAmount,
      'upiId': upiId,
      'duedate': dueDate.toIso8601String(),
      'createdByAdminId': createdByAdminId,
      'isPaid': isPaid,
    };
  }

  // 🔹 Static list of months
  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // 🔹 Helper to get current month name
  static String getCurrentMonth() {
    final now = DateTime.now();
    return months[now.month - 1]; // month index starts from 1
  }
}
