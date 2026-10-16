import 'package:flutter/material.dart';
import 'dart:typed_data';

class UploadPreviewArea extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onPickImage;
  final TextEditingController captionController;
  final VoidCallback onClear;

  const UploadPreviewArea({
    super.key,
    required this.imageBytes,
    required this.onPickImage,
    required this.captionController,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytes == null) {
      return _buildEmptyState();
    } else {
      return _buildPreviewState();
    }
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text("Tap to select a photo", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Max size: 1.5 MB (Auto-compressed)", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewState() {
    return Column(
      children: [
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: captionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Write a caption for this post... (Optional)",
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text("Remove Photo", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
