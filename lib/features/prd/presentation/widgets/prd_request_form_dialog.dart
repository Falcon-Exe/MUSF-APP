// lib/features/prd/presentation/widgets/prd_request_form_dialog.dart

import 'package:flutter/material.dart';
import '../../../../services/cloud_storage_service.dart';
import '../../logic/prd_controller.dart';
import 'prd_theme.dart';

class PrdRequestFormDialog extends StatefulWidget {
  final PrdController controller;
  final String? initialCommittee;

  const PrdRequestFormDialog({
    super.key,
    required this.controller,
    this.initialCommittee,
  });

  @override
  State<PrdRequestFormDialog> createState() => _PrdRequestFormDialogState();
}

class _PrdRequestFormDialogState extends State<PrdRequestFormDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();

  final List<String> _committees = [
    'Arts',
    'Fine Arts',
    'Sports',
    'Literary',
    'Library',
    'Social Affairs',
    'Bank',
    'Research',
    'Garden',
    'Medical',
    'Store',
    'General',
  ];
  final List<String> _types = [
    'Poster Design',
    'Video/Reel',
    'Certificate',
    'ID Card',
    'Other',
  ];

  late String _selectedCommittee;
  String _selectedType = 'Poster Design';
  String _posterUrl = '';
  bool _isUploadingPoster = false;

  @override
  void initState() {
    super.initState();
    _selectedCommittee = widget.initialCommittee ?? 'General';
    if (!_committees.contains(_selectedCommittee)) {
      _selectedCommittee = 'General';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Submit PRD Task",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: PrdTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: widget.initialCommittee != null
                      ? _buildLockedField(_selectedCommittee)
                      : _buildDropdown(
                          _selectedCommittee,
                          _committees,
                          (val) => setState(() => _selectedCommittee = val!),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    _selectedType,
                    _types,
                    (val) => setState(() => _selectedType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField(
              _titleCtrl,
              "Project Title (e.g. Debate Poster)",
              Icons.title,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              _descCtrl,
              "Details (Theme, Content, Text)",
              Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isUploadingPoster
                  ? null
                  : () async {
                      setState(() => _isUploadingPoster = true);
                      try {
                        final upload = await CloudStorageService().uploadImage(
                          folder: CloudStorageFolder.prdPosters,
                          fileNamePrefix: _titleCtrl.text.trim().isEmpty
                              ? 'prd_poster'
                              : _titleCtrl.text.trim(),
                        );
                        if (upload == null) return;
                        setState(() => _posterUrl = upload.url);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Poster upload failed: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _isUploadingPoster = false);
                      }
                    },
              icon: _isUploadingPoster
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_rounded),
              label: Text(
                _posterUrl.isEmpty ? 'Upload Poster' : 'Poster Uploaded',
              ),
            ),
            const SizedBox(height: 16),
            _buildDeadlinePicker(context),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PrdTheme.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  if (_titleCtrl.text.isEmpty || _deadlineCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill title and deadline"),
                      ),
                    );
                    return;
                  }
                  await widget.controller.submitTask({
                    'committeeName': _selectedCommittee,
                    'type': _selectedType,
                    'requestTitle': _titleCtrl.text.trim(),
                    'description': _descCtrl.text.trim(),
                    'deadline': _deadlineCtrl.text.trim(),
                    'status': 'Pending',
                    'poster_url': _posterUrl,
                    'image_url': _posterUrl,
                    'requestedBy':
                        'Committee Lead', // Standardizing requestedBy
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  "SEND TO PRD",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedField(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: Colors.blueGrey,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String current,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: PrdTheme.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.blueGrey) : null,
        hintText: hint,
        filled: true,
        fillColor: PrdTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDeadlinePicker(BuildContext context) {
    return TextField(
      controller: _deadlineCtrl,
      readOnly: true,
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(
            () => _deadlineCtrl.text =
                "${picked.day}/${picked.month}/${picked.year}",
          );
        }
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.calendar_month_rounded,
          color: Colors.blueGrey,
        ),
        hintText: "Select Deadline",
        filled: true,
        fillColor: PrdTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
