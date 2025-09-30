import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
//import 'package:omm_admin/Amenities_booking/amenities_admin_widget.dart';
import 'package:omm_admin/Amenities_booking/booking_amenitis.dart';

import 'package:omm_admin/bills_managements/bill_page.dart';
// import 'package:omm_admin/bills_managements/bll_card.dart'; // not used here
import 'package:omm_admin/complaints/complaint_widget.dart';
import 'package:omm_admin/security_guards/security_dashboard.dart';
import 'package:omm_admin/admin_info/admin_info_form_module.dart';

// ---------------- Dummy Pages ----------------
class FestivalScreenn extends StatelessWidget {
  const FestivalScreenn({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ongoing Events")),
      body: const Center(child: Text("Here are the ongoing events.")),
    );
  }
}

class ManageMembersPage extends StatelessWidget {
  const ManageMembersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Members")),
      body: const Center(child: Text("Here you can manage members.")),
    );
  }
}

class Announcements extends StatelessWidget {
  const Announcements({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Announcements")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation
            /* Lottie.asset(
              'assets/gifs/empty_red.json',
              width: 220,
              height: 220,
              repeat: true,
            ),
            const SizedBox(height: 16),*/

            // Text below animation
            const Text(
              "No Announcements",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Dashboard ----------------
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _apartmentName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadApartmentName();
    adminInfoModel.addListener(_onAdminInfoChanged);
  }

  @override
  void dispose() {
    adminInfoModel.removeListener(_onAdminInfoChanged);
    super.dispose();
  }

  void _onAdminInfoChanged() {
    if (mounted) {
      setState(() {
        _apartmentName = adminInfoModel.apartment.isNotEmpty
            ? adminInfoModel.apartment
            : "Omm Apartments";
      });
    }
  }

  void _loadApartmentName() async {
    try {
      await AdminInfoModel.loadFromBackend();
      if (mounted) {
        setState(() {
          _apartmentName = adminInfoModel.apartment.isNotEmpty
              ? adminInfoModel.apartment
              : "Omm Apartments";
        });
      }
    } catch (e) {
      debugPrint("Error loading apartment name: $e");
      if (mounted) {
        setState(() {
          _apartmentName = "Omm Apartments"; // Fallback
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imgList = [
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1491553895911-0055eca6402d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1501785888041-af3ef285b470?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Header ----------
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _apartmentName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Premium Residential Complex",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFF455A64),
                      child: Icon(Icons.apartment, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ---------- Carousel ----------
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  aspectRatio: 16 / 9,
                ),
                items: imgList.map((item) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      item,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ---------- Manage Section ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.manage_accounts),
                        SizedBox(width: 5),
                        const Text(
                          "Manage",
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildManageCard(
                          context,
                          icon: Icons.report_problem,
                          title: "Complaints",
                          subtitle: "3 active complaints",
                          color: Colors.red.shade100,
                          iconColor: Colors.red,
                          page: ComplaintPage(),
                        ),
                        _buildManageCard(
                          context,
                          icon: Icons.receipt_long,
                          title: "Manage Bills",
                          subtitle: "12 pending bills",
                          color: Colors.green.shade100,
                          iconColor: Colors.green,
                          page: BillsPage(),
                        ),

                        _buildManageCard(
                          context,
                          icon: Icons.theater_comedy,
                          title: "Bookings ",
                          subtitle: "Tap to view",
                          color: Colors.blue.shade100,
                          iconColor: Colors.blueAccent,
                          page: BookingAmenitiesPage(),
                        ),
                        _buildManageCard(
                          context,
                          icon: Icons.security,
                          title: "Security & Staff",
                          subtitle: "Tap to view",
                          color: Colors.purple.shade100,
                          iconColor: Colors.deepPurple,
                          page: SecurityDashboardPage(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ---------- Bottom Navigation ----------
    );
  }

  // ---------- Manage Card ----------
  Widget _buildManageCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    Widget? page,
  }) {
    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
