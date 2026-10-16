import 'package:flutter/material.dart';
import 'library_theme.dart';

class BookCatalogCard extends StatelessWidget {
  final String title;
  final String author;
  final String? imageUrl;
  final VoidCallback? onDelete;

  const BookCatalogCard({
    super.key,
    required this.title,
    required this.author,
    this.imageUrl,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LibraryTheme.cardDecoration,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    width: 70,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: LibraryTheme.textMain,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  "by $author",
                  style: const TextStyle(
                    color: LibraryTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: LibraryTheme.error),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 90,
      color: LibraryTheme.primary.withValues(alpha: 0.1),
      child: const Icon(Icons.book, color: LibraryTheme.primary),
    );
  }
}
