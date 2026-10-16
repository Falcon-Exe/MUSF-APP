// lib/features/finance/presentation/pages/finance_ledger_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../logic/finance_controller.dart';
import '../widgets/finance_theme.dart';
import '../widgets/ledger_item_card.dart';

class FinanceLedgerPage extends StatefulWidget {
  const FinanceLedgerPage({super.key});

  @override
  State<FinanceLedgerPage> createState() => _FinanceLedgerPageState();
}

class _FinanceLedgerPageState extends State<FinanceLedgerPage> {
  final FinanceController _controller = FinanceController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinanceTheme.background,
      appBar: AppBar(
        title: const Column(
          children: [
            Text("MUSF Account Book", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Sub-committee Ledgers", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _controller.aeroLedgerStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];
          int totalIncome = 0;
          int totalExpense = 0;

          for (var data in docs) {
            int amt = (data['amount'] as num?)?.toInt() ?? int.tryParse(data['amount']?.toString() ?? '') ?? 0;
            if (data['type'] == 'INCOME') { totalIncome += amt; } else { totalExpense += amt; }
          }

          int balance = totalIncome - totalExpense;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildBalanceCard(balance),
                      const SizedBox(height: 16),
                      _buildSummaryRow(totalIncome, totalExpense),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Recent Transactions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FinanceTheme.textMain)),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (docs.isEmpty)
                const SliverToBoxAdapter(child: Center(child: Text("No entries found")))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index];
                      final docId = data['id']?.toString() ?? '';
                      return LedgerItemCard(
                        data: data,
                        docId: docId,
                        onDismissed: (id) => _controller.deleteLedger(context: context, docId: id),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(),
        backgroundColor: FinanceTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBalanceCard(int amount) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Current Balance", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text("₹ ${NumberFormat('#,##,###').format(amount)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(int inc, int exp) {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard("Income", "+ ₹$inc", Icons.arrow_upward, FinanceTheme.incomeGreen)),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard("Expense", "- ₹$exp", Icons.arrow_downward, FinanceTheme.expenseRed)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 4), Text(title, style: const TextStyle(color: FinanceTheme.textSub, fontSize: 12))]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  void _showAddEntryDialog() {
    final purposeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedType = 'INCOME';
    String selectedSub = 'MUSF UNION';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("New Entry"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioGroup<String>(
                  groupValue: selectedType,
                  onChanged: (v) => setState(() => selectedType = v ?? 'INCOME'),
                  child: Row(
                    children: [
                      Expanded(child: RadioListTile<String>(title: const Text('Income'), value: 'INCOME')),
                      Expanded(child: RadioListTile<String>(title: const Text('Expense'), value: 'EXPENSE')),
                    ],
                  ),
                ),
                TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: "Purpose")),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹)")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                int amt = int.tryParse(amountCtrl.text) ?? 0;
                if (amt > 0 && purposeCtrl.text.isNotEmpty) {
                  _controller.addLedger(context: context, date: DateTime.now(), subcommittee: selectedSub, purpose: purposeCtrl.text, type: selectedType, amount: amt);
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
