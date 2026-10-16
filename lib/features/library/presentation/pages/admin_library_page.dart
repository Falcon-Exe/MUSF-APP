// lib/features/library/presentation/pages/admin_library_page.dart

import 'package:flutter/material.dart';
import '../../logic/library_controller.dart';
import '../../data/repositories/supabase_library_repository.dart';
import '../widgets/fine_breakdown_card.dart';
import '../widgets/book_catalog_card.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';

class AdminLibraryPage extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminLibraryPage({super.key, this.onBack});

  @override
  State<AdminLibraryPage> createState() => _AdminLibraryPageState();
}

class _AdminLibraryPageState extends State<AdminLibraryPage> {
  late final LibraryController _controller;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _classes = [
    "All",
    "Thamheediyya Ula",
    "Thamheediyya Saniya",
    "Aliya Ula",
    "Aliya Saniya",
    "Aliya Salisa",
  ];

  @override
  void initState() {
    super.initState();
    _controller = LibraryController(SupabaseLibraryRepository());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalCommitteeDashboard(
      committeeName: "Library",
      displayTitle: "Library Management",
      subtitle: "Command Center",
      onBack: () =>
          widget.onBack != null ? widget.onBack!() : Navigator.pop(context),
      searchController: _searchController,
      onSearchChanged: (query) => _controller.setSearchQuery(query),
      extraTabs: [
        CommitteeTabConfig(
          label: "Student Fines",
          icon: Icons.money_off_rounded,
          key: 'fines',
          content: _buildFinesTab(),
        ),
        CommitteeTabConfig(
          label: "Book Catalog",
          icon: Icons.library_books_rounded,
          key: 'catalog',
          content: _buildCatalogTab(),
        ),
      ],
    );
  }

  Widget _buildFinesTab() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _controller.getStudentsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Could not load fines: ${snapshot.error}"),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data ?? [];
          final filteredDocs = _filterDocs(docs);

          return Column(
            children: [
              _buildClassFilter(),
              Expanded(
                child: filteredDocs.isEmpty
                    ? const Center(child: Text("No matching records found"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) =>
                            _buildStudentCard(filteredDocs[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterDocs(List<Map<String, dynamic>> docs) {
    return docs.where((data) {
      final String course = data['course']?.toString() ?? '';
      final String name = (data['full_name'] ?? data['fullName'])?.toString() ?? '';
      final String id = (data['student_id'] ?? data['studentID'])?.toString() ?? '';

      bool matchesClass =
          _controller.selectedClass == "All" ||
          course.toLowerCase().trim() ==
              _controller.selectedClass.toLowerCase().trim();
      bool matchesSearch =
          name.toLowerCase().contains(_controller.searchQuery.toLowerCase()) ||
          id.contains(_controller.searchQuery);

      return matchesClass && matchesSearch;
    }).toList();
  }

  Widget _buildClassFilter() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final isSel = _controller.selectedClass == _classes[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _classes[index],
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.black87,
                  fontSize: 11,
                ),
              ),
              selected: isSel,
              selectedColor: const Color(0xFF39544B),
              backgroundColor: const Color(0xFFF3F4F6),
              onSelected: (_) => _controller.setClass(_classes[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> data) {
    final int fine = int.tryParse(data['library_fine']?.toString() ?? data['libraryFine']?.toString() ?? '0') ?? 0;
    final String docId = data['id']?.toString() ?? '';
    final String name = (data['full_name'] ?? data['fullName'])?.toString() ?? 'Unknown';
    final String studentID = (data['student_id'] ?? data['studentID'])?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "ID: $studentID • ${data['course'] ?? '-'}",
        ),
        trailing: Text(
          "₹$fine",
          style: TextStyle(
            color: fine > 0 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () => _showStudentActions(docId, data),
      ),
    );
  }

  void _showStudentActions(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.red),
            title: const Text("Add Fine"),
            onTap: () {
              Navigator.pop(context);
              _showFineDialog(docId, data, true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.green),
            title: const Text("Deduct / Pay Fine"),
            onTap: () {
              Navigator.pop(context);
              _showFineDialog(docId, data, false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue),
            title: const Text("Payment History"),
            onTap: () {
              Navigator.pop(context);
              _showHistory(data['student_id'] ?? data['studentID'] ?? '');
            },
          ),
          ListTile(
            leading: const Icon(Icons.message_outlined, color: Colors.orange),
            title: const Text("Send Notice"),
            onTap: () {
              Navigator.pop(context);
              _showNoticeDialog(data['student_id'] ?? data['studentID'] ?? '');
            },
          ),
        ],
      ),
    );
  }

  void _showFineDialog(String docId, Map<String, dynamic> data, bool isAdding) {
    final amountController = TextEditingController();
    final int currentFine =
        int.tryParse(data['library_fine']?.toString() ?? data['libraryFine']?.toString() ?? '0') ?? 0;
    final String studentID = (data['student_id'] ?? data['studentID'])?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdding ? "Add Library Fine" : "Deduct Library Fine"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Amount (₹)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final amt = int.tryParse(amountController.text) ?? 0;
              if (amt > 0) {
                _controller.updateFine(
                  docId: docId,
                  studentID: studentID,
                  amount: amt,
                  isAdding: isAdding,
                  currentFine: currentFine,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _showNoticeDialog(String studentID) {
    final msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send Library Notice"),
        content: TextField(
          controller: msgController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Message",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (msgController.text.isNotEmpty) {
                _controller.sendNotice(
                  studentID: studentID,
                  message: msgController.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  void _showHistory(String studentID) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Transaction History"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _controller.getHistoryStream(studentID),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text("Could not load history: ${snapshot.error}"),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("No history found"));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final dat = docs[index];
                  DateTime dt = DateTime.tryParse(dat['date']?.toString() ?? '') ??
                      DateTime.tryParse(dat['created_at']?.toString() ?? '') ??
                      DateTime.now();

                  return FineBreakdownCard(
                    type: dat['type'] ?? 'Deduction',
                    amount: int.tryParse(dat['amount']?.toString() ?? '0') ?? 0,
                    date: dt,
                    onDelete: () {
                      _controller.deleteTransaction(
                        transId: dat['id']?.toString() ?? '',
                        studentID: studentID,
                        amount:
                            int.tryParse(dat['amount']?.toString() ?? '0') ?? 0,
                        type: dat['type'] ?? 'Deduction',
                      );
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddBook,
            icon: const Icon(Icons.add),
            label: const Text("ADD NEW BOOK"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _controller.getBooksCatalogStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text("Could not load books: ${snapshot.error}"),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("No books in catalog"));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index];
                  final docId = data['id']?.toString() ?? '';

                  return BookCatalogCard(
                    title: data['title'] ?? 'Untitled',
                    author: data['author'] ?? 'Unknown Author',
                    imageUrl: data['image_url'] ?? data['imageUrl'],
                    onDelete: () => _controller.deleteBook(docId),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddBook() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Book"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Book Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: "Author Name",
                border: OutlineInputBorder(),
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
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  authorController.text.isNotEmpty) {
                _controller.addBook(
                  title: titleController.text,
                  author: authorController.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Add Book"),
          ),
        ],
      ),
    );
  }
}
