import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsPage extends StatefulWidget {
  final bool isAdmin;
  const SettingsPage({super.key, required this.isAdmin});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _globalNotif = true;
  bool _eventNotif = true;
  bool _libraryNotif = true;
  bool _complaintNotif = true;

  String _cacheSize = "Calculating...";

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    if (widget.isAdmin) {
      _calculateCacheSize();
    }
  }

  void _loadPreferences() {
    setState(() {
      _globalNotif = PreferencesService.getGlobalNotifications();
      _eventNotif = PreferencesService.getEventReminders();
      _libraryNotif = PreferencesService.getLibraryDueDates();
      _complaintNotif = PreferencesService.getComplaintUpdates();
    });
  }

  Future<void> _calculateCloudStorageSize() async {
    if (mounted) {
      setState(() {
        _cacheSize = "Cloudflare R2";
      });
    }
  }

  Future<void> _calculateCacheSize() async {
    // Keep local cache calculation as well if needed, or just switch to cloud
    _calculateCloudStorageSize();
  }

  void _showAnnouncementDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Broadcast Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will send a global alert to all students.'),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39544B),
            ),
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  bodyController.text.trim().isEmpty) {
                return;
              }

              await Supabase.instance.client.from('executive_announcements').insert({
                'title': titleController.text.trim(),
                'body': bodyController.text.trim(),
                'sender': 'Admin',
                'timestamp': DateTime.now().toUtc().toIso8601String(),
              });
              await Supabase.instance.client.from('notifications').insert({
                'student_id': 'all',
                'title': titleController.text.trim(),
                'message': bodyController.text.trim(),
                'type': 'broadcast',
              });

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement Broadcasted!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: palette.brandDark,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance'),
          _buildCard(
            palette.surface,
            Column(
              children: [
                ListTile(
                  leading: Icon(Icons.dark_mode_rounded, color: palette.accent),
                  title: const Text('Dark Mode'),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeNotifier.value,
                    dropdownColor: palette.surface,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        themeNotifier.value = mode;
                        PreferencesService.setThemeMode(mode);
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Notifications'),
          _buildCard(
            palette.surface,
            Column(
              children: [
                SwitchListTile(
                  activeThumbColor: palette.accent,
                  secondary: Icon(
                    Icons.notifications_active_rounded,
                    color: palette.accent,
                  ),
                  title: const Text('Global Notifications'),
                  subtitle: const Text('Enable or disable all app alerts'),
                  value: _globalNotif,
                  onChanged: (v) {
                    setState(() => _globalNotif = v);
                    PreferencesService.setGlobalNotifications(v);
                  },
                ),
                if (_globalNotif) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    activeThumbColor: palette.accent,
                    secondary: const Icon(Icons.event_rounded),
                    title: const Text('Event Reminders'),
                    value: _eventNotif,
                    onChanged: (v) {
                      setState(() => _eventNotif = v);
                      PreferencesService.setEventReminders(v);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeThumbColor: palette.accent,
                    secondary: const Icon(Icons.menu_book_rounded),
                    title: const Text('Library Due Dates'),
                    value: _libraryNotif,
                    onChanged: (v) {
                      setState(() => _libraryNotif = v);
                      PreferencesService.setLibraryDueDates(v);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeThumbColor: palette.accent,
                    secondary: const Icon(Icons.report_problem_rounded),
                    title: const Text('Complaint Updates'),
                    value: _complaintNotif,
                    onChanged: (v) {
                      setState(() => _complaintNotif = v);
                      PreferencesService.setComplaintUpdates(v);
                    },
                  ),
                ],
              ],
            ),
          ),

          if (widget.isAdmin) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Admin Options', color: Colors.redAccent),
            _buildCard(
              palette.surface,
              Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.cloud_done_rounded,
                      color: Colors.blue,
                    ),
                    title: const Text('Cloud Image & Video Storage'),
                    subtitle: Text('Total Used: $_cacheSize'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.campaign_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text('Global App Announcements'),
                    subtitle: const Text('Blast a notification to all users'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: _showAnnouncementDialog,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: color ?? palette.textMuted,
        ),
      ),
    );
  }

  Widget _buildCard(Color color, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
