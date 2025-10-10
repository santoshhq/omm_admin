import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:omm_admin/config/api_config.dart';

// ------------------- BOOKING SERVICE -------------------

class BookingService {
  // 📦 Fetch all bookings (Admin)
  static Future<List<Map<String, dynamic>>> fetchBookings() async {
    try {
      print("🌐 Fetching from: ${ApiService.fetchBookings}");
      final response = await http.get(Uri.parse(ApiService.fetchBookings));
      print("📦 Status: ${response.statusCode}");
      print("📦 Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        } else if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else {
          print("⚠️ Unexpected response format");
          return [];
        }
      } else {
        print("❌ Failed to fetch bookings: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("BookingService.fetchBookings error: $e");
      return [];
    }
  }

  // ✅ Approve a booking
  static Future<bool> approveBooking(String bookingId) async {
    try {
      final url = ApiService.updateBookingStatus(bookingId);
      print("🟢 Approving booking at: $url");
      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": "accepted"}),
      );
      print("📦 Approve response: ${response.statusCode}, ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("BookingService.approveBooking error: $e");
      return false;
    }
  }

  // ❌ Reject a booking
  static Future<bool> rejectBooking(String bookingId) async {
    try {
      final url = ApiService.updateBookingStatus(bookingId);
      print("🔴 Rejecting booking at: $url");
      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": "rejected"}),
      );
      print("📦 Reject response: ${response.statusCode}, ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("BookingService.rejectBooking error: $e");
      return false;
    }
  }
}

// ------------------- BOOKING AMENITIES PAGE -------------------
class BookingAmenitiesPage extends StatefulWidget {
  const BookingAmenitiesPage({super.key});

  @override
  State<BookingAmenitiesPage> createState() => _BookingAmenitiesPageState();
}

class _BookingAmenitiesPageState extends State<BookingAmenitiesPage> {
  final List<Map<String, dynamic>> _bookings = [];
  DateTime? _selectedDate;
  String _filterStatus = "pending"; // lowercase to match backend

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() async {
    final bookings = await BookingService.fetchBookings();
    setState(() {
      _bookings.clear();
      _bookings.addAll(bookings);
    });
  }

