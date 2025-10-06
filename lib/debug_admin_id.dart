import 'package:flutter/material.dart';
import '../services/admin_session_service.dart';

class AdminIdDebugWidget extends StatefulWidget {
  @override
  _AdminIdDebugWidgetState createState() => _AdminIdDebugWidgetState();
}

class _AdminIdDebugWidgetState extends State<AdminIdDebugWidget> {
  String? currentAdminId;

  @override
  void initState() {
    super.initState();
    loadAdminId();
  }

  Future<void> loadAdminId() async {
    final adminId = await AdminSessionService.getAdminId();
    setState(() {
      currentAdminId = adminId;
    });
    print('🔍 Current Admin ID: $adminId');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Current Admin ID: ${currentAdminId ?? "Loading..."}'),
          ElevatedButton(
            onPressed: loadAdminId,
            child: Text('Refresh Admin ID'),
          ),
        ],
      ),
    );
  }
}
