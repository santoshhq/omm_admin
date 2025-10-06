import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 CHECKING EVENT STRUCTURE IN DATABASE');
  print('=======================================');

  const baseUrl = 'http://localhost:8080/api';
  const adminId = '68d664d7d84448fff5dc3a8b'; // Admin with 3 events

  try {
    // Get the existing events and examine structure
    print('\n📡 FETCHING EVENTS...');
    final eventsUrl = Uri.parse('$baseUrl/events?adminId=$adminId');
    final eventsResponse = await http.get(eventsUrl);

    if (eventsResponse.statusCode != 200) {
      print('❌ Failed to fetch events: ${eventsResponse.statusCode}');
      exit(1);
    }

    final eventsData = jsonDecode(eventsResponse.body);
    print('✅ Response Status: ${eventsResponse.statusCode}');
    print('✅ Response Body: ${eventsResponse.body}');

    if (eventsData['data'] != null && eventsData['data'].isNotEmpty) {
      print('\n📋 EVENT STRUCTURE ANALYSIS:');
      final firstEvent = eventsData['data'][0];

      print('Available fields in event object:');
      firstEvent.forEach((key, value) {
        print('  • $key: $value (${value.runtimeType})');
      });

      // Check what ID field is available
      if (firstEvent['_id'] != null) {
        print('\n✅ Using _id: ${firstEvent['_id']}');
      } else if (firstEvent['id'] != null) {
        print('\n✅ Using id: ${firstEvent['id']}');
      } else {
        print('\n❌ No ID field found!');
        return;
      }
    } else {
      print('❌ No events found');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
