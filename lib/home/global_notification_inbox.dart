import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class GlobalNotificationInbox extends StatelessWidget {
  final String studentID;
  final bool isAdmin;
  final Map<String, dynamic>? studentData;

  const GlobalNotificationInbox({
    required this.studentID,
    this.isAdmin = false,
    this.studentData,
    super.key,
  });

  static const Color _navy = Color(0xFF0F172A);
  static const Color _green = Color(0xFF39544B);
  static const Color _teal = Color(0xFF14B8A6);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);

  static const List<_CommitteeTarget> _committees = [
    _CommitteeTarget('CUC', Icons.school_rounded, Color(0xFF1565C0), [
      'cuc member',
    ]),
    _CommitteeTarget(
      'Treasurer',
      Icons.account_balance_wallet_rounded,
      Color(0xFF00796B),
      ['treasurer'],
    ),
    _CommitteeTarget('Bank', Icons.account_balance_rounded, Color(0xFF3949AB), [
      'bank manager',
    ]),
    _CommitteeTarget('Library', Icons.menu_book_rounded, Color(0xFF5D4037), [
      'library coordinator',
    ]),
    _CommitteeTarget('Fine Arts', Icons.palette_rounded, Color(0xFF8E24AA), [
      'fine arts coordinator',
    ]),
    _CommitteeTarget('Sports', Icons.sports_soccer_rounded, Color(0xFFF4511E), [
      'sports coordinator',
    ]),
    _CommitteeTarget('Literary', Icons.edit_note_rounded, Color(0xFF1E88E5), [
      'literary coordinator',
    ]),
    _CommitteeTarget('Research', Icons.science_rounded, Color(0xFF00ACC1), [
      'research coordinator',
    ]),
    _CommitteeTarget(
      'Social Affairs',
      Icons.public_rounded,
      Color(0xFF00897B),
      ['social affairs officer'],
    ),
    _CommitteeTarget('PRD', Icons.campaign_rounded, Color(0xFFFB8C00), [
      'public relations officer',
    ]),
    _CommitteeTarget('Garden', Icons.local_florist_rounded, Color(0xFF43A047), [
      'garden supervisor',
    ]),
    _CommitteeTarget(
      'Medical',
      Icons.medical_services_rounded,
      Color(0xFFEF4444),
      ['medical coordinator'],
    ),
    _CommitteeTarget('Store', Icons.shopping_cart_rounded, Color(0xFF546E7A), [
      'store keeper',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final canSend = isAdmin || _hasNotificationAccess(studentData);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          canSend ? "Notification Center" : "Notifications",
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          if (canSend)
            SliverToBoxAdapter(
              child: _AdminNotificationPanel(studentID: studentID),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, canSend ? 6 : 18, 18, 6),
              child: Text(
                canSend ? "Inbox Preview" : "Your Inbox",
                style: const TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _buildInboxList(),
        ],
      ),
    );
  }

  Widget _buildInboxList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allNotifications = snapshot.data ?? [];
        final notifications = allNotifications.where((n) {
          final sid = (n['student_id'] ?? n['studentID'])?.toString();
          return sid == studentID || sid == 'all' || (isAdmin && sid == 'admin');
        }).toList();

        if (notifications.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_rounded,
                    size: 74,
                    color: Colors.blueGrey.shade200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "You're all caught up!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final data = notifications[index];
            return _NotificationTile(
              docId: data['id']?.toString() ?? '',
              title: (data['title'] ?? 'Notice').toString(),
              message: (data['message'] ?? 'No detail provided.').toString(),
              priority: (data['priority'] ?? 'normal').toString(),
              isRead: data['is_read'] == true || data['isRead'] == true,
              createdAt: data['created_at'] ?? data['createdAt'],
              committee: data['committee']?.toString(),
            );
          },
        );
      },
    );
  }

  static bool _hasNotificationAccess(Map<String, dynamic>? data) {
    if (data == null) return false;
    final roles = [
      data['assignedRole']?.toString().toLowerCase() ?? '',
      data['role']?.toString().toLowerCase() ?? '',
      data['designation']?.toString().toLowerCase() ?? '',
    ];
    const allowed = [
      'executive',
      'president',
      'secretary',
      'union director',
      'treasurer',
    ];
    return roles.any((role) => allowed.any(role.contains));
  }
}

