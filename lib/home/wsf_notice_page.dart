import 'package:flutter/material.dart';
import '../features/cuc/logic/cuc_controller.dart';

/// This is a generic page widget that can be navigated to from your main app.
/// It does not contain `void main()` or `MaterialApp`.
class WsfNotice extends StatefulWidget {
  // You can pass data to this page via the constructor
  final String? pageTitle;

  const WsfNotice({super.key, this.pageTitle});

  @override
  State<WsfNotice> createState() => _WsfNoticeState();
}

class _WsfNoticeState extends State<WsfNotice> {
  final CucController _cucController = CucController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar is standard for secondary pages
      appBar: AppBar(
        title: Text(widget.pageTitle ?? 'CUC Notice Board'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),

      // SafeArea ensures content doesn't overlap with system status bars/notches
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _cucController.getNoticesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "No important notices at the moment.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index];
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: const Border(
                      left: BorderSide(color: Colors.redAccent, width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['title'] ?? 'Notice',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (data['date'] != null &&
                              data['date'].toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data['date'],
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (data['content'] != null &&
                          data['content'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          data['content'],
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
