class Bill {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final DateTime createdAt;

  Bill({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

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
