// lib/features/finance/presentation/widgets/purchase_request_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'finance_theme.dart';
import '../../../../core/theme/committee_theme.dart';

class PurchaseRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final Function(String) onApprove;
  final Function(String) onReject;
  final Function(String) onDelete;

  const PurchaseRequestCard({
    super.key,
    required this.data,
    required this.docId,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  Color _getCommitteeColor(String committee) {
    return getCommitteeTheme(committee).accentColor;
  }

  @override
  Widget build(BuildContext context) {
    final String status = data['status'] ?? 'pending';
    final Color statusColor = FinanceTheme.getStatusColor(status);
    final String committee =
        data['committee_name'] ?? data['committee'] ?? data['committeeName'] ?? 'General';
    final Color committeeColor = _getCommitteeColor(committee);

    String dateStr = "N/A";
    final rawDate = data['created_at'] ?? data['submitted_at'] ?? data['submittedAt'];
    if (rawDate != null) {
      final dt = rawDate is DateTime
          ? rawDate
          : DateTime.tryParse(rawDate.toString());
      if (dt != null) {
        dateStr = DateFormat('dd MMM, hh:mm a').format(dt);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: FinanceTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: committeeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(committee.toUpperCase(), style: TextStyle(color: committeeColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              Text(dateStr, style: const TextStyle(color: FinanceTheme.textSub, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(data['item_name'] ?? data['itemName'] ?? 'Untitled Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FinanceTheme.textMain)),
          if (data['remarks'] != null && data['remarks'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(data['remarks'].toString(), style: const TextStyle(color: FinanceTheme.textSub, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("₹ ${data['estimated_price'] ?? data['estimatedPrice'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: FinanceTheme.textMain)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          if (status == 'pending') ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => onReject(docId),
                  icon: const Icon(Icons.close_rounded, color: FinanceTheme.expenseRed, size: 16),
                  label: const Text("Reject", style: TextStyle(color: FinanceTheme.expenseRed)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => onApprove(docId),
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  label: const Text("Approve", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: FinanceTheme.incomeGreen, elevation: 0),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
