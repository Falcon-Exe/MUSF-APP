// lib/features/research/presentation/widgets/research_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'research_theme.dart';

class ResearchDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResearchDetailsDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    String title = data['title'] ?? "Untitled";
    String author = data['author'] ?? "Unknown";
    String paperText =
        data['full_paper'] ??
        data['description'] ??
        data['abstract'] ??
        "No paper text provided.";
    String category = data['category'] ?? data['field'] ?? "General";
    final rawDate = data['published_at'] ?? data['date'];
    String dateStr = rawDate != null
        ? DateFormat('MMMM dd, yyyy').format(_parseDate(rawDate))
        : "Recently Published";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ResearchTheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ResearchTheme.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        color: ResearchTheme.accentIndigo,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: ResearchTheme.textMuted,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: ResearchTheme.textMain,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Author: $author  |  $dateStr",
                        style: const TextStyle(
                          color: ResearchTheme.textMuted,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(height: 1),
                      ),
                      const Text(
                        "Full Paper",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: ResearchTheme.brandPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        paperText,
                        style: const TextStyle(
                          color: ResearchTheme.textMuted,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
