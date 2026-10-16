import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/storage/r2_storage_config.dart';
import '../../../../services/cloud_storage_service.dart';

class HomeBackgroundAdminPage extends StatefulWidget {
  final VoidCallback? onBack;
  const HomeBackgroundAdminPage({super.key, this.onBack});

  @override
  State<HomeBackgroundAdminPage> createState() =>
      _HomeBackgroundAdminPageState();
}

class _HomeBackgroundAdminPageState extends State<HomeBackgroundAdminPage> {
  static const String _settingKey = 'home_background_image_url';
  static const Color _dark = Color(0xFF0F172A);

  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  String _currentUrl = '';

  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_refreshPreview);
    _loadCurrentBackground();
  }

  @override
  void dispose() {
    _urlController.removeListener(_refreshPreview);
    _urlController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCurrentBackground() async {
    setState(() => _isLoading = true);
    try {
      final row = await _client
          .from('app_settings')
          .select('setting_value')
          .eq('setting_key', _settingKey)
          .maybeSingle();
      final url = row?['setting_value']?.toString().trim() ?? '';
      if (!mounted) return;
      _urlController.text = url;
      setState(() {
        _currentUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load background image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBackground({String? overrideUrl}) async {
    final imageUrl = (overrideUrl ?? _urlController.text).trim();
    setState(() => _isSaving = true);
    try {
      await _client.from('app_settings').upsert({
        'setting_key': _settingKey,
        'setting_value': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'setting_key');
      if (!mounted) return;
      _urlController.text = imageUrl;
      setState(() {
        _currentUrl = imageUrl;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Home background saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadImage() async {
    if (!R2StorageConfig.isConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cloud upload is not configured yet. Please paste image URL.',
          ),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final upload = await CloudStorageService().uploadImage(
        folder: CloudStorageFolder.homeBackgrounds,
        fileNamePrefix: 'home_background',
      );
      if (upload == null) return;
      await _saveBackground(overrideUrl: upload.url);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('R2_SIGN_UPLOAD_ENDPOINT')
          ? 'Cloud upload is not configured yet. Please paste image URL.'
          : 'Upload failed: $e';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _resetBackground() async {
    _urlController.clear();
    await _saveBackground(overrideUrl: '');
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSaving || _isUploading;
    final uploadConfigured = R2StorageConfig.isConfigured;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Home Background Image'),
        backgroundColor: _dark,
        foregroundColor: Colors.white,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreview(),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Background Image URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: busy || !uploadConfigured
                          ? () {
                              if (!uploadConfigured) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cloud upload is not configured yet. Please paste image URL.',
                                    ),
                                  ),
                                );
                              }
                            }
                          : _uploadImage,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_rounded),
                      label: Text(
                        _isUploading
                            ? 'Uploading...'
                            : uploadConfigured
                            ? 'Upload Image'
                            : 'Upload Image unavailable',
                      ),
                    ),
                  ),
                  if (!uploadConfigured) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Cloud upload is not configured yet. Please paste image URL.',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : () => _saveBackground(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dark,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: busy ? null : _resetBackground,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Remove/Reset'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPreview() {
    final url = _urlController.text.trim().isNotEmpty
        ? _urlController.text.trim()
        : _currentUrl;

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty ? _buildDefaultPreview() : _buildNetworkPreview(url),
    );
  }

  Widget _buildNetworkPreview(String url) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultPreview(),
        ),
        _buildPreviewOverlay(),
      ],
    );
  }

  Widget _buildDefaultPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/slide1.jpeg', fit: BoxFit.cover),
        _buildPreviewOverlay(),
      ],
    );
  }

  Widget _buildPreviewOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.58),
          ],
        ),
      ),
      child: const Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Current background image preview',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class AdminLeadershipPage extends HomeBackgroundAdminPage {
  const AdminLeadershipPage({super.key, super.onBack});
}
