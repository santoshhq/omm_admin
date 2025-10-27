import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/admin_session_service.dart';

class Donation {
  final String id;
  final String transactionId;
  final double amount;
  final String upiApp;
  final String status;
  final User user;

  const Donation({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.upiApp,
    required this.status,
    required this.user,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['_id']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      upiApp: json['upiApp']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      user: User.fromJson(json['userId'] ?? {}),
    );
  }
}

class User {
  final String firstName;
  final String lastName;
  final String flatNo;
  final String floor;
  final String mobile;

  const User({
    required this.firstName,
    required this.lastName,
    required this.flatNo,
    required this.floor,
    required this.mobile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      flatNo: json['flatNo']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
    );
  }

  String get displayName => '$firstName $lastName'.trim();
}

class ShowDonationsPage extends StatefulWidget {
  final String eventId;
  final String eventName;
  final VoidCallback? onDonationStatusChanged;

  const ShowDonationsPage({
    super.key,
    required this.eventId,
    required this.eventName,
    this.onDonationStatusChanged,
  });

  @override
  State<ShowDonationsPage> createState() => _ShowDonationsPageState();
}

class _ShowDonationsPageState extends State<ShowDonationsPage> {
  List<Donation> donations = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Safe setState that checks if widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  Future<void> _loadDonations() async {
    if (_isDisposed) return;

    try {
      _safeSetState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception('Admin session expired. Please login again.');
      }

      final url = Uri.parse(
        '${ApiService.donationsBaseUrl}/event/${widget.eventId}/$adminId',
      );

      print('🔍 Fetching donations from: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (_isDisposed || !mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final donationsData = responseData['data'] as List<dynamic>;
          final loadedDonations = donationsData
              .map((json) => Donation.fromJson(json))
              .toList();

          // Sort donations: Pending first, then Accepted, then Rejected
          loadedDonations.sort((a, b) {
            final statusOrder = {'pending': 0, 'accepted': 1, 'rejected': 2};
            final aOrder = statusOrder[a.status.toLowerCase()] ?? 3;
            final bOrder = statusOrder[b.status.toLowerCase()] ?? 3;
            return aOrder.compareTo(bOrder);
          });

          _safeSetState(() {
            donations = loadedDonations;
            _isLoading = false;
          });
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to load donations',
          );
        }
      } else {
        throw Exception('Failed to load donations: ${response.statusCode}');
      }
    } catch (e) {
      _safeSetState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDonationStatus(
    String donationId,
    String newStatus,
  ) async {
    try {
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception('Admin session expired. Please login again.');
      }

      final result = await ApiService.updateDonationStatus(
        donationId: donationId,
        adminId: adminId,
        status: newStatus,
      );
      if (result['success'] == true) {
        // Update local donation status
        _safeSetState(() {
          final index = donations.indexWhere((d) => d.id == donationId);
          if (index != -1) {
            donations[index] = Donation(
              id: donations[index].id,
              transactionId: donations[index].transactionId,
              amount: donations[index].amount,
              upiApp: donations[index].upiApp,
              status: newStatus,
              user: donations[index].user,
            );
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Donation ${newStatus.toLowerCase()} successfully'),
              backgroundColor: newStatus == 'Accepted'
                  ? Colors.green
                  : Colors.red,
            ),
          );
        }

        // Notify parent widget that donation status changed
        widget.onDonationStatusChanged?.call();
      } else {
        throw Exception(result['message'] ?? 'Failed to update donation');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update donation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Donations - ${widget.eventName}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade400),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadDonations,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (donations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No donations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDonations,
      color: Colors.blue.shade600,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: donations.length,
        itemBuilder: (context, index) {
          final donation = donations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Row
                  Row(
                    children: [
                      // User Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // User Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              donation.user.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.apartment,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Flat: ${donation.user.flatNo}, Floor: ${donation.user.floor}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  donation.user.mobile,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            donation.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(donation.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          donation.status,
                          style: TextStyle(
                            color: _getStatusColor(donation.status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Transaction Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transaction ID:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              donation.transactionId,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment App:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              donation.upiApp,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '₹${donation.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons (only show for pending donations)
                  if (donation.status.toLowerCase() == 'pending') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _updateDonationStatus(donation.id, 'Accepted'),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _updateDonationStatus(donation.id, 'Rejected'),
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
