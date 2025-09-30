class UserInfo {
  final String flatNo;
  final String name;

  UserInfo({required this.flatNo, required this.name});
}

class Donation {
  final UserInfo user;
  final double amount;

  Donation({required this.user, required this.amount});
}

class Festival {
  final String name;
  final String description;
  final double targetAmount;
  double collectedAmount;
  final List<Donation> donations;
  final String? imageUrl;
  final DateTime? startDate; // 👈 add this
  DateTime? endDate;
  bool isActive;
  final List<String> eventDetails; // 👈 List of event details
  Festival({
    required this.name,
    required this.description,
    required this.targetAmount,
    this.collectedAmount = 0,
    this.donations = const [],
    this.imageUrl,
    this.startDate,
    this.endDate, // 👈 add this
    this.isActive = true,
    this.eventDetails =
        const [], // 👈 List of event details with default empty list
  });
}
