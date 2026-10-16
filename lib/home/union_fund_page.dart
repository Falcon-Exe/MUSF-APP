import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_notification_badge.dart';
import '../core/theme/app_colors.dart';

class UnionFundPage extends StatelessWidget {
  final String studentID;

  const UnionFundPage({super.key, required this.studentID});

  static const String _studentSelect =
      'student_id,cic_no,full_name,course,class_name,union_total_paid,union_balance,store_balance,store_total_added,prd_print_balance,prd_print_total_added,library_fine,auth_email';

  // Helper to handle nulls and data types safely
  double _safeNum(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Future<Map<String, dynamic>?> _fetchStudent() async {
    final client = Supabase.instance.client;
    var query = client.from('students').select(_studentSelect);
    if (studentID.trim().isNotEmpty) {
      return query.eq('student_id', studentID.trim()).maybeSingle();
    }

    final email = client.auth.currentUser?.email;
    if (email == null || email.trim().isEmpty) return null;
    return client
        .from('students')
        .select(_studentSelect)
        .eq('auth_email', email.trim().toLowerCase())
        .maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text(
          "My Fees & Fines",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        backgroundColor: AppColors.darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: const [
          StudentNotificationBadge(
            committeeName: "Union Fund",
            themeColor: AppColors.accentTeal,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchStudent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.darkNavy),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _buildErrorState(studentID);
          }

          final data = snapshot.data!;

          final String studentId =
              (data['student_id'] ?? data['cic_no'] ?? studentID).toString();
          final String name = data['full_name'] ?? "Student";
          final String course = data['course'] ?? data['class_name'] ?? "N/A";

          double unionPaid = _safeNum(data['union_total_paid']);
          double unionDue = data['union_balance'] == null
              ? (1000 - unionPaid).clamp(0, 1000).toDouble()
              : _safeNum(data['union_balance']);
          double storeDue = _safeNum(data['store_balance']);
          double storePaid =
              _safeNum(data['store_total_added']) -
              _safeNum(data['store_balance']);
          double prdDue = _safeNum(data['prd_print_balance']);
          double prdPaid =
              _safeNum(data['prd_print_total_added']) -
              _safeNum(data['prd_print_balance']);
          double libFine = _safeNum(data['library_fine']);

          double totalOutstanding = unionDue + storeDue + prdDue + libFine;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(name, studentId, course),
                _buildTotalOutstandingCard(totalOutstanding),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      _buildCircularFineCard(
                        "Union Fund",
                        unionDue,
                        unionPaid,
                        AppColors.accentTeal,
                      ),
                      _buildCircularFineCard(
                        "Store Fund",
                        storeDue,
                        storePaid,
                        AppColors.primaryGreen,
                      ),
                      _buildCircularFineCard(
                        "PRD Fund",
                        prdDue,
                        prdPaid,
                        AppColors.accentPurple,
                      ),
                      _buildLibraryCard(libFine),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Upcoming History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      Icon(
                        Icons.history_toggle_off_rounded,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),

                // The Combined Chronological History List
                _buildUpcomingHistoryList(data),

                const SizedBox(height: 35),
              ],
            ),
          );
        },
      ),
    );
  }

  // Master Transaction List: Merges Union, Store, and PRD manually
  Widget _buildUpcomingHistoryList(Map<String, dynamic> data) {
    List<Map<String, dynamic>> dues = [];

    double unionPaid = _safeNum(data['union_total_paid']);
    double unionDue = data['union_balance'] == null
        ? (1000 - unionPaid).clamp(0, 1000).toDouble()
        : _safeNum(data['union_balance']);
    double storeDue = _safeNum(data['store_balance']);
    double prdDue = _safeNum(data['prd_print_balance']);
    double libFine = _safeNum(data['library_fine']);

    if (unionDue > 0) {
      dues.add({
        'title': 'Union Fund Due',
        'type': 'UNION',
        'amount': unionDue,
        'color': AppColors.accentTeal,
        'icon': Icons.account_balance_wallet_rounded,
      });
    }
    if (storeDue > 0) {
      dues.add({
        'title': 'Store Debt/Credit',
        'type': 'STORE',
        'amount': storeDue,
        'color': AppColors.textMuted,
        'icon': Icons.storefront_rounded,
      });
    }
    if (prdDue > 0) {
      dues.add({
        'title': 'PRD Print Due',
        'type': 'PRD',
        'amount': prdDue,
        'color': Colors.redAccent,
        'icon': Icons.print_rounded,
      });
    }
    if (libFine > 0) {
      dues.add({
        'title': 'Library Fine',
        'type': 'LIBRARY',
        'amount': libFine,
        'color': Colors.brown,
        'icon': Icons.menu_book_rounded,
      });
    }

    if (dues.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            "No upcoming dues. You are all cleared!",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dues.length,
      itemBuilder: (context, index) {
        final item = dues[index];
        final Color color = item['color'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(item['icon'], color: color, size: 20),
            ),
            title: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              "Pending Payment",
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            trailing: Text(
              "₹${(item['amount'] as double).toInt()}",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- UI HELPER COMPONENTS ---

  Widget _buildTotalOutstandingCard(double amount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: amount > 0
            ? Colors.redAccent.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: amount > 0
              ? Colors.redAccent.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TOTAL OUTSTANDING",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                "₹${amount.toInt()}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: amount > 0 ? Colors.redAccent : Colors.green,
                ),
              ),
            ],
          ),
          Icon(
            amount > 0
                ? Icons.warning_amber_rounded
                : Icons.verified_user_rounded,
            color: amount > 0 ? Colors.redAccent : Colors.green,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String id, String course) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 15),
      decoration: const BoxDecoration(
        color: Color(0xFF08233E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: const TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "STUDENT ID: $id | ${course.toUpperCase()}",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard(double fine) {
    bool isCleared = fine <= 0;
    return Container(
      width: 180,
      margin: const EdgeInsets.only(left: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const Text(
            "LIBRARY FINE",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.brown,
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 20),
          Icon(
            isCleared
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            size: 50,
            color: isCleared ? Colors.green : Colors.brown,
          ),
          const SizedBox(height: 15),
          Text(
            isCleared ? "CLEARED" : "₹${fine.toInt()}",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isCleared ? Colors.green : Colors.brown,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Updated in real-time",
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularFineCard(
    String title,
    double due,
    double paid,
    Color color,
  ) {
    double total = (due + paid);
    double progress = (total <= 0) ? 1.0 : (paid / total);
    bool isCleared = due <= 0;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(left: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 20),
          if (isCleared) ...[
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 50,
              color: Colors.green,
            ),
            const SizedBox(height: 15),
            const Text(
              "CLEARED",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Updated in real-time",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ] else ...[
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "DUE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      "₹${due.toInt()}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF08233E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Paid: ₹${paid.toInt()}",
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String id) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            "Record for ID $id not found.",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const Text(
            "Import students from sheet or add manually",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
