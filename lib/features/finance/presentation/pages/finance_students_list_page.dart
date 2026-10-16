import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/finance_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/dues_transaction_dialog.dart';
import '../../data/repositories/finance_repository.dart';

class FinanceStudentsListPage extends StatefulWidget {
  final String filterType; // "all", "paid", "pending"
  final int unionDueAmount;
  final CollectionType collectionType;

  const FinanceStudentsListPage({
    super.key,
    required this.filterType,
    required this.unionDueAmount,
    this.collectionType = CollectionType.union,
  });

  @override
  State<FinanceStudentsListPage> createState() =>
      _FinanceStudentsListPageState();
}

class _FinanceStudentsListPageState extends State<FinanceStudentsListPage> {
  static const int _pageSize = 20;
  static const String _studentSelect =
      'student_id,cic_no,full_name,course,class_name,phone,union_total_paid,union_balance,store_balance,designation,assigned_role';

  final FinanceController _controller = FinanceController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _students = [];
  Timer? _searchDebounce;
  String _searchQuery = "";
  String _selectedClass = "All Courses";
  bool _isAdminVerified = false;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreStudents = true;
  Object? _loadError;
  int _nextStudentIndex = 0;

  static const List<String> _classes = [
    "All Courses",
    "Thamheediyya Ula",
    "Thamheediyya Saniya",
    "Allya Ula",
    "Allya Saniya",
    "Allya Sallsa",
  ];

  String get _pageTitle {
    switch (widget.filterType) {
      case 'paid':
        return 'Paid Students';
      case 'pending':
        return 'Pending Due Students';
      default:
        return 'All Student Dues';
    }
  }

  Color get _themeColor {
    switch (widget.filterType) {
      case 'paid':
        return AppColors.accentTeal;
      case 'pending':
        return AppColors.accentAmber;
      default:
        return AppColors.primaryGreen;
    }
  }

