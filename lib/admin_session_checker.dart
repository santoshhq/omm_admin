import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Session Checker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AdminSessionChecker(),
    );
  }
}

class AdminSessionChecker extends StatefulWidget {
  @override
  _AdminSessionCheckerState createState() => _AdminSessionCheckerState();
}

class _AdminSessionCheckerState extends State<AdminSessionChecker> {
  String? adminId;
  String? adminEmail;
  bool? isLoggedIn;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminSession();
  }

  Future<void> _checkAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        adminId = prefs.getString('adminId');
        adminEmail = prefs.getString('adminEmail');
        isLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error checking admin session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Session Status'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Admin Session',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildSessionRow('Admin ID:', adminId ?? 'NOT SET'),
                          _buildSessionRow('Email:', adminEmail ?? 'NOT SET'),
                          _buildSessionRow(
                            'Logged In:',
                            isLoggedIn?.toString() ?? 'false',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    color: adminId == null ? Colors.red[50] : Colors.green[50],
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Status Analysis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          if (adminId == null)
                            Text(
                              '❌ NO ADMIN SESSION FOUND!\n\n'
                              '💡 Solution: Login to the app first',
                              style: TextStyle(color: Colors.red[700]),
                            )
                          else if (adminId == '675240e8f6e68a8b8c1b9e87')
                            Text(
                              '⚠️ CURRENT ADMIN HAS NO EVENTS!\n\n'
                              'Your admin ID: $adminId\n'
                              'Events in database: 0\n\n'
                              '💡 Solutions:\n'
                              '  • Create new events with current admin\n'
                              '  • Login with admin: 68d664d7d84448fff5dc3a8b\n'
                              '    (Email: qwert123@gmail.com, Has 3 events)',
                              style: TextStyle(color: Colors.orange[700]),
                            )
                          else if (adminId == '68d664d7d84448fff5dc3a8b')
                            Text(
                              '✅ CURRENT ADMIN HAS EVENTS!\n\n'
                              'Your admin ID: $adminId\n'
                              'Events in database: 3\n\n'
                              '🎯 Events should display correctly.\n'
                              'If not showing, check frontend filtering logic.',
                              style: TextStyle(color: Colors.green[700]),
                            )
                          else
                            Text(
                              '❓ UNKNOWN ADMIN\n\n'
                              'Your admin ID: $adminId\n'
                              'Database status: Unknown\n\n'
                              '💡 Check if this admin has created events',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkAdminSession,
                    child: Text('🔄 Refresh Session Data'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSessionRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                color: value.contains('NOT SET') ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
