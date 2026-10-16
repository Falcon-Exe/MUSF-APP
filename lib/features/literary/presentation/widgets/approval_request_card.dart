import 'package:flutter/material.dart';

class ApprovalRequestCard extends StatelessWidget {
  final String title;
  final String author;
  final String category;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onDelete;

  const ApprovalRequestCard({
    super.key,
    required this.title,
    required this.author,
    required this.category,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFC5A059);
    const Color dark = Color(0xFF39544B);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF1F5F9),
          child: Icon(Icons.description_outlined, color: gold),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: dark),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text("By $author • $category", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: onApprove,
              tooltip: "Approve",
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.orange),
              onPressed: onReject,
              tooltip: "Reject",
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: "Permanent Delete",
              ),
          ],
        ),
      ),
    );
  }
}
