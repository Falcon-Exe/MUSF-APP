// lib/features/sports/presentation/widgets/sports_result_entry_dialog.dart

import 'package:flutter/material.dart';
import '../../logic/sports_controller.dart';

class SportsResultEntryDialog extends StatefulWidget {
  final String docId;
  final String eventName;
  final Map<String, dynamic> data;
  final SportsController controller;

  const SportsResultEntryDialog({
    super.key,
    required this.docId,
    required this.eventName,
    required this.data,
    required this.controller,
  });

  @override
  State<SportsResultEntryDialog> createState() => _SportsResultEntryDialogState();
}

class _SportsResultEntryDialogState extends State<SportsResultEntryDialog> {
  late final TextEditingController firstController;
  late final TextEditingController secondController;
  late final TextEditingController thirdController;

  @override
  void initState() {
    super.initState();
    firstController = TextEditingController(text: widget.data['firstPlaceId'] ?? '');
    secondController = TextEditingController(text: widget.data['secondPlaceId'] ?? '');
    thirdController = TextEditingController(text: widget.data['thirdPlaceId'] ?? '');
  }

  @override
  void dispose() {
    firstController.dispose();
    secondController.dispose();
    thirdController.dispose();
    super.dispose();
  }

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
    const Color primaryDark = Color(0xFF08233E);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 25,
        right: 25,
        top: 25,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Assign Winners: ${widget.eventName}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildInputField(firstController, "🥇 1st Place (Student ID)"),
            const SizedBox(height: 10),
            _buildInputField(secondController, "🥈 2nd Place (Student ID)"),
            const SizedBox(height: 10),
            _buildInputField(thirdController, "🥉 3rd Place (Student ID)"),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDark,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                if (firstController.text.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (c) => const Center(child: CircularProgressIndicator()),
                  );

                  String id1 = firstController.text.trim();
                  String id2 = secondController.text.trim();
                  String id3 = thirdController.text.trim();

                  String name1 = await widget.controller.getStudentNameFromID(id1);
                  String name2 = id2.isNotEmpty ? await widget.controller.getStudentNameFromID(id2) : "";
                  String name3 = id3.isNotEmpty ? await widget.controller.getStudentNameFromID(id3) : "";

                  await widget.controller.updateResults(widget.docId, {
                    'firstPlaceId': id1,
                    'secondPlaceId': id2,
                    'thirdPlaceId': id3,
                    'firstPlaceName': name1,
                    'secondPlaceName': name2,
                    'thirdPlaceName': name3,
                    'resultsPublished': true,
                  });

                  if (context.mounted) {
                    Navigator.pop(context); // Pop loading
                    Navigator.pop(context); // Pop sheet
                    _showSuccessDialog(context, "Results Published");
                  }
                }
              },
              child: const Text("PUBLISH SCORES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
