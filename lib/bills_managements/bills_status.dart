// bill_status_page.dart
// Polished, responsive, professional Flutter UI for Bill Status and Payment Requests

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:omm_admin/bills_managements/bills_modules.dart';
import 'package:omm_admin/bills_managements/bill_request_model.dart';
import 'package:omm_admin/config/api_config.dart';

class BillStatusPage extends StatefulWidget {
  final Bill bill;
  const BillStatusPage({Key? key, required this.bill}) : super(key: key);

  @override
  State<BillStatusPage> createState() => _BillStatusPageState();
}

class _BillStatusPageState extends State<BillStatusPage>
    with SingleTickerProviderStateMixin {
  List<BillRequest> requests = [];
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  late final AnimationController _animController;
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fetchRequests();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final url = Uri.parse(ApiService.updateBillRequest(requestId));
      final res = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          setState(() {
            final request = requests.firstWhere((r) => r.id == requestId);
            request.status = status;
          });
          scaffold.showSnackBar(
            SnackBar(content: Text('Request $status successfully')),
          );
        } else {
          scaffold.showSnackBar(
            SnackBar(content: Text('Failed: ${data['message']}')),
          );
        }
      } else {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Failed to update request')),
        );
      }
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _fetchRequests() async {
    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = '';
    });

    try {
      final url = Uri.parse(ApiService.getBillRequests(widget.bill.id));
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          final requestsData = data['data'] as List;
          setState(() {
            requests = requestsData
                .map((json) => BillRequest.fromJson(json))
                .toList();
            isLoading = false;
          });
          _animController.forward(from: 0);
        } else {
          setState(() {
            isLoading = false;
            isError = true;
            errorMessage = data['message'] ?? 'Unknown API response';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          errorMessage = 'Server returned ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = e.toString();
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'accepted':
        return Colors.green.shade700;
      case 'rejected':
      case 'failed':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildHeader(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final isSmall = width < 600;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F9D58), Color(0xFF34A853)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmall ? 56 : 72,
            height: isSmall ? 56 : 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Icon(
                Icons.receipt_long,
                size: isSmall ? 30 : 36,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bill.billTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: isSmall ? 18 : 22,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.bill.billDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: isSmall ? 13 : 15,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _infoChip(
                      Icons.attach_money,
                      currencyFormatter.format(widget.bill.billAmount),
                    ),
                    _infoChip(
                      Icons.calendar_today,
                      DateFormat('yyyy-MM-dd').format(widget.bill.dueDate),
                    ),
                    if (widget.bill.upiId.isNotEmpty)
                      _infoChip(
                        Icons.account_balance_wallet,
                        widget.bill.upiId,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(BuildContext ctx, BillRequest request, int index) {
    final statusColor = _statusColor(request.status);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final animationValue = Curves.easeOut.transform(
          (_animController.value - (index * 0.04)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(0, (1 - animationValue) * 12),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () => _showRequestDetails(ctx, request),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Icon(
                    request.status.toLowerCase() == 'pending'
                        ? Icons.hourglass_top
                        : request.status.toLowerCase() == 'accepted'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: statusColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${request.user.firstName} ${request.user.lastName}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Txn: ${request.transactionId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.payment, size: 14, color: Colors.black45),
                          const SizedBox(width: 6),
                          Text(
                            request.paymentApp,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRequestDetails(BuildContext ctx, BillRequest request) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (c) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _statusColor(
                        request.status,
                      ).withOpacity(0.14),
                      child: Icon(
                        Icons.person,
                        color: _statusColor(request.status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${request.user.firstName} ${request.user.lastName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${request.status}',
                            style: TextStyle(
                              color: _statusColor(request.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(),
                const SizedBox(height: 8),
                _detailRow('Transaction ID', request.transactionId),
                _detailRow('Payment App', request.paymentApp),
                _detailRow(
                  'Amount',
                  request.amount != null
                      ? currencyFormatter.format(request.amount)
                      : '-',
                ),
                _detailRow('Flat No', request.user.flatNo),
                _detailRow('Floor No', request.user.floorNo),
                _detailRow('Mobile', request.user.mobile),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(c); // Close bottom sheet
                          _updateRequestStatus(request.id, 'Accepted');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Accept",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(c); // Close bottom sheet
                          _updateRequestStatus(request.id, 'Rejected');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            _buildHeader(constraints),
            Expanded(
              child: isLoading
                  ? _buildLoadingList()
                  : isError
                  ? _buildErrorView()
                  : RefreshIndicator(
                      onRefresh: _fetchRequests,
                      child: requests.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Center(
                                  child: Text(
                                    'No payment requests yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                bottom: 16,
                                top: 8,
                              ),
                              itemCount: requests.length,
                              itemBuilder: (ctx, i) =>
                                  _buildRequestTile(ctx, requests[i], i),
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.grey[100],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              'Failed to load requests',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${widget.bill.billTitle} - Payment Requests',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7F9FB), Color(0xFFFFFFFF)],
            ),
          ),
          child: _buildBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _fetchRequests();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Refreshed')));
        },
        label: const Text('Refresh'),
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}
