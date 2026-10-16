// lib/features/prd/presentation/pages/prd_request_desk_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../logic/prd_controller.dart';
import '../widgets/prd_theme.dart';
import '../widgets/prd_task_card.dart';
import '../widgets/prd_request_form_dialog.dart';

class PrdRequestDeskPage extends StatefulWidget {
  final String? initialCommittee;

  const PrdRequestDeskPage({super.key, this.initialCommittee});

  @override
  State<PrdRequestDeskPage> createState() => _PrdRequestDeskPageState();
}

class _PrdRequestDeskPageState extends State<PrdRequestDeskPage> with SingleTickerProviderStateMixin {
  late final PrdController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = PrdController(committeeName: widget.initialCommittee);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = widget.initialCommittee != null
        ? "${widget.initialCommittee?.toUpperCase()} REQUESTS"
        : "PRD SERVICE DESK";

    return Scaffold(
      backgroundColor: PrdTheme.background,
      body: Stack(
        children: [
          Container(
            height: 300, width: double.infinity,
            decoration: const BoxDecoration(
              color: PrdTheme.primaryDark,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(45), bottomRight: Radius.circular(45)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopActionBar(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayTitle, style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 11)),
                      const Text("Track Designs", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Text("Submit your poster, video, and media requests to the Public Relations Department here.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: "Active"),
                    Tab(text: "History"),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(isActive: true),
                      _buildTaskList(isActive: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (context) => PrdRequestFormDialog(controller: _controller, initialCommittee: widget.initialCommittee),
        ),
        backgroundColor: PrdTheme.accentPrd,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: const Text("NEW REQUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildTopActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22), onPressed: () => Navigator.pop(context)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 28), onPressed: () => _generatePdfReport()),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildTaskList({required bool isActive}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _controller.tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white70)));
        }

        final allDocs = List<Map<String, dynamic>>.from(snapshot.data ?? []);
        
        allDocs.sort((a, b) {
          final aTime = a['createdAt']?.toString() ?? '';
          final bTime = b['createdAt']?.toString() ?? '';
          return bTime.compareTo(aTime);
        });
        
        final docs = allDocs.where((data) {
          final status = (data['status'] ?? 'Pending').toString().toLowerCase();
          final isCompleted = status == 'completed' || status == 'cancelled' || status == 'rejected';
          return isActive ? !isCompleted : isCompleted;
        }).toList();

        if (docs.isEmpty) return _buildNoResults(isActive ? "No active requests." : "No request history.");

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index];
            final String docId = data['id']?.toString() ?? '';
            return PrdTaskCard(
              data: data, docId: docId,
              onLongPress: () => _confirmDelete(context, docId, data['status'] ?? 'Pending'),
            );
          },
        );
      },
    );
  }

  Widget _buildNoResults(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_turned_in_rounded, size: 60, color: Colors.white38),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String status) {
    if (status != 'Pending') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot delete a task already in progress!")));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _controller.deleteTask(docId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    try {
      var filter = Supabase.instance.client
          .from('prd_tasks')
          .select();
      if (widget.initialCommittee != null) {
        filter = filter.eq('committee_name', widget.initialCommittee!);
      }
      final docs = List<Map<String, dynamic>>.from(
        await filter.order('created_at', ascending: false),
      );

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Header(level: 0, child: pw.Text("PRD Service Desk Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 10),
            pw.Text("Filter: ${widget.initialCommittee ?? 'All Committees'}"),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Committee', 'Task', 'Type', 'Deadline', 'Status'],
              data: docs.map((data) {
                return [
                  data['committee_name'] ?? data['committeeName'] ?? data['committee'] ?? 'General',
                  data['request_title'] ?? data['requestTitle'] ?? data['title'] ?? 'Untitled',
                  data['type'] ?? 'Unknown',
                  data['deadline'] ?? 'Not set',
                  data['status'] ?? 'Pending'
                ];
              }).toList(),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: '${widget.initialCommittee ?? "Global"}_PRD_Report');
    } catch (e) {
      debugPrint("Error generating PDF: $e");
    }
  }
}
