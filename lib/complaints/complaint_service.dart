import '../config/api_config.dart';
import '../services/admin_session_service.dart';
import 'complaint_module.dart';

class ComplaintService {
  /// Get admin ID from session
  static Future<String?> _getAdminId() async {
    return await AdminSessionService.getAdminId();
  }

  /// Create a new complaint
  static Future<Complaint> createComplaint({
    required String userId,
    required String title,
    required String description,
  }) async {
    try {
      print('🔄 ComplaintService: Creating complaint');
      final adminId = await _getAdminId();

      if (adminId == null) {
        throw Exception('Admin session not found. Please login again.');
      }

      final response = await ApiService.createComplaint(
        userId: userId,
        createdByadmin: adminId,
        title: title,
        description: description,
      );

      if (response['success'] == true) {
        final complaintData = response['data'];
        return Complaint.fromJson(complaintData);
      } else {
        throw Exception(response['message'] ?? 'Failed to create complaint');
      }
    } catch (e) {
      print('❌ ComplaintService Error: $e');
      throw Exception('Failed to create complaint: $e');
    }
  }

  /// Get all complaints for current admin
  static Future<List<Complaint>> getAdminComplaints({String? status}) async {
    try {
      print('🔄 ComplaintService: Loading admin complaints');
      final adminId = await _getAdminId();

      if (adminId == null) {
        throw Exception('Admin session not found. Please login again.');
      }

      final response = await ApiService.getAdminComplaints(
        adminId,
        status: status,
      );

      if (response['success'] == true) {
        final List<dynamic> complaintsJson = response['data'] ?? [];
        return complaintsJson.map((json) => Complaint.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch complaints');
      }
    } catch (e) {
      print('❌ ComplaintService Error: $e');
      throw Exception('Failed to fetch complaints: $e');
    }
  }

  /// Get complaint details with messages
  static Future<Map<String, dynamic>> getComplaintDetails(
    String complaintId,
  ) async {
    try {
      print('🔄 ComplaintService: Loading complaint details');

      final response = await ApiService.getComplaintDetails(complaintId);

      if (response['success'] == true) {
        final data = response['data'];
        return {
          'complaint': Complaint.fromJson(data['complaint']),
          'messages': data['messages'] ?? [],
        };
      } else {
        throw Exception(
          response['message'] ?? 'Failed to fetch complaint details',
        );
      }
    } catch (e) {
      print('❌ ComplaintService Error: $e');
      throw Exception('Failed to fetch complaint details: $e');
    }
  }

  /// Update complaint status
  static Future<Complaint> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async {
    try {
      print('🔄 ComplaintService: Updating complaint status');
      final adminId = await _getAdminId();

      if (adminId == null) {
        throw Exception('Admin session not found. Please login again.');
      }

      final response = await ApiService.updateComplaintStatus(
        complaintId: complaintId,
        status: status.name,
        adminId: adminId,
      );

      if (response['success'] == true) {
        final complaintData = response['data'];
        return Complaint.fromJson(complaintData);
      } else {
        throw Exception(
          response['message'] ?? 'Failed to update complaint status',
        );
      }
    } catch (e) {
      print('❌ ComplaintService Error: $e');
      throw Exception('Failed to update complaint status: $e');
    }
  }

  /// Delete complaint
  static Future<void> deleteComplaint(String complaintId) async {
    try {
      print('🔄 ComplaintService: Deleting complaint');

      final response = await ApiService.deleteComplaint(complaintId);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete complaint');
      }
    } catch (e) {
      print('❌ ComplaintService Error: $e');
      throw Exception('Failed to delete complaint: $e');
    }
  }
}