  List<Map<String, dynamic>> get _filteredBookings {
    return _bookings.where((booking) {
      final matchesDate =
          _selectedDate == null ||
          (DateTime.parse(booking['date']).year == _selectedDate!.year &&
              DateTime.parse(booking['date']).month == _selectedDate!.month &&
              DateTime.parse(booking['date']).day == _selectedDate!.day);

      final matchesStatus =
          (booking['status']?.toString().toLowerCase() ?? '') ==
          _filterStatus.toLowerCase();

      return matchesDate && matchesStatus;
    }).toList();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _updateBookingStatus(Map<String, dynamic> booking, String status) {
    setState(() {
      booking['status'] = status;
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// 🔹 Dialog for Accept/Reject
  void _showBookingDialog(Map<String, dynamic> booking) {
    final member = booking['userId'] ?? {};
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Booking Action",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Do you want to Accept or Reject the booking for ${member['firstName'] ?? ''}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              final success = await BookingService.approveBooking(
                booking['_id'],
              );
              if (success) {
                _updateBookingStatus(booking, "accepted");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Booking accepted!")),
                );
              }
            },
            child: const Text("Accept", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await BookingService.rejectBooking(
                booking['_id'],
              );
              if (success) {
                _updateBookingStatus(booking, "rejected");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Booking rejected!")),
                );
              }
            },
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Amenity Bookings",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month,
              size: 26,
              color: Colors.white,
            ),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                "📅 Showing bookings for: ${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          Expanded(
            child: _filteredBookings.isEmpty
                ? const Center(
                    child: Text(
                      "No bookings found for this filter.",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = _filteredBookings[index];
                      final member = booking['userId'] ?? {};
                      final amenity = booking['amenityId'] ?? {};

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showBookingDialog(booking),
                        child: Card(
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Color(0xFF455A64),
                                      child: Icon(
                                        Icons.event,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            amenity['name'] ??
                                                'Unknown Amenity',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF455A64),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${member['firstName'] ?? ''} ${member['lastName'] ?? ''}",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.home,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${member['flatNo'] ?? ''} • Floor ${member['floor'] ?? ''}",
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(booking['status']),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        booking['status'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${booking['startTime']} - ${booking['endTime']}",
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text("cash:₹${booking['amount']}"),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (() {
                                        final date = DateTime.parse(
                                          booking['date'],
                                        ).toLocal();
                                        return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                                      })(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        spacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _statusChip("pending", Colors.orange),
          _statusChip("accepted", Colors.green),
          _statusChip("rejected", Colors.red),
        ],
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    return ChoiceChip(
      label: Text(
        status.capitalize(),
        style: const TextStyle(color: Colors.white),
      ),
      selected: _filterStatus == status,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.6),
      onSelected: (_) => setState(() => _filterStatus = status),
    );
  }
}

// Small string helper

/// ------------------- BOOKING DETAIL PAGE -------------------

class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Function(Map<String, dynamic>, String) onStatusChange;

  const BookingDetailPage({
    super.key,
    required this.booking,
    required this.onStatusChange,
  });

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🔒 Confirmation dialog before approving/rejecting
  Future<bool> _confirmAction(BuildContext context, String action) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  action == "approve" ? Icons.check_circle : Icons.cancel,
                  color: action == "approve" ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text('Confirm ${action.capitalize()}'),
              ],
            ),
            content: Text(
              'Are you sure you want to ${action.toLowerCase()} this booking?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: action == "approve"
                      ? Colors.green
                      : Colors.red,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  action.capitalize(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// ✅ Approve booking
  Future<void> _approveBooking(BuildContext context) async {
    final confirmed = await _confirmAction(context, "approve");
    if (!confirmed) return;

    final bookingId = widget.booking['_id'];
    final success = await BookingService.approveBooking(bookingId);

    if (success) {
      widget.onStatusChange(widget.booking, "accepted");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Booking approved for ${widget.booking['userId']['firstName'] ?? ''}",
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to approve booking")),
      );
    }
  }

  /// ❌ Reject booking
  Future<void> _rejectBooking(BuildContext context) async {
    final confirmed = await _confirmAction(context, "reject");
    if (!confirmed) return;

    final bookingId = widget.booking['_id'];
    final success = await BookingService.rejectBooking(bookingId);

    if (success) {
      widget.onStatusChange(widget.booking, "rejected");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "❌ Booking rejected for ${widget.booking['userId']['firstName'] ?? ''}",
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to reject booking")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final amenity = booking['amenityId'] ?? {};
    final member = booking['userId'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          amenity['name'] ?? 'Booking Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.check, color: Colors.white),
              text: "Approve",
            ),
            Tab(
              icon: Icon(Icons.close, color: Colors.white),
              text: "Reject",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetails(context, booking, member, amenity, true),
          _buildDetails(context, booking, member, amenity, false),
        ],
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    Map<String, dynamic> booking,
    Map<String, dynamic> member,
    Map<String, dynamic> amenity,
    bool isApprove,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(Icons.business, "Amenity", amenity['name'] ?? 'N/A'),
          _detailRow(
            Icons.person,
            "Name",
            "${member['firstName'] ?? ''} ${member['lastName'] ?? ''}",
          ),
          _detailRow(Icons.apartment, "Flat No", member['flatNo'] ?? 'N/A'),
          _detailRow(Icons.layers, "Floor No", member['floor'] ?? 'N/A'),
          _detailRow(Icons.phone, "Contact", member['mobile'] ?? 'N/A'),
          _detailRow(
            Icons.access_time,
            "Time",
            "${booking['startTime'] ?? ''} - ${booking['endTime'] ?? ''}",
          ),
          _detailRow(
            Icons.calendar_today,
            "Date",
            DateTime.parse(booking['date']).toLocal().toString().split(' ')[0],
          ),
          _detailRow(
            Icons.attach_money,
            "Amount",
            "₹${booking['amount']?.toString() ?? '0'}",
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              icon: Icon(
                isApprove ? Icons.check : Icons.close,
                size: 22,
                color: Colors.white,
              ),
              label: Text(
                isApprove ? "Approve Booking" : "Reject Booking",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onPressed: () => isApprove
                  ? _approveBooking(context)
                  : _rejectBooking(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF455A64)),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// 🧩 Helper extension
extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}

// Keep this one at the bottom:
