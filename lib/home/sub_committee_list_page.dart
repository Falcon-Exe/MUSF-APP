import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/widgets/student_name_widget.dart';

// 🟢 PUBLIC THEME
class ExecutiveTheme {
  static const Color primaryMidnight = Color(0xFF08233E);
  static const Color accentGold = Color(0xFFC5A059);
  static const Color backgroundSlate = Color(0xFFF1F5F9);
}

// 🟢 THE COMMITTEE RESULTS FEED (PERSONALIZED)
class SubCommitteeListPage extends StatelessWidget {
  final String studentID; // 🟢 We now require the student's ID

  const SubCommitteeListPage({super.key, required this.studentID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExecutiveTheme.backgroundSlate,
      appBar: AppBar(
        title: const Text(
          "MY AWARDS",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        backgroundColor: ExecutiveTheme.primaryMidnight,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Fetches all published committee awards
        stream: Supabase.instance.client
            .from('committee_awards')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .map((rows) => rows.map((r) => {
                  ...r,
                  'goldId': r['gold_id'] ?? r['goldId'] ?? '',
                  'silverId': r['silver_id'] ?? r['silverId'] ?? '',
                  'bronzeId': r['bronze_id'] ?? r['bronzeId'] ?? '',
                }).toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: ExecutiveTheme.primaryMidnight,
              ),
            );
          }

          final docs = snapshot.data ?? [];

          // 🟢 FILTER LOGIC: Only keep the results where THIS student is a winner
          final myAwards = docs.where((data) {
            final gold = (data['goldId'] ?? '').toString().trim();
            final silver = (data['silverId'] ?? '').toString().trim();
            final bronze = (data['bronzeId'] ?? '').toString().trim();
            final target = studentID.trim();

            // Returns true ONLY if the student's ID matches one of the winners
            return gold == target || silver == target || bronze == target;
          }).toList();

          // If they haven't won anything yet, show this friendly message
          if (myAwards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 70,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No awards yet!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ExecutiveTheme.primaryMidnight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Participate in events to see your name here!",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // If they have won, build their personal feed!
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: myAwards.length,
            itemBuilder: (context, index) {
              final data = myAwards[index];
              return _buildDialogCard(data);
            },
          );
        },
      ),
    );
  }

  // 🟢 THE DIALOG BOX STRUCTURE
  Widget _buildDialogCard(Map<String, dynamic> data) {
    final String committee = data['committee'] ?? 'General Committee';
    final String program = data['title'] ?? 'Unnamed Program';
    final String date = data['date'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP OF THE BOX: COMMITTEE NAME (Dark Header)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: ExecutiveTheme.primaryMidnight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_rounded,
                  color: ExecutiveTheme.accentGold,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    committee.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // 2. NEXT: NAME OF THE PROGRAM
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              program,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // 3. PRIZE PLACES (Still shows all 3 winners so the student can see who they beat/lost to)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                if (_hasId(data['goldId']))
                  _buildWinnerRow(
                    "🥇 First Prize",
                    data['goldId'],
                    const Color(0xFFD97706),
                  ),
                if (_hasId(data['silverId']))
                  _buildWinnerRow(
                    "🥈 Second Prize",
                    data['silverId'],
                    const Color(0xFF64748B),
                  ),
                if (_hasId(data['bronzeId']))
                  _buildWinnerRow(
                    "🥉 Third Prize",
                    data['bronzeId'],
                    const Color(0xFFB45309),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasId(dynamic id) {
    return id != null && id.toString().trim().isNotEmpty;
  }

  // HELPER TO BUILD INDIVIDUAL WINNER ROWS
  Widget _buildWinnerRow(
    String position,
    String rowStudentId,
    Color medalColor,
  ) {
    // Highlight the row if it belongs to the logged-in student!
    bool isMe = rowStudentId.trim() == studentID.trim();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? medalColor.withValues(alpha: 0.15)
            : medalColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? medalColor : medalColor.withValues(alpha: 0.1),
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: Text(
              position,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: medalColor,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            height: 15,
            width: 2,
            color: medalColor.withValues(alpha: 0.4),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Expanded(
            flex: 5,
            child: StudentNameWidget(
              studentId: rowStudentId,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                fontSize: 14,
                color: const Color(0xFF1E293B),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Add a little "YOU" badge if this is the logged-in student
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: medalColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  "YOU",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
