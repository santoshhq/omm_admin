import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omm_admin/bills_managements/bills_modules.dart';
import 'package:omm_admin/bills_managements/bll_card.dart';
import 'package:omm_admin/bills_managements/bill_add_page.dart';
import 'package:omm_admin/config/api_config.dart';
import 'package:omm_admin/services/admin_session_service.dart';

class BillManagementPage extends StatefulWidget {
  const BillManagementPage({super.key});

  @override
  State<BillManagementPage> createState() => _BillManagementPageState();
}

class _BillManagementPageState extends State<BillManagementPage> {
  final List<Bill> bills = [];

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    print('_fetchBills called');
    final adminId = await AdminSessionService.getAdminId();
    if (adminId == null) {
      print('Admin ID null in _fetchBills');
      return;
    }
    print('Admin ID: $adminId');

    try {
      final url = Uri.parse(ApiService.getBillsByAdmin(adminId));
      print('Fetch URL: $url');
      final res = await http.get(url);
      print('Fetch response status: ${res.statusCode}');
      print('Fetch response body: ${res.body}');

      if (res.statusCode == 200) {
        final responseJson = jsonDecode(res.body);
        if (responseJson['status'] == true) {
          final billsData = responseJson['data'] as List;
          final fetchedBills = billsData
              .map((json) => Bill.fromJson(json))
              .toList();
          print('Fetched ${fetchedBills.length} bills for admin');
          setState(() {
            bills.clear();
            bills.addAll(fetchedBills);
          });
        } else {
          print('Backend error: ${responseJson['message']}');
        }
      } else {
        print('Failed to fetch bills: ${res.statusCode}');
      }
    } catch (e) {
      print('Error in _fetchBills: $e');
    }
  }

  void _addBill(Bill bill) async {
    print('_addBill called with bill: ${bill.toJson()}');
    // Fetch admin ID from session
    final adminId = await AdminSessionService.getAdminId();
    if (adminId == null) {
      print('Admin ID null in _addBill');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin not logged in')));
      return;
    }
    print('Admin ID in _addBill: $adminId');

    try {
      final url = Uri.parse(ApiService.createBill);
      print('API URL: $url');
      final billData = bill.toJson();
      billData['createdByAdminId'] = adminId;
      print('Bill data to send: $billData');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(billData),
      );
      print('Response status: ${res.statusCode}');
      print('Response body: ${res.body}');

      if (res.statusCode == 201 || res.statusCode == 200) {
        final responseJson = jsonDecode(res.body);
        final billJson =
            responseJson['data'] ??
            responseJson; // Handle both {data: bill} and direct bill
        final responseData = Bill.fromJson(billJson);
        print('Bill created successfully, adding to list');
        setState(() {
          bills.add(responseData);
        });
      } else {
        print(
          'Failed to create bill - Status: ${res.statusCode}, Body: ${res.body}',
        );
        try {
          final errorData = jsonDecode(res.body);
          print(
            'Backend error details: Status=${errorData['status']}, Message=${errorData['message']}, Error=${errorData['error']}',
          );
        } catch (e) {
          print('Could not parse error response: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create bill: ${res.body}')),
        );
      }
    } catch (e) {
      print('Error in _addBill: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Management'),
        elevation: 1,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Total Amount Collected Container
            LayoutBuilder(
              builder: (context, constraints) {
                double iconSize = constraints.maxWidth * 0.06;
                double fontSizeTitle = constraints.maxWidth * 0.045;
                double spacing = constraints.maxWidth * 0.02;

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: spacing * 2,
                    horizontal: spacing * 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade100, Colors.green.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.25),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title + Month Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: Colors.blueGrey,
                                size: iconSize,
                              ),
                              SizedBox(width: spacing),
                              Text(
                                'Total Amount Collected',
                                style: TextStyle(
                                  fontSize: fontSizeTitle,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          // Month Button
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                240,
                                242,
                                243,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing * 2,
                                vertical: spacing * 0.8,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              final currentMonthIndex =
                                  DateTime.now().month - 1;
                              final previousMonths = Bill.months.sublist(
                                0,
                                currentMonthIndex,
                              );
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Previous Months'),
                                  content: SizedBox(
                                    width: double.minPositive,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: previousMonths.length,
                                      itemBuilder: (context, index) => ListTile(
                                        title: Text(previousMonths[index]),
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              Bill.getCurrentMonth(),
                              style: TextStyle(
                                fontSize: fontSizeTitle * 0.85,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing * 1.5),
                      // Amount Row with Rupee Icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(spacing),
                            child: Icon(
                              Icons.currency_rupee,
                              size: iconSize,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing * 1.5),
                      // Additional Info Row
                      Row(
                        children: [
                          Icon(
                            Icons.list_alt,
                            size: iconSize * 0.65,
                            color: Colors.blueGrey,
                          ),
                          SizedBox(width: spacing / 2),
                          Text(
                            'Total Bills: ${bills.length}',
                            style: TextStyle(
                              fontSize: fontSizeTitle * 0.85,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: spacing * 2),
                          Icon(
                            Icons.pending_actions,
                            size: iconSize * 0.65,
                            color: Colors.orange,
                          ),
                          SizedBox(width: spacing / 2),
                          Text(
                            'Pending: ${bills.where((b) => !b.isPaid).length}',
                            style: TextStyle(
                              fontSize: fontSizeTitle * 0.85,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Bill Cards List
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.receipt_long,
                          color: Colors.blueGrey,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Current Bills",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: bills.isEmpty
                            ? const Center(
                                child: Text(
                                  'No bills yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await _fetchBills();
                                },
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: bills.length,
                                  itemBuilder: (context, index) => BillCard(
                                    bill: bills[index],
                                    onDelete: (deletedId) {
                                      if (deletedId == null) return;
                                      setState(() {
                                        bills.removeWhere(
                                          (b) => b.id == deletedId,
                                        );
                                      });
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final newBill = await Navigator.push<Bill>(
            context,
            MaterialPageRoute(builder: (_) => const AddBillPage()),
          );
          if (newBill != null) _addBill(newBill);
        },
      ),
    );
  }
}
