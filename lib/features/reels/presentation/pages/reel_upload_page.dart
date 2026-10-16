import 'package:flutter/material.dart';
import '../../data/repositories/supabase_reels_repository.dart';
import '../../logic/reels_controller.dart';
import '../widgets/upload_preview_area.dart';
import '../widgets/uploaded_reels_list.dart';

class ReelUploadPage extends StatefulWidget {
  final String committeeName;

  const ReelUploadPage({super.key, required this.committeeName});

  @override
  State<ReelUploadPage> createState() => _ReelUploadPageState();
}

class _ReelUploadPageState extends State<ReelUploadPage> {
  late final ReelsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReelsController(SupabaseReelsRepository());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("${widget.committeeName} Upload", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Center(
                child: _controller.isUploading
                    ? const Padding(padding: EdgeInsets.only(top: 100), child: CircularProgressIndicator(color: Color(0xFF0D1B2A)))
                    : UploadPreviewArea(
                        imageBytes: _controller.imageBytes,
                        onPickImage: _controller.pickImage,
                        captionController: _controller.captionController,
                        onClear: _controller.clearSelection,
                      ),
              ),
              const SizedBox(height: 40),
              if (!_controller.isUploading)
                UploadedReelsList(
                  stream: _controller.getReelsStream(widget.committeeName),
                  onDelete: _controller.deleteReel,
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _controller.imageBytes == null
            ? null
            : _buildUploadFab(),
      ),
    );
  }

  Widget _buildUploadFab() {
    return FloatingActionButton.extended(
      onPressed: _controller.isUploading ? null : _handleUpload,
      backgroundColor: const Color(0xFF0D1B2A),
      label: Text(_controller.isUploading ? "UPLOADING..." : "CONFIRM UPLOAD", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      icon: _controller.isUploading ? null : const Icon(Icons.cloud_upload, color: Colors.white),
    );
  }

  Future<void> _handleUpload() async {
    bool success = await _controller.uploadReel(widget.committeeName);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo Uploaded Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload failed!"), backgroundColor: Colors.red));
      }
    }
  }
}
