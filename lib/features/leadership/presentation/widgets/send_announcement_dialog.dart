// lib/features/leadership/presentation/widgets/send_announcement_dialog.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SendAnnouncementDialog extends StatefulWidget {
  final Function({
    required String title,
    required String message,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String targetType,
    String? targetCommittee,
    required String priority,
  })
  onSend;

  const SendAnnouncementDialog({super.key, required this.onSend});

  @override
  State<SendAnnouncementDialog> createState() => _SendAnnouncementDialogState();
}

class _SendAnnouncementDialogState extends State<SendAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _targetType = 'all';
  String? _targetCommittee;
  String _priority = 'normal';

  final List<String> _committees = [
    'TREASURY',
    'STORE',
    'ARTS',
    'LITERARY',
    'SPORTS',
    'SOCIAL AFFAIRS',
    'PRD',
    'RESEARCH',
    'CUC',
    'LIBRARY',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.campaign_rounded, color: Color(0xFF39544B)),
          SizedBox(width: 10),
          Text(
            "Send Announcement",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Announcement Title",
                  hintText: "e.g., Emergency Meeting",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Title required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Message",
                  hintText: "Enter your message here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Message required" : null,
              ),
              const SizedBox(height: 20),
              const Text(
                "Target Audience",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _targetType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text("All Committees")),
                  DropdownMenuItem(
                    value: 'committee',
                    child: Text("Specific Committee"),
                  ),
                  DropdownMenuItem(
                    value: 'students',
                    child: Text("Students Only"),
                  ),
                  DropdownMenuItem(value: 'admins', child: Text("Admins Only")),
                ],
                onChanged: (v) => setState(() {
                  _targetType = v!;
                  if (_targetType != 'committee') _targetCommittee = null;
                }),
              ),
              if (_targetType == 'committee') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _targetCommittee,
                  hint: const Text("Select Committee"),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: _committees
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _targetCommittee = v),
                  validator: (v) => (_targetType == 'committee' && v == null)
                      ? "Select a committee"
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                "Priority Level",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _priorityChip(
                      "Normal",
                      'normal',
                      Icons.info_outline_rounded,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _priorityChip(
                      "Important",
                      'important',
                      Icons.priority_high_rounded,
                      Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39544B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _handleSend,
          child: const Text("Send Now"),
        ),
      ],
    );
  }

  Widget _priorityChip(String label, String value, IconData icon, Color color) {
    bool selected = _priority == value;
    return InkWell(
      onTap: () => setState(() => _priority = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? color : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSend() async {
    if (_formKey.currentState!.validate()) {
      final user = supabase.Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      Map<String, dynamic>? userData;
      try {
        final email = user.email ?? '';
        final searchId = email.contains('@') ? email.split('@')[0] : email;
        userData = await supabase.Supabase.instance.client
            .from('students')
            .select()
            .or('id.eq.${user.id},student_id.eq.${searchId.trim()}')
            .maybeSingle();
      } catch (_) {}

      String senderName =
          userData?['fullName'] ??
          user.userMetadata?['full_name'] ??
          "Executive";
      String senderRole =
          userData?['designation'] ?? userData?['assignedRole'] ?? "Executive";

      await widget.onSend(
        title: _titleController.text,
        message: _messageController.text,
        senderId: user.id,
        senderName: senderName,
        senderRole: senderRole,
        targetType: _targetType,
        targetCommittee: _targetCommittee,
        priority: _priority,
      );

      if (mounted) Navigator.pop(context);
    }
  }
}
