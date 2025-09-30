import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:omm_admin/Amenities_booking/amenities_admin_widget.dart';
import 'package:omm_admin/Users_magement.dart/view_members_widget.dart';
import 'package:omm_admin/services/admin_session_service.dart';
import 'package:omm_admin/authentications/login_page/login_page_widget.dart';

import 'Events_Announ/event_announ.dart';
import 'package:omm_admin/admin_info.dart';

import 'package:omm_admin/dashboard.dart';

class BottumNavigation extends StatefulWidget {
  const BottumNavigation({super.key});

  @override
  State<BottumNavigation> createState() => _BottumNavigationState();
}

class _BottumNavigationState extends State<BottumNavigation> {
  int _selectedIndex = 2;
  String? _adminId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminId();
  }

  // Load admin ID from session service
  Future<void> _loadAdminId() async {
    try {
      final isLoggedIn = await AdminSessionService.isLoggedIn();

      if (isLoggedIn) {
        final adminId = await AdminSessionService.getAdminId();
        final isExpired = await AdminSessionService.isSessionExpired();

        if (adminId != null && !isExpired) {
          if (mounted) {
            setState(() {
              _adminId = adminId;
              _isLoading = false;
            });
          }

          print('✅ Admin session loaded successfully');
          print('🔑 Admin ID: $adminId');
        } else {
          // Session expired or invalid
          await AdminSessionService.clearAdminSession();
          _handleNotLoggedIn();
        }
      } else {
        // Admin not logged in
        _handleNotLoggedIn();
      }
    } catch (e) {
      print('❌ Error loading admin session: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _handleNotLoggedIn();
    }
  }

  void _handleNotLoggedIn() {
    // Navigate back to login screen or show error
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // Build pages dynamically based on admin ID
  List<Widget> get _pages {
    if (_adminId == null) {
      // Return loading or error pages if admin ID not available
      return [
        const Center(child: Text("Please login to access members")),
        AmenitiesAdminPage(),
        const DashboardPage(),
        const Event_Announ(),
        const AdminPage(),
      ];
    }

    return [
      // Members management page - uses logged-in admin ID
      MembersPage(adminId: _adminId),
      AmenitiesAdminPage(), // Amenities management
      const DashboardPage(), // Dashboard home
      const Event_Announ(), // Events & announcements
      const AdminPage(), // Admin profile
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while fetching admin ID
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading admin session..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: _pages[_selectedIndex], // Swap body based on selected index

      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60,
        items: const [
          Icon(Icons.groups_outlined, size: 28, color: Colors.white),
          Icon(Icons.theater_comedy, size: 28, color: Colors.white),
          Icon(Icons.home, size: 28, color: Colors.white),
          Icon(Icons.add_box, size: 28, color: Colors.white),
          Icon(Icons.person_outline, size: 28, color: Colors.white),
        ],
        color: const Color(0xFF607D8B),
        buttonBackgroundColor: const Color(0xFF455A64),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 300),
        onTap: _onItemTapped,
      ),
    );
  }
}
