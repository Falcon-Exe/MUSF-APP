// lib/features/research/presentation/pages/my_submissions_page.dart

import 'package:flutter/material.dart';
import '../../logic/research_controller.dart';
import '../widgets/research_theme.dart';

class MySubmissionsPage extends StatelessWidget {
  final ResearchController controller;

  const MySubmissionsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResearchTheme.background,
      appBar: AppBar(
        backgroundColor: ResearchTheme.brandPrimary,
        centerTitle: true,
        title: const Text(
          "MY SUBMISSIONS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          children: [
            _buildInfoBanner(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: controller.mySubmissionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ResearchTheme.brandPrimary,
                      ),
                    );
                  }

                  final docs = snapshot.data ?? [];
                  final sortedDocs = List<Map<String, dynamic>>.from(docs);
                  sortedDocs.sort((a, b) {
                    final dateA = _parseDate(a['created_at']);
                    final dateB = _parseDate(b['created_at']);
                    return dateB.compareTo(dateA);
                  });

                  if (sortedDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No active submissions pending.",
                        style: TextStyle(
                          color: ResearchTheme.textLight,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: sortedDocs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = sortedDocs[index];
                      final docId = data['id']?.toString() ?? '';

                      String status = data['status']?.toString() ?? 'draft';
                      // Standardise 'draft' as 'pending' for the student UI
                      if (status == 'draft') {
                        status = 'pending';
                      }
                      
                      Color statusColor = status == 'rejected' || status == 'archived'
                          ? Colors.red
                          : (status == 'published' ? Colors.green : Colors.orange);

                      return _buildSubmissionCard(
                        context,
                        docId,
                        data,
                        status,
                        statusColor,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: ResearchTheme.accentGold.withValues(alpha: 0.1),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: ResearchTheme.accentGold, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Pending requests await Admin approval. You can delete or retract them here before review.",
              style: TextStyle(
                fontSize: 13,
                color: ResearchTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    String status,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ResearchTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          data['title'] ?? "Untitled",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: ResearchTheme.textMain,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: ResearchTheme.rose,
            size: 28,
          ),
          onPressed: () => _confirmDelete(context, docId),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Retract Submission?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ResearchTheme.brandPrimary,
          ),
        ),
        content: const Text(
          "Are you sure you want to delete this pending research request?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ResearchTheme.rose),
            onPressed: () async {
              await controller.deleteRequest(docId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Submission retracted.")),
                );
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
