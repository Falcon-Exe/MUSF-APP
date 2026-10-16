// lib/features/finance/presentation/pages/purchase_inbox_page.dart

import 'package:flutter/material.dart';
import '../../logic/finance_controller.dart';
import '../widgets/finance_theme.dart';
import '../widgets/purchase_request_card.dart';

class PurchaseInboxPage extends StatefulWidget {
  const PurchaseInboxPage({super.key});

  @override
  State<PurchaseInboxPage> createState() => _PurchaseInboxPageState();
}

class _PurchaseInboxPageState extends State<PurchaseInboxPage> with SingleTickerProviderStateMixin {
  final FinanceController _controller = FinanceController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinanceTheme.background,
      appBar: AppBar(
        title: const Text("Treasurer Inbox", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A), centerTitle: true, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: "ALL"), Tab(text: "PENDING"), Tab(text: "REVIEWED")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList('all'),
          _buildRequestList('pending'),
          _buildRequestList('approved'), // Simplified index setups configs layouts
        ],
      ),
    );
  }

  Widget _buildRequestList(String status) {
    return StreamBuilder(
      stream: _controller.getPurchaseRequests(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) return const Center(child: Text("No requests found", style: TextStyle(color: FinanceTheme.textSub)));

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return PurchaseRequestCard(
              data: doc.data() as Map<String, dynamic>,
              docId: doc.id,
              onApprove: (id) => _controller.approvePurchase(context: context, docId: id),
              onReject: (id) => _controller.rejectPurchase(context: context, docId: id, reason: "Rejected by Treasurer"),
              onDelete: (id) => _controller.deletePurchase(context: context, docId: id),
            );
          },
        );
      },
    );
  }
}
