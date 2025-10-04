import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omm_admin/authentications/login_page/login_page_widget.dart';
import 'package:omm_admin/services/admin_session_service.dart';
import 'admin_info_module.dart';
import 'admin_info_form_module.dart';
import 'admin_info_form_widget.dart';

class AdminPageWidget extends StatefulWidget {
  final AdminInfo info;

  /// Backwards-compatible constructor: if no [info] is provided,
  /// it falls back to the package-level `adminInfo` constant.
  const AdminPageWidget({super.key, AdminInfo? info})
    : info = info ?? adminInfo;

  @override
  State<AdminPageWidget> createState() => _AdminPageWidgetState();
}

class _AdminPageWidgetState extends State<AdminPageWidget> {
  @override
  void initState() {
    super.initState();
    _loadProfileFromBackend();
  }

  void _loadProfileFromBackend() async {
    try {
      debugPrint(
        "🔄 AdminPageWidget: Starting to load profile from backend...",
      );

      // Debug: Check SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      debugPrint("🔍 SharedPreferences before loading:");
      debugPrint("  - user_id: ${prefs.getString('user_id')}");
      debugPrint("  - user_email: ${prefs.getString('user_email')}");
      debugPrint(
        "  - admin_profile_id: ${prefs.getString('admin_profile_id')}",
      );
      debugPrint(
        "  - isProfileComplete: ${prefs.getBool('isProfileComplete')}",
      );

      await AdminInfoModel.loadFromBackend();

      // Debug: Check if data was loaded
      debugPrint("🔍 AdminPageWidget: Profile data after loading:");
      debugPrint("  - Name: ${adminInfoModel.fullName}");
      debugPrint("  - Email: ${adminInfoModel.email}");
      debugPrint("  - Phone: ${adminInfoModel.phone}");
      debugPrint("  - Apartment: ${adminInfoModel.apartment}");
      debugPrint("  - Address: ${adminInfoModel.address}");

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("❌ AdminPageWidget: Error loading profile from backend: $e");

      // Show user-friendly message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unable to load profile data: ${e.toString()}"),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: "Retry",
              onPressed: _loadProfileFromBackend,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyBgColor = Color(0xFFF9F9F9);

    return PopScope(
      child: Scaffold(
        backgroundColor: bodyBgColor,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage profile settings',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: const Color(0xFF455A64),
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF455A64), Color(0xFF607D8B)],
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
                onPressed: () {
                  debugPrint("🔄 Manual refresh triggered");
                  _loadProfileFromBackend();
                },
                tooltip: 'Refresh Profile',
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF607D8B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  // Navigate to edit page and wait for result
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminInfoFormPage(isEditMode: true),
                    ),
                  );
                  // Reload profile data after returning from edit
                  _loadProfileFromBackend();
                },
                tooltip: 'Edit Profile',
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Professional spacing from AppBar
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFF455A64),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Listen to the editable admin model for updates
                                AnimatedBuilder(
                                  animation: adminInfoModel,
                                  builder: (_, __) => Text(
                                    adminInfoModel.fullName.isNotEmpty
                                        ? adminInfoModel.fullName
                                        : widget.info.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'President',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Contact Info
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              "Contact Info",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          ...contactItems.map(
                            (it) => Column(
                              children: [
                                ListTile(
                                  leading: Icon(it.icon, color: Colors.black54),
                                  title: AnimatedBuilder(
                                    animation: adminInfoModel,
                                    builder: (_, __) {
                                      // Replace placeholders with live values

                                      if (it.icon == Icons.apartment)
                                        return Text(
                                          adminInfoModel.apartment.isNotEmpty
                                              ? adminInfoModel.apartment
                                              : 'No apartment provided',
                                        );
                                      if (it.icon == Icons.email_outlined)
                                        return Text(
                                          adminInfoModel.email.isNotEmpty
                                              ? adminInfoModel.email
                                              : 'No email provided',
                                        );
                                      if (it.icon == Icons.phone)
                                        return Text(
                                          adminInfoModel.phone.isNotEmpty
                                              ? adminInfoModel.phone
                                              : 'No phone provided',
                                        );
                                      if (it.icon == Icons.location_on)
                                        return Text(
                                          adminInfoModel.address.isNotEmpty
                                              ? adminInfoModel.address
                                              : 'No address provided',
                                        );
                                      return Text(it.title);
                                    },
                                  ),
                                ),
                                const Divider(height: 1),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ...removed inline edit button; edit is available from the app bar

                    // Support Section
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              "Support",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          ...supportItems
                              .where((it) => it.title != 'Logout')
                              .map(
                                (it) => Column(
                                  children: [
                                    ListTile(
                                      leading: Icon(
                                        it.icon,
                                        color: it.color ?? Colors.black87,
                                      ),
                                      title: Text(
                                        it.title,
                                        style: TextStyle(color: it.color),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                ),
                              ),
                          // Custom logout text button
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextButton.icon(
                              onPressed: () => _handleLogout(context),
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.red,
                                size: 20,
                              ),
                              label: const Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Version footer
                    Text(
                      widget.info.version,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle logout functionality
  static void _handleLogout(BuildContext context) async {
    try {
      // Show confirmation dialog
      final bool? shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true) {
        // Clear login state using both AdminSessionService and traditional method
        try {
          // Clear admin session using service
          await AdminSessionService.clearAdminSession();

          // Clear traditional SharedPreferences for backward compatibility
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', false);
          await prefs.clear(); // Clear all preferences

          debugPrint('✅ Logout successful - all sessions cleared');
        } catch (e) {
          debugPrint("Error clearing sessions during logout: $e");
        }

        // Navigate to login page and clear navigation stack
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint("Error during logout: $e");
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
