import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'purchase_request_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'reel_upload_page.dart';
import 'event_management_page.dart';
import '../services/cloud_storage_service.dart';
import '../features/prd/presentation/pages/prd_request_desk_page.dart';
import 'admin_committee_prize.dart'; // Ensure this matches your actual filename

class LibraryFinePage extends StatefulWidget {
  final VoidCallback? onBack; // 🟢 Add this
  const LibraryFinePage({super.key, this.onBack});

  @override
  State<LibraryFinePage> createState() => _LibraryFinePageState();
}

class _LibraryFinePageState extends State<LibraryFinePage> {
  final Color primaryBrown = const Color(0xFF2D1410);
  final Color surfaceGrey = const Color(0xFFF8F9FA);

  final List<String> _classes = [
    "All",
    "Thamheediyya Ula",
    "Thamheediyya Saniya",
    "Aliya Ula",
    "Aliya Saniya",
    "Aliya Salisa",
  ];
  String _selectedClass = "All";
  String _searchQuery = "";
  Uint8List? _selectedBookBytes;

  // --- REFRESH LOGIC ---
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {});
  }

  // --- CORE DELETE LOGIC: DELETES FROM DB AND REVERTS BALANCES ---
  Future<void> _deleteTransaction(
    String transId,
    String studentID,
    int transAmount,
    String transType,
  ) async {
    // 1. Delete log from database
    await FirebaseFirestore.instance
        .collection('library_payments')
        .doc(transId)
        .delete();

    // 2. Reverse the math in the students collection
    var studentQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('studentID', isEqualTo: studentID)
        .limit(1)
        .get();

    if (studentQuery.docs.isNotEmpty) {
      var doc = studentQuery.docs.first;
      int currentFine =
          int.tryParse(doc['libraryFine']?.toString() ?? '0') ?? 0;

      // If we deleted an 'Addition', subtract it. If we deleted a 'Deduction', add it back.
      int updatedFine = (transType == 'Addition')
          ? (currentFine - transAmount).clamp(0, 999999)
          : (currentFine + transAmount);

      await doc.reference.update({
        'libraryFine': updatedFine,
        'libraryStatus': updatedFine == 0 ? "Cleared" : "Pending",
      });
    }
  }

  // --- ADD BOOK DIALOG ---
  void _showAddBookDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    _selectedBookBytes = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Book to Catalog"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Book Title"),
                ),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(labelText: "Author"),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _pickBookImage(setDialogState),
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("Add Book Photo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                ),
                if (_selectedBookBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Image.memory(
                      _selectedBookBytes!,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBrown),
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  // Show loading indicator
                  setDialogState(() {});

                  String? imageUrl;
                  if (_selectedBookBytes != null) {
                    try {
                      String fileName =
                          "book_${DateTime.now().millisecondsSinceEpoch}.jpg";
                      final upload = await CloudStorageService().uploadBytes(
                        bytes: _selectedBookBytes!,
                        folder: CloudStorageFolder.committeeImages,
                        fileName: fileName,
                        contentType: 'image/jpeg',
                      );
                      imageUrl = upload.url;
                    } catch (e) {
                      debugPrint("Image upload error: $e");
                    }
                  }

                  await FirebaseFirestore.instance
                      .collection('library_books')
                      .add({
                        'title': titleController.text,
                        'author': authorController.text,
                        'imageUrl': imageUrl,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                "SAVE BOOK",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HISTORY DIALOG (Long press to delete and revert) ---
  void _showHistoryDialog(String studentID, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("History: $name"),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('library_payments')
                .where('studentID', isEqualTo: studentID)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(child: Text("No transaction history."));
              }

              return ListView.builder(
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snap.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  DateTime dt = (data['date'] as Timestamp).toDate();
                  bool isAdd = data['type'] == 'Addition';
                  int amt =
                      int.tryParse(data['amount']?.toString() ?? '0') ?? 0;

                  return ListTile(
                    leading: Icon(
                      isAdd ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isAdd ? Colors.red : Colors.green,
                    ),
                    title: Text("${data['type']}: ₹$amt"),
                    subtitle: Text(DateFormat('dd MMM, hh:mm a').format(dt)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete & Revert?"),
                              content: Text(
                                "This will remove the log and reverse ₹$amt in the student's fine balance.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("CANCEL"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _deleteTransaction(
                                      doc.id,
                                      studentID,
                                      amt,
                                      data['type'],
                                    );
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text(
                                    "DELETE",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_forever,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete & Revert',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  // --- MANAGE BOOKS DIALOG (Delete Catalog) ---
  void _showManageBooksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manage Catalog"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('library_books')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(child: Text("No books in catalog."));
              }

              return ListView.builder(
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snap.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: data['imageUrl'] != null
                        ? Image.network(
                            data['imageUrl'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.book),
                          )
                        : const Icon(Icons.book),
                    title: Text(data['title'] ?? 'Unknown Title'),
                    subtitle: Text(data['author'] ?? 'Unknown Author'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete Book?"),
                            content: Text(
                              "Remove '${data['title']}' from the library?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("CANCEL"),
                              ),
                              TextButton(
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('library_books')
                                      .doc(doc.id)
                                      .delete();
                                  Navigator.pop(ctx);
                                },
                                child: const Text(
                                  "DELETE",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  // --- SEND MESSAGE DIALOG ---
  void _showSendMessageDialog(String studentID, String name) {
    final TextEditingController msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Message $name"),
        content: TextField(
          controller: msgController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Type your message here...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBrown),
            onPressed: () async {
              if (msgController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .add({
                      'studentID': studentID,
                      'title': 'Library Notice',
                      'message': msgController.text.trim(),
                      'timestamp': FieldValue.serverTimestamp(),
                      'isRead': false,
                      'type': 'library_notice',
                    });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Message Sent!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: const Text("SEND", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- LOGIC: SAVES TO DATABASE AND UPDATES BALANCE ---
  Future<void> _processFineUpdate(
    String docId,
    String studentID,
    int amount,
    bool isAdding,
    int currentFine,
  ) async {
    if (amount <= 0) return;
    int newFine = isAdding
        ? (currentFine + amount)
        : (currentFine - amount).clamp(0, 999999);

    await FirebaseFirestore.instance.collection('students').doc(docId).update({
      'libraryFine': newFine,
      'libraryStatus': newFine == 0 ? "Cleared" : "Pending",
    });

    await FirebaseFirestore.instance.collection('library_payments').add({
      'studentID': studentID,
      'amount': amount,
      'type': isAdding ? 'Addition' : 'Deduction',
      'date': FieldValue.serverTimestamp(),
    });
  }

  // 🟢 LOGIC: GENERATE AND DOWNLOAD PDF REPORT
  Future<void> _generatePdfReport(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    int totalFines = 0;

    final tableData = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final int fine =
          int.tryParse(data['libraryFine']?.toString() ?? '0') ?? 0;
      totalFines += fine;

      return [
        data['fullName']?.toString() ?? 'Unknown',
        data['studentID']?.toString() ?? '-',
        data['course']?.toString().toUpperCase() ?? '-',
        fine.toString(),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Library Fines Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown800,
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
            pw.SizedBox(height: 10),

            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        "Total Outstanding Fines",
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Rs. $totalFines",
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              "Student Breakdown",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              headers: ['Student Name', 'ID', 'Course', 'Pending Fine (Rs)'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
              },
              data: tableData,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Library_Fines_$dateStr.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBrown,
      appBar: AppBar(
        title: const Text(
          "Library Records",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBrown,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Download PDF Report',
            onPressed: () async {
              try {
                final snap = await FirebaseFirestore.instance
                    .collection('students')
                    .get();
                final filteredDocs = snap.docs.where((doc) {
                  var data = doc.data();
                  bool matchesClass =
                      _selectedClass == "All" ||
                      data['course'].toString().toLowerCase().trim() ==
                          _selectedClass.toLowerCase().trim();
                  return matchesClass;
                }).toList();

                if (filteredDocs.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No students found to generate PDF."),
                      ),
                    );
                  }
                  return;
                }

                _generatePdfReport(filteredDocs);
              } catch (e) {
                debugPrint("Error generating PDF: $e");
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showManagementMenu,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          var docs = snapshot.data!.docs;

          int totalFines = docs.fold(
            0,
            (sumVal, doc) =>
                sumVal +
                (int.tryParse(
                      (doc.data() as Map<String, dynamic>)['libraryFine']
                              ?.toString() ??
                          '0',
                    ) ??
                    0),
          );

          var filteredDocs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            bool matchesClass =
                _selectedClass == "All" ||
                data['course'].toString().toLowerCase().trim() ==
                    _selectedClass.toLowerCase().trim();
            bool matchesSearch =
                data['studentID'].toString().contains(_searchQuery) ||
                data['fullName'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
            return matchesClass && matchesSearch;
          }).toList();

          return Column(
            children: [
              _buildHeaderStats(totalFines, docs.length),
              _buildSearchBar(),
              _buildClassFilter(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: surfaceGrey,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: primaryBrown,
                    child: filteredDocs.isEmpty
                        ? const Center(child: Text("No matching records found"))
                        : ListView.builder(
                            padding: const EdgeInsets.all(25),
                            physics:
                                const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              var data =
                                  filteredDocs[index].data()
                                      as Map<String, dynamic>;
                              return _buildStudentCard(
                                data,
                                filteredDocs[index].id,
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search Name or ID...",
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, String docId) {
    int fine = int.tryParse(student['libraryFine']?.toString() ?? '0') ?? 0;
    bool isCleared = fine == 0;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text("Add Fine"),
                onTap: () {
                  Navigator.pop(context);
                  _showAmountInputDialog(
                    docId,
                    student['fullName'],
                    student['studentID'],
                    true,
                    fine,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text("Deduct Fine"),
                onTap: () {
                  Navigator.pop(context);
                  _showAmountInputDialog(
                    docId,
                    student['fullName'],
                    student['studentID'],
                    false,
                    fine,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text("View History"),
                onTap: () {
                  Navigator.pop(context);
                  _showHistoryDialog(student['studentID'], student['fullName']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.purple),
                title: const Text("Send Message"),
                onTap: () {
                  Navigator.pop(context);
                  _showSendMessageDialog(
                    student['studentID'],
                    student['fullName'],
                  );
                },
              ),
            ],
          ),
        );
      },
      onLongPress: () => _showHistoryDialog(
        student['studentID'] ?? "",
        student['fullName'] ?? "",
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: surfaceGrey,
              child: Text(
                student['fullName']?[0] ?? 'S',
                style: TextStyle(
                  color: primaryBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['fullName'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "ID: ${student['studentID']}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  // --- AUTO-CLEARED STATUS LABEL ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isCleared
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isCleared ? "CLEARED" : "PENDING",
                      style: TextStyle(
                        color: isCleared ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "₹$fine",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats(int total, int count) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              "Total Fines",
              "₹$total",
              Icons.account_balance_wallet_outlined,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _statCard("Active Users", "$count", Icons.people_outline),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white60, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassFilter() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          bool isSel = _selectedClass == _classes[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(_classes[index]),
              selected: isSel,
              onSelected: (val) =>
                  setState(() => _selectedClass = _classes[index]),
              selectedColor: Colors.blueAccent,
            ),
          );
        },
      ),
    );
  }

  void _showAmountInputDialog(
    String docId,
    String name,
    String studentID,
    bool isAdding,
    int currentFine,
  ) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${isAdding ? 'Add' : 'Deduct'} Fine: $name"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: "₹ "),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              _processFineUpdate(
                docId,
                studentID,
                int.tryParse(amountController.text) ?? 0,
                isAdding,
                currentFine,
              );
              Navigator.pop(context);
            },
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }

  // --- UPDATED MANAGEMENT MENU WITH DIRECT LIBRARY PRIZE LINK ---
  void _showManagementMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.library_add, color: Colors.indigo),
            title: const Text("Add Book to Catalog"),
            onTap: () {
              Navigator.pop(context);
              _showAddBookDialog();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.shopping_cart_rounded,
              color: Colors.green,
            ),
            title: const Text("Purchase Requests"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const PurchaseRequestPage(committeeName: 'Library'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_stories, color: Colors.blue),
            title: const Text("Manage Books"),
            onTap: () {
              Navigator.pop(context);
              _showManageBooksDialog();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.video_collection_rounded,
              color: Colors.red,
            ),
            title: const Text("Upload Library Reel"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ReelUploadPage(committeeName: "Library"),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.event_available_rounded,
              color: Colors.teal,
            ),
            title: const Text("Manage Events"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const EventManagementPage(initialCommittee: "Library"),
                ),
              );
            },
          ),
          ListTile(
            // 🟢 Changed Icon to represent "Design"
            leading: const Icon(
              Icons.design_services_rounded,
              color: Colors.orange,
            ),
            title: const Text("PRD Request Desk"),
            onTap: () {
              Navigator.pop(context); // Closes the drawer/menu
              Navigator.push(
                context,
                MaterialPageRoute(
                  // 🟢 THIS IS THE FIX: Passing "Library" automatically!
                  builder: (context) =>
                      const PrdRequestDeskPage(initialCommittee: "Library"),
                ),
              );
            },
          ),

          // --- UPDATED PRIZE LINK WITH GATEKEEPER KEY ---
          ListTile(
            leading: const Icon(
              Icons.stars_rounded,
              color: Color.fromARGB(255, 166, 230, 5),
            ),
            title: const Text("Sub-Committee Prize"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  // THIS LINE IS THE FIX: Passing "Library" opens the Library page directly
                  builder: (context) => const AdminCommitteeDashboard(
                    initialCommittee: "Library",
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickBookImage(StateSetter setDialogState) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes != null) setDialogState(() => _selectedBookBytes = bytes);
  }
}
