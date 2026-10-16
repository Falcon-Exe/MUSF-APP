// lib/features/library/presentation/pages/admin_library_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/library_controller.dart';
import '../../data/repositories/firestore_library_repository.dart';
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
    _controller = LibraryController(FirestoreLibraryRepository());
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
      onSearchChanged: _controller.setSearchQuery,
      extraTabs: [
        CommitteeTabConfig(
          label: "Fines",
          icon: Icons.account_balance_wallet_rounded,
          key: 'fines',
          content: _buildFinesTab(),
        ),
        CommitteeTabConfig(
          label: "Catalog",
          icon: Icons.menu_book_rounded,
          key: 'catalog',
          content: _buildCatalogTab(),
        ),
      ],
    );
  }

  Widget _buildFinesTab() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => StreamBuilder<QuerySnapshot>(
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
          final docs = snapshot.data?.docs ?? [];
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

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String course = data['course']?.toString() ?? '';
      final String name = data['fullName']?.toString() ?? '';
      final String id = data['studentID']?.toString() ?? '';

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

  Widget _buildStudentCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final int fine = int.tryParse(data['libraryFine']?.toString() ?? '0') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(
          data['fullName'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "ID: ${data['studentID'] ?? '-'} • ${data['course'] ?? '-'}",
        ),
        trailing: Text(
          "₹$fine",
          style: TextStyle(
            color: fine > 0 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () => _showStudentActions(doc.id, data),
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
              _showInputDialog(docId, data, true);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.remove_circle_outline,
              color: Colors.green,
            ),
            title: const Text("Deduct Fine"),
            onTap: () {
              Navigator.pop(context);
              _showInputDialog(docId, data, false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: Colors.blue),
            title: const Text("View History"),
            onTap: () {
              Navigator.pop(context);
              _showHistory(data['studentID']);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showInputDialog(
    String docId,
    Map<String, dynamic> data,
    bool isAdding,
  ) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdding ? "Add Fine" : "Deduct Fine"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount (₹)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final amt = int.tryParse(ctrl.text) ?? 0;
              if (amt > 0) {
                _controller.updateFine(
                  docId: docId,
                  studentID: data['studentID'],
                  amount: amt,
                  isAdding: isAdding,
                  currentFine:
                      int.tryParse(data['libraryFine']?.toString() ?? '0') ?? 0,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
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
          child: StreamBuilder<QuerySnapshot>(
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
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("No history found"));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final d = docs[index];
                  final dat = d.data() as Map<String, dynamic>;
                  return FineBreakdownCard(
                    type: dat['type'] ?? 'Deduction',
                    amount: int.tryParse(dat['amount']?.toString() ?? '0') ?? 0,
                    date: dat['date'] != null
                        ? (dat['date'] as Timestamp).toDate()
                        : DateTime.now(),
                    onDelete: () {
                      _controller.deleteTransaction(
                        transId: d.id,
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
          child: StreamBuilder<QuerySnapshot>(
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
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("No books in catalog"));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BookCatalogCard(
                      title: data['title'] ?? 'Untitled',
                      author: data['author'] ?? 'Unknown',
                      imageUrl: data['imageUrl'],
                      onDelete: () => _controller.deleteBook(docs[index].id),
                    ),
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
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Book"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Book Title"),
            ),
            TextField(
              controller: authorCtrl,
              decoration: const InputDecoration(labelText: "Author"),
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
              if (titleCtrl.text.isNotEmpty && authorCtrl.text.isNotEmpty) {
                _controller.addBook(
                  title: titleCtrl.text,
                  author: authorCtrl.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
