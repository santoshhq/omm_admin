import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:omm_admin/complaints/complaint_module.dart';
import 'package:omm_admin/complaints/complaint_service.dart';
import 'package:omm_admin/complaints/whatsapp_message_widget.dart';
import '../utils/ist_time_util.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Complaint> _filteredComplaints = [];
  List<Complaint> _complaints = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Map<String, int> _unreadCounts = {}; // Store unread message counts
  Timer? _unreadCountsRefreshTimer;
  Timer? _autoRefreshTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _unreadCountsRefreshTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // Show detailed complaint information
  void _showComplaintDetails(BuildContext context, Complaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Complaint Details',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Status Badge (Display Only)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: complaint.status.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: complaint.status.color.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: complaint.status.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              complaint.status.displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: complaint.status.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      _buildDetailRow('Title', complaint.title),
                      const SizedBox(height: 20),

                      // Description
                      _buildDetailRow('Description', complaint.description),
                      const SizedBox(height: 20),

                      // Reporter Info
                      _buildDetailRow('Reported By', complaint.name),
                      const SizedBox(height: 20),

                      // Flat Number
                      _buildDetailRow('Flat Number', complaint.flatNo),
                      const SizedBox(height: 20),

                      // Date & Time
                      _buildDetailRow(
                        'Submitted On',
                        '${ISTTimeUtil.formatDateHeader(complaint.createdAt)} at ${ISTTimeUtil.formatMessageTime(complaint.createdAt)}',
                      ),
                      const SizedBox(height: 40),

                      // Chat Button
                      _buildFullWidthChatButton(complaint),
                      const SizedBox(height: 16), // Add bottom spacing
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF1F2937),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChatButtonWithBadge(Complaint complaint) {
    final unreadCount = _unreadCounts[complaint.id] ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WhatsAppChatScreen(
                  complaintId: complaint.id!,
                  complaintTitle: complaint.title,
                  complaint: complaint,
                ),
              ),
            );
            // Refresh unread counts when returning from chat
            _refreshUnreadCounts();
          },
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Chat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Unread messages badge
        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // Load complaints from backend with smooth animations
  Future<void> _loadComplaints({String? status, bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      } else {
        setState(() {
          _isRefreshing = true;
          _error = null;
        });
      }

      print('📋 Loading complaints from backend...');
      final complaints = await ComplaintService.getAdminComplaints(
        status: status,
      );

      print('✅ Loaded ${complaints.length} complaints');

      // Load unread message counts for all complaints
      final complaintIds = complaints
          .where((c) => c.id != null)
          .map((c) => c.id!)
          .toList();
      final unreadCounts = await ComplaintService.getUnreadMessagesCounts(
        complaintIds,
      );

      if (mounted) {
        setState(() {
          _complaints = complaints;
          _unreadCounts = unreadCounts;
          _isLoading = false;
          _isRefreshing = false;
          _filterComplaints();
        });
      }
    } catch (e) {
      print('❌ Error loading complaints: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  // Auto refresh complaints every 30 seconds
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading && !_isRefreshing) {
        print('🔄 Auto-refreshing complaints...');
        _loadComplaints(isRefresh: true);
      }
    });
  }

  // Manual refresh with pull-to-refresh
  Future<void> _onRefresh() async {
    await _loadComplaints(isRefresh: true);
  }

  @override
  void initState() {
    super.initState();
    _loadComplaints();
    _searchController.addListener(() {
      _filterComplaints();
      setState(() {});
    });
    _startUnreadCountsRefresh();
    _startAutoRefresh();
  }

  void _startUnreadCountsRefresh() {
    // Refresh unread counts every 10 seconds
    _unreadCountsRefreshTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) {
      if (mounted && !_isLoading) {
        _refreshUnreadCounts();
      }
    });
  }

  void _filterComplaints() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredComplaints = _complaints;
      } else {
        _filteredComplaints = _complaints.where((complaint) {
          final title = complaint.title.toLowerCase();
          final reporter = complaint.reporter.toLowerCase();
          return title.contains(query) || reporter.contains(query);
        }).toList();
      }
    });
  }

  // Refresh unread message counts
  Future<void> _refreshUnreadCounts() async {
    try {
      final complaintIds = _complaints
          .where((c) => c.id != null)
          .map((c) => c.id!)
          .toList();
      final unreadCounts = await ComplaintService.getUnreadMessagesCounts(
        complaintIds,
      );

      if (mounted) {
        setState(() {
          _unreadCounts = unreadCounts;
        });
      }
    } catch (e) {
      print('❌ Error refreshing unread counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              "Complaints",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: const Color(0xFF1F2937),
              ),
            ),
            if (_isRefreshing) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                ),
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            onPressed: _isRefreshing
                ? null
                : () => _loadComplaints(isRefresh: true),
            icon: Icon(
              Icons.refresh,
              color: _isRefreshing ? Colors.grey : const Color(0xFF4F46E5),
            ),
            tooltip: 'Refresh Complaints',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or reporter name...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF6B7280)),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4F46E5),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Content Area with Pull-to-Refresh
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoader()
                : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: const Color(0xFF4F46E5),
                    backgroundColor: Colors.white,
                    child: _filteredComplaints.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredComplaints.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final c = _filteredComplaints[index];
                              return _buildComplaintCard(c, index);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // Build simple loading indicator
  Widget _buildSkeletonLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF4F46E5)),
            SizedBox(height: 16),
            Text(
              'Loading complaints...',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Error loading complaints',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadComplaints(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _searchController.text.isNotEmpty
                    ? Icons.search_off
                    : Icons.report_problem_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isNotEmpty
                    ? "No complaints found"
                    : "No complaints yet",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchController.text.isNotEmpty
                    ? "Try searching with different keywords"
                    : "Complaints raised by residents will appear here",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build individual complaint card - simple and light
  Widget _buildComplaintCard(Complaint c, int index) {
    // Define background colors and border colors based on complaint status
    Color cardBackgroundColor;
    Color borderColor;
    double borderWidth;

    switch (c.status) {
      case ComplaintStatus.pending:
        cardBackgroundColor = Colors.yellow.shade50; // Light yellowish
        borderColor = Colors.yellow.shade200; // Subtle yellow border
        borderWidth = 1.0;
        break;
      case ComplaintStatus.unsolved:
        cardBackgroundColor = Colors.red.shade50; // Light reddish
        borderColor = Colors.red.shade200; // Subtle red border
        borderWidth = 1.0;
        break;
      case ComplaintStatus.solved:
        cardBackgroundColor = Colors.white; // Default white (remains same)
        borderColor = Colors.transparent; // No border for solved
        borderWidth = 0.0;
        break;
    }

    // Add subtle pulse animation for unsolved complaints
    Widget cardWidget = Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      color: cardBackgroundColor, // Apply the status-based background color
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showComplaintDetails(context, c);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getCardGradient(
              c.status,
            ), // Add subtle gradient based on status
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Title and Status
                Row(
                  children: [
                    // Status icon indicator
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: c.status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(c.status),
                        size: 16,
                        color: c.status.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: c.status.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.status.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.status.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reporter Info
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: const Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Flat Number
                Row(
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Flat ${c.flatNo}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bottom Row with Time and Chat Button
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ISTTimeUtil.formatMessageTime(c.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const Spacer(),
                    _buildChatButtonWithBadge(c),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return cardWidget;
  }

  // Get gradient decoration based on complaint status
  LinearGradient? _getCardGradient(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.yellow.shade50,
            Colors.yellow.shade100.withOpacity(0.3), // Very subtle gradient
          ],
          stops: const [0.0, 1.0],
        );
      case ComplaintStatus.unsolved:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade50,
            Colors.red.shade100.withOpacity(0.3), // Very subtle gradient
          ],
          stops: const [0.0, 1.0],
        );
      case ComplaintStatus.solved:
        return null; // No gradient for solved complaints (keep it simple)
    }
  }

  // Get appropriate icon for complaint status
  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Icons.schedule; // Clock icon for pending
      case ComplaintStatus.unsolved:
        return Icons.error_outline; // Warning icon for unsolved
      case ComplaintStatus.solved:
        return Icons.check_circle_outline; // Check icon for solved
    }
  }

  Widget _buildFullWidthChatButton(Complaint complaint) {
    final unreadCount = _unreadCounts[complaint.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 8), // Add margin for badge overflow
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56, // Fixed height for consistent layout
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WhatsAppChatScreen(
                      complaintId: complaint.id!,
                      complaintTitle: complaint.title,
                      complaint: complaint,
                    ),
                  ),
                );
                // Refresh unread counts when returning from chat
                _refreshUnreadCounts();
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: Text(
                unreadCount > 0
                    ? 'Start Chat ($unreadCount new)'
                    : 'Start Chat',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: const Color(0xFF25D366).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Unread messages badge for full width button
          if (unreadCount > 0)
            Positioned(
              right: 12,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
