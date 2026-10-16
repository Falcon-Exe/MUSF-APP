import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/home/presentation/pages/home_page.dart';
import 'student_notification_badge.dart';
import '../core/theme/app_colors.dart';

class BankManagementPage extends StatelessWidget {
  final String studentID;
  final String studentName;

  const BankManagementPage({
    super.key,
    required this.studentID,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isSupabaseAdmin(),
      builder: (context, adminSnapshot) {
        final isAdmin = adminSnapshot.data == true;
        return StreamBuilder<QuerySnapshot>(
          stream: isAdmin
              ? FirebaseFirestore.instance.collection('treasury').snapshots()
              : FirebaseFirestore.instance
                    .collection('treasury')
                    .where('studentID', isEqualTo: studentID)
                    .snapshots(),
          builder: (context, snapshot) {
        double income = 0.0;
        double expense = 0.0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            double amount =
                double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
            if (data['type'] == 'income') {
              income += amount;
            } else {
              expense += amount;
            }
          }
        }

            return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      studentID: studentID,
                      studentName: studentName,
                      isAdmin: isAdmin,
                    ),
                  ),
                  (route) => false,
                ),
              ),
              const StudentNotificationBadge(
                committeeName: "Bank",
                themeColor: Colors.white,
              ),
              const SizedBox(width: 8),
            ],
            title: Text(
              isAdmin ? "Global Bank Admin" : "$studentName's Bank",
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: AppColors.darkNavy,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
          body: Column(
            children: [
              _buildBalanceCard(income - expense, income, expense, isAdmin),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Transaction Passbook",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildPassbookList(snapshot)),
            ],
          ),
            );
          },
        );
      },
    );
  }

  Future<bool> _isSupabaseAdmin() async {
    final client = Supabase.instance.client;
    final email = client.auth.currentUser?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;

    final row = await client
        .from('students')
        .select('role,is_admin')
        .eq('auth_email', email)
        .maybeSingle();
    final role = row?['role']?.toString().toLowerCase().trim();
    return role == 'admin' || row?['is_admin'] == true;
  }

  Widget _buildPassbookList(AsyncSnapshot<QuerySnapshot> snap) {
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    var docs = snap.data!.docs;
    if (docs.isEmpty) {
      return const Center(child: Text("No transactions found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var data = docs[index].data() as Map<String, dynamic>;
        bool isInc = data['type'] == 'income';

        Color bgColor = isInc
            ? AppColors.accentTeal.withValues(alpha: 0.12)
            : AppColors.alertRed.withValues(alpha: 0.12);
        Color themeColor = isInc ? AppColors.accentTeal : AppColors.alertRed;

        String dateStr = "Unknown";
        if (data['date'] != null) {
          DateTime dt = (data['date'] as Timestamp).toDate();
          dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: themeColor.withValues(alpha: 0.2),
              child: Icon(
                isInc ? Icons.south_west : Icons.north_east,
                color: themeColor,
                size: 20,
              ),
            ),
            title: Text(
              data['studentName'] ?? "Student",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              dateStr,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            trailing: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${isInc ? '+' : '-'} ₹${data['amount']}",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: themeColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(
    double balance,
    double inc,
    double exp,
    bool isAdmin,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, AppColors.primaryGreen],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.22),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? "TOTAL COLLEGE FUND" : "AVAILABLE SAVINGS",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              "₹ ${balance.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _balanceStat(
                  "Income",
                  inc,
                  Icons.call_received,
                  AppColors.accentTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _balanceStat(
                  "Expense",
                  exp,
                  Icons.call_made,
                  AppColors.accentAmber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceStat(String lab, double val, IconData icon, Color col) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: col, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lab,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "₹${val.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
