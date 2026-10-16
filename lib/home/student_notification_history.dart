import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('studentID', isEqualTo: studentID)
            .snapshots(),
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
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "You have no new notifications.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs.toList();

          // Sort locally in memory to avoid needing a composite index in Firestore
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            Timestamp? tA = dataA['timestamp'] as Timestamp?;
            Timestamp? tB = dataB['timestamp'] as Timestamp?;

            if (tA == null && tB == null) return 0;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA); // Descending order
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Notification';
              final message = data['message'] ?? '';
              final Timestamp? ts = data['timestamp'];
              final isRead = data['isRead'] ?? true;

              String timeStr = 'Just now';
              if (ts != null) {
                timeStr = DateFormat(
                  'dd MMM yyyy, hh:mm a',
                ).format(ts.toDate());
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRead
                              ? Colors.grey.withValues(alpha: 0.1)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color: isRead ? Colors.grey : const Color(0xFFF59E0B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
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
                                          : FontWeight.w900,
                                      fontSize: 15,
                                      color: isRead
                                          ? Colors.black87
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isRead
                                        ? Colors.grey
                                        : const Color(0xFFF59E0B),
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 13,
                                color: isRead ? Colors.black54 : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
