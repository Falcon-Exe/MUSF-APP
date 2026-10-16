// lib/features/arts/presentation/widgets/arts_sheets_import_dialog.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/google_sheets_helper.dart';
import '../../logic/arts_controller.dart';

class ArtsSheetsImportDialog extends StatelessWidget {
  final BuildContext parentContext;

  const ArtsSheetsImportDialog({super.key, required this.parentContext});

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkController = TextEditingController();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.table_chart_rounded, color: Colors.green),
          SizedBox(width: 10),
          Text("Import from Sheets"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Paste a public Google Sheet or direct CSV link. Columns: Event, Prize, Name. Optional: Student ID, Category.",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: linkController,
            decoration: InputDecoration(
              labelText: "Google Sheet or CSV Link",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final url = linkController.text.trim();
            if (url.isEmpty) return;

            Navigator.pop(context);
            _showSuccessDialog(parentContext, "Fetching results... Please wait.");

            try {
              final results = await GoogleSheetsHelper.fetchResults(url);
              if (results.isEmpty) {
                if (parentContext.mounted) {
                  _showSuccessDialog(parentContext, "No results found in sheet.");
                }
                return;
              }

              final client = Supabase.instance.client;
              int matchCount = 0;

              final eventsRows = await client.from('arts_events').select();

              for (var res in results) {
                Map<String, dynamic>? eventRow;
                for (final row in eventsRows) {
                  final title = (row['title'] ?? '').toString().toLowerCase().trim();
                  if (title == res.eventName.toLowerCase().trim()) {
                    eventRow = row;
                    break;
                  }
                }

                final category = ArtsController.normalizeCategory(res.category);
                final resultData = {
                  'title': res.eventName,
                  'type': category,
                  'first_place_id': res.firstPlaceId ?? '',
                  'first_place_name': res.firstPlaceName ?? '',
                  'second_place_id': res.secondPlaceId ?? '',
                  'second_place_name': res.secondPlaceName ?? '',
                  'third_place_id': res.thirdPlaceId ?? '',
                  'third_place_name': res.thirdPlaceName ?? '',
                  'results_published': true,
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                };

                if (eventRow != null) {
                  await client
                      .from('arts_events')
                      .update(resultData)
                      .eq('id', eventRow['id']);
                } else {
                  await client.from('arts_events').insert({
                    ...resultData,
                    'created_at': DateTime.now().toUtc().toIso8601String(),
                  });
                }
                matchCount++;
              }

              if (parentContext.mounted) {
                _showSuccessDialog(
                  parentContext,
                  "Imported results for $matchCount events successfully.",
                );
              }
            } catch (e) {
              if (parentContext.mounted) {
                _showSuccessDialog(parentContext, "Error: $e");
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Import", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
