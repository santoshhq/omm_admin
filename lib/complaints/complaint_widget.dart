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
  // 🔹 Sample data (later replace with Firebase fetch)
  final List<Complaint> _complaints = [
    Complaint(
      title: "Water Leakage",
      description: "Leakage in basement, bathrooms, tanks, others…",
      reporter: "Flat 302 - Mr. Ramesh",
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Complaint(
      title: "Power Issue",
      description: "Frequent power cuts, voltage issues, wiring faults…",
      reporter: "Flat 104 - Mrs. Kavya",
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Complaint(
      title: "Cleaning",
      description: "Garbage left in corridor, pest control needed…",
      reporter: "Flat 210 - Mr. Arjun",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

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
      body: _complaints.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.report_problem_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No complaints yet",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Complaints raised by residents will appear here",
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
              itemCount: _complaints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = _complaints[index];
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
                          builder: (_) => ComplaintDetailPage(complaint: c),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
