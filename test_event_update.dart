import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 TESTING EVENT UPDATE FUNCTIONALITY');
  print('=====================================');

  const baseUrl = 'http://localhost:8080/api';
  const adminId = '68d664d7d84448fff5dc3a8b'; // Admin with 3 events

  try {
    // 1. Get the existing events first
    print('\n1️⃣ FETCHING EXISTING EVENTS...');
    final eventsUrl = Uri.parse('$baseUrl/events?adminId=$adminId');
    final eventsResponse = await http.get(eventsUrl);

    if (eventsResponse.statusCode != 200) {
      print('❌ Failed to fetch events: ${eventsResponse.statusCode}');
      exit(1);
    }

    final eventsData = jsonDecode(eventsResponse.body);
    if (eventsData['data'] == null || eventsData['data'].isEmpty) {
      print('❌ No events found for admin');
      exit(1);
    }

    final firstEvent = eventsData['data'][0];
    final eventId = firstEvent['_id'];
    print('✅ Found event ID: $eventId');
    print('   Current name: ${firstEvent['name']}');

    // 2. Test update functionality
    print('\n2️⃣ TESTING EVENT UPDATE...');
    final updateUrl = Uri.parse('$baseUrl/events/$eventId');
    final updateData = {
      'adminId': adminId,
      'name': 'Updated Event ${DateTime.now().millisecondsSinceEpoch}',
    };

    final updateResponse = await http.put(
      updateUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );

    print('📡 Update Status: ${updateResponse.statusCode}');

    if (updateResponse.statusCode == 200) {
      final updateResult = jsonDecode(updateResponse.body);
      print('✅ UPDATE SUCCESS!');
      print('   Response structure: ${updateResult.keys}');
      print('   Updated name: ${updateResult['data']['name']}');

      // Verify the structure matches what frontend expects
      if (updateResult['data'] != null &&
          updateResult['data']['name'] != null) {
        print('✅ Response structure is correct for frontend');
      } else {
        print('❌ Response structure mismatch');
      }
    } else {
      print('❌ Update failed: ${updateResponse.body}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
