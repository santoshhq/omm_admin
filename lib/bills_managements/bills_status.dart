import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omm_admin/bills_managements/bills_modules.dart';
import 'package:omm_admin/bills_managements/bill_request_model.dart';
import 'package:omm_admin/config/api_config.dart';

class BillStatusPage extends StatefulWidget {
  final Bill bill;

  const BillStatusPage({Key? key, required this.bill}) : super(key: key);

  @override
  State<BillStatusPage> createState() => _BillStatusPageState();
}

class _BillStatusPageState extends State<BillStatusPage> {
  List<BillRequest> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
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
        }
      }
    } catch (e) {
      print('Error fetching requests: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bill.billTitle} - Payment Requests'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text('No payment requests yet'))
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: request.status == 'pending'
                          ? Colors.orange
                          : request.status == 'accepted'
                          ? Colors.green
                          : Colors.red,
                      child: Icon(
                        request.status == 'pending'
                            ? Icons.hourglass_empty
                            : request.status == 'accepted'
                            ? Icons.check
                            : Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      '${request.user.firstName} ${request.user.lastName}',
                    ),
                    subtitle: Text(
                      'Transaction: ${request.transactionId}\nAmount: ₹${widget.bill.billAmount}',
                    ),
                    trailing: request.status == 'Pending'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Accept request
                                  setState(() => request.status = 'Accepted');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Accept'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Reject request
                                  setState(() => request.status = 'Rejected');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Reject'),
                              ),
                            ],
                          )
                        : Text(request.status.toUpperCase()),
                  ),
                );
              },
            ),
    );
  }
}
