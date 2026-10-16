// lib/features/research/presentation/pages/admin_research_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../admin/admin_committee_prize.dart';
import '../../../../admin/event_management_page.dart';
import '../../../../admin/purchase_request_page.dart';
import '../../logic/research_controller.dart';
import '../widgets/research_details_dialog.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';
import '../../../../core/utils/pdf_text_helpers.dart';
import '../../../../core/widgets/admin_shared_components.dart';
import '../../../../features/reels/presentation/pages/reel_upload_page.dart';
import '../../../../features/prd/presentation/pages/prd_request_desk_page.dart';
import '../../../../core/theme/committee_theme.dart';

class AdminResearchPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminResearchPage({super.key, this.onBack});

  @override
  State<AdminResearchPage> createState() => _AdminResearchPageState();
}

class _AdminResearchPageState extends State<AdminResearchPage> {
  static const String _committeeName = 'Research';
  final ResearchController _controller = ResearchController();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _abstractController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  String _selectedField = "Science";
  bool _isPublishing = false;
  String _initialTabKey = 'dashboard';
  int _dashboardResetKey = 0;

  late Future<List<Map<String, dynamic>>> _historyRecordsFuture;

  List<Map<String, dynamic>> _historyRecords = [];
  final Set<String> _deletingRecordIds = <String>{};

  @override
  void initState() {
    super.initState();
    _historyRecordsFuture = _fetchHistoryRecords();
  }

  void _refreshData() {
    setState(() {
      _historyRecordsFuture = _fetchHistoryRecords();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchHistoryRecords() async {
    final records = await _controller.fetchResearchRecords(
      committeeName: _committeeName,
      statusGroup: 'history',
    );
    _historyRecords = List<Map<String, dynamic>>.from(records);
    return _historyRecords;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _abstractController.dispose();
    _authorController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalCommitteeDashboard(
      key: ValueKey(_dashboardResetKey),
      committeeName: _committeeName,
      displayTitle: "Research Center",
      subtitle: "Command Center",
      onBack: () =>
          widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
      onPdfDownload: _generatePdfReport,
      customDashboard: _buildResearchDashboard(),
      initialTabKey: _initialTabKey,
      extraTabs: [
        CommitteeTabConfig(
          label: "Publish",
          icon: Icons.publish_rounded,
          key: 'publish',
          content: _buildPublishTab(),
        ),
        CommitteeTabConfig(
          label: "History",
          icon: Icons.history_rounded,
          key: 'history',
          content: _buildHistoryTab(),
        ),
      ],
    );
  }

  Widget _buildResearchDashboard() {
    final theme = getCommitteeTheme(_committeeName);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoreToolsSection(theme),
          const SizedBox(height: 35),
          _buildSupportToolsSection(theme),
        ],
      ),
    );
  }

