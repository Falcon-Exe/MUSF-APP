import 'package:flutter/material.dart';

class LeaderListCard extends StatelessWidget {
  final String name;
  final String role;
  final int order;
  final String? imageUrl;
  final String? backgroundImageUrl;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LeaderListCard({
    super.key,
    required this.name,
    required this.role,
    required this.order,
    this.imageUrl,
    this.backgroundImageUrl,
    this.isActive = true,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey.shade100,
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
          child: imageUrl == null || imageUrl!.isEmpty
              ? const Icon(Icons.person, color: Colors.blueGrey)
              : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '$role - Order: $order - ${isActive ? 'Active' : 'Inactive'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
