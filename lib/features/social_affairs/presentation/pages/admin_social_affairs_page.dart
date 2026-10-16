// lib/features/social_affairs/presentation/pages/admin_social_affairs_page.dart

import 'package:flutter/material.dart';
import '../../logic/social_controller.dart';
import '../widgets/css_tab_view.dart';
import '../widgets/exams_tab_view.dart';
import '../widgets/add_css_dialog.dart';
import '../widgets/add_exam_dialog.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';

class AdminSocialAffairsPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminSocialAffairsPage({super.key, this.onBack});

  @override
  State<AdminSocialAffairsPage> createState() => _AdminSocialAffairsPageState();
}

class _AdminSocialAffairsPageState extends State<AdminSocialAffairsPage> {
  late final SocialController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SocialController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalCommitteeDashboard(
      committeeName: "Social Affairs",
      displayTitle: "Social Affairs Management",
      subtitle: "Command Center",
      onBack: () =>
          widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
      searchHint: "Search works...",
      searchController: _searchController,
      onSearchChanged: (_) => setState(() {}),
      extraTabs: [
        CommitteeTabConfig(
          label: "CSS Works",
          icon: Icons.people_alt_rounded,
          key: 'css',
          content: _buildCssWorksTab(),
        ),
        CommitteeTabConfig(
          label: "Exams",
          icon: Icons.calendar_today_rounded,
          key: 'exams',
          content: _buildExamsTab(),
        ),
      ],
    );
  }

  Widget _buildCssWorksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          CssTabView(
            stream: _controller.getCssWorksStream(),
            onDelete: _controller.deleteCssWork,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(context, 'css'),
            icon: const Icon(Icons.add),
            label: const Text("ADD CSS WORK"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          ExamsTabView(
            stream: _controller.getExamsStream(),
            onDelete: _controller.deleteExam,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(context, 'exams'),
            icon: const Icon(Icons.add),
            label: const Text("ADD EXAM"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, String type) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add",
      barrierColor: Colors.black.withValues(alpha: 0.6),
      pageBuilder: (context, animation, secondaryAnimation) {
        if (type == 'css') {
          return AddCssDialog(
            onSubmit: (title, instr, start, end) => _controller.addCssWork(
              title: title,
              instruction: instr,
              startDate: start,
              endDate: end,
            ),
          );
        } else {
          return AddExamDialog(
            onSubmit: (sub, date, loc) =>
                _controller.addExam(subject: sub, date: date, location: loc),
          );
        }
      },
    );
  }
}