class _AdminNotificationPanel extends StatefulWidget {
  final String studentID;

  const _AdminNotificationPanel({required this.studentID});

  @override
  State<_AdminNotificationPanel> createState() =>
      _AdminNotificationPanelState();
}

class _AdminNotificationPanelState extends State<_AdminNotificationPanel> {
  String _audience = 'all';
  String _selectedCommittee = GlobalNotificationInbox._committees.first.name;
  String _priority = 'normal';
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final selected = GlobalNotificationInbox._committees.firstWhere(
      (committee) => committee.name == _selectedCommittee,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: GlobalNotificationInbox._green,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Send Notification",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Choose who should receive it and mark the priority.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                _optionWrap([
                  _Option("All Students", 'all', Icons.groups_rounded),
                  _Option(
                    "Committee People",
                    'committee_people',
                    Icons.admin_panel_settings_rounded,
                  ),
                  _Option("Admins", 'admin', Icons.verified_user_rounded),
                  _Option("One Committee", 'committee', Icons.campaign_rounded),
                ]),
                if (_audience == 'committee') ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCommittee,
                    dropdownColor: Colors.white,
                    decoration: _fieldDecoration(
                      "Committee",
                      Icons.account_tree_rounded,
                    ),
                    items: GlobalNotificationInbox._committees.map((committee) {
                      return DropdownMenuItem(
                        value: committee.name,
                        child: Text(committee.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCommittee = value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _priorityChip(
                        "Normal",
                        'normal',
                        Icons.info_outline_rounded,
                        GlobalNotificationInbox._teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _priorityChip(
                        "Important",
                        'important',
                        Icons.priority_high_rounded,
                        GlobalNotificationInbox._amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _priorityChip(
                        "Urgent",
                        'urgent',
                        Icons.warning_rounded,
                        GlobalNotificationInbox._red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSending
                        ? null
                        : () => _showComposeDialog(context, selected),
                    icon: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSending ? "Sending..." : "Write & Send"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: GlobalNotificationInbox._green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Every Committee",
            style: TextStyle(
              color: GlobalNotificationInbox._navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...GlobalNotificationInbox._committees.map(_committeeCard),
        ],
      ),
    );
  }

  Widget _optionWrap(List<_Option> options) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = _audience == option.value;
        return ChoiceChip(
          selected: selected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option.icon,
                size: 16,
                color: selected
                    ? GlobalNotificationInbox._green
                    : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(option.label),
            ],
          ),
          labelStyle: TextStyle(
            color: selected ? GlobalNotificationInbox._green : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          selectedColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          side: BorderSide(
            color: Colors.white.withValues(alpha: selected ? 0 : 0.16),
          ),
          onSelected: (_) => setState(() => _audience = option.value),
        );
      }).toList(),
    );
  }

  Widget _priorityChip(String label, String value, IconData icon, Color color) {
    final selected = _priority == value;
    return InkWell(
      onTap: () => setState(() => _priority = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _committeeCard(_CommitteeTarget committee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: committee.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(committee.icon, color: committee.color),
        ),
        title: Text(
          committee.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text("Send or review ${committee.name} notices"),
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: "History",
              icon: const Icon(Icons.history_rounded),
              onPressed: () => _showCommitteeHistory(context, committee),
            ),
            IconButton(
              tooltip: "Send",
              icon: Icon(Icons.send_rounded, color: committee.color),
              onPressed: () {
                setState(() {
                  _audience = 'committee';
                  _selectedCommittee = committee.name;
                });
                _showComposeDialog(context, committee);
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Future<void> _showComposeDialog(
    BuildContext context,
    _CommitteeTarget selected,
  ) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          _composeTitle(selected),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: _dialogDecoration("Title", Icons.title_rounded),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              minLines: 3,
              maxLines: 5,
              decoration: _dialogDecoration("Message", Icons.message_rounded),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text("Send"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _priorityColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final title = titleController.text.trim();
              final message = messageController.text.trim();
              if (title.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter title and message.")),
                );
                return;
              }
              Navigator.pop(dialogContext);
              await _sendNotification(context, title, message, selected);
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _dialogDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  String _composeTitle(_CommitteeTarget selected) {
    if (_audience == 'committee') return "Notify ${selected.name}";
    if (_audience == 'committee_people') return "Notify Committee People";
    if (_audience == 'admin') return "Notify Admins";
    return "Notify Everyone";
  }

  Color get _priorityColor {
    switch (_priority) {
      case 'urgent':
        return GlobalNotificationInbox._red;
      case 'important':
        return GlobalNotificationInbox._amber;
      default:
        return GlobalNotificationInbox._teal;
    }
  }

  Future<void> _sendNotification(
    BuildContext context,
    String title,
    String message,
    _CommitteeTarget selected,
  ) async {
    setState(() => _isSending = true);
    try {
      final client = Supabase.instance.client;
      final String? committeeName = _audience == 'committee'
          ? selected.name
          : null;

      await client.from('committee_notifications').insert({
        'committee': committeeName ?? 'Global',
        'title': title,
        'message': message,
        'priority': _priority,
        'target_type': _audience,
        'target_committee': committeeName,
        'sender_id': widget.studentID,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final recipients = await _loadRecipients(selected);
      final notificationData = {
        'title': committeeName == null ? title : "[${selected.name}] $title",
        'message': message,
        'priority': _priority,
        'type': 'global_notice',
        'committee': committeeName ?? 'Global',
        'target_type': _audience,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (recipients.isEmpty) {
        await client.from('notifications').insert({
          ...notificationData,
          'student_id': _audience == 'admin' ? 'admin' : 'all',
        });
      } else {
        await _commitRecipientNotifications(recipients, notificationData);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Notification sent to ${_audienceLabel(selected)}."),
            backgroundColor: _priorityColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send notification: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<List<String>> _loadRecipients(_CommitteeTarget selected) async {
    if (_audience == 'all') return [];
    if (_audience == 'admin') return [];

    final students = await Supabase.instance.client
        .from('students')
        .select();
    final roles = _audience == 'committee'
        ? selected.roleKeywords
        : GlobalNotificationInbox._committees
              .expand((committee) => committee.roleKeywords)
              .toList();

    final ids = <String>{};
    for (final data in students) {
      final studentID = (data['student_id'] ?? data['studentID'] ?? data['cic_no'] ?? '')
          .toString()
          .trim();
      if (studentID.isEmpty) continue;

      final userRoles = [
        data['assigned_role']?.toString().toLowerCase() ?? data['assignedRole']?.toString().toLowerCase() ?? '',
        data['role']?.toString().toLowerCase() ?? '',
        data['designation']?.toString().toLowerCase() ?? '',
      ];

      final matches = userRoles.any(
        (userRole) => roles.any((role) => userRole.contains(role)),
      );
      if (matches) ids.add(studentID);
    }

    return ids.toList();
  }

  Future<void> _commitRecipientNotifications(
    List<String> recipients,
    Map<String, dynamic> notificationData,
  ) async {
    final client = Supabase.instance.client;
    for (var i = 0; i < recipients.length; i += 450) {
      final chunk = recipients.skip(i).take(450);
      final rows = chunk.map((studentID) => {
        ...notificationData,
        'student_id': studentID,
      }).toList();
      await client.from('notifications').insert(rows);
    }
  }

  String _audienceLabel(_CommitteeTarget selected) {
    if (_audience == 'committee') return selected.name;
    if (_audience == 'committee_people') return "committee people";
    if (_audience == 'admin') return "admins";
    return "everyone";
  }

  void _showCommitteeHistory(BuildContext context, _CommitteeTarget committee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(committee.icon, color: committee.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${committee.name} Notifications",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('committee_notifications')
                    .stream(primaryKey: ['id'])
                    .eq('committee', committee.name)
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("No notifications sent yet."),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index];
                      return _HistoryTile(
                        title: (data['title'] ?? 'Notice').toString(),
                        message: (data['message'] ?? '').toString(),
                        priority: (data['priority'] ?? 'normal').toString(),
                        timestamp: data['timestamp'] ?? data['created_at'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String docId;
  final String title;
  final String message;
  final String priority;
  final bool isRead;
  final dynamic createdAt;
  final String? committee;

  const _NotificationTile({
    required this.docId,
    required this.title,
    required this.message,
    required this.priority,
    required this.isRead,
    required this.createdAt,
    this.committee,
  });

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority, isRead);
    String timeString = '';
    if (createdAt != null) {
      final dt = DateTime.tryParse(createdAt.toString());
      if (dt != null) {
        timeString = DateFormat('MMM dd, hh:mm a').format(dt);
      }
    }

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.horizontal,
      onDismissed: (_) async {
        await Supabase.instance.client
            .from('notifications')
            .delete()
            .eq('id', docId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification deleted.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.blueGrey.shade800,
            ),
          );
        }
      },
      background: _deleteBg(Alignment.centerLeft, EdgeInsets.only(left: 20)),
      secondaryBackground: _deleteBg(
        Alignment.centerRight,
        EdgeInsets.only(right: 20),
      ),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: !isRead
                ? color.withValues(alpha: 0.45)
                : Colors.grey.shade200,
            width: !isRead ? 1.5 : 1,
          ),
        ),
        color: !isRead ? color.withValues(alpha: 0.05) : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_priorityIcon(priority, isRead), color: color),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                    fontSize: 15.5,
                    color: GlobalNotificationInbox._navy,
                  ),
                ),
              ),
              if (timeString.isNotEmpty)
                Text(
                  timeString,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (committee != null && committee!.isNotEmpty)
                  Text(
                    committee!,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            if (!isRead && docId.isNotEmpty) {
              Supabase.instance.client
                  .from('notifications')
                  .update({'is_read': true})
                  .eq('id', docId);
            }
          },
        ),
      ),
    );
  }

  Widget _deleteBg(Alignment alignment, EdgeInsets padding) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      child: const Icon(
        Icons.delete_sweep_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  static Color _priorityColor(String priority, bool isRead) {
    if (isRead) return Colors.blueGrey;
    switch (priority) {
      case 'urgent':
        return GlobalNotificationInbox._red;
      case 'important':
        return GlobalNotificationInbox._amber;
      default:
        return Colors.blueAccent;
    }
  }

  static IconData _priorityIcon(String priority, bool isRead) {
    if (isRead) return Icons.notifications_rounded;
    if (priority == 'urgent') return Icons.warning_rounded;
    if (priority == 'important') return Icons.priority_high_rounded;
    return Icons.mark_email_unread_rounded;
  }
}

class _HistoryTile extends StatelessWidget {
  final String title;
  final String message;
  final String priority;
  final dynamic timestamp;

  const _HistoryTile({
    required this.title,
    required this.message,
    required this.priority,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final color = _NotificationTile._priorityColor(priority, false);
    String time = 'Just now';
    if (timestamp != null) {
      final dt = DateTime.tryParse(timestamp.toString());
      if (dt != null) {
        time = DateFormat('MMM dd, hh:mm a').format(dt);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _NotificationTile._priorityIcon(priority, false),
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.blueGrey.shade700, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _CommitteeTarget {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> roleKeywords;

  const _CommitteeTarget(this.name, this.icon, this.color, this.roleKeywords);
}

class _Option {
  final String label;
  final String value;
  final IconData icon;

  const _Option(this.label, this.value, this.icon);
}
