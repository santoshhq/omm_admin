import '../config/api_config.dart';
import '../services/admin_session_service.dart';
import '../utils/ist_time_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageSender {
  final String? id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? flatNo;

  MessageSender({
    this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.flatNo,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['_id'] ?? json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'],
      email: json['email'],
      flatNo: json['flatNo'],
    );
  }

  String get fullName => firstName + (lastName != null ? ' $lastName' : '');
  String get displayName =>
      '$fullName${flatNo != null ? ' (Flat $flatNo)' : ''}';
}

class Message {
  final String? id;
  final String complaintId;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final DateTime? createdAt;
  final bool isDeleted;
  final MessageSender? senderDetails;

  Message({
    this.id,
    required this.complaintId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.createdAt,
    this.isDeleted = false,
    this.senderDetails,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      // Handle timestamp parsing
      DateTime timestamp;
      if (json['timestamp'] is String) {
        timestamp = DateTime.parse(json['timestamp']);
      } else if (json['createdAt'] is String) {
        timestamp = DateTime.parse(json['createdAt']);
      } else {
        timestamp = DateTime.now();
      }

      // Handle isDeleted field with null safety
      bool isDeleted = false;
      if (json['isDeleted'] != null) {
        if (json['isDeleted'] is bool) {
          isDeleted = json['isDeleted'];
        } else if (json['isDeleted'] is String) {
          isDeleted = json['isDeleted'].toLowerCase() == 'true';
        }
      }

      // Parse sender details if populated
      MessageSender? senderDetails;
      if (json['senderId'] != null &&
          json['senderId'] is Map<String, dynamic>) {
        senderDetails = MessageSender.fromJson(json['senderId']);
      }

      final message = Message(
        id: json['_id'] ?? json['id'],
        complaintId: json['complaintId'] ?? '',
        senderId: json['senderId'] is String
            ? json['senderId']
            : json['senderId']?['_id'] ?? '',
        message: json['message'] ?? '',
        timestamp: timestamp,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        isDeleted: isDeleted,
        senderDetails: senderDetails,
      );

      return message;
    } catch (e) {
      print('❌ Message.fromJson Error: $e');
      print('❌ Message.fromJson JSON was: $json');
      throw Exception('Failed to parse message JSON: $e');
    }
  }

  // Get sender name with fallback
  String get senderName {
    if (senderDetails != null) {
      return senderDetails!.fullName;
    }
    return 'Unknown User';
  }

  // Get sender flat with fallback
  String get senderFlat {
    if (senderDetails != null && senderDetails!.flatNo != null) {
      return senderDetails!.flatNo!;
    }
    return 'N/A';
  }

  // Get display name for WhatsApp-style chat
  String get senderDisplayName {
    if (senderDetails != null) {
      return senderDetails!.displayName;
    }
    return 'Unknown User';
  }

  // Convert server timestamp to Indian Standard Time (IST)
  DateTime get timestampIST {
    return ISTTimeUtil.toIST(timestamp);
  }

  // Format timestamp for display with IST and detailed date/day info
  String formatTimestampIST() {
    return ISTTimeUtil.formatMessageTime(timestamp);
  }

  // Format timestamp for detailed display
  String formatDetailedTimestampIST() {
    return ISTTimeUtil.formatDetailedTime(timestamp);
  }

  // Determine if sender is admin by comparing with current admin ID
  bool isAdminMessage(String? currentAdminId) {
    if (senderId.isEmpty) {
      print('🔍 Message positioning: Empty senderId → Member message (LEFT)');
      return false;
    }

    // Check if this sender ID is in our known admin IDs list
    if (MessageService._isKnownAdminId(senderId)) {
      print(
        '🔍 Message positioning: senderId=$senderId is in known admin list → Admin message (RIGHT)',
      );
      return true;
    }

    // If currentAdminId is available, use direct comparison
    if (currentAdminId != null && currentAdminId.isNotEmpty) {
      final isAdmin = senderId == currentAdminId;
      if (isAdmin) {
        // Add to known admin IDs for future reference
        MessageService._addKnownAdminId(senderId);
      }
      print(
        '🔍 Message positioning: senderId=$senderId, currentAdminId=$currentAdminId → ${isAdmin ? 'Admin message (RIGHT)' : 'Member message (LEFT)'}',
      );
      return isAdmin;
    }

    // Enhanced fallback logic using populated sender details from backend
    print('⚠️ No admin ID available, analyzing sender details...');

    // Now with backend fix: Check if sender has member characteristics
    if (senderDetails != null) {
      final hasFullMemberDetails =
          senderDetails!.firstName.isNotEmpty &&
          senderDetails!.flatNo != null &&
          senderDetails!.flatNo!.isNotEmpty;

      // If has flatNo, it's definitely a member (residents have flat numbers)
      if (hasFullMemberDetails) {
        print(
          '🔍 Sender analysis: Has member details (${senderDetails!.firstName}, Flat ${senderDetails!.flatNo}) → Member message (LEFT)',
        );
        return false;
      }

      // If has name but no flatNo, likely admin (admins don't have flats)
      if (senderDetails!.firstName.isNotEmpty &&
          (senderDetails!.flatNo == null || senderDetails!.flatNo!.isEmpty)) {
        print(
          '🔍 Sender analysis: Has name but no flat (${senderDetails!.firstName}) → Likely Admin message (RIGHT)',
        );
        MessageService._addKnownAdminId(senderId);
        return true;
      }
    }

    // If no sender details populated, fall back to content analysis
    final messageText = message.toLowerCase();
    final hasAdminKeywords =
        messageText.contains('resolved') ||
        messageText.contains('working on') ||
        messageText.contains('will fix');

    if (hasAdminKeywords) {
      print(
        '🔍 Content analysis: Contains admin keywords → Admin message (RIGHT)',
      );
      MessageService._addKnownAdminId(senderId);
      return true;
    }

    // Default to member message if unclear
    print('🔍 Fallback: No clear indicators → Member message (LEFT)');
    return false;
  }
}

