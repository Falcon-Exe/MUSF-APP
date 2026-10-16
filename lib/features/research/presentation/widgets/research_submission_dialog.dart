// lib/features/research/presentation/widgets/research_submission_dialog.dart

import 'package:flutter/material.dart';
import '../../../../services/cloud_storage_service.dart';
import '../../logic/research_controller.dart';
import 'research_theme.dart';

class ResearchSubmissionDialog extends StatefulWidget {
  final ResearchController controller;

  const ResearchSubmissionDialog({super.key, required this.controller});

  @override
  State<ResearchSubmissionDialog> createState() =>
      _ResearchSubmissionDialogState();
}

class _ResearchSubmissionDialogState extends State<ResearchSubmissionDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _abstractController = TextEditingController();
  String _localCategory = "Science";
  String _pdfUrl = '';
  bool _isUploadingPdf = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _studentIdController.dispose();
    _abstractController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Submit Research",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ResearchTheme.brandPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Sent to Admin for verification. Track status in 'My Submissions'.",
              style: TextStyle(color: ResearchTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 25),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  ['Science', 'Technology', 'Social', 'Literature', 'Arts'].map(
                    (cat) {
                      final isSelected = _localCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) =>
                            setState(() => _localCategory = cat),
                        selectedColor: ResearchTheme.brandPrimary,
                        backgroundColor: ResearchTheme.background,
                        side: BorderSide(
                          color: isSelected
                              ? ResearchTheme.brandPrimary
                              : ResearchTheme.brandPrimary.withValues(
                                  alpha: 0.45,
                                ),
                          width: 1.1,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : ResearchTheme.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        showCheckmark: false,
                      );
                    },
                  ).toList(),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              _titleController,
              "Research Paper Title",
              Icons.title_rounded,
            ),
            const SizedBox(height: 15),
            _buildInputField(
              _authorController,
              "Principal Author Name",
              Icons.person_outline_rounded,
            ),
            const SizedBox(height: 15),
            _buildInputField(
              _studentIdController,
              "Official Student ID (e.g. 17208)",
              Icons.badge_rounded,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _abstractController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Enter a brief abstract snippet...",
                hintStyle: const TextStyle(color: ResearchTheme.textLight),
                filled: true,
                fillColor: ResearchTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: _isUploadingPdf
                  ? null
                  : () async {
                      setState(() => _isUploadingPdf = true);
                      try {
                        final upload = await CloudStorageService().uploadPdf(
                          folder: CloudStorageFolder.researchPapers,
                          fileNamePrefix: _titleController.text.trim().isEmpty
                              ? 'research_paper'
                              : _titleController.text.trim(),
                        );
                        if (upload == null) return;
                        setState(() => _pdfUrl = upload.url);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('PDF upload failed: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _isUploadingPdf = false);
                      }
                    },
              icon: _isUploadingPdf
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                _pdfUrl.isEmpty ? 'Upload Research PDF' : 'PDF Uploaded',
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ResearchTheme.brandPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  if (_titleController.text.isEmpty ||
                      _authorController.text.isEmpty ||
                      _studentIdController.text.isEmpty) {
                    return;
                  }

                  await widget.controller.submitPaper({
                    'title': _titleController.text.trim(),
                    'author': _authorController.text.trim(),
                    'studentID': _studentIdController.text.trim(),
                    'abstract': _abstractController.text.trim(),
                    'field': _localCategory,
                    'file_url': _pdfUrl,
                    'pdf_url': _pdfUrl,
                  });

                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Manuscript sent to Admin!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text(
                  "SUBMIT TO ADMIN",
                  style: TextStyle(
                    color: ResearchTheme.accentGold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: ResearchTheme.textLight),
        prefixIcon: Icon(icon, color: ResearchTheme.textLight),
        filled: true,
        fillColor: ResearchTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
