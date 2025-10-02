import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'message_service.dart';

class WhatsAppMessageWidget extends StatelessWidget {
  final Message message;
  final bool isAdmin;
  final VoidCallback? onLongPress;

  const WhatsAppMessageWidget({
    Key? key,
    required this.message,
    required this.isAdmin,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isAdmin
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isAdmin) _buildAvatar(),
          if (!isAdmin) const SizedBox(width: 8.0),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(0xFF25D366) // WhatsApp green for admin
                        : Colors.grey[200], // Light grey for users
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isAdmin
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: isAdmin
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isAdmin) _buildSenderInfo() else _buildAdminInfo(),
                      const SizedBox(height: 4.0),
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isAdmin ? Colors.white : Colors.black87,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              color: isAdmin
                                  ? Colors.white70
                                  : Colors.grey[600],
                              fontSize: 12.0,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 4.0),
                            Icon(
                              Icons.done_all,
                              size: 16.0,
                              color: Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isAdmin) const SizedBox(width: 8.0),
          if (isAdmin) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: isAdmin
          ? const Color(0xFF075E54) // WhatsApp dark green for admin
          : Colors.blue[600], // Blue for members
      child: Text(
        isAdmin ? 'ADMIN' : _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isAdmin ? 8 : 16,
        ),
      ),
    );
  }

  Widget _buildSenderInfo() {
    return Container(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.senderName,
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
          if (message.senderFlat != 'N/A')
            Text(
              'Flat ${message.senderFlat}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminInfo() {
    return Container(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        'Admin',
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 14.0,
        ),
      ),
    );
  }

  String _getInitials() {
    final name = message.senderName;
    if (name.isEmpty) return 'U';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show only time
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else if (now.difference(dateTime).inDays < 7) {
      // This week - show day and time
      return DateFormat('EEE HH:mm').format(dateTime);
    } else {
      // Older - show date and time
      return DateFormat('dd/MM/yy HH:mm').format(dateTime);
    }
  }
}

class WhatsAppChatScreen extends StatefulWidget {
  final String complaintId;
  final String complaintTitle;

  const WhatsAppChatScreen({
    Key? key,
    required this.complaintId,
    required this.complaintTitle,
  }) : super(key: key);

  @override
  State<WhatsAppChatScreen> createState() => _WhatsAppChatScreenState();
}

class _WhatsAppChatScreenState extends State<WhatsAppChatScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _loadAdminIdAndMessages();
  }

  Future<void> _loadAdminIdAndMessages() async {
    // Load admin ID first, then messages
    await _loadAdminId();
    await _loadMessages();
  }

  Future<void> _loadAdminId() async {
    try {
      _adminId = await _messageService.getAdminId();
      print('✅ Admin ID loaded: $_adminId');
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ Error loading admin ID: $e');
      // Continue without admin ID - fallback logic will handle it
    }
  }

  Future<void> _loadMessages() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      final messages = await _messageService.getMessagesForComplaint(
        widget.complaintId,
      );

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();

        // Debug: Show admin ID status for positioning
        print('📋 Messages loaded: ${messages.length}, Admin ID: $_adminId');
        print('🔍 Message positioning analysis:');
        for (int i = 0; i < messages.length; i++) {
          final msg = messages[i];
          final isAdmin = msg.isAdminMessage(_adminId);
          final preview = msg.message.length > 20
              ? '${msg.message.substring(0, 20)}...'
              : msg.message;
          print(
            '   [$i] "$preview" | sender=${msg.senderId} | ${isAdmin ? '→ RIGHT (Admin)' : '← LEFT (Member)'}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    try {
      setState(() => _isSending = true);

      final newMessage = await _messageService.sendMessage(
        widget.complaintId,
        messageText,
      );

      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // WhatsApp chat background
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54), // WhatsApp dark green
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.complaintTitle,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_messages.length} messages',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Manual refresh triggered');
              _loadAdminIdAndMessages();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet.\nStart the conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isAdmin = message.isAdminMessage(_adminId);

                      // Debug: Show message positioning
                      print(
                        '💬 Message $index: "${message.message.substring(0, message.message.length > 20 ? 20 : message.message.length)}..." - Sender: ${message.senderId} - ${isAdmin ? 'ADMIN (RIGHT)' : 'MEMBER (LEFT)'}',
                      );

                      return WhatsAppMessageWidget(
                        message: message,
                        isAdmin: isAdmin,
                        onLongPress: () {
                          // TODO: Add message options (delete, copy, etc.)
                        },
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF25D366),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
