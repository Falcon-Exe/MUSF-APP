import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PublicationCard extends StatelessWidget {
  final String title;
  final String author;
  final String category;
  final String content;
  final DateTime date;
  final int likesCount;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onReadFull;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PublicationCard({
    super.key,
    required this.title,
    required this.author,
    required this.category,
    required this.content,
    required this.date,
    required this.likesCount,
    required this.isLiked,
    required this.onLike,
    required this.onReadFull,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFC5A059);
    const Color dark = Color(0xFF39544B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onReadFull,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM').format(date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),
                  Text(
                    "By $author",
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: dark, height: 1.4),
                  ),
                  const Divider(height: 30),
                  Row(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: onLike,
                          icon: Icon(
                            (isLiked == true)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: (isLiked == true) ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                      Text(
                        "$likesCount",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (onEdit != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          onPressed: onEdit,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Colors.blue,
                          ),
                          label: const Text(
                            "Edit",
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      if (onDelete != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          label: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: dark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(68, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        onPressed: onReadFull,
                        child: const Text(
                          "READ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
