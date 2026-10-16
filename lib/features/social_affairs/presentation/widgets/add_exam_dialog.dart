import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddExamDialog extends StatefulWidget {
  final Function(String subject, DateTime date, String location) onSubmit;

  const AddExamDialog({super.key, required this.onSubmit});

  @override
  State<AddExamDialog> createState() => _AddExamDialogState();
}

class _AddExamDialogState extends State<AddExamDialog> {
  final _subjectCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  DateTime? _date;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Schedule New Exam", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildLabel("Subject Name"),
              _buildTextField(_subjectCtrl, "e.g. Political Science"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Date"),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                            if (picked != null) setState(() => _date = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18)),
                            child: Text(_date != null ? DateFormat('yyyy-MM-dd').format(_date!) : "Select Date", style: TextStyle(color: _date != null ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Location"),
                        _buildTextField(_locationCtrl, "Hall B-02"),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey)))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: () {
                        if (_subjectCtrl.text.isNotEmpty && _date != null) {
                          widget.onSubmit(
                            _subjectCtrl.text,
                            _date!,
                            _locationCtrl.text,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 6), child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)));
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
    );
  }
}
