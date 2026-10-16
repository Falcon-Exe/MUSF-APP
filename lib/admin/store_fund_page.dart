import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

// Imports for navigation
import 'event_management_page.dart';
import '../features/prd/presentation/pages/prd_request_desk_page.dart';
import 'reel_upload_page.dart';
import 'store_item_page.dart';
import 'admin_committee_prize.dart';
import 'purchase_request_page.dart';

class StoreFundPage extends StatefulWidget {
  final VoidCallback? onBack; // 🟢 Add this
  const StoreFundPage({super.key, this.onBack});

  @override
  State<StoreFundPage> createState() => _StoreFundPageState();
}

class _StoreFundPageState extends State<StoreFundPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = ""; // 🟢 Add this

  String _selectedClass = "All Courses";
  final List<String> _classes = [
    "All Courses",
    "Thamheediyya Ula",
    "Thamheediyya Saniya",
    "Aliya Ula",
    "Aliya Saniya",
    "Aliya Salisa",
  ];

  // 🟢 LOGIC: "Add" increases both balances. "Deduct" only decreases live balance.
  // 🟢 FIX: Added `studentID` parameter to save the transaction history
  Future<void> _updateBalance(
    String docId,
    String studentID,
    int amount,
    bool isAddingDebt,
  ) async {
    try {
      if (isAddingDebt) {
        await FirebaseFirestore.instance.collection('students').doc(docId).set({
          'storeBalance': FieldValue.increment(amount),
          'storeTotalAdded': FieldValue.increment(amount),
        }, SetOptions(merge: true));
      } else {
        await FirebaseFirestore.instance.collection('students').doc(docId).set({
          'storeBalance': FieldValue.increment(-amount),
        }, SetOptions(merge: true));
      }

      // 🟢 CRITICAL FIX: Save the log so the student history works!
      if (studentID.isNotEmpty) {
        await FirebaseFirestore.instance.collection('store_payments').add({
          'studentID': studentID.trim(),
          'amount': amount,
          'type': isAddingDebt ? 'Debt Added' : 'Payment Collected',
          'date': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAddingDebt ? "Added ₹$amount to Due" : "Collected ₹$amount",
            ),
            backgroundColor: isAddingDebt ? Colors.redAccent : Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating balance: $e");
    }
  }

  // 🔴 LOGIC: Completely Reset/Delete the Record
  Future<void> _deleteRecord(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('students').doc(docId).update(
        {
          'storeBalance': FieldValue.delete(),
          'storeTotalAdded': FieldValue.delete(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Store record cleared successfully!"),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting record: $e");
    }
  }

  // 🟢 POPUP DIALOG (Now accepts studentID)
  void _showTransactionDialog(
    String docId,
    String studentName,
    String studentID,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Store Transaction",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // 🔴 DELETE BUTTON AT THE TOP RIGHT
            IconButton(
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
              ),
              tooltip: "Clear Record",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Clear Record?"),
                    content: const Text(
                      "Are you sure you want to completely reset this student's store balance to ₹0?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _deleteRecord(docId);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Yes, Clear",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Student: $studentName",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              int amt = int.tryParse(controller.text) ?? 0;
              if (amt > 0) {
                // 🟢 Pass studentID here
                _updateBalance(docId, studentID, amt, false);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.remove, size: 16, color: Colors.white),
            label: const Text("Collect", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          ElevatedButton.icon(
            onPressed: () {
              int amt = int.tryParse(controller.text) ?? 0;
              if (amt > 0) {
                // 🟢 Pass studentID here
                _updateBalance(docId, studentID, amt, true);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text("Add Due", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_rounded, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Text(
                    "Store Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildDrawerItem(
            icon: Icons.inventory_2_rounded,
            title: "Store Items",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StoreItemPage()),
              );
            },
          ),

          const Divider(color: Colors.white10),

          _buildDrawerItem(
            icon: Icons.event_note_rounded,
            title: "Event Management",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const EventManagementPage(initialCommittee: "Store"),
                ),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.stars_rounded,
            title: "Sub-Committee Prizes",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminCommitteeDashboard(initialCommittee: "Store"),
                ),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.campaign_rounded,
            title: "PRD Admin",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const PrdRequestDeskPage(initialCommittee: "Store"),
                ),
              );
            },
          ),

          _buildDrawerItem(
            icon: Icons.video_library_rounded,
            title: "Reel Upload",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ReelUploadPage(committeeName: "Store"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildSideDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Collection Ledger"),
        backgroundColor: const Color(0xFF607D8B),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
            tooltip: 'Purchase Requests',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const PurchaseRequestPage(committeeName: 'Store'),
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            tooltip: 'Download PDF Report',
            onPressed: () => _generatePdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF607D8B)),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          int overallTotalAdded = 0;
          int classTotalAdded = 0;
          int classLiveBalance = 0;

          List<DocumentSnapshot> filteredDocs = [];

          for (var doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            int added = data['storeTotalAdded'] ?? 0;
            int bal = data['storeBalance'] ?? 0;
            String course = (data['course'] ?? '').toString().toLowerCase();

            // 🟢 SEARCH LOGIC
            String name = (data['fullName'] ?? '').toString().toLowerCase();
            bool matchesSearch = name.contains(_searchQuery.toLowerCase());

            overallTotalAdded += added;

            if ((_selectedClass == "All Courses" ||
                    course == _selectedClass.toLowerCase()) &&
                matchesSearch) {
              filteredDocs.add(doc);

              classTotalAdded += added;
              classLiveBalance += bal;
            }
          }

          return Column(
            children: [
              // 🟢 3-BALANCE PREMIUM HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
                decoration: const BoxDecoration(
                  color: Color(0xFF607D8B),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "OVERALL TOTAL COLLECTION",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹ $overallTotalAdded",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              "CLASS COLLECTION",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 9,
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹ $classTotalAdded",
                              style: const TextStyle(
                                color: Color(0xFF69F0AE),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.white24),
                        Column(
                          children: [
                            Text(
                              "CLASS LIVE BALANCE",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 9,
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹ $classLiveBalance",
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 🟢 SEARCH BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search by student name...",
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF607D8B),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              // CLASS SELECTOR CHIPS
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(vertical: 15),
                color: Colors.transparent,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _classes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final className = _classes[index];
                    final isSelected = className == _selectedClass;
                    return ChoiceChip(
                      label: Text(className),
                      selected: isSelected,
                      onSelected: (val) =>
                          setState(() => _selectedClass = className),
                      selectedColor: const Color(0xFF607D8B),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  },
                ),
              ),

              // STUDENTS LIST
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Text(
                          "No students found",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                        itemCount: filteredDocs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final data =
                              filteredDocs[index].data()
                                  as Map<String, dynamic>;
                          final String docId = filteredDocs[index].id;

                          // 🟢 FIX: Extract studentID from the data map
                          final String studentID =
                              data['studentID']?.toString() ?? "";

                          final String name =
                              data['fullName'] ?? "Unknown Student";
                          final String courseLabel = data['course'] != null
                              ? data['course'].toString().toUpperCase()
                              : "";

                          final int balance = data['storeBalance'] ?? 0;
                          bool isCleared = balance <= 0;

                          return InkWell(
                            // 🟢 Pass studentID to the dialog
                            onTap: () =>
                                _showTransactionDialog(docId, name, studentID),
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
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // 1. AVATAR
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : "?",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF607D8B),
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // 2. NAME, COURSE & STATUS BADGE
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        if (courseLabel.isNotEmpty)
                                          Text(
                                            courseLabel,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        const SizedBox(height: 6),

                                        // CLEARED / DUE BADGE
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isCleared
                                                ? Colors.green.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.red.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            isCleared ? "CLEARED" : "DUE",
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                              color: isCleared
                                                  ? Colors.green
                                                  : Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 3. LARGE AMOUNT
                                  Text(
                                    "₹$balance",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isCleared
                                          ? Colors.grey.shade400
                                          : Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── PDF GENERATION ───────────────────────────────────────────────────────────
Future<void> _generatePdf(BuildContext context) async {
  final snap = await FirebaseFirestore.instance.collection('students').get();
  final docs = snap.docs;

  final pdf = pw.Document();
  final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

  final rows = <List<String>>[
    [
      '#',
      'Name',
      'Student ID',
      'Course',
      'Total Added (₹)',
      'Balance (₹)',
      'Status',
    ],
  ];

  int idx = 1;
  for (var doc in docs) {
    final data = doc.data();
    final name = data['fullName']?.toString() ?? '-';
    final sid = data['studentID']?.toString() ?? '-';
    final course = data['course']?.toString() ?? '-';
    final totalAdded = data['storeTotalAdded']?.toString() ?? '0';
    final balance = data['storeBalance']?.toString() ?? '0';
    final status = (int.tryParse(balance) ?? 0) <= 0 ? 'CLEARED' : 'DUE';
    rows.add([idx.toString(), name, sid, course, totalAdded, balance, status]);
    idx++;
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context ctx) => [
        pw.Text(
          'Store Collection Report',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Generated: $now', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: rows.first,
          data: rows.sublist(1),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey700,
          ),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          headerAlignment: pw.Alignment.center,
          cellAlignment: pw.Alignment.center,
        ),
      ],
    ),
  );

  if (!context.mounted) return;
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
