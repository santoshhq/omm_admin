import 'dart:async';
import '../config/api_config.dart';
import '../services/admin_session_service.dart';
import 'complaint_module.dart';
import 'message_service.dart';

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
      print('🔑 Admin ID from session: $adminId');

      if (adminId == null) {
        throw Exception('Admin session not found. Please login again.');
      }

      print('📋 Fetching complaints for admin: $adminId, status: $status');

      final response = await ApiService.getAdminComplaints(
        adminId,
        status: status,
      );

      print('🔍 Raw API Response: $response');

      if (response['success'] == true) {
        final List<dynamic> complaintsJson = response['data'] ?? [];
        print('✅ Parsed ${complaintsJson.length} complaints from response');

        final complaints = complaintsJson
            .map((json) => Complaint.fromJson(json))
            .toList();
        print('✅ Successfully parsed ${complaints.length} complaints');

        return complaints;
      } else {
        print('❌ API response indicates failure: ${response['message']}');
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

  /// Check and delete expired solved complaints (72+ hours old)
  static Future<void> cleanupExpiredSolvedComplaints() async {
    try {
      print('🔄 ComplaintService: Checking for expired solved complaints');

      // Get all solved complaints
      final solvedComplaints = await getAdminComplaints(status: 'solved');
      final now = DateTime.now();

      for (final complaint in solvedComplaints) {
        // Check if complaint is older than 72 hours (3 days)
        final ageInHours = now.difference(complaint.createdAt).inHours;

        if (ageInHours >= 72) {
          print(
            '🗑️ Auto-deleting expired solved complaint: ${complaint.title} (${ageInHours}h old)',
          );
          await deleteComplaint(complaint.id!);
        }
      }

      print('✅ Cleanup completed');
    } catch (e) {
      print('❌ Error during cleanup: $e');
      // Don't throw exception - cleanup should be non-critical
    }
  }

  static Timer? _cleanupTimer;

  /// Initialize periodic cleanup (call this when app starts)
  static void initializeAutoCleanup() {
    // Cancel existing timer if any
    _cleanupTimer?.cancel();

    // Run cleanup immediately
    cleanupExpiredSolvedComplaints();

    // Schedule periodic cleanup every 12 hours
    _cleanupTimer = Timer.periodic(const Duration(hours: 12), (timer) {
      cleanupExpiredSolvedComplaints();
    });

    print('🔄 Auto-cleanup initialized - will run every 12 hours');
  }

  /// Stop the auto-cleanup timer
  static void stopAutoCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    print('🛑 Auto-cleanup stopped');
  }

  /// Get unread messages count for a specific complaint
  static Future<int> getUnreadMessagesCount(String complaintId) async {
    try {
      final messageService = MessageService();
      return await messageService.getUnreadMessagesCount(complaintId);
    } catch (e) {
      print('❌ ComplaintService Error getting unread count: $e');
      return 0;
    }
  }

  /// Get unread messages counts for multiple complaints
  static Future<Map<String, int>> getUnreadMessagesCounts(
    List<String> complaintIds,
  ) async {
    try {
      final Map<String, int> unreadCounts = {};

      // Get unread count for each complaint
      for (final complaintId in complaintIds) {
        unreadCounts[complaintId] = await getUnreadMessagesCount(complaintId);
      }

      return unreadCounts;
    } catch (e) {
      print('❌ ComplaintService Error getting unread counts: $e');
      return {};
    }
  }

  /// Mark complaint as read when admin opens the chat
  static Future<void> markComplaintAsRead(String complaintId) async {
    try {
      final messageService = MessageService();
      await messageService.markComplaintAsRead(complaintId);
    } catch (e) {
      print('❌ ComplaintService Error marking complaint as read: $e');
    }
  }
}
