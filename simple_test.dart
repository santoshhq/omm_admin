// Simple connectivity test to check admin session and API
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🔍 TROUBLESHOOTING EVENT CARD DISPLAY ISSUE');
  print('=' * 60);

  // Test 1: Check backend connectivity
  print('\n1️⃣ TESTING BACKEND CONNECTIVITY...');
  await testBackendConnectivity();

  // Test 2: Check admin-specific events API
  print('\n2️⃣ TESTING ADMIN-SPECIFIC EVENTS API...');
  await testAdminEventsAPI('675240e8f6e68a8b8c1b9e87'); // Current admin
  await testAdminEventsAPI('68d664d7d84448fff5dc3a8b'); // Admin with events

  // Test 3: Check general events API
  print('\n3️⃣ TESTING GENERAL EVENTS API...');
  await testGeneralEventsAPI();

  print('\n' + '=' * 60);
  print('🎯 CONCLUSIONS AND RECOMMENDATIONS:');
  print(
    '1. If backend is UP and events exist for the current admin → Frontend filtering issue',
  );
  print(
    '2. If backend is UP but no events for current admin → Create events or login with correct admin',
  );
  print('3. If backend connectivity fails → Start backend server on port 8080');
  print('4. If intermittent connectivity → Large payload/timeout issue');
}

Future<void> testBackendConnectivity() async {
  try {
    final response = await http
        .get(
          Uri.parse('http://localhost:8080'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(Duration(seconds: 10));

    print('✅ Backend server is RUNNING (Status: ${response.statusCode})');
  } catch (e) {
    print('❌ Backend server is NOT ACCESSIBLE: $e');
    print(
      '💡 SOLUTION: Start your backend server with: npm start or node server.js',
    );
  }
}

Future<void> testAdminEventsAPI(String adminId) async {
  try {
    print('\n🔍 Testing events for admin: $adminId');

    final url = 'http://localhost:8080/api/events/admin/$adminId';
    final response = await http
        .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
        .timeout(Duration(seconds: 30));

    print('📡 API Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        final events = body['data'] as List;
        print('✅ SUCCESS: Found ${events.length} events for admin $adminId');

        if (events.isNotEmpty) {
          print('📋 Sample event adminId format: ${events.first['adminId']}');
        }
      } else {
        print('❌ API returned success: false - ${body['message']}');
      }
    } else {
      print('❌ API returned status ${response.statusCode}');
    }
  } catch (e) {
    if (e.toString().contains('timeout')) {
      print('⏰ REQUEST TIMEOUT - This suggests large payload issue');
      print('💡 SOLUTION: Reduce image sizes or implement pagination');
    } else if (e.toString().contains('Connection closed')) {
      print('🔌 CONNECTION CLOSED - Large data transfer interrupted');
      print('💡 SOLUTION: Increase server timeout or reduce payload size');
    } else {
      print('❌ ERROR: $e');
    }
  }
}

Future<void> testGeneralEventsAPI() async {
  try {
    print('\n🔍 Testing general events API...');

    final url = 'http://localhost:8080/api/events';
    final response = await http
        .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
        .timeout(Duration(seconds: 30));

    print('📡 API Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        final events = body['data'] as List;
        print('✅ SUCCESS: Found ${events.length} total events in database');

        // Analyze adminId formats
        if (events.isNotEmpty) {
          Set<String> adminIds = {};
          for (var event in events) {
            final adminId = event['adminId'];
            if (adminId is Map) {
              adminIds.add(adminId['_id']?.toString() ?? 'unknown');
            } else {
              adminIds.add(adminId?.toString() ?? 'unknown');
            }
          }
          print('📊 Admins with events: ${adminIds.join(', ')}');
        }
      } else {
        print('❌ API returned success: false - ${body['message']}');
      }
    } else {
      print('❌ API returned status ${response.statusCode}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
}
