import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  String eventId = "68dcb66185bd1d89cfbe2205";

  try {
    print('\n🔄 Testing event toggle endpoint...');
    print('Event ID: $eventId');
    print('URL: http://localhost:8080/api/events/$eventId/toggle');

    // Test the toggle endpoint that the frontend is calling
    final response = await http.put(
      Uri.parse('http://localhost:8080/api/events/$eventId/toggle'),
      headers: {'Content-Type': 'application/json'},
    );

    print('\n📊 Response Status: ${response.statusCode}');
    print('📊 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      print('\n✅ Toggle successful!');
      print('Response data: ${jsonEncode(responseData)}');
    } else {
      print('\n❌ Toggle failed');
      print('This endpoint likely does not exist in the backend');
    }
  } catch (e) {
    print('\n💥 Error during toggle test: $e');
  }

  // Let's also check what endpoints are available
  try {
    print('\n\n🔍 Testing available endpoints...');

    // Test basic event endpoint
    final getResponse = await http.get(
      Uri.parse('http://localhost:8080/api/events/$eventId'),
      headers: {'Content-Type': 'application/json'},
    );

    print('GET /api/events/$eventId - Status: ${getResponse.statusCode}');
  } catch (e) {
    print('Error testing endpoints: $e');
  }
}
