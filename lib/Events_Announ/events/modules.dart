class Festival {
  final String? id;
  final String? adminId;
  final String name;
  final String description;
  final double targetAmount;
  final double collectedAmount;
  final List<Donation> donations;
  final List<String>
  imagePaths; // Changed to support multiple images like amenities
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<String> eventDetails;
  final String? upiId;
  final int totalDonors;
  final double averageDonation;

  const Festival({
    this.id,
    this.adminId,
    required this.name,
    required this.description,
    required this.targetAmount,
    this.collectedAmount = 0,
    this.donations = const [],
    this.imagePaths = const [],
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.eventDetails = const [],
    this.upiId,
    this.totalDonors = 0,
    this.averageDonation = 0.0,
  });

  // Helper getter for backward compatibility
  String? get imageUrl => imagePaths.isNotEmpty ? imagePaths.first : null;

  double get progress =>
      targetAmount <= 0 ? 0 : (collectedAmount / targetAmount).clamp(0, 1);

  Festival copyWith({
    String? id,
    String? adminId,
    String? name,
    String? description,
    double? targetAmount,
    double? collectedAmount,
    List<Donation>? donations,
    List<String>? imagePaths,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    List<String>? eventDetails,
    String? upiId,
    int? totalDonors,
    double? averageDonation,
  }) {
    return Festival(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      donations: donations ?? this.donations,
      imagePaths: imagePaths ?? this.imagePaths,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      eventDetails: eventDetails ?? this.eventDetails,
      upiId: upiId ?? this.upiId,
      totalDonors: totalDonors ?? this.totalDonors,
      averageDonation: averageDonation ?? this.averageDonation,
    );
  }

  /// Helper method to extract images from various formats
  static List<String> _getImagePaths(Map<String, dynamic> json) {
    // Check for 'images' array first (backend format)
    final images = json['images'];
    if (images is List && images.isNotEmpty) {
      return images
          .where((img) => img is String && img.isNotEmpty)
          .cast<String>()
          .toList();
    }

    // Check for 'imagePaths' array
    final imagePaths = json['imagePaths'];
    if (imagePaths is List && imagePaths.isNotEmpty) {
      return imagePaths
          .where((img) => img is String && img.isNotEmpty)
          .cast<String>()
          .toList();
    }

    // Check for single image formats
    final singleImage =
        json['image']?.toString() ?? json['imageUrl']?.toString();
    if (singleImage != null && singleImage.isNotEmpty) {
      return [singleImage];
    }

    return [];
  }

  factory Festival.fromJson(Map<String, dynamic> json) {
    final adminSource = json['adminId'];
    String? adminId;
    if (adminSource is Map<String, dynamic>) {
      adminId = adminSource['_id']?.toString() ?? adminSource['id']?.toString();
    } else if (adminSource != null) {
      adminId = adminSource.toString();
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value.toLocal();
      try {
        return DateTime.parse(value.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    final rawDonations = json['donations'];
    final donations = rawDonations is List
        ? rawDonations
              .whereType<Map<String, dynamic>>()
              .map(Donation.fromJson)
              .toList()
        : const <Donation>[];

    final rawDetails = json['eventdetails'] ?? json['eventDetails'];
    final details = rawDetails is List
        ? rawDetails
              .map((detail) => detail?.toString() ?? '')
              .where((detail) => detail.trim().isNotEmpty)
              .toList()
        : const <String>[];

    final statusRaw = json['status'];
    final bool isActive;
    if (statusRaw is bool) {
      isActive = statusRaw;
    } else if (statusRaw is num) {
      isActive = statusRaw != 0;
    } else {
      isActive = statusRaw?.toString().toLowerCase() == 'true';
    }

    return Festival(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      adminId: adminId,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      targetAmount: _parseDouble(
        json['targetamount'] ?? json['targetAmount'] ?? 0,
      ),
      collectedAmount: _parseDouble(
        json['collectedamount'] ?? json['collectedAmount'] ?? 0,
      ),
      donations: donations,
      imagePaths: _getImagePaths(json),
      startDate: parseDate(json['startdate'] ?? json['startDate']),
      endDate: parseDate(json['enddate'] ?? json['endDate']),
      isActive: isActive,
      eventDetails: details,
      upiId: json['upiId']?.toString(),
      totalDonors: _parseInt(json['totalDonors'] ?? 0),
      averageDonation: _parseDouble(json['averageDonation'] ?? 0),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'targetamount': targetAmount,
      'collectedamount': collectedAmount,
      'eventdetails': eventDetails,
      'status': isActive,
      'images': imagePaths,
      'adminId': adminId,
      'startdate': startDate?.toUtc().toIso8601String(),
      'enddate': endDate?.toUtc().toIso8601String(),
      'donations': donations.map((donation) => donation.toJson()).toList(),
      'upiId': upiId,
      'totalDonors': totalDonors,
      'averageDonation': averageDonation,
    };

    data.removeWhere((key, value) => value == null);

    if (includeId && id != null) {
      data['_id'] = id;
    }

    return data;
  }
}

class Donation {
  final String? id;
  final String? userId;
  final double amount;
  final DateTime? date;
  final String? donorName;
  final String? donorFlat;
  final String status; // 'pending', 'accepted', 'rejected'

  const Donation({
    this.id,
    this.userId,
    required this.amount,
    this.date,
    this.donorName,
    this.donorFlat,
    this.status = 'pending',
  });

  String get displayName => donorName?.trim().isNotEmpty == true
      ? donorName!.trim()
      : 'Anonymous Donor';

  factory Donation.fromJson(Map<String, dynamic> json) {
    final userRaw = json['userId'];
    String? userId;
    String? donorName;
    String? donorFlat;

    if (userRaw is Map<String, dynamic>) {
      userId = userRaw['_id']?.toString() ?? userRaw['id']?.toString();

      final name = userRaw['name']?.toString();
      final firstName = userRaw['firstName']?.toString();
      final lastName = userRaw['lastName']?.toString();

      if (name != null && name.trim().isNotEmpty) {
        donorName = name.trim();
      } else {
        final parts = [firstName, lastName]
            .where((part) => part != null && part.trim().isNotEmpty)
            .map((part) => part!.trim())
            .toList();
        if (parts.isNotEmpty) {
          donorName = parts.join(' ');
        }
      }

      donorFlat = userRaw['flatNo']?.toString() ?? userRaw['flat']?.toString();
    } else if (userRaw != null) {
      userId = userRaw.toString();
    }

    return Donation(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      userId: userId,
      amount: _parseDouble(json['amount']),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())?.toLocal()
          : null,
      donorName: donorName,
      donorFlat: donorFlat,
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'userId': userId,
      'amount': amount,
      'date': date?.toUtc().toIso8601String(),
      'donorName': donorName,
      'donorFlat': donorFlat,
      'status': status,
    };

    data.removeWhere((key, value) => value == null);

    if (id != null) {
      data['_id'] = id;
    }

    return data;
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
