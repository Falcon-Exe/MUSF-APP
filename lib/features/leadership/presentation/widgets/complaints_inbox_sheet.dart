import 'package:flutter/material.dart';

class ComplaintsInboxSheet extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> complaintsStream;
  final Function(String) onDeleteComplaint;

  const ComplaintsInboxSheet({
    super.key,
    required this.complaintsStream,
    required this.onDeleteComplaint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildComplaintsList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, color: Colors.white, size: 36),
          SizedBox(height: 8),
          Text(
            'Complaints & Suggestions',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: complaintsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No complaints or suggestions yet.',
              style: TextStyle(color: Colors.blueGrey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index];
            final docId = data['id']?.toString() ?? '';
            return _buildComplaintCard(docId, data);
          },
        );
      },
    );
  }

  String _formatTime(dynamic created) {
    if (created == null) return 'Just now';
    DateTime? dt;
    if (created is DateTime) {
      dt = created;
    } else if (created is String) {
      dt = DateTime.tryParse(created);
    }
    if (dt == null) return 'Just now';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildComplaintCard(String docId, Map<String, dynamic> data) {
    final type = data['type'] ?? 'Complaint';
    final title = data['title'] ?? '';
    final message = data['message'] ?? '';
    final studentID = data['studentID'] ?? data['student_id'] ?? '';
    final String timeStr = _formatTime(data['createdAt'] ?? data['created_at']);

    Color typeColor = Colors.redAccent;
    IconData typeIcon = Icons.report_problem_rounded;
    if (type == 'Suggestion') {
      typeColor = Colors.amber;
      typeIcon = Icons.lightbulb_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 18),
                const SizedBox(width: 6),
                Text(type, style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                  onPressed: () => onDeleteComplaint(docId),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
            const SizedBox(height: 8),
            Text('From: $studentID', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
}
