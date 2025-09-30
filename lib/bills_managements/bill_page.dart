import 'package:flutter/material.dart';
import 'package:omm_admin/bills_managements/bills_modules.dart';
import 'package:omm_admin/bills_managements/bll_card.dart';
// import 'dart:math' as math; // unused

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  List<Bill> bills = [
    Bill(
      id: '1',
      title: 'Elevator Bill',
      category: 'Maintenance',
      amount: 2500,
      dueDate: DateTime.now().add(const Duration(days: 7)),
    ),
    Bill(
      id: '2',
      title: 'Security Salaries',
      category: 'Security Services',
      amount: 15000,
      dueDate: DateTime.now().add(const Duration(days: 15)),
    ),
  ];

  void _addBill(Bill bill) {
    setState(() {
      bills.add(bill);
    });
  }

  double getTotalAmount() {
    return bills.fold(0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    // final currentMonth = "${DateTime.now().month}-${DateTime.now().year}";

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
            // 🔹 Total Amount Collected Container
            LayoutBuilder(
              builder: (context, constraints) {
                // Use constraints to adjust sizes dynamically
                double iconSize =
                    constraints.maxWidth * 0.06; // adaptive icon size
                double fontSizeTitle =
                    constraints.maxWidth * 0.045; // title font
                double fontSizeAmount =
                    constraints.maxWidth * 0.07; // amount font
                double spacing = constraints.maxWidth * 0.02; // dynamic spacing

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
                      // 🔹 Header Row: Title + Month Button
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
                          // 🔹 Month Button
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
                              minimumSize: const Size(
                                0,
                                0,
                              ), // remove default min size
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
                                          // Handle month selection
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
                      // 🔹 Amount Row with Rupee Icon
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
                            getTotalAmount().toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: fontSizeAmount,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing * 1.5),
                      // 🔹 Additional Info Row: Total / Pending Bills
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

            // 🔹 Bill Cards List
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ), // reduce padding to increase width
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title with Icon
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

                    // List of Bills
                    Expanded(
                      child: SizedBox(
                        width: double.infinity, // take full horizontal space
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
                            : ListView.builder(
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
          final newBill = await showDialog<Bill>(
            context: context,
            builder: (context) => const BillForm(),
          );
          if (newBill != null) _addBill(newBill);
        },
      ),
    );
  }
}
