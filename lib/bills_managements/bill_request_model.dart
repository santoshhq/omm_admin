class BillRequest {
  final String id;
  final UserProfile user;
  final String billId;
  final String transactionId;
  final String paymentApp;
  final String paymentAppName;
  final double? amount; // Payment amount
  String status; // 'Pending', 'Accepted', 'Rejected'
  final DateTime createdAt;
  final DateTime updatedAt;

  BillRequest({
    required this.id,
    required this.user,
    required this.billId,
    required this.transactionId,
    required this.paymentApp,
    required this.paymentAppName,
    this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BillRequest.fromJson(Map<String, dynamic> json) {
    return BillRequest(
      id: json['_id'] ?? '',
      user: UserProfile.fromJson(json['userId'] ?? {}),
      billId: json['billId'] is Map
          ? json['billId']['_id'] ?? ''
          : (json['billId'] ?? ''),
      transactionId: json['transactionId'] ?? '',
      paymentApp: json['paymentapp'] ?? '',
      paymentAppName: json['PaymentAppName'] ?? '',
      amount: json['billId'] is Map
          ? (json['billId']['billamount'] as num?)?.toDouble()
          : null,
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String flatNo;
  final String floorNo;
  final String mobile;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.flatNo,
    required this.floorNo,
    required this.mobile,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      flatNo: json['flatNo'] ?? '',
      floorNo: json['floor'] ?? '', // Note: backend uses 'floor'
      mobile: json['mobile'] ?? '',
    );
  }
}