  Widget _buildCoreToolsSection(CommitteeTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionTitle(title: "CORE TOOLS", color: theme.accentColor),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.25,
          children: [
            AdminCoreToolCard(
              icon: Icons.event_available_rounded,
              label: "Events",
              subtitle: "Manage events",
              color: theme.accentColor,
              iconBackgroundColor: theme.lightColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EventManagementPage(
                    initialCommittee: _committeeName,
                  ),
                ),
              ),
            ),
            AdminCoreToolCard(
              icon: Icons.video_collection_rounded,
              label: "Reel Upload",
              subtitle: "Upload media",
              color: theme.accentColor,
              iconBackgroundColor: theme.lightColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ReelUploadPage(committeeName: _committeeName),
                ),
              ),
            ),
            AdminCoreToolCard(
              icon: Icons.emoji_events_rounded,
              label: "Prizes",
              subtitle: "Winners & rankings",
              color: theme.accentColor,
              iconBackgroundColor: theme.lightColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminCommitteeDashboard(
                    initialCommittee: _committeeName,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportToolsSection(CommitteeTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionTitle(title: "SUPPORT TOOLS", color: theme.accentColor),
        const SizedBox(height: 18),
        AdminSupportToolCard(
          icon: Icons.design_services_rounded,
          title: "PRD Request",
          subtitle: "Submit designs & posters",
          color: theme.accentColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const PrdRequestDeskPage(initialCommittee: _committeeName),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AdminSupportToolCard(
          icon: Icons.account_balance_wallet_rounded,
          title: "Fund Request",
          subtitle: "Request fund from Treasurer",
          color: theme.accentColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const PurchaseRequestPage(committeeName: _committeeName),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AdminSupportToolCard(
          icon: Icons.picture_as_pdf_rounded,
          title: "Research Report PDF",
          subtitle: "Generate Research Center report",
          color: theme.accentColor,
          onTap: _generatePdfReport,
        ),
      ],
    );
  }

  Widget _buildPublishTab() {
    final theme = getCommitteeTheme(_committeeName);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionTitle(
            title: "Publish Research Paper",
            color: theme.accentColor,
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _selectedField,
            decoration: _inputDecoration("Category", Icons.category_rounded),
            items: ['Science', 'Technology', 'Social', 'Literature', 'Arts']
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) =>
                setState(() => _selectedField = val ?? "Science"),
          ),
          const SizedBox(height: 15),
          _buildModernInput(_titleController, "Title", Icons.title_rounded),
          const SizedBox(height: 15),
          _buildModernInput(
            _authorController,
            "Author Name",
            Icons.person_search_rounded,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _abstractController,
            minLines: 10,
            maxLines: 22,
            decoration: _inputDecoration(
              "Full Paper / Description",
              Icons.notes_rounded,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _publishResearchPaper,
              icon: _isPublishing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.publish_rounded, color: Colors.white),
              label: const Text(
                "Publish Paper",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39544B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(Future<List<Map<String, dynamic>>> future) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                "No published research papers found.",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final record = list[index];
            final data = _recordToResearchData(record);
            final String docId = record['id']?.toString() ?? '';
            final dateStr = DateFormat(
              'dd MMM yyyy',
            ).format(_parsePublicationDate(record['published_at']));
            final category = data['category']?.toString() ?? 'General';
            final fullPaperPreview = data['full_paper']?.toString().trim();
            final preview =
                fullPaperPreview != null && fullPaperPreview.isNotEmpty
                ? fullPaperPreview
                : data['description']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => ResearchDetailsDialog(data: data),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? "Untitled",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("By ${data['author']} | $category | $dateStr"),
                        if (preview.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            preview,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(height: 1.35),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: _deletingRecordIds.contains(docId)
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: "Delete Research Paper",
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: docId.isEmpty
                                  ? null
                                  : () => _showDeleteConfirm(docId),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionTitle(
            title: "PUBLISHED RESEARCH HISTORY",
            color: const Color(0xFF39544B),
          ),
          const SizedBox(height: 18),
          _buildHistoryList(_historyRecordsFuture),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String docId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Manuscript"),
          content: const Text("Permanently delete this manuscript?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deleteRecord(docId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRecord(String recordId) async {
    if (_deletingRecordIds.contains(recordId)) return;
    setState(() => _deletingRecordIds.add(recordId));

    try {
      await _controller.deletePublishedPaper(recordId);
      if (!mounted) return;
      setState(() {
        _deletingRecordIds.remove(recordId);
      });
      _refreshData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Manuscript deleted")));
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingRecordIds.remove(recordId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  Future<void> _publishResearchPaper() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isPublishing = true);

    try {
      final now = DateTime.now().toIso8601String();
      final paperText = _abstractController.text.trim();
      await Supabase.instance.client.from('research_works').insert({
        'title': _titleController.text.trim(),
        'author_name': _authorController.text.trim(),
        'category': _selectedField,
        'description': paperText,
        'full_paper': paperText,
        'status': 'published',
        'published_at': now,
        'created_at': now,
        'updated_at': now,
      });

      if (!mounted) return;
      _titleController.clear();
      _authorController.clear();
      _abstractController.clear();
      setState(() {
        _initialTabKey = 'history';
        _dashboardResetKey++;
        _historyRecordsFuture = _fetchHistoryRecords();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Research paper published.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Publish failed: $e")));
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Widget _buildModernInput(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(hint, icon),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    try {
      final records = await _controller.fetchResearchRecords(
        committeeName: _committeeName,
        statusGroup: 'history',
      );
      final rows = records.map(_recordToResearchData).toList();
      final groupedRows = groupPdfRowsByField(rows, 'category');
      final pdf = pw.Document();
      final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Research Center Report',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo800,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Text(
                    dateStr,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            ...groupedRows.entries.expand((entry) {
              return [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  color: PdfColors.indigo50,
                  child: pw.Text(
                    entry.key.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo800,
                    ),
                  ),
                ),
                ...entry.value.expand((data) {
                  return [
                    pw.Text(
                      data['title']?.toString() ?? 'Untitled',
                      softWrap: true,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'By ${data['author'] ?? 'Unknown'}',
                      softWrap: true,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    ...buildPdfTextBlocks(
                      data['full_paper']?.toString() ??
                          data['abstract']?.toString() ??
                          '',
                    ),
                    pw.SizedBox(height: 15),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 15),
                  ];
                }),
              ];
            }),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Research_Center_Report_$dateStr.pdf',
      );
    } catch (e) {
      debugPrint('Error generating Research PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not generate PDF: $e')));
    }
  }

  Map<String, dynamic> _recordToResearchData(Map<String, dynamic> data) {
    final desc = data['description']?.toString() ?? '';
    final fullPaper = data['full_paper']?.toString() ?? desc;
    final regExp = RegExp(r'^\[(.*?)\] (.*)$');
    final match = regExp.firstMatch(desc);
    final category =
        data['category']?.toString() ??
        (match != null ? match.group(1) : 'General');
    final abstractText = match != null ? match.group(2) : desc;

    return {
      ...data,
      'title': data['title'],
      'author': data['author_name'] ?? 'Unknown',
      'abstract': abstractText,
      'full_paper': fullPaper,
      'category': category,
      'field': category,
      'likes': 0,
      'date': _parsePublicationDate(data['published_at']),
    };
  }

  DateTime _parsePublicationDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
