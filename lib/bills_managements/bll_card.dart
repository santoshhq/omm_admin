import 'package:flutter/material.dart';
import 'package:omm_admin/bills_managements/bills_modules.dart';
import 'package:omm_admin/bills_managements/bills_status.dart';
import 'package:omm_admin/services/admin_session_service.dart';

/// 🔹 Bill Card Widget
class BillCard extends StatelessWidget {
  final Bill bill;
  final ValueChanged<String?>? onDelete;

  const BillCard({super.key, required this.bill, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final iconSize = isSmallScreen ? 24.0 : 28.0;
        final titleSize = isSmallScreen ? 15.0 : 17.0;
        final subtitleSize = isSmallScreen ? 12.0 : 14.0;
        final amountSize = isSmallScreen ? 14.0 : 16.0;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BillStatusPage(bill: bill)),
                );
              },
              splashColor: Colors.blue.withOpacity(0.1),
              highlightColor: Colors.blue.withOpacity(0.05),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      bill.isPaid
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: bill.isPaid
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status Indicator
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: bill.isPaid
                            ? Colors.green.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: bill.isPaid ? Colors.green : Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        bill.isPaid ? Icons.check_circle : Icons.pending,
                        color: bill.isPaid ? Colors.green : Colors.orange,
                        size: iconSize,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Main Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bill Title
                          Text(
                            bill.billTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Category and Due Date
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  bill.category
                                      .replaceAll('-', ' ')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: subtitleSize,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                bill.dueDate.toLocal().toString().split(' ')[0],
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // UPI and Created Date
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  bill.upiId,
                                  style: TextStyle(
                                    fontSize: subtitleSize,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                bill.createdAt.toLocal().toString().split(
                                  ' ',
                                )[0],
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),

                          // Description (if space allows)
                          if (!isSmallScreen) ...[
                            const SizedBox(height: 6),
                            Text(
                              bill.billDescription,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: subtitleSize - 1,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Amount Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: bill.isPaid ? Colors.green : Colors.blueGrey,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (bill.isPaid ? Colors.green : Colors.blueGrey)
                                    .withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.currency_rupee,
                            color: Colors.white,
                            size: 18,
                          ),
                          Text(
                            bill.billAmount.toStringAsFixed(0),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: amountSize,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 🔹 Bill Form Widget
/*class BillForm extends StatefulWidget {
  const BillForm({super.key});

  @override
  State<BillForm> createState() => _BillFormState();
}

class _BillFormState extends State<BillForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  String _selectedCategory = 'Select';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Add New Bill',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bill Title',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => val!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bill Description',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => val!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  final v = double.tryParse(val.trim());
                  if (v == null) return 'Enter a valid number';
                  if (v <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _upiCtrl,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => val!.isEmpty ? 'Enter UPI ID' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                value: _selectedCategory,
                items:
                    [
                          'Select',
                          'maintenance',
                          'security-services',
                          'cleaning',
                          'amenities',
                          'others',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Due Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.calendar_today,
                      color: Colors.blueGrey,
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: _selectedDate,
                      );
                      if (picked != null)
                        setState(() => _selectedDate = picked);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.blueGrey[700])),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Add', style: TextStyle(color: Colors.white)),
          onPressed: () async {
            print('Add button pressed');
            if (!_formKey.currentState!.validate()) {
              print('Form validation failed');
              return;
            }
            print('Form validation passed');

            final parsedAmount = double.tryParse(_amountCtrl.text.trim());
            if (parsedAmount == null || parsedAmount <= 0) {
              print('Invalid amount: ${parsedAmount}');
              return;
            }
            print('Parsed amount: $parsedAmount');

            if (_selectedCategory == 'Select') {
              print('Category not selected');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a category')),
              );
              return;
            }
            print('Selected category: $_selectedCategory');

            // Fetch adminId from session
            print('Fetching admin ID from session...');
            final adminId = await AdminSessionService.getAdminId();
            if (adminId == null) {
              print('Admin ID is null');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin not logged in')),
              );
              return;
            }
            print('Fetched admin ID: $adminId');

            final bill = Bill(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              billTitle: _titleCtrl.text.trim(),
              billDescription: _descriptionCtrl.text.trim(),
              category: _selectedCategory,
              billAmount: parsedAmount,
              upiId: _upiCtrl.text.trim(),
              dueDate: _selectedDate,
              createdByAdminId: adminId,
            );
            print('Created bill object: ${bill.toJson()}');

            print('Popping bill back to previous screen');
            Navigator.pop(context, bill);
          },
        ),
      ],
    );
  }
}*/
