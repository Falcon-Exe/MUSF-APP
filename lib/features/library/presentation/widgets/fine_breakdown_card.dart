import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'library_theme.dart';

class FineBreakdownCard extends StatelessWidget {
  final String type;
  final int amount;
  final DateTime date;
  final VoidCallback? onDelete;

  const FineBreakdownCard({
    super.key,
    required this.type,
    required this.amount,
    required this.date,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    bool isAddition = type == 'Addition';
    Color statusColor = isAddition ? LibraryTheme.error : LibraryTheme.success;

    return Container(
      decoration: LibraryTheme.cardDecoration,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(
            isAddition ? Icons.arrow_upward : Icons.arrow_downward,
            color: statusColor,
          ),
        ),
        title: Text(
          "$type: ₹$amount",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: LibraryTheme.textMain,
          ),
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy, hh:mm a').format(date),
          style: const TextStyle(color: LibraryTheme.textMuted, fontSize: 12),
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: LibraryTheme.error),
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}
