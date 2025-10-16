import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omm_admin/bills_managements/bills_modules.dart';
import 'package:omm_admin/bills_managements/bll_card.dart';
import 'package:omm_admin/bills_managements/bill_add_page.dart';
import 'package:omm_admin/bills_managements/bill_request_model.dart';
import 'package:omm_admin/config/api_config.dart';
import 'package:omm_admin/services/admin_session_service.dart';
import 'package:intl/intl.dart';

class BillManagementPage extends StatefulWidget {
  const BillManagementPage({super.key});

  @override
  State<BillManagementPage> createState() => _BillManagementPageState();
}

class _BillManagementPageState extends State<BillManagementPage> {
  final List<Bill> bills = [];
  final List<Bill> _filteredBills = [];
  double totalCollectedAmount = 0.0;
  String _selectedMonth = Bill.getCurrentMonth();
  bool _isMonthPickerExpanded = false;

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
            _filterBillsByMonth(_selectedMonth);
          });
          // Calculate total collected amount after fetching bills
          _calculateTotalCollectedAmount();
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

  void _filterBillsByMonth(String monthName) {
    final monthIndex =
        Bill.months.indexOf(monthName) + 1; // Convert to 1-based month
    final filteredBills = bills.where((bill) {
      return bill.createdAt.month == monthIndex &&
          bill.createdAt.year == DateTime.now().year;
    }).toList();

    setState(() {
      _selectedMonth = monthName;
      _filteredBills.clear();
      _filteredBills.addAll(filteredBills);
    });

    print('Filtered ${filteredBills.length} bills for month: $monthName');
  }

  Future<void> _calculateTotalCollectedAmount() async {
    double total = 0.0;

    for (final bill in bills) {
      try {
        final url = Uri.parse(ApiService.getBillRequests(bill.id));
        final res = await http.get(url);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['status'] == true) {
            final requestsData = data['data'] as List;
            final requests = requestsData
                .map((json) => BillRequest.fromJson(json))
                .toList();

            // Sum amounts from accepted requests
            for (final request in requests) {
              if (request.status.toLowerCase() == 'accepted' &&
                  request.amount != null) {
                total += request.amount!;
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching requests for bill ${bill.id}: $e');
      }
    }

    setState(() {
      totalCollectedAmount = total;
    });
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
          _filterBillsByMonth(_selectedMonth);
        });
        // Recalculate total collected amount after adding new bill
        _calculateTotalCollectedAmount();
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
                          // Professional Month Picker
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    _isMonthPickerExpanded =
                                        !_isMonthPickerExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing * 1.5,
                                    vertical: spacing * 0.8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        size: iconSize * 0.7,
                                        color: Colors.blue.shade600,
                                      ),
                                      SizedBox(width: spacing * 0.5),
                                      Text(
                                        _selectedMonth,
                                        style: TextStyle(
                                          fontSize: fontSizeTitle * 0.85,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(width: spacing * 0.3),
                                      Icon(
                                        _isMonthPickerExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: iconSize * 0.7,
                                        color: Colors.grey.shade600,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Month Dropdown (when expanded)
                      if (_isMonthPickerExpanded) ...[
                        SizedBox(height: spacing),
                        Container(
                          constraints: BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: Bill.months.length,
                            itemBuilder: (context, index) {
                              final month = Bill.months[index];
                              final isSelected = month == _selectedMonth;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _filterBillsByMonth(month);
                                    setState(() {
                                      _isMonthPickerExpanded = false;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing * 1.5,
                                      vertical: spacing,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue.shade50
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: index < Bill.months.length - 1
                                            ? BorderSide(
                                                color: Colors.grey.shade200,
                                              )
                                            : BorderSide.none,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: iconSize * 0.6,
                                          color: isSelected
                                              ? Colors.blue.shade600
                                              : Colors.grey.shade600,
                                        ),
                                        SizedBox(width: spacing),
                                        Text(
                                          month,
                                          style: TextStyle(
                                            fontSize: fontSizeTitle * 0.8,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.blue.shade600
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const Spacer(),
                                          Icon(
                                            Icons.check,
                                            size: iconSize * 0.6,
                                            color: Colors.blue.shade600,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
                          SizedBox(width: spacing),
                          Text(
                            '₹${totalCollectedAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: fontSizeTitle * 1.2,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          SizedBox(width: spacing * 0.5),
                          IconButton(
                            onPressed: _calculateTotalCollectedAmount,
                            icon: Icon(
                              Icons.refresh,
                              size: iconSize * 0.8,
                              color: Colors.blue.shade600,
                            ),
                            tooltip: 'Refresh total amount',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                            'Total Bills: ${_filteredBills.length}',
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
                            'Pending: ${_filteredBills.where((b) => !b.isPaid).length}',
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              color: Colors.blueGrey,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Bills for $_selectedMonth",
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            '${_filteredBills.length} bill${_filteredBills.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: _filteredBills.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No bills found for $_selectedMonth',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try selecting a different month or create a new bill',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await _fetchBills();
                                },
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: _filteredBills.length,
                                  itemBuilder: (context, index) => BillCard(
                                    bill: _filteredBills[index],
                                    onDelete: (deletedId) {
                                      if (deletedId == null) return;
                                      setState(() {
                                        bills.removeWhere(
                                          (b) => b.id == deletedId,
                                        );
                                        _filterBillsByMonth(_selectedMonth);
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
