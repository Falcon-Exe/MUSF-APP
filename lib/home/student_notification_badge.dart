import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentNotificationBadge extends StatelessWidget {
  final String committeeName;
  final Color themeColor;

  const StudentNotificationBadge({
    super.key,
    required this.committeeName,
    required this.themeColor,
  });

  void _showCommitteeNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Icon(Icons.campaign_rounded, color: themeColor, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      "$committeeName \nNotifications",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('committee_notifications')
                      .where('committee', isEqualTo: committeeName)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No notifications found.",
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      );
                    }
                    final docs = snapshot.data!.docs
                      ..sort((a, b) {
                        final aTs =
                            (a.data() as Map<String, dynamic>)['timestamp']
                                as Timestamp?;
                        final bTs =
                            (b.data() as Map<String, dynamic>)['timestamp']
                                as Timestamp?;
                        if (aTs == null && bTs == null) return 0;
                        if (aTs == null) return 1;
                        if (bTs == null) return -1;
                        return bTs.compareTo(aTs);
                      });
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Notice';
                        final message = data['message'] ?? '';
                        final Timestamp? ts = data['timestamp'];
                        final String timeStr = ts != null
                            ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
                            : 'Just now';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 18,
                                      color: Colors.blueGrey,
                                    ),
                                    onSelected: (value) async {
                                      if (value == 'delete') {
                                        await FirebaseFirestore.instance
                                            .collection(
                                              'committee_notifications',
                                            )
                                            .doc(docs[index].id)
                                            .delete();
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('committee_notifications')
          .where('committee', isEqualTo: committeeName)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasData = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: themeColor),
              onPressed: () => _showCommitteeNotifications(context),
            ),
            if (hasData)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
