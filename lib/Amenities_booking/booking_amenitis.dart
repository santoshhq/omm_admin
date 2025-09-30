import 'package:flutter/material.dart';

// ------------------- BookingAmenitiesPage -------------------
class BookingAmenitiesPage extends StatefulWidget {
  const BookingAmenitiesPage({super.key});

  @override
  State<BookingAmenitiesPage> createState() => _BookingAmenitiesPageState();
}

class _BookingAmenitiesPageState extends State<BookingAmenitiesPage> {
  // Dummy booking data with "date" and "status"
  final List<Map<String, dynamic>> _bookings = [];

  DateTime? _selectedDate;
  String _filterStatus = "Pending"; // Default filter

  // Function to filter bookings
  List<Map<String, dynamic>> get _filteredBookings {
    return _bookings.where((booking) {
      final matchesDate =
          _selectedDate == null ||
          (booking['date'].year == _selectedDate!.year &&
              booking['date'].month == _selectedDate!.month &&
              booking['date'].day == _selectedDate!.day);
      final matchesStatus = booking['status'] == _filterStatus;
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _updateBookingStatus(Map<String, dynamic> booking, String status) {
    setState(() {
      booking['status'] = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bookings Amenities",
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
          // Pending / Approved / Rejected Tabs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text(
                    "Pending",
                    style: TextStyle(color: Colors.white),
                  ),
                  selected: _filterStatus == "Pending",
                  selectedColor: Colors.orange,
                  backgroundColor: Colors.orange.withOpacity(0.6),
                  onSelected: (_) => setState(() => _filterStatus = "Pending"),
                ),
                ChoiceChip(
                  label: const Text(
                    "Approved",
                    style: TextStyle(color: Colors.white),
                  ),
                  selected: _filterStatus == "Approved",
                  selectedColor: Colors.green,
                  backgroundColor: Colors.green.withOpacity(0.6),
                  onSelected: (_) => setState(() => _filterStatus = "Approved"),
                ),
                ChoiceChip(
                  label: const Text(
                    "Rejected",
                    style: TextStyle(color: Colors.white),
                  ),
                  selected: _filterStatus == "Rejected",
                  selectedColor: Colors.red,
                  backgroundColor: Colors.red.withOpacity(0.6),
                  onSelected: (_) => setState(() => _filterStatus = "Rejected"),
                ),
              ],
            ),
          ),
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
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailPage(
                                booking: booking,
                                onStatusChange: _updateBookingStatus,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(vertical: 10),
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
                                            booking["amenity"],
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
                                              Text(booking['name']),
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
                                                "${booking['flatNo']} • Floor ${booking['floorNo']}",
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
                                        color: booking['status'] == "Pending"
                                            ? Colors.orange
                                            : booking['status'] == "Approved"
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        booking['status'],
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
                                      Icons.phone,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(booking['contact']),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.group,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text("People: ${booking['people']}"),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.celebration,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text("Event: ${booking['event']}"),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(booking['time']),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.payment,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "₹${booking['payment'].toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 18,
                                      color: Color(0xFF455A64),
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
}

// ------------------- BookingDetailPage -------------------
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

  void _approveBooking(BuildContext context) {
    widget.onStatusChange(widget.booking, "Approved");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Booking approved for ${widget.booking['name']}"),
      ),
    );
    Navigator.pop(context);
  }

  void _rejectBooking(BuildContext context) {
    widget.onStatusChange(widget.booking, "Rejected");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Booking rejected for ${widget.booking['name']}"),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          booking["amenity"],
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
          labelColor: Colors.white, // Active tab text/icon color
          unselectedLabelColor: Colors.white70, // Inactive tab color
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
          _buildDetails(context, booking, true),
          _buildDetails(context, booking, false),
        ],
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    Map<String, dynamic> booking,
    bool isApprove,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(Icons.business, "Amenity", booking['amenity']),
          _detailRow(Icons.person, "Name", booking['name']),
          _detailRow(Icons.apartment, "Flat No", booking['flatNo']),
          _detailRow(Icons.layers, "Floor No", booking['floorNo']),
          _detailRow(Icons.phone, "Contact", booking['contact']),
          _detailRow(Icons.group, "People", booking['people'].toString()),
          _detailRow(Icons.celebration, "Event", booking['event']),
          _detailRow(Icons.access_time, "Time", booking['time']),
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
                  color: Colors.white, // 👈 make text white
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
