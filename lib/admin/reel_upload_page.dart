import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../services/cloud_storage_service.dart';

class ReelUploadPage extends StatefulWidget {
  // 🟢 1. Lock the upload to a specific committee
  final String committeeName;

  const ReelUploadPage({super.key, required this.committeeName});

  @override
  State<ReelUploadPage> createState() => _ReelUploadPageState();
}

class _ReelUploadPageState extends State<ReelUploadPage> {
  Uint8List? _imageBytes;
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  // 🟢 2. Pick and AUTO-COMPRESS the Image
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = result?.files.single.bytes;

    if (bytes != null) {
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  // 🟢 3. Upload to Firebase Storage and Firestore
  Future<void> _uploadReel() async {
    if (_imageBytes == null) return;

    setState(() => _isUploading = true);

    try {
      // Create a unique file name
      String fileName =
          "${widget.committeeName}_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final upload = await CloudStorageService().uploadBytes(
        bytes: _imageBytes!,
        folder: CloudStorageFolder.reelVideos,
        fileName: fileName,
        contentType: 'image/jpeg',
      );

      // Save to Firestore Database
      await FirebaseFirestore.instance.collection('committee_reels').add({
        'committee':
            widget.committeeName, // Automatically assigned to their department
        'imageUrl': upload.url,
        'caption': _captionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Photo Uploaded Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // 🟢 Clearly shows which committee they are uploading for
        title: Text(
          "${widget.committeeName} Upload",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        // Changed to scrollable so the keyboard doesn't block the view
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: _isUploading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: CircularProgressIndicator(
                        color: Color(0xFF0D1B2A),
                      ),
                    )
                  : _imageBytes == null
                  ? _buildEmptyState()
                  : _buildPreviewState(),
            ),
            const SizedBox(height: 40),
            if (!_isUploading)
              _buildUploadedReels(), // 🟢 Show previous uploads below
            const SizedBox(height: 100), // Padding for the floating button
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _imageBytes == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _isUploading ? null : _uploadReel,
              backgroundColor: const Color(0xFF0D1B2A),
              label: _isUploading
                  ? const Text(
                      "UPLOADING...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Text(
                      "CONFIRM UPLOAD",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              icon: _isUploading
                  ? null
                  : const Icon(Icons.cloud_upload, color: Colors.white),
            ),
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _pickImage, // Allow tapping the empty state to pick an image
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              "Tap to select a photo",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Max size: 1.5 MB (Auto-compressed)",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🟢 Show the actual image they picked instead of just a checkmark
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
            image: DecorationImage(
              image: MemoryImage(_imageBytes!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 🟢 Optional caption field
        TextField(
          controller: _captionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Write a caption for this post... (Optional)",
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),

        TextButton.icon(
          onPressed: () => setState(() {
            _imageBytes = null;
            _captionController.clear();
          }),
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text(
            "Remove Photo",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  // 🟢 4. Show Previously Uploaded Reels for this Committee
  Widget _buildUploadedReels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Manage Uploaded Reels",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('committee_reels')
              .where('committee', isEqualTo: widget.committeeName)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "No reels uploaded yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            // Sort docs by timestamp descending manually to avoid needing a composite index
            var docs = snapshot.data!.docs;
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['timestamp'] as Timestamp?;
              final bTime = bData['timestamp'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final Timestamp? tStamp = data['timestamp'] as Timestamp?;
                String dateStr = tStamp != null
                    ? DateFormat('dd MMM yyyy').format(tStamp.toDate())
                    : 'Unknown Date';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                  color: Colors.grey[50],
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['imageUrl'] ?? '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    title: Text(
                      (data['caption'] == null ||
                              data['caption'].toString().isEmpty)
                          ? "No Caption"
                          : data['caption'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "$dateStr • Tap trash icon to delete",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(
                        doc.id,
                        data['imageUrl'] ?? '',
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // 🟢 5. Delete Reel logic
  Future<void> _showDeleteConfirmation(String docId, String imageUrl) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Delete Reel",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this reel? This action cannot be undone.",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReel(docId, imageUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReel(String docId, String imageUrl) async {
    try {
      await FirebaseFirestore.instance
          .collection('committee_reels')
          .doc(docId)
          .delete();
      if (imageUrl.isNotEmpty) {
        await CloudStorageService().deleteFile(fileUrl: imageUrl);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reel deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
