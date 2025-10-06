// Test announcement update functionality directly
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔧 TESTING ANNOUNCEMENT UPDATE FUNCTIONALITY');
  print('=' * 60);

  await testAnnouncementUpdate();

  print('\n' + '=' * 60);
  print('🎯 ANNOUNCEMENT UPDATE TEST COMPLETE!');
}

Future<void> testAnnouncementUpdate() async {
  const adminId = '68d664d7d84448fff5dc3a8b';

  try {
    print('📋 Step 1: Getting existing announcements...');

    // Get admin announcements
    var response = await http.get(
      Uri.parse('http://localhost:8080/api/announcements/admin/$adminId'),
    );

    if (response.statusCode != 200) {
      // Fallback to general endpoint
      response = await http.get(
        Uri.parse('http://localhost:8080/api/announcements'),
      );
    }

    print('📡 Get Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      print('📦 Response Structure: ${body.keys.toList()}');

      if (body['success'] == true &&
          body['data'] != null &&
          body['data'].isNotEmpty) {
        final announcements = body['data'] as List;
        final announcement = announcements.first;
        final announcementId = announcement['_id'];

        print('✅ Found announcement to test: $announcementId');
        print('   Original title: "${announcement['title']}"');
        print('   Original description: "${announcement['description']}"');

        print('\n📝 Step 2: Testing announcement update...');

        final updateResponse = await http.put(
          Uri.parse('http://localhost:8080/api/announcements/$announcementId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'adminId': adminId,
            'title':
                'Updated Announcement - ${DateTime.now().millisecondsSinceEpoch}',
            'description':
                'Updated description for testing announcement functionality',
            'priority': 'high',
          }),
        );

        print('📡 Update Response Status: ${updateResponse.statusCode}');
        print('📄 Update Response Body:');
        print(updateResponse.body);

        if (updateResponse.statusCode == 200) {
          final updateBody = jsonDecode(updateResponse.body);
          print('\n✅ UPDATE SUCCESS!');
          print('  • Success: ${updateBody['success']}');
          print('  • Message: ${updateBody['message']}');

          if (updateBody['data'] != null) {
            final updatedData = updateBody['data'];
            print('  • Updated title: "${updatedData['title']}"');
            print('  • Updated description: "${updatedData['description']}"');
            print('  • Priority: ${updatedData['priority']}');
          }
        } else {
          print('❌ UPDATE FAILED with status: ${updateResponse.statusCode}');
          try {
            final errorBody = jsonDecode(updateResponse.body);
            print('   Error message: ${errorBody['message']}');
          } catch (e) {
            print('   Raw error: ${updateResponse.body}');
          }
        }
      } else {
        print('❌ No announcements found to test');
        print('   Response data: ${body['data']}');
      }
    } else {
      print('❌ Failed to get announcements: ${response.statusCode}');
      print('   Response body: ${response.body}');
    }
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}
