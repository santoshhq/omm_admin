import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  String eventId = "68dcb66185bd1d89cfbe2205";
  String adminId = "68d664d7d84448fff5dc3a8b";

  // Prepare update data
  Map<String, dynamic> updateData = {
    'title': 'Updated Event Title - Test',
    'description': 'Updated description for testing',
    'adminId': adminId,
  };

  try {
    print('\n🔧 Testing direct event update...');
    print('Event ID: $eventId');
    print('Admin ID: $adminId');
    print('Update data: ${jsonEncode(updateData)}');

    // Make PUT request to update event
    final response = await http.put(
      Uri.parse('http://localhost:8080/api/events/$eventId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );

    print('\n📊 Response Status: ${response.statusCode}');
    print('📊 Response Headers: ${response.headers}');
    print('📊 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      print('\n✅ Update successful!');
      print('Updated event data: ${jsonEncode(responseData)}');
    } else {
      print('\n❌ Update failed');
      print('Error response: ${response.body}');
    }
  } catch (e) {
    print('\n💥 Error during direct update test: $e');
  }
}
