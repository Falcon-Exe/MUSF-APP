// lib/features/finance/presentation/widgets/savings_student_card.dart

import 'package:flutter/material.dart';
import 'finance_theme.dart';

class SavingsStudentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isExecutiveOrManager;
  final Function(String, String, bool) onAction; // (name, id, isDeposit)

  const SavingsStudentCard({
    super.key,
    required this.data,
    required this.isExecutiveOrManager,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final String name = data['fullName'] ?? "Unknown";
    final String studentID = data['studentID'] ?? "N/A";
    final String course = (data['course'] ?? '').toString().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: FinanceTheme.primaryBlue.withValues(alpha: 0.1),
          child: const Icon(Icons.person, size: 20, color: FinanceTheme.primaryBlue),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: FinanceTheme.textMain)),
        subtitle: Text("ID: $studentID • $course", style: const TextStyle(color: FinanceTheme.textSub)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.add_circle, color: isExecutiveOrManager ? FinanceTheme.incomeGreen : Colors.grey),
              onPressed: () => onAction(name, studentID, true),
            ),
            IconButton(
              icon: Icon(Icons.remove_circle, color: isExecutiveOrManager ? FinanceTheme.expenseRed : Colors.grey),
              onPressed: () => onAction(name, studentID, false),
            ),
          ],
        ),
      ),
    );
  }
}
