import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'admin_aero_ledger_page.dart';
import 'treasurer_inbox_page.dart';

class UnionAdminPage extends StatefulWidget {
  final VoidCallback? onBack; // 🟢 Add this
  const UnionAdminPage({super.key, this.onBack});

  @override
  State<UnionAdminPage> createState() => _UnionAdminPageState();
}

class _UnionAdminPageState extends State<UnionAdminPage> {
  final Color primaryDark = const Color(0xFF08233E);
  final Color cardColor = const Color(0xFF153354);
  final Color accentUnion = Colors.tealAccent[400]!;

  String _selectedClass = "All";
  String _searchQuery = "";
  final int yearlyRequirement = 1000;

  final List<String> _classes = [
    "All",
    "Thamheediyya Ula",
    "Thamheediyya Saniya",
    "Aliya Ula",
    "Aliya Saniya",
    "Aliya Salisa",
  ];

  Future<void> _deleteTransaction(
    String transId,
    String studentID,
    int amount,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('union_payments')
          .doc(transId)
          .delete();

      var studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('studentID', isEqualTo: studentID)
          .limit(1)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        var doc = studentQuery.docs.first;
        await doc.reference.update({
          'unionBalance': FieldValue.increment(amount),
          'unionTotalPaid': FieldValue.increment(-amount),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment deleted and balance restored"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  Future<void> _collectFund(
    String docId,
    String studentID,
    int amount,
    int currentDue,
  ) async {
    if (amount <= 0) return;

    if (amount > currentDue) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Maximum allowed: ₹$currentDue"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(docId)
          .update({
            'unionBalance': (currentDue - amount).clamp(0, yearlyRequirement),
            'unionTotalPaid': FieldValue.increment(amount),
          });

      // 🟢 SAVES THE LOG FOR THE STUDENT HISTORY PAGE
      await FirebaseFirestore.instance.collection('union_payments').add({
        'studentID': studentID.toString().trim(),
        'amount': amount,
        'type': 'Collection',
        'date': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Collected ₹$amount from $studentID"),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error collecting: $e");
    }
  }

  void _showHistoryDialog(String studentID, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "History: $name",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('union_payments')
                .where('studentID', isEqualTo: studentID)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No records found."));
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  int amt = (data['amount'] ?? 0);

                  return ListTile(
                    title: Text("Collected: ₹$amt"),
                    subtitle: Text(
                      data['date'] != null
                          ? DateFormat(
                              'dd MMM, hh:mm a',
                            ).format((data['date'] as Timestamp).toDate())
                          : "Pending...",
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        _deleteTransaction(doc.id, studentID, amt);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCollectDialog(
    String docId,
    String name,
    String studentID,
    int currentBalance,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Collect Union Fund",
          style: TextStyle(color: primaryDark, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Student: $name",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              "Current Due: ₹$currentBalance",
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter Amount",
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryDark),
            onPressed: () {
              int amt = int.tryParse(controller.text) ?? 0;
              _collectFund(docId, studentID, amt, currentBalance);
              Navigator.pop(context);
            },
            child: const Text("CONFIRM", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🟢 LOGIC: GENERATE AND DOWNLOAD PDF REPORT
  Future<void> _generatePdfReport(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    int totalDue = 0;
    int totalCollected = 0;

    final tableData = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final int due = ((data['unionBalance'] ?? yearlyRequirement) as num)
          .toInt();
      final int collected = ((data['unionTotalPaid'] ?? 0) as num).toInt();
      totalDue += due;
      totalCollected += collected;

      return [
        data['fullName']?.toString() ?? 'Unknown',
        data['studentID']?.toString() ?? '-',
        data['course']?.toString().toUpperCase() ?? '-',
        due.toString(),
        collected.toString(),
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
                    'Union Fund Ledger',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800,
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
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        "Total Pending",
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Rs. $totalDue",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        "Total Collected",
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Rs. $totalCollected",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
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
              headers: [
                'Student Name',
                'ID',
                'Course',
                'Due (Rs)',
                'Collected (Rs)',
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              data: tableData,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Union_Fund_Ledger_$dateStr.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: const Text(
          "Union Fund Admin",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox_rounded),
            tooltip: 'Purchase Requests Inbox',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TreasurerInboxPage(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            onSelected: (value) {
              if (value == 'ledger') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminAeroLedgerPage(),
                  ),
                );
              } else if (value == 'pdf') {
                _downloadPdfAction();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Download PDF Ledger',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ledger',
                child: Row(
                  children: [
                    Icon(Icons.rocket_launch_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('AeroLedger'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopStats(),
          _buildFilters(),
          Expanded(child: _buildStudentList()),
        ],
      ),
    );
  }

  void _downloadPdfAction() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .get();
      final docs = snap.docs.where((doc) {
        var data = doc.data();
        bool classMatch =
            _selectedClass == "All" ||
            data['course'].toString().toLowerCase() ==
                _selectedClass.toLowerCase();
        return classMatch;
      }).toList();

      if (docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No students found to generate PDF.")),
          );
        }
        return;
      }

      _generatePdfReport(docs);
    } catch (e) {
      debugPrint("Error generating PDF: $e");
    }
  }

  Widget _buildTopStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, snapshot) {
        int totalDue = 0;
        int totalCollected = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            totalDue += ((data['unionBalance'] ?? yearlyRequirement) as num)
                .toInt();
            totalCollected += ((data['unionTotalPaid'] ?? 0) as num).toInt();
          }
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _statCard(
                "Total Pending",
                "₹$totalDue",
                Icons.account_balance_wallet,
              ),
              const SizedBox(width: 15),
              _statCard("Total Collected", "₹$totalCollected", Icons.verified),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Text(
              val,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search student...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: _classes
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _selectedClass == c,
                      onSelected: (s) => setState(() => _selectedClass = c),
                      selectedColor: Colors.tealAccent[700],
                      backgroundColor: cardColor,
                      labelStyle: TextStyle(
                        color: _selectedClass == c
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStudentList() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            bool nameMatch = data['fullName'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            bool classMatch =
                _selectedClass == "All" ||
                data['course'].toString().toLowerCase() ==
                    _selectedClass.toLowerCase();
            return nameMatch && classMatch;
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var data = docs[i].data() as Map<String, dynamic>;
              int due = ((data['unionBalance'] ?? yearlyRequirement) as num)
                  .toInt();
              bool isCleared = due <= 0;
              final String studentID = data['studentID']?.toString() ?? "";

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  onTap: isCleared
                      ? null
                      : () => _showCollectDialog(
                          docs[i].id,
                          data['fullName'],
                          studentID,
                          due,
                        ),
                  onLongPress: () =>
                      _showHistoryDialog(studentID, data['fullName']),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[50],
                    child: Text(
                      data['fullName'][0],
                      style: TextStyle(
                        color: primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    data['fullName'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "ID: $studentID • ${data['course'].toString().toUpperCase()}",
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹$due",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isCleared ? Colors.green : Colors.redAccent,
                        ),
                      ),
                      Text(
                        isCleared ? "CLEARED" : "PENDING",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isCleared ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
