// lib/features/prd/presentation/widgets/prd_transaction_dialog.dart

import 'package:flutter/material.dart';
import '../../logic/prd_controller.dart';
import 'prd_theme.dart';

class PrdTransactionDialog extends StatefulWidget {
  final PrdController controller;
  final String docId;
  final String studentName;
  final String studentID;

  const PrdTransactionDialog({
    super.key,
    required this.controller,
    required this.docId,
    required this.studentName,
    required this.studentID,
  });

  @override
  State<PrdTransactionDialog> createState() => _PrdTransactionDialogState();
}

class _PrdTransactionDialogState extends State<PrdTransactionDialog> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Transaction", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PrdTheme.primaryDark)),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Student: ${widget.studentName}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
          const SizedBox(height: 15),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Enter Amount",
              prefixIcon: const Icon(Icons.currency_rupee, color: PrdTheme.primaryDark, size: 20),
              filled: true, fillColor: PrdTheme.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        ElevatedButton.icon(
          onPressed: () => _process(false),
          icon: const Icon(Icons.remove, size: 16, color: Colors.white),
          label: const Text("Collect"),
          style: ElevatedButton.styleFrom(backgroundColor: PrdTheme.accentPrd, foregroundColor: Colors.white),
        ),
        ElevatedButton.icon(
          onPressed: () => _process(true),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text("Add Due"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Future<void> _process(bool isAdding) async {
    int amt = int.tryParse(_amountCtrl.text) ?? 0;
    if (amt <= 0) return;

    await widget.controller.updateBalance(widget.docId, widget.studentID, amt, isAdding);
    if (mounted) Navigator.pop(context);
    
    _showSnackbar(isAdding ? "Added ₹$amt to Due" : "Collected ₹$amt", isAdding ? Colors.redAccent : PrdTheme.accentPrd);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Record?"),
        content: const Text("Are you sure you want to delete this print record history?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await widget.controller.deleteRecord(widget.docId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context); // Close TransactionDialog too
              _showSnackbar("Print record cleared", Colors.red);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 1)));
  }
}
