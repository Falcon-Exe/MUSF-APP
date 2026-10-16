// lib/features/finance/presentation/widgets/dues_transaction_dialog.dart

import 'package:flutter/material.dart';
import '../../data/repositories/finance_repository.dart';
import '../widgets/finance_theme.dart';

class DuesTransactionDialog extends StatelessWidget {
  final String studentName;
  final String studentID;
  final String docId;
  final CollectionType type;
  final Function(int, bool) onSubmit; // (amount, isAddingDebt)
  final VoidCallback onClear;

  const DuesTransactionDialog({
    super.key,
    required this.studentName,
    required this.studentID,
    required this.docId,
    required this.type,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    bool isUnion = type == CollectionType.union;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Transaction", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: FinanceTheme.expenseRed),
            tooltip: "Clear Record",
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Student: $studentName", style: const TextStyle(fontWeight: FontWeight.bold, color: FinanceTheme.textSub)),
          const SizedBox(height: 15),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Enter Amount",
              prefixIcon: const Icon(Icons.currency_rupee),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            int amt = int.tryParse(controller.text) ?? 0;
            if (amt > 0) { onSubmit(amt, false); Navigator.pop(context); }
          },
          icon: const Icon(Icons.remove, size: 16, color: Colors.white),
          label: const Text("Collect", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: FinanceTheme.incomeGreen),
        ),
        if (!isUnion) // Union doesn't add dynamic debt in legacy
          ElevatedButton.icon(
            onPressed: () {
              int amt = int.tryParse(controller.text) ?? 0;
              if (amt > 0) { onSubmit(amt, true); Navigator.pop(context); }
            },
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text("Add Due", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: FinanceTheme.expenseRed),
          ),
      ],
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Record?"),
        content: const Text("Are you sure you want to completely reset this balance to ₹0?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () { onClear(); Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text("Clear", style: TextStyle(color: FinanceTheme.expenseRed)),
          ),
        ],
      ),
    );
  }
}
