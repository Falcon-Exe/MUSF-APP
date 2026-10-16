import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/widgets/student_name_widget.dart';

// 🟢 PUBLIC THEME
class ExecutiveTheme {
  static const Color primaryMidnight = Color(0xFF08233E);
  static const Color accentGold = Color(0xFFC5A059);
  static const Color backgroundSlate = Color(0xFFF1F5F9);
}

// 🟢 THE NEW LOBBY PAGE WITH A UNIQUE NAME
class NewCommitteeLobbyPage extends StatelessWidget {
  const NewCommitteeLobbyPage({super.key});

  final List<Map<String, dynamic>> committees = const [
    {'name': 'Library', 'icon': Icons.local_library_rounded, 'color': Colors.blue},
    {'name': 'Literary', 'icon': Icons.menu_book_rounded, 'color': Colors.orange},
    {'name': 'Fine Arts', 'icon': Icons.palette_rounded, 'color': Colors.purple},
    {'name': 'Social Affairs', 'icon': Icons.people_alt_rounded, 'color': Colors.green},
    {'name': 'Bank', 'icon': Icons.account_balance_rounded, 'color': Colors.teal},
    {'name': 'Research', 'icon': Icons.science_rounded, 'color': Colors.indigo},
    {'name': 'PRD', 'icon': Icons.public_rounded, 'color': Colors.blueGrey},
    {'name': 'Garden', 'icon': Icons.local_florist_rounded, 'color': Colors.pink},
    {'name': 'Store', 'icon': Icons.storefront_rounded, 'color': Colors.brown},
    {'name': 'Sports', 'icon': Icons.sports_soccer_rounded, 'color': Colors.amber},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExecutiveTheme.backgroundSlate,
      appBar: AppBar(
        title: const Text("COMMITTEE AWARDS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: ExecutiveTheme.primaryMidnight,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: committees.length,
        itemBuilder: (context, index) {
          final c = committees[index];
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewCommitteeResultsPage(committeeName: c['name']),
              ),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: (c['color'] as Color).withValues(alpha: 0.1),
                    child: Icon(c['icon'] as IconData, color: c['color'] as Color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ExecutiveTheme.primaryMidnight),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 🟢 THE NEW RESULTS PAGE WITH A UNIQUE NAME
class NewCommitteeResultsPage extends StatelessWidget {
  final String committeeName;
  const NewCommitteeResultsPage({super.key, required this.committeeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExecutiveTheme.backgroundSlate,
      appBar: AppBar(title: Text("$committeeName Results"), backgroundColor: ExecutiveTheme.primaryMidnight, foregroundColor: Colors.white, elevation: 0),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('committee_awards')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .map((rows) => rows
                .where((r) =>
                    (r['committee']?.toString().toLowerCase() ?? '') ==
                    committeeName.toLowerCase())
                .map((r) => {
                      ...r,
                      'goldId': r['gold_id'] ?? r['goldId'],
                      'silverId': r['silver_id'] ?? r['silverId'],
                      'bronzeId': r['bronze_id'] ?? r['bronzeId'],
                    })
                .toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) return const Center(child: Text("No prizes published yet."));
          
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventHeader(data['title'] ?? "Event", data['date'] ?? "Recent"),
                  const SizedBox(height: 15),
                  if (data['goldId'] != null && data['goldId'].toString().isNotEmpty) _buildPrizeWinner(data['goldId'].toString(), "🥇 Gold", Colors.amber),
                  if (data['silverId'] != null && data['silverId'].toString().isNotEmpty) _buildPrizeWinner(data['silverId'].toString(), "🥈 Silver", const Color(0xFF94A3B8)),
                  if (data['bronzeId'] != null && data['bronzeId'].toString().isNotEmpty) _buildPrizeWinner(data['bronzeId'].toString(), "🥉 Bronze", const Color(0xFFB45309)),
                  const SizedBox(height: 30),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventHeader(String eventName, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: ExecutiveTheme.primaryMidnight.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eventName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ExecutiveTheme.primaryMidnight)),
          Row(children: [const Icon(Icons.calendar_today, size: 14, color: Colors.grey), const SizedBox(width: 5), Text(date, style: const TextStyle(color: Colors.grey, fontSize: 14))]),
        ],
      ),
    );
  }

  Widget _buildPrizeWinner(String id, String position, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.emoji_events, color: color)),
        title: StudentNameWidget(studentId: id, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(position, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}