class MessageService {
  // Store admin IDs that we've seen sending messages
  static final Set<String> _knownAdminIds = <String>{};

  // Add admin ID to known list
  static void _addKnownAdminId(String adminId) {
    _knownAdminIds.add(adminId);
    print(
      '✅ Added admin ID to known list: $adminId (total: ${_knownAdminIds.length})',
    );
  }

  // Check if sender ID is in known admin list
  static bool _isKnownAdminId(String senderId) {
    return _knownAdminIds.contains(senderId);
  }

  // Get messages for a complaint with populated sender details
  Future<List<Message>> getMessagesForComplaint(String complaintId) async {
    try {
      print('� MessageService: Getting messages for complaint: $complaintId');

      final response = await ApiService.getMessagesByComplaint(complaintId);

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> messagesJson = response['data'] as List<dynamic>;

        final List<Message> messages = messagesJson
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .where((message) => !message.isDeleted)
            .toList();

        // Sort by timestamp for chronological order
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        print(
          '✅ MessageService: Successfully loaded ${messages.length} messages',
        );
        return messages;
      } else {
        print('⚠️ MessageService: No messages found or API returned failure');
        return [];
      }
    } catch (e) {
      print('❌ MessageService Error getting messages: $e');
      throw Exception('Failed to load messages: $e');
    }
  }

  // Send a new message
  Future<Message> sendMessage(String complaintId, String message) async {
    try {
      print('� MessageService: Sending message for complaint: $complaintId');

      // Get admin ID
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception('Admin session not found. Please login again.');
      }

      // Add admin ID to known list before sending
      MessageService._addKnownAdminId(adminId);

      final response = await ApiService.sendMessage(
        complaintId: complaintId,
        senderId: adminId,
        message: message,
      );

      if (response['success'] == true && response['data'] != null) {
        final Message newMessage = Message.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        print('✅ MessageService: Message sent successfully');
        return newMessage;
      } else {
        final errorMsg = response['message'] ?? 'Unknown error';
        print('❌ MessageService: Failed to send message - $errorMsg');
        throw Exception('Failed to send message: $errorMsg');
      }
    } catch (e) {
      print('❌ MessageService Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Get admin ID for message positioning
  Future<String?> getAdminId() async {
    try {
      return await AdminSessionService.getAdminId();
    } catch (e) {
      print('⚠️ MessageService: Could not get admin ID: $e');
      return null;
    }
  }

  // Mark message as read (if needed for future functionality)
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      // This would be implemented when backend supports read receipts
      print('📖 MessageService: Marking message $messageId as read');
      return true;
    } catch (e) {
      print('❌ MessageService Error marking message as read: $e');
      return false;
    }
  }

  // Mark complaint as read (when admin opens the chat)
  Future<void> markComplaintAsRead(String complaintId) async {
    try {
      print('📖 MessageService: Marking complaint $complaintId as read');

      final prefs = await SharedPreferences.getInstance();
      final key = 'last_read_$complaintId';
      final now = DateTime.now().toIso8601String();

      await prefs.setString(key, now);
      print('✅ MessageService: Marked complaint $complaintId as read at $now');
    } catch (e) {
      print('❌ MessageService Error marking complaint as read: $e');
    }
  }

  // Get the last time admin read this complaint
  Future<DateTime?> getLastReadTime(String complaintId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'last_read_$complaintId';
      final lastReadString = prefs.getString(key);

      if (lastReadString != null) {
        return DateTime.parse(lastReadString);
      }
      return null;
    } catch (e) {
      print('❌ MessageService Error getting last read time: $e');
      return null;
    }
  }

  // Get count of unread messages for a complaint
  Future<int> getUnreadMessagesCount(String complaintId) async {
    try {
      print(
        '🔍 MessageService: Getting unread messages count for complaint: $complaintId',
      );

      // Get all messages for the complaint
      final messages = await getMessagesForComplaint(complaintId);

      // Get admin ID to determine which messages are from users (not admin)
      final adminId = await getAdminId();

      if (adminId == null) {
        print('⚠️ MessageService: No admin ID found, returning 0 unread count');
        return 0;
      }

      // Get the last time admin read this complaint
      final lastReadTime = await getLastReadTime(complaintId);

      // Count messages that are:
      // 1. Not from admin (from users)
      // 2. Newer than the last time admin viewed this complaint
      final unreadCount = messages.where((message) {
        // Check if message is not from admin
        final isFromUser = !message.isAdminMessage(adminId);

        if (!isFromUser) return false; // Skip admin messages

        // If no last read time, all user messages are unread
        if (lastReadTime == null) return true;

        // Check if message is newer than last read time
        final messageTime = message.timestamp;
        final isNewer = messageTime.isAfter(lastReadTime);

        return isNewer;
      }).length;

      print(
        '✅ MessageService: Found $unreadCount unread messages (last read: $lastReadTime)',
      );
      return unreadCount;
    } catch (e) {
      print('❌ MessageService Error getting unread count: $e');
      return 0;
    }
  }
}
