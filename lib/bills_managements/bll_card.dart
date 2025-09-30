import 'package:flutter/material.dart';
import 'package:omm_admin/bills_managements/bills_modules.dart';
import 'package:omm_admin/bills_managements/bills_status.dart';

/// 🔹 Section Header Widget

/// 🔹 Bill Card Widget (Redesigned)
class BillCard extends StatelessWidget {
  final Bill bill;
  final ValueChanged<String?>? onDelete;

  const BillCard({super.key, required this.bill, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => BillStatusPage(bill: bill)))
            .then((result) {
              // If the details page returned a deleted bill id, notify parent
              if (result is String && onDelete != null) onDelete!(result);
            });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        shadowColor: Colors.grey.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Status Icon
              Icon(
                bill.isPaid ? Icons.check_circle : Icons.pending_actions,
                color: bill.isPaid ? Colors.green : Colors.orange,
                size: 36,
              ),
              const SizedBox(width: 12),
              // 🔹 Bill Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      bill.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category
                    Text(
                      bill.category,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Due Date
                    Text(
                      'Due: ${bill.dueDate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // 🔹 Amount Column
              Row(
                children: [
                  const Icon(
                    Icons.currency_rupee,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    bill.amount.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 Bill Form Widget
class BillForm extends StatefulWidget {
  const BillForm({super.key});

  @override
  State<BillForm> createState() => _BillFormState();
}

class _BillFormState extends State<BillForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
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
              DropdownButtonFormField(
                value: _selectedCategory,
                items:
                    [
                          'Select',
                          'Security Services',
                          'Maintenance',
                          'Cleaning',
                          'Amenities',
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
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            final parsed = double.tryParse(_amountCtrl.text.trim());
            if (parsed == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
              return;
            }

            if (_selectedCategory == 'Select' || _selectedCategory.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a category')),
              );
              return;
            }

            final bill = Bill(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: _titleCtrl.text.trim(),
              category: _selectedCategory,
              amount: parsed,
              dueDate: _selectedDate,
            );
            Navigator.pop(context, bill);
          },
        ),
      ],
    );
  }
}
////