import 'package:flutter/material.dart';

class AdminIdDebugWidget extends StatefulWidget {
  const AdminIdDebugWidget({super.key});

  @override
  State<AdminIdDebugWidget> createState() => _AdminIdDebugWidgetState();
}

class _AdminIdDebugWidgetState extends State<AdminIdDebugWidget> {
  String? currentAdminId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAdminId();
  }

  Future<void> loadAdminId() async {
    try {
      // Import the AdminSessionService
      final adminId = "Test"; // Replace with actual service call
      setState(() {
        currentAdminId = adminId;
        isLoading = false;
      });
      print('🔍 Current Admin ID: $adminId');
    } catch (e) {
      setState(() {
        currentAdminId = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin ID Debug')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else ...[
              const Text(
                'Current Admin ID:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SelectableText(
                currentAdminId ?? 'Unknown',
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loadAdminId,
                child: const Text('Refresh Admin ID'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
