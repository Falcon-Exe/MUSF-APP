import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminAeroLedgerPage extends StatefulWidget {
  const AdminAeroLedgerPage({super.key});

  @override
  State<AdminAeroLedgerPage> createState() => _AdminAeroLedgerPageState();
}

class _AdminAeroLedgerPageState extends State<AdminAeroLedgerPage> {
  // Clean Light Theme Colors
  final Color bgLightGray = const Color(0xFFF3F4F6);
  final Color surfaceWhite = const Color(0xFFFFFFFF);
  final Color primaryBlue = const Color(0xFF0066FF);
  final Color incomeGreen = const Color(0xFF34C759);
  final Color expenseRed = const Color(0xFFFF3B30);
  final Color textDarkCharcoal = const Color(0xFF111827);
  final Color textSlateGray = const Color(0xFF6B7280);
  final Color borderLightGray = const Color(0xFFE5E7EB);

  // Mock Data is completely removed

  @override
  void initState() {
    super.initState();
    _checkAndTriggerSummaries();
  }

  Future<void> _checkAndTriggerSummaries() async {
    try {
      final summaryRef = FirebaseFirestore.instance
          .collection('system_status')
          .doc('ledger_summary');
      final summaryDoc = await summaryRef.get();

      final now = DateTime.now();
      bool shouldSendWeekly = false;
      bool shouldSendMonthly = false;

      if (!summaryDoc.exists) {
        // First time initialization - set to past so first run triggers if data exists
        await summaryRef.set({
          'lastWeeklySummary': Timestamp.fromDate(
            now.subtract(const Duration(days: 8)),
          ),
          'lastMonthlySummary': Timestamp.fromDate(
            DateTime(now.year, now.month - 1, 1),
          ),
        });
        return;
      }

      final data = summaryDoc.data()!;
      final lastWeekly = (data['lastWeeklySummary'] as Timestamp).toDate();
      final lastMonthly = (data['lastMonthlySummary'] as Timestamp).toDate();

      // Check Weekly (7 days)
      if (now.difference(lastWeekly).inDays >= 7) {
        shouldSendWeekly = true;
      }

      // Check Monthly (New month)
      if (now.month != lastMonthly.month || now.year != lastMonthly.year) {
        shouldSendMonthly = true;
      }

      if (shouldSendWeekly || shouldSendMonthly) {
        // Determine range
        DateTime startTime;
        String periodName;
        if (shouldSendMonthly) {
          startTime = DateTime(now.year, now.month, 1);
          periodName = "Monthly";
        } else {
          startTime = now.subtract(const Duration(days: 7));
          periodName = "Weekly";
        }

        // 1. Calculate Summary for the range
        final ledgerSnapshot = await FirebaseFirestore.instance
            .collection('aero_ledger')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startTime),
            )
            .get();

        int totalIncome = 0;
        int totalExpense = 0;
        for (var doc in ledgerSnapshot.docs) {
          final d = doc.data();
          final int amt = ((d['amount'] ?? 0) as num).toInt();
          if (d['type'] == 'INCOME') {
            totalIncome += amt;
          } else if (d['type'] == 'EXPENSE') {
            totalExpense += amt;
          }
        }

        // 2. Find Directors
        final directorSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('role', isEqualTo: 'UNION_DIRECTOR')
            .get();

        if (directorSnapshot.docs.isNotEmpty) {
          String title = "$periodName Financial Summary 📊";
          String message =
              "Income: +₹$totalIncome | Expenses: -₹$totalExpense (Net: ₹${totalIncome - totalExpense})";

          for (var directorDoc in directorSnapshot.docs) {
            final directorData = directorDoc.data();
            final studentID = directorData['studentID'];

            if (studentID != null) {
              await FirebaseFirestore.instance.collection('notifications').add({
                'studentID': studentID,
                'title': title,
                'message': message,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }

        // 3. Update status
        Map<String, dynamic> updates = {};
        if (shouldSendWeekly) {
          updates['lastWeeklySummary'] = Timestamp.fromDate(now);
        }
        if (shouldSendMonthly) {
          updates['lastMonthlySummary'] = Timestamp.fromDate(now);
        }
        await summaryRef.update(updates);
      }
    } catch (e) {
      debugPrint("Error checking summaries: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLightGray,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textDarkCharcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              "MUSF Account Book",
              style: TextStyle(
                color: textDarkCharcoal,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "2025-2026",
              style: TextStyle(
                color: textSlateGray,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('aero_ledger')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            int totalIncome = 0;
            int totalExpense = 0;
            List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

            if (snapshot.hasData) {
              docs = snapshot.data!.docs;
              for (var doc in docs) {
                final data = doc.data();
                final int amt = ((data['amount'] ?? 0) as num).toInt();
                if (data['type'] == 'INCOME') {
                  totalIncome += amt;
                } else if (data['type'] == 'EXPENSE') {
                  totalExpense += amt;
                }
              }
            }

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('system_status')
                  .doc('ledger_summary')
                  .snapshots(),
              builder: (context, balanceSnapshot) {
                int openingBalance = 0;
                if (balanceSnapshot.hasData && balanceSnapshot.data!.exists) {
                  final data =
                      balanceSnapshot.data!.data() as Map<String, dynamic>?;
                  openingBalance = ((data?['openingBalance'] ?? 0) as num)
                      .toInt();
                }

                int currentBalance =
                    openingBalance + totalIncome - totalExpense;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBalanceCard(currentBalance),
                            const SizedBox(height: 16),
                            _buildSummaryRow(totalIncome, totalExpense),
                            const SizedBox(height: 32),
                            Text(
                              "Recent Transactions",
                              style: TextStyle(
                                color: textDarkCharcoal,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final data = docs[index].data();
                        return _buildTransactionItem(data, docs[index].id);
                      }, childCount: docs.length),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ), // Padding for FAB
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(),
        backgroundColor: primaryBlue,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showAddEntryDialog() {
    final purposeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedType = 'INCOME';
    String selectedSub = 'MUSF UNION';
    DateTime selectedDate = DateTime.now();

    final List<String> subs = [
      'MUSF UNION',
      'FINE ARTS',
      'LITERARY',
      'STORE BOARD',
      'RESEARCH CELL',
      'GARDEN',
      'BANK',
      'SOCIAL AFFAIRS',
      'IT & PRD',
      'MEDICAL BOARD',
      'LIBRARY',
      'SPORTS',
      'ARTS',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "New Entry",
                style: TextStyle(
                  color: textDarkCharcoal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type Selection
                    RadioGroup<String>(
                      groupValue: selectedType,
                      onChanged: (val) => setState(() => selectedType = val ?? 'INCOME'),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                'Income',
                                style: TextStyle(
                                  color: incomeGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              value: 'INCOME',
                              activeColor: incomeGreen,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                'Expense',
                                style: TextStyle(
                                  color: expenseRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              value: 'EXPENSE',
                              activeColor: expenseRed,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sub-committee Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedSub,
                      decoration: InputDecoration(
                        labelText: "Sub-committee",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: subs
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedSub = val!),
                    ),
                    const SizedBox(height: 16),
                    // Purpose TextField
                    TextField(
                      controller: purposeCtrl,
                      decoration: InputDecoration(
                        labelText: "Purpose (e.g. Rent, Splash Screen)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amount TextField
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Amount (₹)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.currency_rupee),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Picker
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: Text(
                        "Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}",
                        style: TextStyle(
                          color: textDarkCharcoal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(Icons.edit, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: primaryBlue,
                                  onPrimary: Colors.white,
                                  onSurface: textDarkCharcoal,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: textSlateGray)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (purposeCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                      return;
                    }

                    final amount = int.tryParse(amountCtrl.text) ?? 0;
                    if (amount <= 0) return;

                    Navigator.pop(context); // Close dialog early for better UX

                    try {
                      await FirebaseFirestore.instance
                          .collection('aero_ledger')
                          .add({
                            'date': Timestamp.fromDate(selectedDate),
                            'subcommittee': selectedSub,
                            'purpose': purposeCtrl.text.trim().toUpperCase(),
                            'type': selectedType,
                            'amount': amount,
                          });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Entry added successfully!',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: primaryBlue,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint("Error adding entry: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBalanceCard(int currentBalance) {
    return InkWell(
      onLongPress: () => _showUpdateOpeningBalanceDialog(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current Balance",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "₹${NumberFormat('#,##0').format(currentBalance)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateOpeningBalanceDialog() {
    final balanceCtrl = TextEditingController();

    // Fetch current setting first to pre-fill
    FirebaseFirestore.instance
        .collection('system_status')
        .doc('ledger_summary')
        .get()
        .then((doc) {
          if (doc.exists) {
            final currentOpen = (doc.data()?['openingBalance'] ?? 0).toString();
            balanceCtrl.text = currentOpen;
          }
        });

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Update Opening Balance",
            style: TextStyle(
              color: textDarkCharcoal,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: balanceCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Initial Balance (₹)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.currency_rupee),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: textSlateGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final newAmount = int.tryParse(balanceCtrl.text) ?? 0;
                await FirebaseFirestore.instance
                    .collection('system_status')
                    .doc('ledger_summary')
                    .set({
                      'openingBalance': newAmount,
                    }, SetOptions(merge: true));

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                "Update",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(int totalIncome, int totalExpense) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: "Total Income",
            amount: "₹${NumberFormat('#,##0').format(totalIncome)}",
            icon: Icons.arrow_upward_rounded,
            titleColor: textSlateGray,
            amountColor: textDarkCharcoal,
            arrowColor: incomeGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: "Total Expense",
            amount: "₹${NumberFormat('#,##0').format(totalExpense)}",
            icon: Icons.arrow_downward_rounded,
            titleColor: textSlateGray,
            amountColor: textDarkCharcoal,
            arrowColor: expenseRed,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color titleColor,
    required Color amountColor,
    required Color arrowColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: arrowColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: arrowColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx, String docId) {
    final isIncome = tx['type'] == 'INCOME';
    final amountColor = isIncome ? incomeGreen : expenseRed;
    final iconColor = textDarkCharcoal.withValues(alpha: 0.7);

    // Format timestamp safely
    String dateStr = "Unknown Date";
    if (tx['date'] != null) {
      if (tx['date'] is Timestamp) {
        dateStr = DateFormat(
          'dd MMM yyyy',
        ).format((tx['date'] as Timestamp).toDate());
      } else if (tx['date'] is String) {
        dateStr =
            tx['date']; // fallback for older hardcoded mock ones if they sneak in
      }
    }

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: expenseRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (direction) async {
        try {
          await FirebaseFirestore.instance
              .collection('aero_ledger')
              .doc(docId)
              .delete();
        } catch (e) {
          debugPrint("Failed to delete entry: $e");
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderLightGray, width: 1),
        ),
        child: Row(
          children: [
            // Left: Flat circular icon with light background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgLightGray,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome
                    ? Icons.attach_money_rounded
                    : Icons.shopping_bag_outlined,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            // Middle: Purpose and Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['purpose'] ?? 'UNKNOWN',
                    style: TextStyle(
                      color: textDarkCharcoal,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${tx['subcommittee']} • $dateStr",
                    style: TextStyle(
                      color: textSlateGray,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right: Amount
            Text(
              "${isIncome ? '+' : '-'}₹${NumberFormat('#,##0').format(tx['amount'] ?? 0)}",
              style: TextStyle(
                color: amountColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
