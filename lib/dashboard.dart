import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:omm_admin/events/festival_widget.dart'; // For Ongoing Events
import 'package:omm_admin/events/modules.dart'; // Keep other module imports as needed

// Additional pages for other boxes
class ViewBillsPage extends StatelessWidget {
  const ViewBillsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Bills"),
        backgroundColor: Colors.green,
      ),
      body: const Center(child: Text("Here you can view all bills.")),
    );
  }
}

class ManageMembersPage extends StatelessWidget {
  const ManageMembersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Members"),
        backgroundColor: Colors.orange,
      ),
      body: const Center(child: Text("Here you can manage members.")),
    );
  }
}

class UpcomingRentPage extends StatelessWidget {
  const UpcomingRentPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Rent"),
        backgroundColor: Colors.purple,
      ),
      body: const Center(child: Text("Here is the upcoming rent info.")),
    );
  }
}

// --------------------- Dashboard Page ---------------------
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 2;
  String _selectedPriority = "Medium";
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imgList = [
      "https://picsum.photos/id/1015/600/300",
      "https://picsum.photos/id/1016/600/300",
      "https://picsum.photos/id/1018/600/300",
    ];

    // Grid box calculation
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = 16;
    final double spacing = 16;
    final double boxWidth = (screenWidth - horizontalPadding * 2 - spacing) / 2;
    final double boxHeight = boxWidth * 0.9; // slightly rectangular

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Header ----------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Omm Apartments",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Comfortable living, happy community",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.apartment, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ---------- Scrollable Content ----------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ---------- Carousel ----------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 180,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            viewportFraction: 0.95,
                            aspectRatio: 16 / 9,
                          ),
                          items: imgList.map((item) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  item,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ---------- Announcements ----------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Announcements",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} "
                                "${DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12}:${DateTime.now().minute.toString().padLeft(2, '0')} "
                                "${DateTime.now().hour >= 12 ? 'PM' : 'AM'}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                hintText: "Enter Title...",
                                prefixIcon: const Icon(
                                  Icons.title,
                                  color: Colors.blueGrey,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: "Enter Description...",
                                prefixIcon: const Icon(
                                  Icons.description,
                                  color: Colors.blueGrey,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedPriority,
                                      items: const [
                                        DropdownMenuItem(
                                          value: "High",
                                          child: Text("High"),
                                        ),
                                        DropdownMenuItem(
                                          value: "Medium",
                                          child: Text("Medium"),
                                        ),
                                        DropdownMenuItem(
                                          value: "Low",
                                          child: Text("Low"),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPriority = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.send,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Post",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ---------- Manage Section ----------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Manage",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: boxWidth / boxHeight,
                            children: [
                              _buildModernManageBox(
                                Icons.event,
                                "Ongoing Events",
                                width: boxWidth,
                                height: boxHeight,
                                color: Colors.teal, // unique color
                                page: const FestivalScreen(),
                              ),
                              _buildModernManageBox(
                                Icons.receipt_long,
                                "View Bills",
                                width: boxWidth,
                                height: boxHeight,
                                color: Colors.blue, // unique color
                                page: null,
                              ),
                              _buildModernManageBox(
                                Icons.group,
                                "Manage Members",
                                width: boxWidth,
                                height: boxHeight,
                                color: Colors.orange, // unique color
                                page: null,
                              ),
                              _buildModernManageBox(
                                Icons.home,
                                "Upcoming Rent",
                                width: boxWidth,
                                height: boxHeight,
                                color: Colors.purple, // unique color
                                page: null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ---------- Bottom Navigation ----------
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _selectedIndex,
        height: 60,
        items: const [
          Icon(Icons.smart_toy_outlined, size: 28, color: Colors.white),
          Icon(Icons.home_outlined, size: 28, color: Colors.white),
          Icon(Icons.add_box_outlined, size: 28, color: Colors.white),
          Icon(Icons.receipt_long, size: 28, color: Colors.white),
          Icon(Icons.person_outline, size: 28, color: Colors.white),
        ],
        color: const Color(0xFF607D8B),
        buttonBackgroundColor: const Color(0xFF455A64),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: _onItemTapped,
      ),
    );
  }

  // ---------- Modern Manage Box ----------
  Widget _buildModernManageBox(
    IconData icon,
    String title, {
    required double width,
    required double height,
    required Color color, // new color parameter
    Widget? page,
  }) {
    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No page available for $title")),
          );
        }
      },
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
