// lib/features/prd/presentation/pages/prd_print_records_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../logic/prd_controller.dart';
import '../widgets/prd_theme.dart';
import '../widgets/prd_transaction_dialog.dart';

class PrdPrintRecordsPage extends StatefulWidget {
  const PrdPrintRecordsPage({super.key});

  @override
  State<PrdPrintRecordsPage> createState() => _PrdPrintRecordsPageState();
}

class _PrdPrintRecordsPageState extends State<PrdPrintRecordsPage> {
  final PrdController _controller = PrdController();

  final List<String> _classes = [
    "All",
    "Thamheediyya Ula",
    "Thamheediyya Saniya",
    "Aliya Ula",
    "Aliya Saniya",
    "Aliya Salisa",
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrdTheme.primaryDark,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _controller.studentsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    final allDocs = snapshot.data ?? [];
                    int totalDue = 0, totalAdded = 0;
                    List<Map<String, dynamic>> filtered = [];

                    for (var data in allDocs) {
                      int bal = (data['prdPrintBalance'] as num?)?.toInt() ?? 0;
                      int added = (data['prdPrintTotalAdded'] as num?)?.toInt() ?? 0;
                      String course = (data['course'] ?? '')
                          .toString()
                          .toLowerCase();
                      String name = (data['fullName'] ?? '')
                          .toString()
                          .toLowerCase();

                      bool matchesClass =
                          _controller.selectedClass == "All" ||
                          course == _controller.selectedClass.toLowerCase();
                      bool matchesSearch =
                          _controller.searchQuery.isEmpty ||
                          name.contains(_controller.searchQuery.toLowerCase());

                      if (matchesClass && matchesSearch) {
                        filtered.add(data);
                        if (bal > 0) totalDue += bal;
                        totalAdded += added;
                      }
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _buildTopCard(
                                "Total Due",
                                "₹$totalDue",
                                Icons.account_balance_wallet_outlined,
                              ),
                              const SizedBox(width: 15),
                              _buildTopCard(
                                "Total Added",
                                "₹$totalAdded",
                                Icons.print_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSearchField(),
                        const SizedBox(height: 15),
                        _buildClassFilterChips(),
                        const SizedBox(height: 20),
                        Expanded(child: _buildStudentsList(filtered)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              "Print Records",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            tooltip: 'Download Report',
            onPressed: () => _generatePdf(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard(String title, String amount, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: PrdTheme.cardBlue,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: _controller.updateSearch,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search Name...",
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: PrdTheme.cardBlue,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildClassFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _classes.length,
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final c = _classes[index];
          final isSelected = c == _controller.selectedClass;
          return ChoiceChip(
            label: Text(c),
            selected: isSelected,
            onSelected: (val) => _controller.setClassFilter(c),
            selectedColor: Colors.blueAccent,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            showCheckmark: false,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentsList(List<Map<String, dynamic>> docs) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: docs.isEmpty
          ? const Center(
              child: Text(
                "No records found.",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = docs[index];
                final String name = data['fullName'] ?? "Unknown";
                final int balance = (data['prdPrintBalance'] as num?)?.toInt() ?? 0;
                bool isCleared = balance <= 0;

                return InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => PrdTransactionDialog(
                      controller: _controller,
                      docId: data['id']?.toString() ?? '',
                      studentName: name,
                      studentID: data['studentID']?.toString() ?? "",
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: PrdTheme.background,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: PrdTheme.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: PrdTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (data['course'] ?? '').toString().toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "₹$balance",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isCleared ? Colors.grey : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    final rowsData = await Supabase.instance.client
        .from('students')
        .select()
        .order('full_name');
    final docs = List<Map<String, dynamic>>.from(rowsData);

    final pdf = pw.Document();
    final rows = <List<String>>[
      ['#', 'Name', 'Student ID', 'Course', 'Total Added', 'Balance', 'Status'],
    ];

    int idx = 1;
    for (var data in docs) {
      final bal = (data['prd_print_balance'] ?? data['prdPrintBalance'])?.toString() ?? '0';
      rows.add([
        idx.toString(),
        data['full_name'] ?? data['fullName'] ?? '-',
        (data['student_id'] ?? data['studentID'])?.toString() ?? '-',
        data['course'] ?? '-',
        (data['prd_print_total_added'] ?? data['prdPrintTotalAdded'])?.toString() ?? '0',
        bal,
        (int.tryParse(bal) ?? 0) <= 0 ? 'CLEARED' : 'DUE',
      ]);
      idx++;
    }

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'PRD Print Collection Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: rows.first,
            data: rows.sublist(1),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
