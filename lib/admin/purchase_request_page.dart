import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/committee_theme.dart';

class PurchaseRequestPage extends StatefulWidget {
  final String committeeName;
  const PurchaseRequestPage({super.key, required this.committeeName});

  @override
  State<PurchaseRequestPage> createState() => _PurchaseRequestPageState();
}

class _PurchaseRequestPageState extends State<PurchaseRequestPage>
    with SingleTickerProviderStateMixin {
  final _itemController = TextEditingController();
  final _descController = TextEditingController();
  final _costController = TextEditingController();
  bool _isSubmitting = false;
  late TabController _tabController;

  Color get _committeeColor {
    return getCommitteeTheme(widget.committeeName).accentColor;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _itemController.dispose();
    _descController.dispose();
    _costController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final item = _itemController.text.trim();
    final desc = _descController.text.trim();
    final costText = _costController.text.trim();

    if (item.isEmpty || costText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in item name and estimated cost'),
          backgroundColor: AppColors.accentAmber,
        ),
      );
      return;
    }

    final cost = int.tryParse(costText);
    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid cost amount'),
          backgroundColor: AppColors.accentAmber,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final docRef = await FirebaseFirestore.instance.collection('purchase_requests').add({
        'committeeName': widget.committeeName,
        'requestTitle': item,
        'reason': desc,
        'amount': cost,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'rejectionReason': null,
        'requestedBy': 'Committee Lead',
      });

      // Notify Treasurer/Admins
      await FirebaseFirestore.instance.collection('notifications').add({
        'studentID': 'admin',
        'title': 'New Fund Request',
        'message': '${widget.committeeName} requested ₹$cost for $item.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'purchase_request',
        'referenceId': docRef.id,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request sent to Treasurer'),
            backgroundColor: AppColors.accentTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.alertRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteRequest(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text(
          'Are you sure you want to delete this purchase request?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('purchase_requests')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request deleted'),
              backgroundColor: AppColors.textMuted,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: AppColors.alertRed,
            ),
          );
        }
      }
    }
  }

  void _showRequestForm() {
    _itemController.clear();
    _descController.clear();
    _costController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _committeeColor.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.shopping_cart_rounded,
                      color: _committeeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Fund Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _committeeColor,
                        ),
                      ),
                      Text(
                        widget.committeeName,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildField(
                _itemController,
                'Request Title (e.g., Office Supplies)',
                Icons.title_rounded,
              ),
              const SizedBox(height: 14),
              _buildField(
                _descController,
                'Description (optional)',
                Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _buildField(
                _costController,
                'Estimated Cost (₹) *',
                Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Sending...' : 'Send to Treasurer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _committeeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: _committeeColor, size: 20),
        filled: true,
        fillColor: AppColors.pageBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _committeeColor, width: 1.5),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.primaryGreen;
      case 'approved':
        return AppColors.accentTeal;
      case 'rejected':
        return AppColors.alertRed;
      default:
        return AppColors.accentAmber;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.task_alt_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  /// Builds the list for a given status filter.
  /// Pass null to show all requests.
  Widget _buildList(String? statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('purchase_requests')
        .where('committeeName', isEqualTo: widget.committeeName);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: _committeeColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: AppColors.alertRed),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];

        // Sort in memory to avoid index issues
        final docs = List.from(allDocs);
        docs.sort((a, b) {
          final aTime = (a.data() as Map)['createdAt'] ?? (a.data() as Map)['submittedAt'] ?? Timestamp.now();
          final bTime = (b.data() as Map)['createdAt'] ?? (b.data() as Map)['submittedAt'] ?? Timestamp.now();
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  statusFilter == 'approved'
                      ? Icons.check_circle_outline_rounded
                      : statusFilter == 'rejected'
                      ? Icons.cancel_outlined
                      : Icons.shopping_bag_outlined,
                  size: 72,
                  color: _committeeColor.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  statusFilter == null
                      ? 'No purchase requests yet'
                      : statusFilter == 'approved'
                      ? 'No approved requests'
                      : statusFilter == 'rejected'
                      ? 'No rejected requests'
                      : 'No pending requests',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (statusFilter == null || statusFilter == 'pending')
                  Text(
                    'Tap + to submit a new request',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: docs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending') as String;
            final cost = data['amount'] ?? data['estimatedCost'] ?? 0;
            final submittedAt = (data['createdAt'] ?? data['submittedAt']) as Timestamp?;
            final reviewedAt = data['reviewedAt'] as Timestamp?;
            final dateStr = submittedAt != null
                ? DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(submittedAt.toDate())
                : 'Pending...';
            final reviewedStr = reviewedAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(reviewedAt.toDate())
                : null;

            final statusColor = _statusColor(status);

            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner (Approved / Rejected)
                  if (status != 'pending')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      color: statusColor.withValues(alpha: 0.12),
                      child: Row(
                        children: [
                          Icon(
                            _statusIcon(status),
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status == 'completed'
                                ? 'Purchased & Completed'
                                : status == 'approved'
                                    ? 'Approved by Treasurer'
                                    : 'Rejected by Treasurer',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          if (reviewedStr != null) ...[
                            const Spacer(),
                            Text(
                              reviewedStr,
                              style: TextStyle(
                                color: statusColor.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Card body
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['requestTitle'] ?? data['itemName'] ?? 'Request',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (status == 'pending')
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentAmber.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.hourglass_top_rounded,
                                          size: 12,
                                          color: AppColors.accentAmber,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'PENDING',
                                          style: TextStyle(
                                            color: AppColors.accentAmber,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.alertRed,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _deleteRequest(docs[index].id),
                                    tooltip: 'Delete Request',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if ((data['reason'] ?? data['description'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            data['reason'] ?? data['description'],
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.currency_rupee,
                              size: 15,
                              color: _committeeColor,
                            ),
                            Text(
                              '$cost',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: _committeeColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Submitted: $dateStr',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                        // Rejection reason
                        if (status == 'rejected' &&
                            (data['rejectionReason'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.alertRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                  color: AppColors.alertRed,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Reason for rejection:',
                                        style: TextStyle(
                                          color: AppColors.alertRed,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        data['rejectionReason'],
                                        style: const TextStyle(
                                          color: AppColors.alertRed,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text(
          'Fund Request',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _committeeColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestForm,
        backgroundColor: _committeeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text(
          'New Request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('pending'),
          _buildList('approved'),
          _buildList('rejected'),
          _buildList('completed'),
        ],
      ),
    );
  }
}
