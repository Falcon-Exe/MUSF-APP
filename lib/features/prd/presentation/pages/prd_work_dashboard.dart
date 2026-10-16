// lib/features/prd/presentation/pages/prd_work_dashboard.dart

import 'package:flutter/material.dart';

import '../../logic/prd_controller.dart';
import '../widgets/prd_theme.dart';
import '../widgets/prd_task_card.dart';
import 'prd_print_records_page.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';

class PrdWorkDashboard extends StatefulWidget {
  final VoidCallback? onBack;
  const PrdWorkDashboard({super.key, this.onBack});

  @override
  State<PrdWorkDashboard> createState() => _PrdWorkDashboardState();
}

class _PrdWorkDashboardState extends State<PrdWorkDashboard> {
  final PrdController _controller = PrdController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalCommitteeDashboard(
      committeeName: "PRD",
      displayTitle: "PRD Management",
      subtitle: "Management Console",
      onBack: () =>
          widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
      extraTabs: [
        CommitteeTabConfig(
          label: "Print Collection",
          icon: Icons.print_rounded,
          key: 'print_collection',
          content: const PrdPrintRecordsPage(),
        ),
        CommitteeTabConfig(
          label: "Pending",
          icon: Icons.pending_actions_rounded,
          key: 'pending',
          content: _buildTaskList("Pending"),
        ),
        CommitteeTabConfig(
          label: "Working",
          icon: Icons.running_with_errors_rounded,
          key: 'working',
          content: _buildTaskList("In Progress"),
        ),
        CommitteeTabConfig(
          label: "Done",
          icon: Icons.check_circle_rounded,
          key: 'done',
          content: _buildTaskList("Completed"),
        ),
      ],
      specialFeatures: [
        CommitteeSpecialFeature(
          title: "Print Collection",
          subtitle: "Manage print records & balances",
          icon: Icons.print_rounded,
          color: const Color(0xFF3B82F6),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrdPrintRecordsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(String status) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _controller.tasksStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Could not load tasks: ${snapshot.error}"),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data ?? [];
          final docs = allDocs
              .where((data) => data['status'] == status)
              .toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No tasks found",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final String docId = data['id']?.toString() ?? '';
              return PrdTaskCard(
                data: data,
                docId: docId,
                onTap: () => _updateStatusSheet(
                  context,
                  docId,
                  data['title'] ?? 'Request',
                  data['status'] ?? 'Pending',
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatusSheet(
    BuildContext context,
    String docId,
    String title,
    String currentStatus,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Update Status",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF39544B),
              ),
            ),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),
            _statusButton(context, docId, "Pending"),
            const SizedBox(height: 10),
            _statusButton(context, docId, "In Progress"),
            const SizedBox(height: 10),
            _statusButton(context, docId, "Completed"),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(BuildContext context, String docId, String status) {
    Color color = PrdTheme.getStatusColor(status);
    return ListTile(
      leading: Icon(PrdTheme.getStatusIcon(status), color: color),
      title: Text(
        "Move to $status",
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      onTap: () async {
        await _controller.updateTaskStatus(docId, status);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}
