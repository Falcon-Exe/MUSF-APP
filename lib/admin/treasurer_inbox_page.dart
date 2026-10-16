import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TreasurerInboxPage extends StatefulWidget {
  const TreasurerInboxPage({super.key});

  @override
  State<TreasurerInboxPage> createState() => _TreasurerInboxPageState();
}

class _TreasurerInboxPageState extends State<TreasurerInboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _streamFor(String status) {
    final client = Supabase.instance.client;
    if (status == 'all') {
      return client
          .from('purchase_requests')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);
    }
    return client
        .from('purchase_requests')
        .stream(primaryKey: ['id'])
        .eq('status', status)
        .order('created_at', ascending: false);
  }

  Future<void> _markCompleted(String docId) async {
    await Supabase.instance.client
        .from('purchase_requests')
        .update({
          'status': 'completed',
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', docId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Request Marked as Completed'),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _approve(String docId) async {
    final client = Supabase.instance.client;
    final doc = await client
        .from('purchase_requests')
        .select()
        .eq('id', docId)
        .maybeSingle();
    final data = doc ?? {};

    await client
        .from('purchase_requests')
        .update({
          'status': 'approved',
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'rejection_reason': null,
        })
        .eq('id', docId);

    // Notify requester (committee)
    final reqTitle = data['request_title'] ?? data['item_name'] ?? data['requestTitle'] ?? 'Request';
    final reqAmt = data['amount'] ?? data['estimated_cost'] ?? data['estimatedCost'] ?? 0;
    await client.from('notifications').insert({
      'student_id': 'all',
      'title': 'Treasurer Request Approved',
      'message': 'Your request for $reqTitle (₹$reqAmt) was approved.',
      'type': 'purchase_update',
      'reference_id': docId,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Request Approved'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _reject(String docId) async {
    final client = Supabase.instance.client;
    final doc = await client
        .from('purchase_requests')
        .select()
        .eq('id', docId)
        .maybeSingle();
    if (!mounted) return;
    final data = doc ?? {};

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reject Request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason for rejection (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Budget exceeded, not approved',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      await client
          .from('purchase_requests')
          .update({
            'status': 'rejected',
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
            'rejection_reason': reason,
          })
          .eq('id', docId);

      final reqTitle = data['request_title'] ?? data['item_name'] ?? data['requestTitle'] ?? 'Request';
      await client.from('notifications').insert({
        'student_id': 'all',
        'title': 'Treasurer Request Rejected',
        'message': 'Your request for $reqTitle was rejected. Reason: ${reason.isEmpty ? "Not specified" : reason}',
        'type': 'purchase_update',
        'reference_id': docId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Request Rejected'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteRequest(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Request?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this purchase request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client
          .from('purchase_requests')
          .delete()
          .eq('id', docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑️ Request Deleted'),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Color _committeeColor(String name) {
    const colors = {
      'Library': Color(0xFF2196F3),
      'Literary': Color(0xFFFF9800),
      'Fine Arts': Color(0xFF9C27B0),
      'Social Affairs': Color(0xFF4CAF50),
      'Bank': Color(0xFF009688),
      'Research': Color(0xFF3F51B5),
      'PRD': Color(0xFF607D8B),
      'Garden': Color(0xFFE91E63),
      'Medical': Color(0xFFEF4444),
      'Store': Color(0xFF795548),
      'Sports': Color(0xFFFFC107),
    };
    return colors[name] ?? const Color(0xFF08233E);
  }

  DateTime _asDateTime(dynamic val) {
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Widget _buildList(String statusFilter) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _streamFor(statusFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data ?? [];
        
        // Sort in memory
        final docs = List<Map<String, dynamic>>.from(allDocs);
        docs.sort((a, b) {
          final aTime = _asDateTime(a['created_at'] ?? a['createdAt'] ?? a['submitted_at']);
          final bTime = _asDateTime(b['created_at'] ?? b['createdAt'] ?? b['submitted_at']);
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_rounded,
                  size: 72,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  statusFilter == 'all'
                      ? 'No purchase requests'
                      : 'No $statusFilter requests',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index];
            final docId = data['id']?.toString() ?? '';
            final status = data['status'] ?? 'pending';
            final committee = data['committee_name'] ?? data['committeeName'] ?? '';
            final cost = data['amount'] ?? data['estimated_cost'] ?? data['estimatedCost'] ?? 0;
            final submittedAtRaw = data['created_at'] ?? data['createdAt'] ?? data['submitted_at'];
            final dateStr = submittedAtRaw != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(_asDateTime(submittedAtRaw).toLocal())
                : 'Just now';
            final color = _committeeColor(committee);

            return InkWell(
              onLongPress: () => _deleteRequest(docId),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Committee tag header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.group_rounded,
                              size: 13,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            committee.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['requestTitle'] ?? data['itemName'] ?? 'Request',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if ((data['description'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              data['description'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.currency_rupee,
                                      size: 14,
                                      color: color,
                                    ),
                                    Text(
                                      '$cost',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (status == 'pending') ...[
                                // Reject
                                OutlinedButton.icon(
                                  onPressed: () => _reject(docId),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                  ),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(
                                      color: Colors.redAccent,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Approve
                                ElevatedButton.icon(
                                  onPressed: () => _approve(docId),
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Approve',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ] else if (status == 'approved') ...[
                                ElevatedButton.icon(
                                  onPressed: () => _markCompleted(docId),
                                  icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Complete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status == 'completed'
                                        ? Colors.blue.withValues(alpha: 0.1)
                                        : status == 'approved'
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        status == 'completed'
                                            ? Icons.task_alt_rounded
                                            : status == 'approved'
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_rounded,
                                        size: 14,
                                        color: status == 'completed'
                                            ? Colors.blue
                                            : status == 'approved'
                                                ? Colors.green
                                                : Colors.redAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: status == 'completed'
                                              ? Colors.blue
                                              : status == 'approved'
                                                  ? Colors.green
                                                  : Colors.redAccent,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (status == 'rejected' &&
                              (data['rejectionReason'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 13,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      data['rejectionReason'],
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            },
          );
        },
      );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Fund Approval',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF08233E),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'PENDING'),
            Tab(text: 'APPROVED'),
            Tab(text: 'REJECTED'),
            Tab(text: 'COMPLETED'),
            Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('pending'),
          _buildList('approved'),
          _buildList('rejected'),
          _buildList('completed'),
          _buildList('all'),
        ],
      ),
    );
  }
}
