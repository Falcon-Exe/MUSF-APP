import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class StudentNotificationHistoryPage extends StatelessWidget {
  final String studentID;

  const StudentNotificationHistoryPage({super.key, required this.studentID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slight grayish BG
      appBar: AppBar(
        title: const Text(
          "Notice History",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF59E0B), // Amber color
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('notifications')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading notifications: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final allDocs = snapshot.data ?? [];
          final docs = allDocs.where((data) {
            final sid = (data['student_id'] ?? data['studentID'])?.toString();
            return sid == studentID || sid == 'all';
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "You have no new notifications.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final title = (data['title'] ?? 'Notice').toString();
              final message = (data['message'] ?? data['body'] ?? '').toString();
              final priority = (data['priority'] ?? 'normal').toString();
              final bool isRead = data['is_read'] ?? data['isRead'] ?? false;

              DateTime? dt;
              final rawDate = data['created_at'] ?? data['timestamp'];
              if (rawDate != null) {
                dt = DateTime.tryParse(rawDate.toString());
              }
              final timeStr = dt != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(dt)
                  : 'Just now';

              final isUrgent = priority == 'urgent' || priority == 'high' || priority == 'important';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUrgent
                        ? Colors.amber.shade400
                        : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              fontSize: 15,
                              color: isUrgent
                                  ? const Color(0xFFB45309)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