  IconData get _headerIcon {
    switch (widget.filterType) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.pending_actions_rounded;
      default:
        return Icons.groups_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadStudents(reset: true));
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        !_hasMoreStudents ||
        _isInitialLoading) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      unawaited(_loadStudents());
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
      unawaited(_loadStudents(reset: true));
    });
  }

  void _selectClass(String className) {
    if (_selectedClass == className) return;
    setState(() => _selectedClass = className);
    unawaited(_loadStudents(reset: true));
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
    final userEmail = client.auth.currentUser?.email;
    if (userEmail == null || userEmail.trim().isEmpty) {
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

    if (_selectedClass != 'All Courses') {
      query = query.eq('course', _selectedClass);
    }

    final isUnion = widget.collectionType == CollectionType.union;
    if (widget.filterType == 'paid') {
      query = isUnion
          ? query.gt('union_total_paid', 0)
          : query.gt('store_balance', 0);
    } else if (widget.filterType == 'pending') {
      query = isUnion
          ? query.gt('union_balance', 0)
          : query.gt('store_balance', 0);
    }

    if (_searchQuery.isNotEmpty) {
      final exact = _searchQuery.replaceAll(',', ' ').trim();
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
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Filter and compute student data based on filterType
  List<Map<String, dynamic>> _processStudents(
    List<Map<String, dynamic>> rows,
    int activeDueAmount,
  ) {
    final List<Map<String, dynamic>> students = [];

    for (var data in rows) {
      final bool isUnion = widget.collectionType == CollectionType.union;
      final int expected = isUnion
          ? activeDueAmount
          : _asInt(data['store_total_added'] ?? data['storeTotalAdded']);
      final int paid = isUnion
          ? _studentUnionPaid(data)
          : _asInt(data['store_total_added'] ?? data['storeTotalAdded']) -
                _asInt(data['store_balance'] ?? data['storeBalance']);
      final int balance = isUnion
          ? _studentUnionBalance(data, activeDueAmount)
          : (expected - paid).clamp(0, expected).toInt();

      String status;
      Color statusColor;

      if (paid == 0) {
        status = "Pending";
        statusColor = AppColors.alertRed;
      } else if (paid >= expected) {
        status = "Paid";
        statusColor = AppColors.accentTeal;
      } else {
        status = "Partial";
        statusColor = AppColors.accentAmber;
      }

      students.add({
        'docId': _studentDocId(data),
        'data': data,
        'paid': paid,
        'expected': expected,
        'balance': balance,
        'status': status,
        'statusColor': statusColor,
      });
    }

    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _controller.unionSettingsStream,
        builder: (context, settingsSnapshot) {
          int activeDueAmount = widget.unionDueAmount;
          if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
            final settingsData =
                settingsSnapshot.data!.data() as Map<String, dynamic>;
            activeDueAmount =
                settingsData['unionDueAmount'] ?? widget.unionDueAmount;
          }

          final students = _processStudents(_students, activeDueAmount);

          int totalAmount = 0;
          int totalPaid = 0;
          int totalBalance = 0;
          for (var s in students) {
            totalAmount += s['expected'] as int;
            totalPaid += s['paid'] as int;
            totalBalance += s['balance'] as int;
          }

          if (_isInitialLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_loadError != null && students.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.alertRed,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Could not load students: $_loadError",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshStudents,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshStudents,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _themeColor,
                            _themeColor.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _headerIcon,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${students.length} Students',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.filterType == 'paid'
                                          ? 'Total Collected: ₹$totalPaid'
                                          : widget.filterType == 'pending'
                                          ? 'Total Pending: ₹$totalBalance'
                                          : 'Total Expected: ₹$totalAmount',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    _pageTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search by student name...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _themeColor,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged("");
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Course Filter Chips
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 56,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      scrollDirection: Axis.horizontal,
                      itemCount: _classes.length,
                      itemBuilder: (context, index) {
                        final className = _classes[index];
                        final isSelected = className == _selectedClass;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              className,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) => _selectClass(className),
                            selectedColor: _themeColor,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? _themeColor
                                    : Colors.grey.shade200,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Student Count Label
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                    child: Row(
                      children: [
                        Text(
                          '${students.length} results',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.filterType.toUpperCase(),
                            style: TextStyle(
                              color: _themeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Student List
                if (students.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 72,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No students found',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Import students from sheet or add manually',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildStudentCard(students[index]),
                        childCount: students.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildLoadMoreFooter()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
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

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final data = student['data'] as Map<String, dynamic>;
    final int paid = student['paid'];
    final int expected = student['expected'];
    final int balance = student['balance'];
    final String status = student['status'];
    final Color statusColor = student['statusColor'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDialog(
          student['docId'],
          _studentName(data),
          _studentId(data),
          expected,
        ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Text(
                      _studentName(data).isEmpty
                          ? "?"
                          : _studentName(data)[0].toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _studentName(data),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _studentCourse(data).toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              // Metrics Row
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricColumn('Due', '₹$expected', const Color(0xFF64748B)),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade200,
                    ),
                    _metricColumn('Paid', '₹$paid', Colors.green),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade200,
                    ),
                    _metricColumn(
                      'Balance',
                      '₹$balance',
                      balance > 0 ? Colors.redAccent : Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
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
        type: widget.collectionType,
        onSubmit: (amt, addDebt) {
          if (widget.collectionType == CollectionType.union) {
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
          if (widget.collectionType == CollectionType.union) {
            await _clearSupabaseUnionBalance(sid);
          } else {
            await _clearSupabaseStoreBalance(sid);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Balance cleared to ₹0'),
                backgroundColor: Colors.green,
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
          .select('union_total_paid')
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
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update Union Fund: $e'),
          backgroundColor: Colors.redAccent,
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
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update Store Fund: $e'),
          backgroundColor: Colors.redAccent,
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

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
