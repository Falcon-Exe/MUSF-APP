// lib/features/arts/presentation/pages/admin_arts_page.dart

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../logic/arts_controller.dart';
import '../widgets/admin_arts_event_card.dart';
import '../widgets/arts_sheets_import_dialog.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';
import '../../../../admin/samajyam_admin_page.dart';

class AdminArtsPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminArtsPage({super.key, this.onBack});

  @override
  State<AdminArtsPage> createState() => _AdminArtsPageState();
}

class _AdminArtsPageState extends State<AdminArtsPage> {
  late final ArtsController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ArtsController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalCommitteeDashboard(
      committeeName: "Fine Arts",
      displayTitle: "Fine Arts Management",
      subtitle: "Command Center",
      onBack: () =>
          widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
      searchController: _searchController,
      onSearchChanged: _controller.updateSearch,
      onPdfDownload: _generatePdfReport,
      extraTabs: [
        CommitteeTabConfig(
          label: "On-Stage",
          icon: Icons.mic_external_on_rounded,
          key: 'on_stage',
          content: _buildEventListTab("On-Stage"),
        ),
        CommitteeTabConfig(
          label: "Off-Stage",
          icon: Icons.draw_rounded,
          key: 'off_stage',
          content: _buildEventListTab("Off-Stage"),
        ),
      ],
      specialFeatures: [
        CommitteeSpecialFeature(
          title: "Add Event",
          subtitle: "Create a new arts event",
          icon: Icons.add_circle_outline_rounded,
          color: const Color(0xFF6366F1),
          onTap: _showAddEventDialog,
        ),
        CommitteeSpecialFeature(
          title: "Import Results",
          subtitle: "Paste Google Sheet or CSV link",
          icon: Icons.text_snippet_rounded,
          color: const Color(0xFF3B82F6),
          onTap: () => showDialog(
            context: context,
            builder: (ctx) => ArtsSheetsImportDialog(parentContext: context),
          ),
        ),
        CommitteeSpecialFeature(
          title: "Samajyam",
          subtitle: "Manage Samajyam teams and records",
          icon: Icons.groups_rounded,
          color: const Color(0xFF10B981),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SamajyamAdminPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildEventListTab(String category) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _controller.eventsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Could not load events: ${snapshot.error}"),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredDocs = (snapshot.data ?? []).where((data) {
          final String title = (data['title'] ?? '').toString().toLowerCase();
          final String type = ArtsController.normalizeCategory(data['type']);

          final bool matchesType = type == category;
          final bool matchesSearch = title.contains(
            _searchController.text.toLowerCase(),
          );
          return matchesType && matchesSearch;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text("No events found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index];
            return AdminArtsEventCard(
              docId: data['id']?.toString() ?? '',
              data: data,
              controller: _controller,
            );
          },
        );
      },
    );
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    final rows = await Supabase.instance.client
        .from('arts_events')
        .select()
        .eq('results_published', true);

    final stageEvents = <Map<String, dynamic>>[];
    final offStageEvents = <Map<String, dynamic>>[];

    for (final raw in rows) {
      final data = {
        ...raw,
        'firstPlaceName': raw['first_place_name'] ?? '',
        'secondPlaceName': raw['second_place_name'] ?? '',
        'thirdPlaceName': raw['third_place_name'] ?? '',
        'firstPlaceId': raw['first_place_id'] ?? '',
        'secondPlaceId': raw['second_place_id'] ?? '',
        'thirdPlaceId': raw['third_place_id'] ?? '',
      };
      final type = ArtsController.normalizeCategory(data['type']);
      if (type == 'Off-Stage') {
        offStageEvents.add(data);
      } else {
        stageEvents.add(data);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            "Fine Arts Results Report",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          _buildPdfSection("Stage Results", stageEvents),
          pw.SizedBox(height: 24),
          _buildPdfSection("Off-Stage Results", offStageEvents),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfSection(String title, List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text("No published results."),
        ],
      );
    }

    events.sort(
      (a, b) => (a['title'] ?? '').toString().compareTo(
        (b['title'] ?? '').toString(),
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ["Event", "1st", "2nd", "3rd"],
          data: events.map((event) {
            return [
              event['title']?.toString() ?? '',
              _winnerLabel(event, 'first'),
              _winnerLabel(event, 'second'),
              _winnerLabel(event, 'third'),
            ];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        ),
      ],
    );
  }

  String _winnerLabel(Map<String, dynamic> event, String place) {
    final name = event['${place}PlaceName']?.toString() ?? '';
    final id = event['${place}PlaceId']?.toString() ?? '';
    if (name.isEmpty && id.isEmpty) return '-';
    if (id.isEmpty) return name;
    if (name.isEmpty) return id;
    return "$name ($id)";
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    String category = "On-Stage";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("New Arts Event"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Event Title"),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                items: ["On-Stage", "Off-Stage"].map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => category = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty) {
                  await _controller.addEvent(titleController.text.trim(), category);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }
}
