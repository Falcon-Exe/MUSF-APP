// lib/features/finance/presentation/pages/finance_collection_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/finance_repository.dart';
import '../../logic/finance_controller.dart';
import '../widgets/dues_transaction_dialog.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';
import '../../../../core/widgets/admin_shared_components.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../admin/purchase_request_page.dart';
import '../../../../admin/treasurer_inbox_page.dart';
import '../../../../features/prd/presentation/pages/prd_request_desk_page.dart';
import 'finance_students_list_page.dart';

class FinanceCollectionPage extends StatefulWidget {
  final CollectionType type;

  const FinanceCollectionPage({super.key, required this.type});

  @override
  State<FinanceCollectionPage> createState() => _FinanceCollectionPageState();
}

class _FinanceCollectionPageState extends State<FinanceCollectionPage> {
  static const int _pageSize = 20;
  static const String _studentSelect =
      'student_id,cic_no,full_name,course,class_name,phone,union_total_paid,union_balance,store_balance,designation,assigned_role';

  final FinanceController _controller = FinanceController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _studentListController = ScrollController();
  final List<Map<String, dynamic>> _students = [];
  Timer? _searchDebounce;
  bool _isAdminVerified = false;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreStudents = true;
  Object? _loadError;
  int _nextStudentIndex = 0;

  final List<String> _classes = [
    "All Courses",
    "Thamheediyya Ula",
    "Thamheediyya Saniya",
    "Allya Ula",
    "Allya Saniya",
    "Allya Sallsa",
  ];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _studentListController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get isUnion => widget.type == CollectionType.union;
  String get committeeName => isUnion ? "Treasurer" : "Store";
  String get displayTitle =>
      isUnion ? "Treasurer Management" : "Store Management";
  String get subtitle => isUnion ? "Union Fund Control" : "Collection Ledger";

  @override
  void initState() {
    super.initState();
    _studentListController.addListener(_onStudentListScroll);
    unawaited(_loadStudents(reset: true));
  }

