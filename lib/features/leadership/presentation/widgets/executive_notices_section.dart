// lib/features/leadership/presentation/widgets/executive_notices_section.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../logic/leadership_controller.dart';
import '../../data/repositories/firestore_leadership_repository.dart';
import '../../../../core/widgets/admin_shared_components.dart';

class ExecutiveNoticesSection extends StatefulWidget {
  final String committeeName;
  const ExecutiveNoticesSection({super.key, required this.committeeName});

  @override
  State<ExecutiveNoticesSection> createState() => _ExecutiveNoticesSectionState();
}

class _ExecutiveNoticesSectionState extends State<ExecutiveNoticesSection> {
  late final LeadershipController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LeadershipController(FirestoreLeadershipRepository());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getAnnouncementsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final allNotices = snapshot.data!.docs;
        
        // Manual filtering because Firestore complex OR queries are tricky
        final filteredNotices = allNotices.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final targetType = data['targetType'] ?? 'all';
          final targetCommittee = data['targetCommittee'];

          if (targetType == 'all') return true;
          if (targetType == 'admins') return true;
          if (targetType == 'committee' && targetCommittee == widget.committeeName) return true;
          return false;
        }).take(3).toList(); // Show top 3

        if (filteredNotices.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionTitle(title: "EXECUTIVE NOTICES"),
            const SizedBox(height: 12),
            ...filteredNotices.map((doc) => _buildNoticeCard(context, doc)),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildNoticeCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isImportant = data['priority'] == 'important';
    final DateTime? createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final String timeStr = createdAt != null ? DateFormat('MMM d, h:mm a').format(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isImportant ? Colors.amber.withValues(alpha: 0.3) : AdminDashboardStyles.borderColor,
          width: isImportant ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: () => _showFullNotice(context, data),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['title'] ?? 'No Title',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminDashboardStyles.textPrimary),
                    ),
                  ),
                  if (isImportant)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text("IMPORTANT", style: TextStyle(color: Colors.amber.shade900, fontSize: 8, fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                data['message'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AdminDashboardStyles.textMuted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_pin_rounded, size: 12, color: Colors.blueGrey.shade300),
                  const SizedBox(width: 4),
                  Text(
                    "${data['senderRole'] ?? 'Executive'}",
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade300),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullNotice(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(data['title'] ?? 'Notice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF39544B).withValues(alpha: 0.1),
                  child: const Icon(Icons.person, size: 16, color: Color(0xFF39544B)),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['senderName'] ?? 'Executive', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(data['senderRole'] ?? 'Union Member', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(data['message'] ?? '', style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }
}
