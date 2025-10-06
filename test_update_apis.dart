// Test update API endpoints to understand response structure
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🔧 TESTING UPDATE API ENDPOINTS');
  print('=' * 50);

  // Test event update endpoint
  print('\n1️⃣ TESTING EVENT UPDATE API...');
  await testEventUpdateAPI();

  // Test announcement update endpoint
  print('\n2️⃣ TESTING ANNOUNCEMENT UPDATE API...');
  await testAnnouncementUpdateAPI();

  print('\n' + '=' * 50);
  print('🎯 ANALYSIS COMPLETE!');
}

Future<void> testEventUpdateAPI() async {
  try {
    // First get an existing event to update
    print('🔍 Getting existing events...');
    final getResponse = await http
        .get(
          Uri.parse(
            'http://localhost:8080/api/events/admin/68d664d7d84448fff5dc3a8b',
          ),
        )
        .timeout(Duration(seconds: 10));

    if (getResponse.statusCode == 200) {
      final getBody = jsonDecode(getResponse.body);
      if (getBody['success'] == true && getBody['data'].isNotEmpty) {
        final eventId = getBody['data'][0]['_id'];
        print('✅ Found event to update: $eventId');

        // Now test update with minimal data
        print('🔄 Testing update API...');
        final updateResponse = await http
            .put(
              Uri.parse('http://localhost:8080/api/events/$eventId'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'adminId': '68d664d7d84448fff5dc3a8b',
                'name':
                    'Test Update - ${DateTime.now().millisecondsSinceEpoch}',
              }),
            )
            .timeout(Duration(seconds: 30));

        print('📡 Update Response Status: ${updateResponse.statusCode}');
        print('📄 Update Response Body: ${updateResponse.body}');

        if (updateResponse.statusCode == 200) {
          final updateBody = jsonDecode(updateResponse.body);
          print('\n🔍 RESPONSE STRUCTURE ANALYSIS:');
          print('  • success: ${updateBody['success']}');
          print('  • message: ${updateBody['message']}');
          print('  • data keys: ${updateBody['data']?.keys?.toList()}');

          if (updateBody['data'] != null) {
            if (updateBody['data']['event'] != null) {
              print('  • data.event exists ✅');
            } else {
              print('  • data.event missing ❌');
              print(
                '  • Available in data: ${updateBody['data'].keys.toList()}',
              );
            }
          }
        }
      } else {
        print('❌ No events found to test update');
      }
    } else {
      print('❌ Failed to get events: ${getResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Event update test failed: $e');
  }
}

Future<void> testAnnouncementUpdateAPI() async {
  try {
    // First get existing announcements
    print('🔍 Getting existing announcements...');
    final getResponse = await http
        .get(
          Uri.parse(
            'http://localhost:8080/api/announcements/admin/68d664d7d84448fff5dc3a8b',
          ),
        )
        .timeout(Duration(seconds: 10));

    if (getResponse.statusCode == 200) {
      final getBody = jsonDecode(getResponse.body);
      if (getBody['success'] == true && getBody['data'].isNotEmpty) {
        final announcementId = getBody['data'][0]['_id'];
        print('✅ Found announcement to update: $announcementId');

        // Test update
        print('🔄 Testing announcement update API...');
        final updateResponse = await http
            .put(
              Uri.parse(
                'http://localhost:8080/api/announcements/$announcementId',
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'adminId': '68d664d7d84448fff5dc3a8b',
                'title':
                    'Test Update - ${DateTime.now().millisecondsSinceEpoch}',
              }),
            )
            .timeout(Duration(seconds: 30));

        print('📡 Update Response Status: ${updateResponse.statusCode}');
        print('📄 Update Response Body: ${updateResponse.body}');

        if (updateResponse.statusCode == 200) {
          final updateBody = jsonDecode(updateResponse.body);
          print('\n🔍 RESPONSE STRUCTURE ANALYSIS:');
          print('  • success: ${updateBody['success']}');
          print('  • message: ${updateBody['message']}');
          print('  • data keys: ${updateBody['data']?.keys?.toList()}');
        }
      } else {
        print('❌ No announcements found to test update');
      }
    } else if (getResponse.statusCode == 404) {
      print(
        '❌ Announcement admin endpoint not found - trying general endpoint',
      );

      final generalResponse = await http.get(
        Uri.parse('http://localhost:8080/api/announcements'),
      );

      if (generalResponse.statusCode == 200) {
        final generalBody = jsonDecode(generalResponse.body);
        if (generalBody['success'] == true && generalBody['data'].isNotEmpty) {
          final announcementId = generalBody['data'][0]['_id'];
          print('✅ Found announcement via general endpoint: $announcementId');

          // Test update
          final updateResponse = await http.put(
            Uri.parse(
              'http://localhost:8080/api/announcements/$announcementId',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'adminId': '68d664d7d84448fff5dc3a8b',
              'title': 'Test Update - ${DateTime.now().millisecondsSinceEpoch}',
            }),
          );

          print('📡 Update Response Status: ${updateResponse.statusCode}');
          print('📄 Update Response Body: ${updateResponse.body}');
        }
      }
    } else {
      print('❌ Failed to get announcements: ${getResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Announcement update test failed: $e');
  }
}