  void _onStudentListScroll() {
    if (!_studentListController.hasClients ||
        _isLoadingMore ||
        !_hasMoreStudents ||
        _isInitialLoading) {
      return;
    }
    final position = _studentListController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      unawaited(_loadStudents());
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _controller.updateSearch(value.trim());
      unawaited(_loadStudents(reset: true));
    });
  }

  Future<void> _loadStudents({bool reset = false}) async {
    if (_isLoadingMore) return;
    if (reset) {
      setState(() {
        _students.clear();
        _nextStudentIndex = 0;
        _hasMoreStudents = true;
        _isInitialLoading = true;
        _isLoadingMore = true;
        _loadError = null;
      });
    } else {
      if (!_hasMoreStudents) return;
      setState(() {
        _isLoadingMore = true;
        _loadError = null;
      });
    }

    try {
      await _ensureSupabaseAdmin();
      final start = reset ? 0 : _nextStudentIndex;
      final end = start + _pageSize - 1;
      final rows = await _fetchStudentPage(start: start, end: end);
      if (!mounted) return;
      setState(() {
        _students.addAll(rows);
        _nextStudentIndex = start + rows.length;
        _hasMoreStudents = rows.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshStudents() => _loadStudents(reset: true);

  Future<void> _ensureSupabaseAdmin() async {
    if (_isAdminVerified) return;
    final client = Supabase.instance.client;
    final userEmail = client.auth.currentUser?.email?.trim().toLowerCase();
    if (userEmail == null || userEmail.isEmpty) {
      throw Exception('User is not authenticated.');
    }

    final studentData = await _fetchCurrentSupabaseStudent(client, userEmail);

    if (!_isSupabaseAdmin(studentData)) {
      throw Exception('Access denied. Administrator privileges required.');
    }
    _isAdminVerified = true;
  }

  Future<List<Map<String, dynamic>>> _fetchStudentPage({
    required int start,
    required int end,
  }) async {
    final client = Supabase.instance.client;
    var query = client.from('students').select(_studentSelect);
    final selectedClass = _controller.selectedClass.trim();
    if (selectedClass.isNotEmpty &&
        selectedClass != 'All' &&
        selectedClass != 'All Courses') {
      query = query.eq('course', selectedClass);
    }
    final search = _controller.searchQuery.trim();
    if (search.isNotEmpty) {
      final exact = search.replaceAll(',', ' ').trim();
      final fuzzy = '%$exact%';
      query = query.or(
        'full_name.ilike.$fuzzy,student_id.eq.$exact,cic_no.eq.$exact',
      );
    }

    final response = await query.order('full_name').range(start, end);
    return List<Map<String, dynamic>>.from(
      response.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchReportStudents() async {
    await _ensureSupabaseAdmin();
    final response = await Supabase.instance.client
        .from('students')
        .select(_studentSelect)
        .order('course')
        .order('full_name');
    return List<Map<String, dynamic>>.from(
      response.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  Future<Map<String, dynamic>?> _fetchCurrentSupabaseStudent(
    SupabaseClient client,
    String userEmail,
  ) async {
    final authEmailRow = await client
        .from('students')
        .select('role,is_admin')
        .eq('auth_email', userEmail)
        .maybeSingle();
    if (authEmailRow != null) return authEmailRow;

    return client
        .from('students')
        .select('role,is_admin')
        .eq('email', userEmail)
        .maybeSingle();
  }

  bool _isSupabaseAdmin(Map<String, dynamic>? data) {
    if (data == null) return false;
    final role = data['role']?.toString().toLowerCase().trim();
    return role == 'admin' || _asBool(data['is_admin']);
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase().trim() == 'true';
  }

  String _studentDocId(Map<String, dynamic> data) =>
      data['id']?.toString() ?? data['student_id']?.toString() ?? '';

  String _studentName(Map<String, dynamic> data) =>
      (data['full_name'] ?? data['fullName'] ?? 'Unknown').toString();

  String _studentId(Map<String, dynamic> data) =>
      (data['student_id'] ?? data['studentID'] ?? data['cic_no'] ?? '')
          .toString();

  String _studentCourse(Map<String, dynamic> data) =>
      (data['course'] ?? data['class_name'] ?? 'N/A').toString();

  int _studentUnionPaid(Map<String, dynamic> data) =>
      _asInt(data['union_total_paid'] ?? data['unionTotalPaid']);

  int _studentUnionBalance(Map<String, dynamic> data, int dueAmount) {
    final storedBalance = data['union_balance'] ?? data['unionBalance'];
    if (storedBalance != null) return _asInt(storedBalance);
    final balance = dueAmount - _studentUnionPaid(data);
    return balance < 0 ? 0 : balance;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _controller.unionSettingsStream,
      builder: (context, settingsSnapshot) {
        int unionDueAmount = 1000;
        if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
          unionDueAmount =
              (settingsSnapshot.data!.data()
                  as Map<String, dynamic>)['unionDueAmount'] ??
              1000;
        }

        final totals = _calculateLoadedTotals(_students, unionDueAmount);

        return UniversalCommitteeDashboard(
          committeeName: committeeName,
          displayTitle: displayTitle,
          subtitle: subtitle,
          onBack: () => Navigator.pop(context),
          summaryRow: _buildHeaderSummary(
            totals.expected,
            totals.collected,
            totals.pending,
          ),
          searchHint: isUnion
              ? "Search name, ID, CIC..."
              : "Search name, ID, CIC...",
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          customDashboard: _buildDashboardTab(
            totals.expected,
            totals.collected,
            totals.pending,
            isUnion,
            unionDueAmount,
          ),
          extraTabs: [
            CommitteeTabConfig(
              label: "Collections",
              icon: Icons.payments_rounded,
              key: 'collections',
              content: _buildCollectionsTab(
                _students,
                isUnion,
                unionDueAmount,
                isLoading: _isInitialLoading,
                error: _loadError,
              ),
            ),
            CommitteeTabConfig(
              label: "Students",
              icon: Icons.groups_rounded,
              key: 'students',
              content: _buildStudentsTab(
                _students,
                isUnion,
                unionDueAmount,
                isLoading: _isInitialLoading,
                error: _loadError,
              ),
            ),
            CommitteeTabConfig(
              label: "Reports",
              icon: Icons.analytics_rounded,
              key: 'reports',
              content: _buildReportsTab(isUnion, unionDueAmount),
            ),
          ],
        );
      },
    );
  }

  _FinanceLoadedTotals _calculateLoadedTotals(
    List<Map<String, dynamic>> students,
    int unionDueAmount,
  ) {
    int totalExpected = 0;
    int totalCollected = 0;
    int pendingDue = 0;

    for (final data in students) {
      if (isUnion) {
        final paid = _studentUnionPaid(data);
        totalExpected += unionDueAmount;
        totalCollected += paid;
        final balance = unionDueAmount - paid;
        if (balance > 0) pendingDue += balance;
      } else {
        final balance = _asInt(data['store_balance'] ?? data['storeBalance']);
        totalExpected += balance;
        pendingDue += balance;
      }
    }

    return _FinanceLoadedTotals(
      expected: totalExpected,
      collected: totalCollected,
      pending: pendingDue,
    );
  }

  Widget _buildHeaderSummary(int total, int collected, int pending) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _summaryItem("Total Expected", "₹$total"),
          _summaryDivider(),
          _summaryItem("Collected", "₹$collected"),
          _summaryDivider(),
          _summaryItem("Pending", "₹$pending"),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _summaryDivider() {
    return Container(
      height: 25,
      width: 1,
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 15),
    );
  }

  Widget _buildDashboardTab(
    int expected,
    int collected,
    int pending,
    bool isUnion,
    int currentDue,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle(title: "FINANCE OVERVIEW"),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _financeCard(
                  "Total Expected",
                  "₹$expected",
                  Icons.account_balance_wallet_rounded,
                  AppColors.primaryGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FinanceStudentsListPage(
                          filterType: 'all',
                          unionDueAmount: currentDue,
                          collectionType: widget.type,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _financeCard(
                  "Total Collected",
                  "₹$collected",
                  Icons.payments_rounded,
                  AppColors.accentTeal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FinanceStudentsListPage(
                          filterType: 'paid',
                          unionDueAmount: currentDue,
                          collectionType: widget.type,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _financeCard(
            "Pending Due",
            "₹$pending",
            Icons.pending_actions_rounded,
            AppColors.accentAmber,
            isFullWidth: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FinanceStudentsListPage(
                    filterType: 'pending',
                    unionDueAmount: currentDue,
                    collectionType: widget.type,
                  ),
                ),
              );
            },
          ),

          if (isUnion) ...[
            const SizedBox(height: 35),
            const AdminSectionTitle(title: "FUND SETTINGS"),
            const SizedBox(height: 18),
            AdminSupportToolCard(
              icon: Icons.settings_suggest_rounded,
              title: "Set Custom Due Amount",
              subtitle: "Current Default: ₹$currentDue",
              color: AppColors.accentPurple,
              onTap: () => _showSetDueDialog(currentDue),
            ),
          ],

          const SizedBox(height: 35),
          const AdminSectionTitle(title: "COMMITTEE TOOLS"),
          const SizedBox(height: 18),
          AdminSupportToolCard(
            icon: Icons.design_services_rounded,
            title: "PRD Request",
            subtitle: "Submit designs & posters",
            color: AppColors.accentPurple,
            onTap: () {
              final name = widget.type == CollectionType.store
                  ? "Store"
                  : "Treasurer";
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrdRequestDeskPage(initialCommittee: name),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          AdminSupportToolCard(
            icon: Icons.account_balance_wallet_rounded,
            title: isUnion ? "Fund Approval" : "Fund Request",
            subtitle: isUnion
                ? "Approve or reject requests"
                : "Request from Treasurer",
            color: AppColors.accentAmber,
            onTap: () {
              if (isUnion) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TreasurerInboxPage()),
                );
              } else {
                final name = widget.type == CollectionType.store
                    ? "Store"
                    : "Treasurer";
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PurchaseRequestPage(committeeName: name),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showSetDueDialog(int current) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Set Custom Due Amount",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "This will update the expected amount for all students in the Union Fund.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Due Amount (₹)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.currency_rupee_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              int val = int.tryParse(controller.text) ?? current;
              _controller.updateUnionDueAmount(val);
              Navigator.pop(ctx);
            },
            child: const Text("Update Amount"),
          ),
        ],
      ),
    );
  }

  Widget _financeCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AdminDashboardStyles.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AdminDashboardStyles.textPrimary,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AdminDashboardStyles.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsTab(
    List<Map<String, dynamic>> students,
    bool isUnion,
    int dueAmount, {
    bool isLoading = false,
    Object? error,
  }) {
    if (error != null) {
      return Center(child: Text("Could not load records: $error"));
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        _buildClassChips(),
        Expanded(
          child: _buildStudentList(
            students,
            isUnion,
            dueAmount,
            showDetailed: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab(
    List<Map<String, dynamic>> students,
    bool isUnion,
    int dueAmount, {
    bool isLoading = false,
    Object? error,
  }) {
    if (error != null) {
      return Center(child: Text("Could not load students: $error"));
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        _buildClassChips(),
        Expanded(
          child: _buildStudentList(
            students,
            isUnion,
            dueAmount,
            showDetailed: false,
          ),
        ),
      ],
    );
  }

  Widget _buildClassChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final className = _classes[index];
          final isSelected = className == _controller.selectedClass;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(className),
              selected: isSelected,
              onSelected: (val) {
                _controller.setClassFilter(className);
                unawaited(_loadStudents(reset: true));
              },
              selectedColor: AppColors.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentList(
    List<Map<String, dynamic>> students,
    bool isUnion,
    int unionDueAmount, {
    required bool showDetailed,
  }) {
    if (students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshStudents,
        child: ListView(
          padding: const EdgeInsets.all(40),
          children: const [
            SizedBox(height: 80),
            Text(
              "No students found",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Try another course or search term.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshStudents,
      child: ListView.builder(
        controller: _studentListController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: students.length + 1,
        itemBuilder: (context, index) {
          if (index == students.length) {
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (_loadError != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: TextButton.icon(
                  onPressed: () => _loadStudents(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Load more failed. Try again'),
                ),
              );
            }
            return const SizedBox(height: 24);
          }

          final data = students[index];

          int paid = 0;
          int balance = 0;
          int expected = unionDueAmount;
          String status = "Pending";
          Color statusColor = AppColors.accentAmber;

          if (isUnion) {
            paid = _studentUnionPaid(data);
            balance = _studentUnionBalance(data, expected);

            if (paid == 0) {
              status = "Pending";
              statusColor = AppColors.alertRed;
            } else if (paid >= expected) {
              status = "Paid";
              statusColor = AppColors.accentTeal;
            } else {
              status = "Partial";
              statusColor = AppColors.primaryGreen;
            }
          } else {
            balance = _asInt(data['store_balance'] ?? data['storeBalance']);
            int totalAdded = _asInt(
              data['store_total_added'] ?? data['storeTotalAdded'],
            );
            paid = totalAdded - balance;
            expected = totalAdded;
            status = balance == 0 ? "Paid" : "Partial";
            statusColor = balance == 0
                ? AppColors.accentTeal
                : AppColors.accentAmber;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AdminDashboardStyles.borderColor),
            ),
            child: InkWell(
              onTap: () => _showDialog(
                _studentDocId(data),
                _studentName(data),
                _studentId(data),
                unionDueAmount,
              ),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryGreen.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            _studentName(data).isEmpty
                                ? "?"
                                : _studentName(data)[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF39544B),
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
                                _studentName(data),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AdminDashboardStyles.textPrimary,
                                ),
                              ),
                              Text(
                                _studentCourse(data).toUpperCase(),
                                style: const TextStyle(
                                  color: AdminDashboardStyles.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (showDetailed) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(
                          height: 1,
                          color: AdminDashboardStyles.borderColor,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _miniMetric("Expected", "₹$expected"),
                          _miniMetric(
                            "Paid",
                            "₹$paid",
                            color: AppColors.accentTeal,
                          ),
                          _miniMetric(
                            "Balance",
                            "₹$balance",
                            color: balance > 0
                                ? AppColors.alertRed
                                : AppColors.accentTeal,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _miniMetric(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AdminDashboardStyles.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? AdminDashboardStyles.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  void _showDialog(String docId, String name, String sid, int dueAmount) {
    showDialog(
      context: context,
      builder: (ctx) => DuesTransactionDialog(
        studentName: name,
        studentID: sid,
        docId: docId,
        type: widget.type,
        onSubmit: (amt, addDebt) {
          if (isUnion) {
            _updateSupabaseUnionDues(
              studentId: sid,
              amount: amt,
              isAddingDebt: addDebt,
              dueAmount: dueAmount,
            );
          } else {
            _updateSupabaseStoreDues(
              studentID: sid,
              amount: amt,
              isAddingDebt: addDebt,
            );
          }
        },
        onClear: () async {
          if (isUnion) {
            await _clearSupabaseUnionBalance(sid);
          } else {
            await _clearSupabaseStoreBalance(sid);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Balance cleared to ₹0'),
                backgroundColor: AppColors.accentTeal,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _updateSupabaseUnionDues({
    required String studentId,
    required int amount,
    required bool isAddingDebt,
    required int dueAmount,
  }) async {
    if (isAddingDebt || amount <= 0) return;

    try {
      final client = Supabase.instance.client;
      final student = await client
          .from('students')
          .select('union_total_paid, union_balance')
          .eq('student_id', studentId)
          .maybeSingle();

      final currentPaid = _asInt(student?['union_total_paid']);
      final newPaid = currentPaid + amount;
      final newBalance = (dueAmount - newPaid).clamp(0, dueAmount).toInt();

      await client
          .from('students')
          .update({'union_total_paid': newPaid, 'union_balance': newBalance})
          .eq('student_id', studentId);

      await client.from('union_payments').insert({
        'student_id': studentId,
        'amount': amount,
        'type': 'Payment Collected',
        'date': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;
      unawaited(_refreshStudents());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dues updated successfully.'),
          backgroundColor: AppColors.accentTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update Union Fund: $e'),
          backgroundColor: AppColors.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearSupabaseUnionBalance(String studentId) async {
    await Supabase.instance.client
        .from('students')
        .update({'union_total_paid': 0, 'union_balance': 0})
        .eq('student_id', studentId);
    if (mounted) {
      unawaited(_refreshStudents());
    }
  }

  Future<void> _updateSupabaseStoreDues({
    required String studentID,
    required int amount,
    required bool isAddingDebt,
  }) async {
    if (amount <= 0) return;

    try {
      final client = Supabase.instance.client;
      final student = await client
          .from('students')
          .select('store_balance, store_total_added')
          .eq('student_id', studentID)
          .maybeSingle();

      final currentBalance = _asInt(student?['store_balance']);
      final currentTotal = _asInt(student?['store_total_added']);
      final newBalance = isAddingDebt
          ? currentBalance + amount
          : (currentBalance - amount).clamp(0, currentBalance).toInt();
      final newTotal = isAddingDebt ? currentTotal + amount : currentTotal;

      await client
          .from('students')
          .update({'store_balance': newBalance, 'store_total_added': newTotal})
          .eq('student_id', studentID);

      await client.from('store_payments').insert({
        'student_id': studentID,
        'amount': amount,
        'type': isAddingDebt ? 'Debt Added' : 'Payment Collected',
        'date': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;
      unawaited(_refreshStudents());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dues updated successfully.'),
          backgroundColor: AppColors.accentTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update Store Fund: $e'),
          backgroundColor: AppColors.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearSupabaseStoreBalance(String studentID) async {
    await Supabase.instance.client
        .from('students')
        .update({'store_total_added': 0, 'store_balance': 0})
        .eq('student_id', studentID);
    if (mounted) {
      unawaited(_refreshStudents());
    }
  }

  Widget _buildReportsTab(bool isUnion, int dueAmount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          AdminSupportToolCard(
            icon: Icons.picture_as_pdf_rounded,
            title: "Download Full Report PDF",
            subtitle: "Complete student-wise collection report",
            color: AppColors.primaryGreen, // green finance theme
            onTap: () => _withReportStudents(
              (students) =>
                  _downloadCollectionReport(students, isUnion, dueAmount),
            ),
          ),
          const SizedBox(height: 12),
          AdminSupportToolCard(
            icon: Icons.group_rounded,
            title: "Course-wise Summary",
            subtitle: "View collection by course",
            color: AppColors.primaryGreen,
            onTap: () => _withReportStudents(
              (students) => _showClassSummary(students, isUnion, dueAmount),
            ),
          ),
          const SizedBox(height: 12),
          AdminSupportToolCard(
            icon: Icons.pending_actions_rounded,
            title: "Pending Due Report",
            subtitle: "Students who still need to pay",
            color: AppColors.primaryGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FinanceStudentsListPage(
                  filterType: 'pending',
                  unionDueAmount: dueAmount,
                  collectionType: widget.type,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AdminSupportToolCard(
            icon: Icons.check_circle_rounded,
            title: "Paid Students Report",
            subtitle: "Students who completed payment",
            color: AppColors.primaryGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FinanceStudentsListPage(
                  filterType: 'paid',
                  unionDueAmount: dueAmount,
                  collectionType: widget.type,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AdminSupportToolCard(
            icon: Icons.history_rounded,
            title: "Payment History",
            subtitle: "Full transaction records",
            color: AppColors.primaryGreen,
            onTap: () => _showPaymentHistory(isUnion),
          ),
        ],
      ),
    );
  }

  Future<void> _withReportStudents(
    FutureOr<void> Function(List<Map<String, dynamic>> students) action,
  ) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loading report data...')));
      final students = await _fetchReportStudents();
      if (!mounted) return;
      await action(students);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load report data: $e'),
          backgroundColor: AppColors.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadCollectionReport(
    List<Map<String, dynamic>> students,
    bool isUnion,
    int dueAmount,
  ) async {
    final rows = students.map((data) {
      final name = _studentName(data);
      final course = _studentCourse(data);
      final paid = isUnion
          ? _studentUnionPaid(data)
          : _asInt(data['store_total_added'] ?? data['storeTotalAdded']) -
                _asInt(data['store_balance'] ?? data['storeBalance']);
      final expected = isUnion
          ? dueAmount
          : _asInt(data['store_total_added'] ?? data['storeTotalAdded']);
      final balance = isUnion
          ? _studentUnionBalance(data, dueAmount)
          : (expected - paid).clamp(0, expected).toInt();
      return [
        name,
        course,
        expected.toString(),
        paid.toString(),
        balance.toString(),
      ];
    }).toList();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            "$committeeName Collection Report",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ["Name", "Course", "Expected", "Paid", "Balance"],
            data: rows,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  void _showClassSummary(
    List<Map<String, dynamic>> students,
    bool isUnion,
    int dueAmount,
  ) {
    final Map<String, ({int expected, int paid, int balance})> summary = {};

    for (final data in students) {
      final course = _studentCourse(data);
      final paid = isUnion
          ? _studentUnionPaid(data)
          : _asInt(data['store_total_added'] ?? data['storeTotalAdded']) -
                _asInt(data['store_balance'] ?? data['storeBalance']);
      final expected = isUnion
          ? dueAmount
          : _asInt(data['store_total_added'] ?? data['storeTotalAdded']);
      final balance = isUnion
          ? _studentUnionBalance(data, dueAmount)
          : (expected - paid).clamp(0, expected).toInt();
      final current = summary[course] ?? (expected: 0, paid: 0, balance: 0);
      summary[course] = (
        expected: current.expected + expected,
        paid: current.paid + paid,
        balance: current.balance + balance,
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Course-wise Summary"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: summary.entries.map((entry) {
                final totals = entry.value;
                return ListTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Expected: ${totals.expected}  Paid: ${totals.paid}",
                  ),
                  trailing: Text(
                    totals.balance.toString(),
                    style: TextStyle(
                      color: totals.balance > 0
                          ? AppColors.alertRed
                          : AppColors.accentTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showPaymentHistory(bool isUnion) {
    final collection = isUnion ? 'union_payments' : 'store_payments';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Payment History",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(collection)
                    .orderBy('date', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Could not load payment history: ${snapshot.error}",
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("No payment history found."),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final amount = _asInt(data['amount']);
                      final type = (data['type'] ?? 'Payment').toString();
                      final studentID = (data['studentID'] ?? 'N/A').toString();
                      final date = data['date'] is Timestamp
                          ? (data['date'] as Timestamp)
                                .toDate()
                                .toString()
                                .split('.')
                                .first
                          : 'Pending sync';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryGreen.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        title: Text(
                          type,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Student ID: $studentID\n$date"),
                        trailing: Text(
                          amount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _FinanceLoadedTotals {
  final int expected;
  final int collected;
  final int pending;

  const _FinanceLoadedTotals({
    required this.expected,
    required this.collected,
    required this.pending,
  });
}
