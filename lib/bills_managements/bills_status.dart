import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:omm_admin/bills_managements/bills_modules.dart';

class BillStatusPage extends StatelessWidget {
  final Bill bill;
  final List<Map<String, dynamic>> payments;

  BillStatusPage({
    Key? key,
    required this.bill,
    List<Map<String, dynamic>>? payments,
  }) : payments = payments ?? _samplePayments(),
       super(key: key);

  static List<Map<String, dynamic>> _samplePayments() {
    return [
      {'sno': 1, 'flat': 'A101', 'name': 'Priya Sharma', 'paid': true},
      {'sno': 2, 'flat': 'B203', 'name': 'Rajesh Kumar', 'paid': false},
      {'sno': 3, 'flat': 'C305', 'name': 'Neha Verma', 'paid': true},
      {'sno': 4, 'flat': 'D410', 'name': 'Amit Joshi', 'paid': false},
      {'sno': 5, 'flat': 'E512', 'name': 'Anjali Gupta', 'paid': true},
      {'sno': 6, 'flat': 'F601', 'name': 'Suresh Mehta', 'paid': false},
      {'sno': 7, 'flat': 'G720', 'name': 'Karan Singh', 'paid': true},
      {'sno': 8, 'flat': 'H810', 'name': 'Rita Patel', 'paid': false},
    ];
  }

  @override
  Widget build(BuildContext context) {
    // (Export handled by the top-level _exportToCSV method below)

    final sortedPayments = List<Map<String, dynamic>>.from(payments)
      ..sort((a, b) {
        final pa = a['paid'] as bool;
        final pb = b['paid'] as bool;
        return (pa ? 1 : 0).compareTo(pb ? 1 : 0); // unpaid first
      });

    final totalMembers = payments.length;
    final paidCount = payments.where((p) => (p['paid'] as bool)).length;
    final collectedAmount = paidCount * bill.amount;
    final totalAmount = totalMembers * bill.amount;
    final pendingAmount = totalAmount - collectedAmount;

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bill Status',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'Delete bill',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete bill'),
                  content: const Text(
                    'Are you sure you want to delete this bill?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('No'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Yes',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // return the deleted bill id to the caller
                Navigator.of(context).pop(bill.id);
              }
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Bill Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blueGrey.shade50,
                          child: Icon(
                            Icons.receipt_long,
                            size: 30,
                            color: Colors.blueGrey[700],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bill.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "₹${bill.amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${bill.title} — charge for ${bill.category}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 Summary: Collected / Pending / Total
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryTile(
                      "Collected",
                      "₹${collectedAmount.toStringAsFixed(2)}",
                      color: Colors.green,
                    ),
                    _buildSummaryTile(
                      "Pending",
                      "₹${pendingAmount.toStringAsFixed(2)}",
                      color: Colors.orange,
                    ),
                    _buildSummaryTile(
                      "Total",
                      "₹${totalAmount.toStringAsFixed(2)}",
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 Payments List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.payment, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Payments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.download,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Export CSV",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    _exportToCSV(context, sortedPayments);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: SizedBox(
                height: 350, // ✅ Fixed height
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: screenWidth - 40,
                              ),
                              child: DataTable(
                                columnSpacing: 20,
                                headingRowColor: MaterialStateProperty.all(
                                  Colors.grey.shade200,
                                ),
                                border: TableBorder(
                                  horizontalInside: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 0.7,
                                  ),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'S.No',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Flat No',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: sortedPayments.map((p) {
                                  final paid = p['paid'] as bool;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(p['sno'].toString())),
                                      DataCell(Text(p['flat'])),
                                      DataCell(Text(p['name'])),
                                      DataCell(
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: paid
                                                    ? Colors.green.shade100
                                                    : Colors.red.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Text(
                                                paid ? 'Paid' : 'Not Paid',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: paid
                                                      ? Colors.green[800]
                                                      : Colors.red[800],
                                                ),
                                              ),
                                            ),
                                            if (!paid) ...[
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed: () {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Reminder sent to ${p['name']}',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.notifications_active,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Send reminder',
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 CSV Export with Share
  Future<void> _exportToCSV(
    BuildContext context,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      List<List<dynamic>> rows = [
        ["S.No", "Flat No", "Name", "Status"],
        ...data.map(
          (p) => [
            p['sno'],
            p['flat'],
            p['name'],
            (p['paid'] as bool) ? "Paid" : "Not Paid",
          ],
        ),
      ];

      String csvData = const ListToCsvConverter().convert(rows);

      // Save file in temp directory using the bill category in the filename
      final dir = await getTemporaryDirectory();
      final safeCategory = bill.category.replaceAll(
        RegExp(r"[^A-Za-z0-9_]"),
        '_',
      );
      final filename =
          'bill_status_${safeCategory}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final path = '${dir.path}/$filename';
      final file = File(path);
      await file.writeAsString(csvData, flush: true);

      // Share the file
      await Share.shareXFiles([XFile(path)], text: "Bill Status Export");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to export CSV: $e")));
    }
  }

  /// 🔹 Reusable summary tile
  Widget _buildSummaryTile(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
