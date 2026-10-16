import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../../../../services/cloud_storage_service.dart';

class AddLeaderDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function({
    required String name,
    required String role,
    required int order,
    required String colorHex,
    required String iconName,
    Uint8List? imageBytes,
    String? imageUrl,
    String? backgroundImageUrl,
    required bool isActive,
  })
  onSave;

  const AddLeaderDialog({super.key, this.initialData, required this.onSave});

  @override
  State<AddLeaderDialog> createState() => _AddLeaderDialogState();
}

class _AddLeaderDialogState extends State<AddLeaderDialog> {
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _backgroundImageUrlCtrl = TextEditingController();
  String _selectedIcon = 'person_rounded';
  String? _currentImageUrl;
  Uint8List? _selectedImageBytes;
  bool _isActive = true;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _nameCtrl.text = d['name'] ?? '';
      _roleCtrl.text = d['role'] ?? '';
      _orderCtrl.text = d['order']?.toString() ?? '1';
      _colorCtrl.text = d['colorHex'] ?? '0xFF6366F1';
      _selectedIcon = d['iconName'] ?? 'person_rounded';
      _currentImageUrl = d['imageUrl'];
      _backgroundImageUrlCtrl.text =
          d['background_image_url'] ?? d['backgroundImageUrl'] ?? '';
      _isActive = d['is_active'] ?? d['isActive'] ?? true;
    } else {
      _orderCtrl.text = '1';
      _colorCtrl.text = '0xFF6366F1';
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isUploading = true);
    try {
      final upload = await CloudStorageService().uploadImage(
        folder: CloudStorageFolder.executiveProfileImages,
        fileNamePrefix: _nameCtrl.text.trim().isEmpty
            ? 'leader'
            : _nameCtrl.text.trim(),
      );
      if (upload == null) return;
      setState(() {
        _currentImageUrl = upload.url;
        _selectedImageBytes = null;
      });
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialData != null ? 'Edit Leader' : 'Add New Leader',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImagePicker(),
            const SizedBox(height: 16),
            _buildTextField(_nameCtrl, 'Name'),
            const SizedBox(height: 10),
            _buildTextField(_roleCtrl, 'Role (e.g. President)'),
            const SizedBox(height: 10),
            _buildTextField(
              _orderCtrl,
              'Display Order',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _buildTextField(_colorCtrl, 'Color Hex (e.g. 0xFF6366F1)'),
            const SizedBox(height: 10),
            _buildTextField(_backgroundImageUrlCtrl, 'Background Image URL'),
            const SizedBox(height: 10),
            _buildIconDropdown(),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active on Home'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _handleSave,
          child: _isUploading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: _selectedImageBytes != null
            ? MemoryImage(_selectedImageBytes!)
            : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                      ? NetworkImage(_currentImageUrl!)
                      : null)
                  as ImageProvider?,
        child:
            _selectedImageBytes == null &&
                (_currentImageUrl == null || _currentImageUrl!.isEmpty)
            ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
            : null,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildIconDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedIcon,
      decoration: const InputDecoration(
        labelText: 'Icon',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: 'person_rounded',
          child: Text('Person (Default)'),
        ),
        DropdownMenuItem(
          value: 'gavel_rounded',
          child: Text('Gavel (President)'),
        ),
        DropdownMenuItem(
          value: 'history_edu_rounded',
          child: Text('Pen (Secretary)'),
        ),
        DropdownMenuItem(
          value: 'account_balance_wallet_rounded',
          child: Text('Wallet (Treasurer)'),
        ),
      ],
      onChanged: (val) => setState(() => _selectedIcon = val!),
    );
  }

  Future<void> _handleSave() async {
    if (_nameCtrl.text.trim().isEmpty || _roleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Role are required.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    await widget.onSave(
      name: _nameCtrl.text.trim(),
      role: _roleCtrl.text.trim(),
      order: int.tryParse(_orderCtrl.text.trim()) ?? 99,
      colorHex: _colorCtrl.text.trim(),
      iconName: _selectedIcon,
      imageBytes: _selectedImageBytes,
      imageUrl: _currentImageUrl,
      backgroundImageUrl: _backgroundImageUrlCtrl.text.trim(),
      isActive: _isActive,
    );
    if (mounted) Navigator.pop(context);
  }
}
