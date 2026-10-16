import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExamCard extends StatelessWidget {
  final String subject;
  final String location;
  final DateTime date;
  final VoidCallback onDelete;

  const ExamCard({
    super.key,
    required this.subject,
    required this.location,
    required this.date,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text("${date.day}", style: const TextStyle(color: Colors.blue)),
        ),
        title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${DateFormat('MMM yyyy').format(date)} • $location"),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
