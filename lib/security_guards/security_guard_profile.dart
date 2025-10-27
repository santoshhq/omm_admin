import 'package:flutter/material.dart';
import 'package:omm_admin/services/security_guard_auth_service.dart';

class SecurityGuardProfilePage extends StatefulWidget {
  const SecurityGuardProfilePage({Key? key}) : super(key: key);

  @override
  State<SecurityGuardProfilePage> createState() =>
      _SecurityGuardProfilePageState();
}

class _SecurityGuardProfilePageState extends State<SecurityGuardProfilePage> {
  Map<String, dynamic>? _guardData;
  bool _isLoading = true;
  bool _imageLoadError = false;

  @override
  void initState() {
    super.initState();
    _loadGuardData();
  }

  Future<void> _loadGuardData() async {
    final data = await SecurityGuardAuthService.getLoggedInGuardData();
    if (mounted) {
      setState(() {
        _guardData = data;
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileImage() {
    if (_guardData?['guardimage'] != null &&
        _guardData!['guardimage'].isNotEmpty &&
        !_imageLoadError) {
      // Display uploaded image
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(_guardData!['guardimage']),
        onBackgroundImageError: (_, __) {
          // Set error state to show fallback
          if (mounted) {
            setState(() {
              _imageLoadError = true;
            });
          }
        },
      );
    } else {
      // Display default user icon
      return const CircleAvatar(
        radius: 60,
        child: Icon(Icons.person, size: 60, color: Colors.white),
        backgroundColor: Color(0xFF455A64),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF455A64).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF455A64), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'My Profile',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF455A64),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF455A64)),
                ),
              )
            : _guardData == null
            ? const Center(
                child: Text(
                  'Unable to load profile data',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Image Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildProfileImage(),
                          const SizedBox(height: 16),
                          Text(
                            '${_guardData!['firstname'] ?? ''} ${_guardData!['lastname'] ?? ''}'
                                .trim(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF455A64).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Gate ${_guardData!['assigngates'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF455A64),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Personal Information Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildInfoRow(
                            'First Name',
                            _guardData!['firstname'] ?? 'N/A',
                            Icons.person,
                          ),

                          _buildInfoRow(
                            'Last Name',
                            _guardData!['lastname'] ?? 'N/A',
                            Icons.person_outline,
                          ),

                          _buildInfoRow(
                            'Mobile Number',
                            _guardData!['mobilenumber'] ?? 'N/A',
                            Icons.phone,
                          ),

                          _buildInfoRow(
                            'Age',
                            '${_guardData!['age'] ?? 'N/A'} years',
                            Icons.calendar_today,
                          ),

                          _buildInfoRow(
                            'Gender',
                            (_guardData!['gender'] ?? 'N/A')
                                .toString()
                                .toUpperCase(),
                            Icons.people,
                          ),

                          _buildInfoRow(
                            'Assigned Gate',
                            'Gate ${_guardData!['assigngates'] ?? 'N/A'}',
                            Icons.location_on,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Account Information Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          FutureBuilder<Map<String, dynamic>>(
                            future: _getSessionInfo(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final sessionInfo = snapshot.data!;
                                return Column(
                                  children: [
                                    _buildInfoRow(
                                      'Login Status',
                                      sessionInfo['isLoggedIn']
                                          ? 'Active'
                                          : 'Inactive',
                                      Icons.security,
                                    ),

                                    if (sessionInfo['loginTime'] != null)
                                      _buildInfoRow(
                                        'Last Login',
                                        sessionInfo['loginTime'].split('T')[0],
                                        Icons.access_time,
                                      ),

                                    _buildInfoRow(
                                      'Token Status',
                                      sessionInfo['hasToken']
                                          ? 'Valid'
                                          : 'Invalid',
                                      Icons.vpn_key,
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getSessionInfo() async {
    final isLoggedIn = await SecurityGuardAuthService.isLoggedIn();
    final loginTime = await SecurityGuardAuthService.getLoginTime();
    final token = await SecurityGuardAuthService.getToken();

    return {
      'isLoggedIn': isLoggedIn,
      'loginTime': loginTime?.toIso8601String(),
      'hasToken': token != null && token.isNotEmpty,
    };
  }

  Future<bool> _onWillPop() async {
    // Show security warning when user tries to go back from profile
    final shouldGoBack = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Security Alert'),
          content: const Text(
            'You are in a secure session. To exit the profile page, please use the back button or logout.\n\n'
            'This prevents unauthorized access and ensures proper session management.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Go back
              child: const Text('Back to Visitor Management'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(false); // Don't pop this dialog
                await _performLogout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    return shouldGoBack ?? false;
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to logout from the security guard panel?\n\n'
            'This will end your current session and return you to the login screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _performLogout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      // Perform logout
      await SecurityGuardAuthService.logout();

      // Navigate back to login screen and clear navigation stack
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/security_guard_login', // Make sure this route is defined
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Show error if logout fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
