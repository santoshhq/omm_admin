import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🚀 Testing Event Cards for Current Admin...');

  // Test base URLs
  final eventsBaseUrl = Platform.isAndroid
      ? "http://10.0.2.2:8080/api/events"
      : "http://localhost:8080/api/events";

  print('🌐 Events Base URL: $eventsBaseUrl');

  // Test with multiple potential admin IDs
  final testAdminIds = [
    "675240e8f6e68a8b8c1b9e87", // First test admin
    "68d664d7d84448fff5dc3a8b", // Admin ID from your example
    "67524", // Shortened version
  ];

  for (String adminId in testAdminIds) {
    print('\n' + '=' * 50);
    print('🔍 Testing Admin ID: $adminId');
    print('=' * 50);

    // Test 1: Admin-specific endpoint
    try {
      print('\n📡 TEST: Admin-specific events endpoint...');
      final adminUrl = '$eventsBaseUrl/admin/$adminId';
      print('🌐 URL: $adminUrl');

      final response = await http
          .get(
            Uri.parse(adminUrl),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 10));

      print('📱 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final events = body['data'] as List;
          print('✅ Events found: ${events.length}');

          if (events.isNotEmpty) {
            print('📋 Event details:');
            for (var event in events) {
              print('  - Name: ${event['name']}');
              print('  - AdminId: ${event['adminId']}');
              print('  - Status: ${event['status']}');
              print('  - Created: ${event['createdAt']}');
              print('  ---');
            }
          } else {
            print('⚠️ No events found for this admin');
          }
        } else {
          print('❌ API returned success: false - ${body['message']}');
        }
      } else {
        print('❌ HTTP Status: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Admin endpoint failed: $e');
    }

    // Test 2: Legacy endpoint with query parameter
    try {
      print('\n📡 TEST: Legacy events endpoint with query...');
      final legacyUrl = '$eventsBaseUrl?adminId=$adminId';
      print('🌐 URL: $legacyUrl');

      final response = await http
          .get(
            Uri.parse(legacyUrl),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 10));

      print('📱 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final events = body['data'] as List;
          print('✅ Legacy events found: ${events.length}');

          if (events.isNotEmpty) {
            for (var event in events) {
              print(
                '  - Legacy Name: ${event['name']} (AdminId: ${event['adminId']})',
              );
            }
          }
        }
      }
    } catch (e) {
      print('❌ Legacy endpoint failed: $e');
    }
  }

  // Test 3: Get ALL events (to see what's in the database)
  try {
    print('\n' + '=' * 50);
    print('📡 TEST: Getting ALL events in database...');
    print('=' * 50);

    // Try the base endpoint without any admin filtering
    final response = await http
        .get(
          Uri.parse(eventsBaseUrl),
          headers: {"Content-Type": "application/json"},
        )
        .timeout(const Duration(seconds: 10));

    print('📱 Status: ${response.statusCode}');
    print('📄 Response: ${response.body}');
  } catch (e) {
    print('❌ All events test failed: $e');
  }

  print('\n✅ Event testing completed!');
}
