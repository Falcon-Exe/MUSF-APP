// lib/features/research/presentation/widgets/research_paper_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../logic/research_controller.dart';
import 'research_theme.dart';
import 'research_details_dialog.dart';

class ResearchPaperCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final ResearchController controller;
  final VoidCallback? onLike;

  const ResearchPaperCard({
    super.key,
    required this.docId,
    required this.data,
    required this.controller,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    String dateStr = _formatDate(data['date']);
    String title = data['title'] ?? "Untitled";
    String author = data['author'] ?? "Unknown";
    String abstractSnippet = data['abstract'] ?? "No abstract provided.";
    String category = data['field'] ?? "General";

    int likes = data['likes'] ?? 0;
    bool isLiked = controller.isLiked(docId);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: ResearchTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ResearchTheme.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => ResearchDetailsDialog(data: data),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: ResearchTheme.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ResearchTheme.textMain,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Authenticated by $author",
                style: const TextStyle(
                  color: ResearchTheme.textMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                abstractSnippet,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ResearchTheme.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(
                    onTap: onLike ?? () => controller.toggleLike(docId, likes),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: isLiked
                                ? ResearchTheme.rose
                                : ResearchTheme.textLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            likes.toString(),
                            style: TextStyle(
                              color: isLiked
                                  ? ResearchTheme.rose
                                  : ResearchTheme.textLight,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Read Full Abstract",
                        style: TextStyle(
                          color: ResearchTheme.brandPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_right_alt_rounded,
                        size: 20,
                        color: ResearchTheme.brandPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate is DateTime) {
      return DateFormat('MMM dd, yyyy').format(rawDate);
    }
    if (rawDate is String) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        return DateFormat('MMM dd, yyyy').format(parsed.toLocal());
      }
    }
    return "Recent";
  }
}
