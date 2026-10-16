import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../features/prd/presentation/widgets/prd_task_card.dart';
import '../features/prd/data/repositories/supabase_prd_repository.dart';

class RequestHistoryPage extends StatefulWidget {
  final String committeeName;
  const RequestHistoryPage({super.key, required this.committeeName});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text("${widget.committeeName} History", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: "PRD Requests", icon: Icon(Icons.design_services_rounded)),
            Tab(text: "Fund Requests", icon: Icon(Icons.currency_rupee_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPrdHistory(),
          _buildFundHistory(),
        ],
      ),
    );
  }

  Widget _buildPrdHistory() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabasePrdRepository().getTasks(committee: widget.committeeName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) return _buildEmptyState("No PRD history found.");

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index];
            return PrdTaskCard(data: data, docId: data['id']?.toString() ?? '');
          },
        );
      },
    );
  }

  Widget _buildFundHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('purchase_requests')
          .where('committeeName', isEqualTo: widget.committeeName)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState("No fund request history found.");

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildFundCard(data);
          },
        );
      },
    );
  }

  Widget _buildFundCard(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'pending') as String;
    final amount = data['amount'] ?? data['estimatedCost'] ?? 0;
    final createdAt = (data['createdAt'] ?? data['submittedAt']) as Timestamp?;
    final dateStr = createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt.toDate()) : '...';
    
    Color statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(data['itemName'] ?? 'Purchase Request', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(data['reason'] ?? data['description'] ?? 'No reason provided', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(dateStr, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("₹$amount", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }
}
