// Test to get actual event/announcement structure
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🔍 ANALYZING EVENT/ANNOUNCEMENT STRUCTURE');
  print('=' * 50);

  // Get actual event structure
  print('\n1️⃣ GETTING EVENT STRUCTURE...');
  await getEventStructure();

  // Get actual announcement structure
  print('\n2️⃣ GETTING ANNOUNCEMENT STRUCTURE...');
  await getAnnouncementStructure();
}

Future<void> getEventStructure() async {
  try {
    final response = await http.get(
      Uri.parse(
        'http://localhost:8080/api/events/admin/68d664d7d84448fff5dc3a8b',
      ),
    );

    print('📡 Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'].isNotEmpty) {
        final event = body['data'][0];
        print('\n🎯 EVENT STRUCTURE:');
        print('Full event object: ${jsonEncode(event)}');
        print('\nKey fields:');
        event.forEach((key, value) {
          if (key == '_id' || key == 'id' || key.contains('id')) {
            print('  • $key: $value (${value.runtimeType})');
          }
        });

        // Try to identify the correct ID field
        final eventId = event['_id'] ?? event['id'];
        if (eventId != null) {
          print('\n✅ Found event ID: $eventId');

          // Test update with correct ID
          print('🔄 Testing update with correct ID...');
          final updateResponse = await http.put(
            Uri.parse('http://localhost:8080/api/events/$eventId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'adminId': '68d664d7d84448fff5dc3a8b',
              'name': 'Test Update ${DateTime.now().millisecondsSinceEpoch}',
            }),
          );

          print('📡 Update Status: ${updateResponse.statusCode}');
          print('📄 Update Body: ${updateResponse.body}');

          if (updateResponse.statusCode == 200) {
            final updateBody = jsonDecode(updateResponse.body);
            print('\n✅ UPDATE SUCCESS! Response structure:');
            print('  • success: ${updateBody['success']}');
            print('  • data structure: ${updateBody['data']?.keys?.toList()}');

            // Check if it returns data.event or just data
            if (updateBody['data'] is Map) {
              if (updateBody['data']['event'] != null) {
                print(
                  '  • ✅ Returns data.event (matches frontend expectation)',
                );
              } else {
                print(
                  '  • ❌ Returns data directly (frontend expects data.event)',
                );
                print(
                  '  • Available fields: ${updateBody['data'].keys.toList()}',
                );
              }
            }
          }
        } else {
          print('❌ No valid ID field found in event');
        }
      } else {
        print('❌ No events found');
      }
    } else {
      print('❌ Failed to get events: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> getAnnouncementStructure() async {
  try {
    // Try admin-specific endpoint first
    var response = await http.get(
      Uri.parse(
        'http://localhost:8080/api/announcements/admin/68d664d7d84448fff5dc3a8b',
      ),
    );

    // If admin endpoint fails, try general endpoint
    if (response.statusCode != 200) {
      response = await http.get(
        Uri.parse('http://localhost:8080/api/announcements'),
      );
    }

    print('📡 Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'].isNotEmpty) {
        final announcement = body['data'][0];
        print('\n🎯 ANNOUNCEMENT STRUCTURE:');
        print('Full announcement object: ${jsonEncode(announcement)}');
        print('\nKey fields:');
        announcement.forEach((key, value) {
          if (key == '_id' || key == 'id' || key.contains('id')) {
            print('  • $key: $value (${value.runtimeType})');
          }
        });

        // Try to identify the correct ID field
        final announcementId = announcement['_id'] ?? announcement['id'];
        if (announcementId != null) {
          print('\n✅ Found announcement ID: $announcementId');

          // Test update with correct ID
          print('🔄 Testing update with correct ID...');
          final updateResponse = await http.put(
            Uri.parse(
              'http://localhost:8080/api/announcements/$announcementId',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'adminId': '68d664d7d84448fff5dc3a8b',
              'title': 'Test Update ${DateTime.now().millisecondsSinceEpoch}',
            }),
          );

          print('📡 Update Status: ${updateResponse.statusCode}');
          print('📄 Update Body: ${updateResponse.body}');
        } else {
          print('❌ No valid ID field found in announcement');
        }
      } else {
        print('❌ No announcements found');
      }
    } else {
      print('❌ Failed to get announcements: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
