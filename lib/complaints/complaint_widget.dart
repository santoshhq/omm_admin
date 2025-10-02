import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omm_admin/complaints/complaint_module.dart';
import 'package:omm_admin/complaints/complaint_detail_widget.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Complaint> _filteredComplaints = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to get status icon
  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Icons.access_time;
      case ComplaintStatus.unsolved:
        return Icons.error_outline;
      case ComplaintStatus.solved:
        return Icons.check_circle;
    }
  }

  // Method to update complaint status
  void _updateComplaintStatus(int filteredIndex, ComplaintStatus newStatus) {
    setState(() {
      // Find the complaint in the original list
      final complaint = _filteredComplaints[filteredIndex];
      final originalIndex = _complaints.indexOf(complaint);
      if (originalIndex != -1) {
        _complaints[originalIndex] = _complaints[originalIndex].copyWith(
          status: newStatus,
        );
        _filterComplaints(); // Refresh the filtered list
      }
    });
  }

  // Method to show status change dialog
  void _showStatusChangeDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Change Status',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ComplaintStatus.values.map((status) {
              return ListTile(
                leading: Icon(_getStatusIcon(status), color: status.color),
                title: Text(
                  status.displayName,
                  style: GoogleFonts.poppins(
                    color: status.color,
                    fontWeight: _complaints[index].status == status
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: _complaints[index].status == status
                    ? Icon(Icons.check, color: status.color)
                    : null,
                onTap: () {
                  _updateComplaintStatus(index, status);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Status updated to ${status.displayName}',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: status.color,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // 🔹 Sample data (later replace with Firebase fetch)
  List<Complaint> _complaints = [
    Complaint(
      title: "Water Leakage",
      description: "Leakage in basement, bathrooms, tanks, others…",
      reporter: "Flat 302 - Mr. Ramesh",
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      status: ComplaintStatus.solved,
    ),
    Complaint(
      title: "Power Issue",
      description: "Frequent power cuts, voltage issues, wiring faults…",
      reporter: "Flat 104 - Mrs. Kavya",
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: ComplaintStatus.unsolved,
    ),
    Complaint(
      title: "Cleaning",
      description: "Garbage left in corridor, pest control needed…",
      reporter: "Flat 210 - Mr. Arjun",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: ComplaintStatus.pending,
    ),
    Complaint(
      title: "Lift Maintenance",
      description: "Lift making strange noises, needs immediate attention…",
      reporter: "Flat 501 - Ms. Priya",
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      status: ComplaintStatus.unsolved,
    ),
    Complaint(
      title: "Parking Space",
      description: "Unauthorized vehicle blocking designated parking…",
      reporter: "Flat 103 - Mr. Kumar",
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: ComplaintStatus.solved,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredComplaints = _complaints;
    _searchController.addListener(() {
      _filterComplaints();
      setState(() {}); // Rebuild to show/hide clear button
    });
  }

  void _filterComplaints() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredComplaints = _complaints;
      } else {
        _filteredComplaints = _complaints.where((complaint) {
          final title = complaint.title.toLowerCase();
          final reporter = complaint.reporter.toLowerCase();
          return title.contains(query) || reporter.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        title: Text(
          "Complaints",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Search Field
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or flat number...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Content Area
          Expanded(
            child: _filteredComplaints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _searchController.text.isNotEmpty
                              ? Icons.search_off
                              : Icons.report_problem_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isNotEmpty
                              ? "No complaints found"
                              : "No complaints yet",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchController.text.isNotEmpty
                              ? "Try searching with different keywords"
                              : "Complaints raised by residents will appear here",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredComplaints.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = _filteredComplaints[index];
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color.fromARGB(
                              255,
                              255,
                              73,
                              73,
                            ).withOpacity(0.3), // light red border
                            width: 1.2,
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.report_problem,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                          title: Text(
                            c.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                c.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Status Tag
                              Row(
                                children: [
                                  GestureDetector(
                                    onLongPress: () =>
                                        _showStatusChangeDialog(context, index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.status.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: c.status.color.withOpacity(
                                            0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getStatusIcon(c.status),
                                            size: 12,
                                            color: c.status.color,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            c.status.displayName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: c.status.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      c.reporter,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ComplaintDetailPage(complaint: c),
                              ),
                            );
                          },
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
