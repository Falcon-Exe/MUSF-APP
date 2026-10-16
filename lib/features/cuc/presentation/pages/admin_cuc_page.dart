// lib/features/cuc/presentation/pages/admin_cuc_page.dart

import 'package:flutter/material.dart';
import '../../logic/cuc_controller.dart';
import '../widgets/cuc_notice_card.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';

class AdminCucPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminCucPage({super.key, this.onBack});

  @override
  State<AdminCucPage> createState() => _AdminCucPageState();
}

class _AdminCucPageState extends State<AdminCucPage> {
  late final CucController _controller;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CucController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalCommitteeDashboard(
      committeeName: "CUC",
      displayTitle: "CUC Management",
      subtitle: "Command Center",
      onBack: () =>
          widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
      extraTabs: [
        CommitteeTabConfig(
          label: "Notices",
          icon: Icons.campaign_rounded,
          key: 'notices',
          content: _buildNoticesPage(),
        ),
      ],
    );
  }

  Widget _buildNoticesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Post Important Message",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 15),
          _buildTextField(_titleCtrl, "Notice Title", Icons.title),
          const SizedBox(height: 15),
          _buildTextField(
            _contentCtrl,
            "Content",
            Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 15),
          _buildPostRow(),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          const Text(
            "Active Notices",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          _buildNoticesList(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  Widget _buildPostRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(_dateCtrl, "Last Date", Icons.calendar_today),
        ),
        const SizedBox(width: 15),
        ElevatedButton(
          onPressed: _handlePost,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(100, 55),
          ),
          child: const Text("POST"),
        ),
      ],
    );
  }

  Widget _buildNoticesList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _controller.getNoticesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Could not load notices: ${snapshot.error}"),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) return const Text("No notices posted");

        return Column(
          children: docs.map((data) {
            return CucNoticeCard(
              title: data['title'] ?? 'Notice',
              content: data['content'] ?? '',
              date: data['date'] ?? 'N/A',
              onDelete: () => _controller.deleteNotice(data['id']?.toString() ?? ''),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _handlePost() async {
    if (_titleCtrl.text.isNotEmpty && _dateCtrl.text.isNotEmpty) {
      await _controller.postNotice(
        title: _titleCtrl.text,
        content: _contentCtrl.text,
        date: _dateCtrl.text,
      );
      if (mounted) {
        _titleCtrl.clear();
        _contentCtrl.clear();
        _dateCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notice Posted!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
