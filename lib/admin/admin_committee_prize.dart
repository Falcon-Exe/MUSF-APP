import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🟢 PUBLIC THEME
class ExecutiveTheme {
  static const Color primaryMidnight = Color(0xFF08233E);
  static const Color accentGold = Color(0xFFC5A059);
  static const Color backgroundSlate = Color(0xFFF1F5F9);
  static const Color cardWhite = Colors.white;
  static const Color textMain = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
}

// 🟢 LINE 13: DASHBOARD CLASS ADDED TO FIX RED LINES ON OTHER PAGES
class AdminCommitteeDashboard extends StatelessWidget {
  final String? initialCommittee;

  const AdminCommitteeDashboard({super.key, this.initialCommittee});

  @override
  Widget build(BuildContext context) {
    // GATEKEEPER LOGIC: If a key like "Library" is passed, go straight to that page
    if (initialCommittee != null && initialCommittee!.isNotEmpty) {
      return CommitteeManagementScreen(committeeName: initialCommittee!);
    }

    // Default dashboard view if no specific committee is requested
    return Scaffold(
      appBar: AppBar(
        title: const Text("EXECUTIVE DASHBOARD"),
        backgroundColor: ExecutiveTheme.primaryMidnight,
      ),
      body: const Center(
        child: Text("Select a department from the Admin Menu"),
      ),
    );
  }
}

class CommitteeManagementScreen extends StatefulWidget {
  final String committeeName;
  const CommitteeManagementScreen({super.key, required this.committeeName});

  @override
  State<CommitteeManagementScreen> createState() =>
      _CommitteeManagementScreenState();
}

class _CommitteeManagementScreenState extends State<CommitteeManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExecutiveTheme.backgroundSlate,
      appBar: AppBar(
        title: Text(
          "MANAGE ${widget.committeeName.toUpperCase()}",
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: ExecutiveTheme.primaryMidnight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: ExecutiveTheme.primaryMidnight,
        icon: const Icon(Icons.add_rounded, color: ExecutiveTheme.accentGold),
        label: const Text(
          "CREATE EVENT",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('committee_awards')
            .stream(primaryKey: ['id'])
            .eq('committee', widget.committeeName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: ExecutiveTheme.primaryMidnight,
              ),
            );
          }
          final awards = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _sectionLabel("SECURITY & SETTINGS"),
              const SizedBox(height: 12),
              _buildDepartmentBadge(),
              const SizedBox(height: 40),
              _sectionLabel("EVENT REGISTRY (${awards.length})"),
              const SizedBox(height: 16),
              if (awards.isEmpty)
                _buildEmptyState()
              else
                ...awards.map((data) {
                  final docId = data['id']?.toString() ?? '';
                  return _buildAwardCommandCard(docId, data);
                }),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAwardCommandCard(String docId, Map<String, dynamic> data) {
    final goldId = data['gold_id'] ?? data['goldId'];
    final silverId = data['silver_id'] ?? data['silverId'];
    final bronzeId = data['bronze_id'] ?? data['bronzeId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showWinnerEditSheet(context, docId, data),
        onLongPress: () => _confirmDelete(docId, data['title'] ?? "this event"),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ExecutiveTheme.primaryMidnight.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: ExecutiveTheme.accentGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? "Untitled",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: ExecutiveTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _previewRow("🥇 Gold:", goldId?.toString(), Colors.amber),
                    _previewRow(
                      "🥈 Silver:",
                      silverId?.toString(),
                      const Color(0xFF94A3B8),
                    ),
                    _previewRow(
                      "🥉 Bronze:",
                      bronzeId?.toString(),
                      const Color(0xFFB45309),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tap to edit • Long press to Delete",
                      style: TextStyle(
                        fontSize: 10,
                        color: ExecutiveTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ExecutiveTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String? id, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: ExecutiveTheme.textMuted,
            ),
          ),
          const SizedBox(width: 5),
          StudentNameWidget(
            studentId: id ?? "",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String docId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Award Record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await Supabase.instance.client
                  .from('committee_awards')
                  .delete()
                  .eq('id', docId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentBadge() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: ExecutiveTheme.accentGold,
          ),
          const SizedBox(width: 12),
          Text(
            widget.committeeName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: ExecutiveTheme.primaryMidnight,
            ),
          ),
          const Spacer(),
          const Text(
            "SECURE ACCESS",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ExecutiveTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: ExecutiveTheme.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No events recorded."));
  }

  void _showAddEventDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Award Category"),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(hintText: "e.g., Best Librarian"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ExecutiveTheme.primaryMidnight,
            ),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty) {
                await Supabase.instance.client.from('committee_awards').insert({
                  'committee': widget.committeeName,
                  'title': title,
                  'date':
                      "Published ${DateTime.now().day}/${DateTime.now().month}",
                  'gold_id': '',
                  'silver_id': '',
                  'bronze_id': '',
                  'results_published': true,
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("CREATE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWinnerEditSheet(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final gold = TextEditingController(
      text: (data['gold_id'] ?? data['goldId'] ?? '').toString(),
    );
    final silver = TextEditingController(
      text: (data['silver_id'] ?? data['silverId'] ?? '').toString(),
    );
    final bronze = TextEditingController(
      text: (data['bronze_id'] ?? data['bronzeId'] ?? '').toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 30,
          right: 30,
          top: 30,
        ),
        decoration: const BoxDecoration(
          color: ExecutiveTheme.primaryMidnight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (data['title'] ?? '').toString().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 25),
            _buildDialogField(gold, "Gold Winner ID", Colors.amber),
            const SizedBox(height: 10),
            _buildDialogField(
              silver,
              "Silver Winner ID",
              const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            _buildDialogField(
              bronze,
              "Bronze Winner ID",
              const Color(0xFFB45309),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ExecutiveTheme.accentGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  await Supabase.instance.client
                      .from('committee_awards')
                      .update({
                        'gold_id': gold.text.trim(),
                        'silver_id': silver.text.trim(),
                        'bronze_id': bronze.text.trim(),
                      })
                      .eq('id', docId);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    color: ExecutiveTheme.primaryMidnight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController ctrl,
    String label,
    Color color,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.stars, color: color),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class StudentNameWidget extends StatelessWidget {
  final String studentId;
  final TextStyle style;

  const StudentNameWidget({
    super.key,
    required this.studentId,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (studentId.isEmpty || studentId == "---") {
      return Text("---", style: style);
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('students')
          .select('full_name')
          .eq('student_id', studentId)
          .maybeSingle(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final String name = snapshot.data!['full_name'] ?? "Unknown";
          return Text("$name ($studentId)", style: style);
        }
        return Text("($studentId)", style: style);
      },
    );
  }
}
