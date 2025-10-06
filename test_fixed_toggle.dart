import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Mock AdminSessionService for testing
class AdminSessionService {
  static Future<String?> getAdminId() async {
    return "68d664d7d84448fff5dc3a8b"; // Test admin ID
  }
}

// Mock the API methods needed for toggle
class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS) {
      return 'http://localhost:8080';
    } else {
      return 'http://localhost:8080';
    }
  }

  static String get eventsBaseUrl => '$baseUrl/api/events';

  static Future<Map<String, dynamic>> getEventCardById(String id) async {
    try {
      final url = Uri.parse("$eventsBaseUrl/$id");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("📱 Get Event Response Status: ${response.statusCode}");
      print("📱 Get Event Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        return {"success": true, "event": body["event"]};
      } else {
        throw Exception(body["message"] ?? "Failed to get event");
      }
    } catch (e) {
      print("🔥 Error getting event: $e");
      throw Exception("Failed to get event: $e");
    }
  }

  /// Toggle Event Status (Fixed Implementation)
  static Future<Map<String, dynamic>> toggleEventStatus(String id) async {
    try {
      print("🚀 Toggling event status...");
      print("🆔 Event ID: $id");

      // First, get the current event to know its current status
      print("📖 Getting current event data...");
      final currentEvent = await getEventCardById(id);

      if (currentEvent['success'] != true || currentEvent['event'] == null) {
        throw Exception("Failed to get current event data");
      }

      final eventData = currentEvent['event'];
      final currentStatus =
          eventData['status'] ?? eventData['isActive'] ?? true;
      final newStatus = !currentStatus;

      print("🔄 Current status: $currentStatus, New status: $newStatus");

      // Get admin session for the update
      String? adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception("Admin not logged in");
      }

      // Use the regular update endpoint to toggle status
      final updateData = {'status': newStatus, 'adminId': adminId};

      print("🌐 URL: $eventsBaseUrl/$id");
      print("📝 Update data: ${jsonEncode(updateData)}");

      final url = Uri.parse("$eventsBaseUrl/$id");
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
      );

      print("📱 Toggle Event Status Response Status: ${response.statusCode}");
      print("📱 Toggle Event Status Response Body: ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        print("✅ Event status toggled successfully!");
        return {
          "success": true,
          "message": "Event status updated successfully",
          "status": newStatus,
        };
      } else {
        print("❌ Toggle event status failed: ${body["message"]}");
        throw Exception(body["message"] ?? "Failed to toggle event status");
      }
    } catch (e) {
      print("🔥 Error toggling event status: $e");
      throw Exception("Failed to toggle event status: $e");
    }
  }
}

void main() async {
  String eventId = "68dcb66185bd1d89cfbe2205";

  try {
    print('\n🔄 Testing FIXED event toggle functionality...');
    print('Event ID: $eventId');

    // Test the fixed toggle functionality
    final result = await ApiService.toggleEventStatus(eventId);

    print('\n✅ Toggle test completed!');
    print('Result: ${jsonEncode(result)}');

    if (result['success'] == true) {
      print('\n🎉 Event toggle is now working!');
      print('New status: ${result['status']}');
    } else {
      print('\n❌ Toggle still failing');
    }
  } catch (e) {
    print('\n💥 Error during toggle test: $e');
  }
}
