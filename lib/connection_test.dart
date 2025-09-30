import 'package:flutter/material.dart';
import 'package:omm_admin/config/api_config.dart';

class ConnectionTestPage extends StatefulWidget {
  const ConnectionTestPage({super.key});

  @override
  State<ConnectionTestPage> createState() => _ConnectionTestPageState();
}

class _ConnectionTestPageState extends State<ConnectionTestPage> {
  String _result = "Tap button to test connection";
  bool _loading = false;

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _result = "Testing connection...";
    });

    try {
      // Test signup with dummy data
      final response = await ApiService.signup("test@example.com", "test123");
      setState(() {
        _loading = false;
        _result = "✅ SUCCESS! Backend connected!\n\nResponse: $response";
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _result =
            "❌ CONNECTION FAILED!\n\nError: $e\n\nBase URL: ${ApiService.baseUrl}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Backend Connection Test"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Backend URL:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(ApiService.baseUrl),
                    SizedBox(height: 10),
                    Text(
                      "Platform:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(Theme.of(context).platform.toString()),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: _loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Testing...",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                  : Text(
                      "Test Backend Connection",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(
                      _result,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
