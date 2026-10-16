// lib/features/finance/presentation/widgets/ledger_item_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'finance_theme.dart';

class LedgerItemCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final Function(String) onDismissed;

  const LedgerItemCard({
    super.key,
    required this.data,
    required this.docId,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = data['type'] == 'INCOME';
    final amountColor = isIncome ? FinanceTheme.incomeGreen : FinanceTheme.expenseRed;
    final iconColor = FinanceTheme.textMain.withValues(alpha: 0.7);

    String dateStr = "Unknown Date";
    if (data['date'] != null) {
      final rawDate = data['date'];
      final dt = rawDate is DateTime
          ? rawDate
          : DateTime.tryParse(rawDate.toString());
      if (dt != null) {
        dateStr = DateFormat('dd MMM yyyy').format(dt);
      }
    }

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: FinanceTheme.expenseRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(docId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(color: FinanceTheme.background, shape: BoxShape.circle),
              child: Icon(
                isIncome ? Icons.attach_money_rounded : Icons.shopping_bag_outlined,
                color: iconColor, size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['purpose'] ?? 'UNKNOWN',
                    style: const TextStyle(color: FinanceTheme.textMain, fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${data['subcommittee']} • $dateStr",
                    style: const TextStyle(color: FinanceTheme.textSub, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              "${isIncome ? '+' : '-'}₹${data['amount']}",
              style: TextStyle(color: amountColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
