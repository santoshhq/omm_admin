import 'dart:async';
import 'package:flutter/material.dart';
import 'message_service.dart';
import '../utils/ist_time_util.dart';
import 'complaint_module.dart';
import 'complaint_service.dart';

class WhatsAppMessageWidget extends StatefulWidget {
  final Message message;
  final bool isAdmin;
  final VoidCallback? onLongPress;
  final int? animationDelay;

  const WhatsAppMessageWidget({
    Key? key,
    required this.message,
    required this.isAdmin,
    this.onLongPress,
    this.animationDelay,
  }) : super(key: key);

  @override
  State<WhatsAppMessageWidget> createState() => _WhatsAppMessageWidgetState();
}

class _WhatsAppMessageWidgetState extends State<WhatsAppMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: Offset(widget.isAdmin ? 0.3 : -0.3, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Start animation with optional delay
    if (widget.animationDelay != null && widget.animationDelay! > 0) {
      Future.delayed(Duration(milliseconds: widget.animationDelay!), () {
        if (mounted) _animationController.forward();
      });
    } else {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(position: _slideAnimation, child: child),
        );
      },
      child: _buildMessageContainer(context),
    );
  }

  Widget _buildMessageContainer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: widget.isAdmin
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isAdmin) _buildAvatar(),
          if (!widget.isAdmin) const SizedBox(width: 8.0),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: GestureDetector(
                onLongPress: widget.onLongPress,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: widget.isAdmin
                        ? const Color(0xFF25D366) // WhatsApp green for admin
                        : Colors.grey[200], // Light grey for users
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: widget.isAdmin
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: widget.isAdmin
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
                      if (!widget.isAdmin)
                        _buildSenderInfo()
                      else
                        _buildAdminInfo(),
                      const SizedBox(height: 4.0),
                      Text(
                        widget.message.message,
                        style: TextStyle(
                          color: widget.isAdmin ? Colors.white : Colors.black87,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            widget.message.formatTimestampIST(),
                            style: TextStyle(
                              color: widget.isAdmin
                                  ? Colors.white70
                                  : Colors.grey[600],
                              fontSize: 12.0,
                            ),
                          ),
                          if (widget.isAdmin) ...[
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
          if (widget.isAdmin) const SizedBox(width: 8.0),
          if (widget.isAdmin) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: widget.isAdmin
          ? const Color(0xFF455A64) // WhatsApp dark green for admin
          : Colors.blue[600], // Blue for members
      child: Text(
        widget.isAdmin ? 'ADMIN' : _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: widget.isAdmin ? 8 : 16,
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
            widget.message.senderName,
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
          if (widget.message.senderFlat != 'N/A')
            Text(
              'Flat ${widget.message.senderFlat}',
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
    final name = widget.message.senderName;
    if (name.isEmpty) return 'U';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// Complaint details header widget
class ComplaintDetailsHeader extends StatefulWidget {
  final Complaint complaint;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(ComplaintStatus) onStatusChange;

  const ComplaintDetailsHeader({
    Key? key,
    required this.complaint,
    required this.isExpanded,
    required this.onToggle,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  State<ComplaintDetailsHeader> createState() => _ComplaintDetailsHeaderState();
}

class _ComplaintDetailsHeaderState extends State<ComplaintDetailsHeader> {
  bool _showSolvedWarning = false;

  @override
  void initState() {
    super.initState();
    // Show warning automatically if complaint is already solved
    if (widget.complaint.status == ComplaintStatus.solved) {
      _showSolvedWarning = true;
    }
  }

  Widget _buildTimeRemaining() {
    final now = DateTime.now();
    final complaintAge = now.difference(widget.complaint.createdAt);
    final remainingTime = const Duration(hours: 72) - complaintAge;

    if (remainingTime.isNegative) {
      // Complaint should have been deleted already
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Eligible for deletion',
          style: TextStyle(
            fontSize: 11,
            color: Colors.red[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final hoursLeft = remainingTime.inHours;
    final minutesLeft = remainingTime.inMinutes % 60;

    String timeText;
    Color timeColor;

    if (hoursLeft > 24) {
      final daysLeft = (hoursLeft / 24).floor();
      timeText = '${daysLeft}d ${hoursLeft % 24}h remaining';
      timeColor = Colors.green[700]!;
    } else if (hoursLeft > 0) {
      timeText = '${hoursLeft}h ${minutesLeft}m remaining';
      timeColor = hoursLeft > 6 ? Colors.orange[700]! : Colors.red[700]!;
    } else {
      timeText = '${minutesLeft}m remaining';
      timeColor = Colors.red[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        timeText,
        style: TextStyle(
          fontSize: 11,
          color: timeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Always visible summary
          InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.complaint.status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.complaint.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.complaint.reporter,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.complaint.status.color
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.complaint.status.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.complaint.status.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // Expandable details
          if (widget.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.complaint.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Created ${ISTTimeUtil.formatDetailedTime(widget.complaint.createdAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick status change buttons
                  const Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ComplaintStatus.values.map((status) {
                      final isSelected = widget.complaint.status == status;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: OutlinedButton(
                            onPressed: () {
                              // Show warning for solved status
                              if (status == ComplaintStatus.solved) {
                                setState(() {
                                  _showSolvedWarning = true;
                                });
                              } else {
                                setState(() {
                                  _showSolvedWarning = false;
                                });
                              }
                              widget.onStatusChange(status);
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? status.color.withOpacity(0.1)
                                  : null,
                              side: BorderSide(
                                color: isSelected
                                    ? status.color
                                    : Colors.grey[300]!,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              status.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? status.color
                                    : Colors.grey[600],
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Warning message for solved status
                  if (_showSolvedWarning &&
                      widget.complaint.status == ComplaintStatus.solved) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Solved complaints will be automatically deleted after 72 hours',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildTimeRemaining(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Date header widget for chat like WhatsApp
class DateHeaderWidget extends StatefulWidget {
  final DateTime date;

  const DateHeaderWidget({Key? key, required this.date}) : super(key: key);

  @override
  State<DateHeaderWidget> createState() => _DateHeaderWidgetState();
}

class _DateHeaderWidgetState extends State<DateHeaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFDCF8C6,
                    ).withOpacity(0.3), // Light WhatsApp green
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    ISTTimeUtil.formatDateHeader(widget.date),
                    style: const TextStyle(
                      color: Color(0xFF128C7E), // WhatsApp green
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WhatsAppChatScreen extends StatefulWidget {
  final String complaintId;
  final String complaintTitle;
  final Complaint? complaint; // Add full complaint object for better UX

  const WhatsAppChatScreen({
    Key? key,
    required this.complaintId,
    required this.complaintTitle,
    this.complaint,
  }) : super(key: key);

  @override
  State<WhatsAppChatScreen> createState() => _WhatsAppChatScreenState();
}

class _WhatsAppChatScreenState extends State<WhatsAppChatScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  List<dynamic> _chatItems = []; // Mixed list of messages and date headers
  bool _isLoading = true;
  bool _isSending = false;
  String? _adminId;
  Timer? _autoRefreshTimer;
  bool _showComplaintDetails = false; // Control complaint details visibility
  bool _showScrollToBottomButton = false; // Show scroll to bottom button

  @override
  void initState() {
    super.initState();
    _loadAdminIdAndMessages();
    _startAutoRefresh();
    _scrollController.addListener(_scrollListener);

    // Mark complaint as read when chat is opened
    _markComplaintAsRead();
  }

  Future<void> _markComplaintAsRead() async {
    try {
      await ComplaintService.markComplaintAsRead(widget.complaintId);
      print('✅ Marked complaint ${widget.complaintId} as read');
    } catch (e) {
      print('❌ Error marking complaint as read: $e');
    }
  }

  void _scrollListener() {
    if (mounted) {
      final shouldShow = !_isScrolledToBottom();
      if (shouldShow != _showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = shouldShow;
        });
      }
    }
  }

  void _startAutoRefresh() {
    // Auto-refresh messages every 5 seconds for real-time feel
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isLoading && !_isSending) {
        _loadMessagesQuietly(); // Load without showing loading indicator
      }
    });
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

      // Add a small delay for smoother transition
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _messages = messages;
          _chatItems = _buildChatItemsWithDateHeaders(messages);
          _isLoading = false;
        });

        // Small delay before scrolling for better animation timing
        await Future.delayed(const Duration(milliseconds: 100));

        // Scroll to bottom after initial load
        if (messages.isNotEmpty) {
          _scrollToBottomWithAnimation();
        }

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

  // Build chat items with date headers
  List<dynamic> _buildChatItemsWithDateHeaders(List<Message> messages) {
    final List<dynamic> chatItems = [];
    DateTime? lastDate;

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageDate = message.timestampIST;

      // Check if we need to add a date header
      if (lastDate == null ||
          ISTTimeUtil.isDifferentDay(lastDate, messageDate)) {
        chatItems.add('DATE_HEADER:${messageDate.toIso8601String()}');
        lastDate = messageDate;
      }

      chatItems.add(message);
    }

    return chatItems;
  }

  // Quiet loading for auto-refresh (no loading indicator)
  Future<void> _loadMessagesQuietly() async {
    try {
      final messages = await _messageService.getMessagesForComplaint(
        widget.complaintId,
      );

      if (mounted) {
        // Only update if there are new messages
        if (messages.length != _messages.length) {
          final hadMessages = _messages.isNotEmpty;
          final newMessageCount = messages.length - _messages.length;
          final wasAtBottom = _isScrolledToBottom();

          setState(() {
            _messages = messages;
            _chatItems = _buildChatItemsWithDateHeaders(messages);
          });

          // Mark complaint as read again when new messages are loaded
          if (newMessageCount > 0) {
            _markComplaintAsRead();
          }

          // Auto-scroll for new messages (like real chat apps)
          if (hadMessages && newMessageCount > 0) {
            // Auto-scroll to bottom if user was already near bottom or if it's a new message
            if (wasAtBottom || newMessageCount > 0) {
              _scrollToBottomWithAnimation();
            }

            // Show subtle notification with gentle animation
            if (newMessageCount > 0) {
              /*ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.new_releases,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$newMessageCount new message${newMessageCount > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF25D366),
                  margin: const EdgeInsets.only(
                    bottom: 80,
                    left: 16,
                    right: 16,
                  ),
                ),
              );*/
            }
          }

          print(
            '🔄 Auto-refresh: Found ${messages.length} messages (was ${_messages.length - newMessageCount})',
          );
        }
      }
    } catch (e) {
      // Silently handle errors during auto-refresh
      print('⚠️ Auto-refresh error: $e');
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

      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _chatItems = _buildChatItemsWithDateHeaders(_messages);
          _messageController.clear();
          _isSending = false;
        });

        // Always scroll to bottom for sent messages with smooth animation
        _scrollToBottomWithAnimation();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if user is scrolled to bottom (within 100 pixels)
  bool _isScrolledToBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) < 100;
  }

  // Smooth auto-scroll to bottom like real chat apps
  void _scrollToBottomWithAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // WhatsApp chat background
      resizeToAvoidBottomInset: true, // Ensure proper keyboard handling
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
            Row(
              children: [
                Text(
                  '${_messages.length} messages',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Live',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
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
      body: Stack(
        children: [
          Column(
            children: [
              // Complaint details header (if complaint object is provided)
              if (widget.complaint != null)
                ComplaintDetailsHeader(
                  complaint: widget.complaint!,
                  isExpanded: _showComplaintDetails,
                  onToggle: () {
                    setState(() {
                      _showComplaintDetails = !_showComplaintDetails;
                    });
                  },
                  onStatusChange: (newStatus) async {
                    try {
                      // Show loading indicator
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text('Updating status...'),
                              ],
                            ),
                          ),
                        );
                      }

                      // Update status via API
                      await ComplaintService.updateComplaintStatus(
                        complaintId: widget.complaint!.id!,
                        status: newStatus,
                      );

                      // Update local state
                      if (mounted) {
                        setState(() {
                          widget.complaint!.status = newStatus;
                        });
                      }

                      // Clear loading snackbar and show success
                      if (mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Status updated to ${newStatus.displayName}',
                            ),
                            backgroundColor: newStatus.color,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }

                      print(
                        '✅ Status updated successfully to ${newStatus.displayName}',
                      );
                    } catch (e) {
                      // Clear loading snackbar and show error
                      if (mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '❌ Failed to update status: ${e.toString().replaceAll('Exception: ', '')}',
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                      print('❌ Error updating status: $e');
                    }
                  },
                ),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No messages yet.\nStart the conversation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: _chatItems.length,
                        itemBuilder: (context, index) {
                          final item = _chatItems[index];

                          // Check if this is a date header
                          if (item is String &&
                              item.startsWith('DATE_HEADER:')) {
                            final dateString = item.substring(
                              'DATE_HEADER:'.length,
                            );
                            final date = DateTime.parse(dateString);
                            return DateHeaderWidget(date: date);
                          }

                          // Otherwise it's a message
                          final message = item as Message;
                          final isAdmin = message.isAdminMessage(_adminId);

                          // Debug: Show message positioning
                          print(
                            '💬 Message $index: "${message.message.substring(0, message.message.length > 20 ? 20 : message.message.length)}..." - Sender: ${message.senderId} - ${isAdmin ? 'ADMIN (RIGHT)' : 'MEMBER (LEFT)'}',
                          );

                          // Calculate staggered animation delay for smooth loading
                          final messageIndex = _chatItems
                              .where((item) => item is Message)
                              .toList()
                              .indexOf(message);
                          final animationDelay = messageIndex < 10
                              ? messageIndex * 50
                              : 0; // Only animate first 10 messages

                          return WhatsAppMessageWidget(
                            message: message,
                            isAdmin: isAdmin,
                            animationDelay: animationDelay,
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
          // Floating scroll to bottom button with animation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showScrollToBottomButton ? 80 : -60,
            right: 16,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              scale: _showScrollToBottomButton ? 1.0 : 0.0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showScrollToBottomButton ? 1.0 : 0.0,
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottomWithAnimation,
                  backgroundColor: const Color(0xFF25D366),
                  elevation: 4,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF25D366).withOpacity(value),
                  ),
                  strokeWidth: 3.0,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Loading text with fade animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: const Text(
                  'Loading messages...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // Animated dots
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(0xFF25D366).withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              );
            },
          ),
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
                onTap: () {
                  // Auto-scroll when user taps to type (like real chat apps)
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) _scrollToBottomWithAnimation();
                  });
                },
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
    _autoRefreshTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
