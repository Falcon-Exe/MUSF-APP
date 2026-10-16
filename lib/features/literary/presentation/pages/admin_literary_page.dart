// lib/features/literary/presentation/pages/admin_literary_page.dart

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/repositories/supabase_publications_repository.dart';
import '../widgets/publication_card.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';
import '../../../../core/utils/pdf_text_helpers.dart';

class AdminLiteraryPage extends StatefulWidget {
  final VoidCallback? onBack;
  final String committeeName;
  const AdminLiteraryPage({
    super.key,
    this.onBack,
    this.committeeName = 'Literary',
  });

  @override
  State<AdminLiteraryPage> createState() => _AdminLiteraryPageState();
}

class _AdminLiteraryPageState extends State<AdminLiteraryPage> {
  late final SupabasePublicationsRepository _publicationsRepository;
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _publicationsFuture;
  List<Map<String, dynamic>> publications = <Map<String, dynamic>>[];
  final Set<String> _deletingPublicationIds = <String>{};

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _authorCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _publicationsRepository = SupabasePublicationsRepository();
    _publicationsFuture = fetchPublications();
  }

  @override
  void didUpdateWidget(covariant AdminLiteraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.committeeName != widget.committeeName) {
      publications = <Map<String, dynamic>>[];
      _publicationsFuture = fetchPublications();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalCommitteeDashboard(
      committeeName: widget.committeeName,
      displayTitle: "${widget.committeeName} Management",
      subtitle: "Command Center",
      onBack: () =>
          widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
      searchHint: "Search content...",
      searchController: _searchController,
      onSearchChanged: (_) => setState(() {}),
      onPdfDownload: _generatePdfReport,
      extraTabs: [
        CommitteeTabConfig(
          label: "Post",
          icon: Icons.post_add_rounded,
          key: 'post',
          content: _buildPostPage(),
        ),
        CommitteeTabConfig(
          label: "Hub",
          icon: Icons.hub_rounded,
          key: 'hub',
          content: _buildHubPage(),
        ),
      ],
    );
  }

  Widget _buildPostPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: _adminInputDecoration("Title"),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _authorCtrl,
            decoration: _adminInputDecoration("Author (e.g. Admin or Name)"),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _contentCtrl,
            maxLines: 8,
            decoration: _adminInputDecoration("Write content here..."),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                if (_titleCtrl.text.isNotEmpty &&
                    _contentCtrl.text.isNotEmpty) {
                  await _publicationsRepository.createPublication(
                    committeeName: widget.committeeName,
                    title: _titleCtrl.text.trim(),
                    authorName: _authorCtrl.text.trim().isEmpty
                        ? 'Admin'
                        : _authorCtrl.text.trim(),
                    content: _contentCtrl.text.trim(),
                    category: "Poetry",
                  );
                  _titleCtrl.clear();
                  _authorCtrl.clear();
                  _contentCtrl.clear();
                  if (mounted) {
                    setState(() => _publicationsFuture = fetchPublications());
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39544B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "PUBLISH DIRECTLY",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _adminInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFC5A059), width: 1.5),
      ),
    );
  }

  Widget _buildHubPage() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _publicationsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Could not load publications: ${snapshot.error}"),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final visiblePublications = (snapshot.data ?? publications).where((
          publication,
        ) {
          final title = (publication['title'] ?? '').toString().toLowerCase();
          return title.contains(_searchController.text.toLowerCase());
        }).toList();

        if (visiblePublications.isEmpty) {
          return const Center(child: Text("No Publications Found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          itemCount: visiblePublications.length,
          itemBuilder: (context, index) {
            final data = visiblePublications[index];
            final docId = data['id']?.toString() ?? '';
            final likesCount =
                int.tryParse(data['likes_count']?.toString() ?? '') ?? 0;
            return PublicationCard(
              title: data['title'] ?? '',
              author: data['author_name'] ?? 'Admin',
              category: data['category'] ?? 'General',
              content: data['content'] ?? '',
              date: _parseDate(data['created_at']),
              likesCount: likesCount,
              isLiked: false,
              onLike: () async {
                await _publicationsRepository.updateLikeCount(
                  id: docId,
                  likesCount: likesCount + 1,
                );
                if (mounted) {
                  setState(() => _publicationsFuture = fetchPublications());
                }
              },
              onReadFull: () => _showReadFullDialog(context, data),
              onDelete: docId.isEmpty
                  ? null
                  : () => _showDeleteConfirm(docId, isWork: true),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirm(String docId, {required bool isWork}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Item"),
          content: Text(
            isWork
                ? "Permanently delete this publication?"
                : "Permanently delete this submission request?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _deletePublication(docId, dialogContext);
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

  Future<List<Map<String, dynamic>>> fetchPublications() async {
    final rows = await _publicationsRepository.fetchPublications(
      committeeName: widget.committeeName,
    );
    publications = List<Map<String, dynamic>>.from(rows);
    return publications;
  }

  Future<void> _deletePublication(
    String publicationId,
    BuildContext dialogContext,
  ) async {
    if (_deletingPublicationIds.contains(publicationId)) return;

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }

    setState(() {
      _deletingPublicationIds.add(publicationId);
      publications.removeWhere(
        (item) => item['id']?.toString() == publicationId,
      );
      _publicationsFuture = Future<List<Map<String, dynamic>>>.value(
        List<Map<String, dynamic>>.from(publications),
      );
    });

    try {
      await _publicationsRepository.deletePublication(publicationId);
      if (!mounted) return;
      
      setState(() {
        _deletingPublicationIds.remove(publicationId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Publication deleted")));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deletingPublicationIds.remove(publicationId);
        _publicationsFuture = fetchPublications();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  Future<void> _generatePdfReport() async {
    try {
      final publications = await _publicationsRepository.fetchPublications(
        committeeName: widget.committeeName,
      );
      final pdf = pw.Document();
      final dateStr =
          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
      final groupedDocs = groupPdfRowsByField(publications, 'category');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "${widget.committeeName} Management Report",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo800,
                    ),
                  ),
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
            ...groupedDocs.entries.expand((entry) {
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
                      data['title']?.toString() ?? "Untitled",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "By ${data['author_name'] ?? 'Admin'} | ${data['category'] ?? 'General'}",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    ...buildPdfTextBlocks(data['content']?.toString() ?? ""),
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
        name: '${widget.committeeName}_Management_Report_$dateStr',
      );
    } catch (e) {
      debugPrint(
        "Error generating ${widget.committeeName} PDF from Supabase: $e",
      );
    }
  }

  void _showReadFullDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF39544B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                "By ${data['author_name'] ?? 'Admin'} | ${data['category'] ?? 'General'}",
                style: const TextStyle(
                  color: Color(0xFFC5A059),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Divider(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    data['content'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
