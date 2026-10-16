import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddCssDialog extends StatefulWidget {
  final Function(String title, String instruction, DateTime startDate, DateTime endDate) onSubmit;

  const AddCssDialog({super.key, required this.onSubmit});

  @override
  State<AddCssDialog> createState() => _AddCssDialogState();
}

class _AddCssDialogState extends State<AddCssDialog> {
  final _titleCtrl = TextEditingController();
  final _instrCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instrCtrl.dispose();
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
              const Text("New CSS Program", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildLabel("Program Name"),
              _buildTextField(_titleCtrl, "e.g. Campus Clean Drive"),
              const SizedBox(height: 16),
              _buildLabel("Instructions / Details"),
              _buildTextField(_instrCtrl, "Brief instructions...", maxLines: 2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDatePicker("Start Date", _startDate, (d) => setState(() => _startDate = d))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDatePicker("End Date", _endDate, (d) => setState(() => _endDate = d), firstDate: _startDate)),
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
                        if (_titleCtrl.text.isNotEmpty && _startDate != null && _endDate != null) {
                          widget.onSubmit(
                            _titleCtrl.text,
                            _instrCtrl.text,
                            _startDate!,
                            _endDate!,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Post Work", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
    );
  }

  Widget _buildDatePicker(String label, DateTime? current, Function(DateTime) onPicked, {DateTime? firstDate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: current ?? firstDate ?? DateTime.now(),
              firstDate: firstDate ?? DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18)),
            child: Text(current != null ? DateFormat('MMM dd, yyyy').format(current) : "Select", style: TextStyle(color: current != null ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
