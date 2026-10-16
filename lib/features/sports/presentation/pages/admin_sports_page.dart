// lib/features/sports/presentation/pages/admin_sports_page.dart

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../logic/sports_controller.dart';
import '../widgets/admin_sports_event_card.dart';
import '../widgets/sports_sheets_import_dialog.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';

class AdminSportsPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminSportsPage({super.key, this.onBack});

  @override
  State<AdminSportsPage> createState() => _AdminSportsPageState();
}

class _AdminSportsPageState extends State<AdminSportsPage> {
  late final SportsController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SportsController();
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
      committeeName: "Sports",
      displayTitle: "Sports Management",
      subtitle: "Command Center",
      onBack: () =>
          widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
      searchController: _searchController,
      onSearchChanged: _controller.updateSearch,
      onPdfDownload: _generatePdfReport,
      extraTabs: [
        CommitteeTabConfig(
          label: "Outdoor",
          icon: Icons.sports_soccer_rounded,
          key: 'outdoor',
          content: _buildEventListTab("Outdoor"),
        ),
        CommitteeTabConfig(
          label: "Indoor",
          icon: Icons.sports_kabaddi_rounded,
          key: 'indoor',
          content: _buildEventListTab("Indoor"),
        ),
      ],
      specialFeatures: [
        CommitteeSpecialFeature(
          title: "Add Event",
          subtitle: "Create a new sports event",
          icon: Icons.add_circle_outline_rounded,
          color: const Color(0xFFF59E0B),
          onTap: _showAddEventDialog,
        ),
        CommitteeSpecialFeature(
          title: "Import Results",
          subtitle: "Paste Google Sheet or CSV link",
          icon: Icons.text_snippet_rounded,
          color: const Color(0xFF10B981),
          onTap: () => showDialog(
            context: context,
            builder: (ctx) => SportsSheetsImportDialog(parentContext: context),
          ),
        ),
      ],
    );
  }

  Widget _buildEventListTab(String category) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _controller.eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredDocs = (snapshot.data ?? []).where((data) {
          final String title = (data['title'] ?? '').toString().toLowerCase();
          final String cat = (data['category'] ?? 'Outdoor').toString();

          final bool matchesType = cat.toLowerCase() == category.toLowerCase();
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
            return AdminSportsEventCard(
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
        .from('sports_events')
        .select()
        .eq('results_published', true);

    final outdoorEvents = <Map<String, dynamic>>[];
    final indoorEvents = <Map<String, dynamic>>[];

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
      final category = (data['category'] ?? 'Outdoor').toString();
      if (category.toLowerCase() == 'indoor') {
        indoorEvents.add(data);
      } else {
        outdoorEvents.add(data);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            "Sports Results Report",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text("Outdoor and Indoor published results"),
          pw.SizedBox(height: 18),
          _buildPdfSection("Outdoor Results", outdoorEvents),
          pw.SizedBox(height: 24),
          _buildPdfSection("Indoor Results", indoorEvents),
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
    String category = "Outdoor";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("New Sports Event"),
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
                items: ["Outdoor", "Indoor"].map((c) {
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
