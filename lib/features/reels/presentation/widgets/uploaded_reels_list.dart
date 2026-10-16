import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UploadedReelsList extends StatelessWidget {
  final Stream stream;
  final Function(String docId, String imageUrl) onDelete;

  const UploadedReelsList({super.key, required this.stream, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Manage Uploaded Reels", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        StreamBuilder(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || (snapshot.data as QuerySnapshot).docs.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No reels uploaded yet.", style: TextStyle(color: Colors.grey))));
            }

            var docs = (snapshot.data as QuerySnapshot).docs;
            docs.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final String docId = docs[index].id;
                final String imageUrl = data['imageUrl'] ?? '';
                final Timestamp? tStamp = data['timestamp'] as Timestamp?;
                String dateStr = tStamp != null ? DateFormat('dd MMM yyyy').format(tStamp.toDate()) : 'Unknown Date';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                  color: Colors.grey[50],
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image)),
                    ),
                    title: Text((data['caption']?.toString().isEmpty ?? true) ? "No Caption" : data['caption'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text("$dateStr • Tap trash to delete", style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                    trailing: IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.red), onPressed: () => _confirmDelete(context, docId, imageUrl)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String docId, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Reel", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this reel? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { onDelete(docId, imageUrl); Navigator.pop(ctx); }, child: const Text("Delete", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
