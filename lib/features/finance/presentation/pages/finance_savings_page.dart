// lib/features/finance/presentation/pages/finance_savings_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/finance_controller.dart';
import '../widgets/finance_theme.dart';
import '../widgets/savings_student_card.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';
import '../../../../core/widgets/admin_shared_components.dart';
import '../../../../core/theme/app_colors.dart';

class FinanceSavingsPage extends StatefulWidget {
  const FinanceSavingsPage({super.key});

  @override
  State<FinanceSavingsPage> createState() => _FinanceSavingsPageState();
}

class _FinanceSavingsPageState extends State<FinanceSavingsPage> {
  static const int _pageSize = 20;
  static const String _studentSelect =
      'student_id,cic_no,full_name,course,class_name,phone,union_total_paid,union_balance,store_balance';

  final FinanceController _controller = FinanceController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _studentListController = ScrollController();
  final List<Map<String, dynamic>> _students = [];
  Timer? _searchDebounce;
  String _selectedClass = "Thamheediyya Ula";
  String _searchQuery = "";
  bool _isAdminVerified = false;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreStudents = true;
  Object? _loadError;
  int _nextStudentIndex = 0;

  final List<String> _classes = [
    "Thamheediyya Ula",
    "Thamheediyya Saniya",
    "Aliya Ula",
    "Aliya Saniya",
    "Aliya Salisa",
  ];

  @override
  void initState() {
    super.initState();
    _studentListController.addListener(_onStudentListScroll);
    unawaited(_loadStudents(reset: true));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _studentListController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
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
        _isInitialLoading = _students.isEmpty;
        _isLoadingMore = true;
        _hasMoreStudents = true;
        _nextStudentIndex = 0;
        _loadError = null;
        _students.clear();
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
      final mappedRows = rows.map(_savingsCardData).toList();

      if (!mounted) return;
      setState(() {
        _students.addAll(mappedRows);
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

    final adminData = await _fetchCurrentSupabaseStudent(client, userEmail);
    if (!_isSupabaseAdmin(adminData)) {
      throw Exception('Access denied. Administrator privileges required.');
    }
    _isAdminVerified = true;
  }

  Future<List<Map<String, dynamic>>> _fetchStudentPage({
    required int start,
    required int end,
  }) async {
    final client = Supabase.instance.client;
    final search = _searchQuery.trim();
    var query = client
        .from('students')
        .select(_studentSelect)
        .eq('course', _selectedClass);

    if (search.isNotEmpty) {
      final pattern = _searchPattern(search);
      query = query.or(
        'full_name.ilike.$pattern,student_id.ilike.$pattern,cic_no.ilike.$pattern',
      );
    }

    final rows = await query.order('full_name').range(start, end);
    return List<Map<String, dynamic>>.from(
      rows.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchReportStudents() async {
    await _ensureSupabaseAdmin();
    final rows = await Supabase.instance.client
        .from('students')
        .select(_studentSelect)
        .order('course')
        .order('full_name');
    return List<Map<String, dynamic>>.from(
      rows.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  String _searchPattern(String value) {
    final safe = value.replaceAll(',', ' ').trim();
    return '%$safe%';
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

  @override
  Widget build(BuildContext context) {
    return UniversalCommitteeDashboard(
      committeeName: "Bank",
      displayTitle: "Bank Management",
      subtitle: "Vault & Savings",
      onBack: () => Navigator.pop(context),
      searchController: _searchController,
      onSearchChanged: _onSearchChanged,
      extraTabs: [
        CommitteeTabConfig(
          label: "Vault",
          icon: Icons.account_balance_rounded,
          key: 'vault',
          content: Column(
            children: [
              _buildVaultHeader(),
              Expanded(child: _buildMainBody()),
            ],
          ),
        ),
        CommitteeTabConfig(
          label: "Reports",
          icon: Icons.analytics_rounded,
          key: 'reports',
          content: _buildReportsTab(),
        ),
      ],
    );
  }

  Widget _buildVaultHeader() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _controller.treasuryStream,
      builder: (context, snapshot) {
        double total = 0;
        if (snapshot.hasData) {
          for (var data in snapshot.data!) {
            double amt = (data['amount'] as num?)?.toDouble() ?? 0;
            if (data['type'] == 'income') {
              total += amt;
            } else {
              total -= amt;
            }
          }
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Vault Balance",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "₹ ${NumberFormat('#,##,###').format(total)}",
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainBody() {
    return Column(
      children: [
        _buildSectionHeader("Course Filter"),
        _buildClassGrid(),
        _buildSectionHeader("Student Accounts ($_selectedClass)"),
        Expanded(child: _buildStudentList()),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: FinanceTheme.textSub,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildClassGrid() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final String currentDep = _classes[index];
          final bool isSelected = _selectedClass == currentDep;
          return GestureDetector(
            onTap: () => _selectClass(currentDep),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 150,
              margin: const EdgeInsets.only(right: 12, bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.school,
                    size: 18,
                    color: FinanceTheme.textSub,
                  ),
                  const Spacer(),
                  Text(
                    currentDep,
                    maxLines: 2,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentList() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _students.isEmpty) {
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

    if (_students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshStudents,
        child: ListView(
          padding: const EdgeInsets.all(40),
          children: const [
            SizedBox(height: 80),
            Icon(
              Icons.account_balance_wallet_outlined,
              color: FinanceTheme.textSub,
              size: 42,
            ),
            SizedBox(height: 12),
            Text(
              "No students found",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "Try another course or search term.",
              textAlign: TextAlign.center,
              style: TextStyle(color: FinanceTheme.textSub),
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _students.length + 1,
        itemBuilder: (context, index) {
          if (index == _students.length) {
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
            if (!_hasMoreStudents) {
              return const SizedBox(height: 20);
            }
            return const SizedBox(height: 32);
          }

          return SavingsStudentCard(
            data: _students[index],
            isExecutiveOrManager: true,
            onAction: (name, id, isDep) => _showTxDialog(name, id, isDep),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _savingsCardData(Map<String, dynamic> data) {
    return {
      ...data,
      'fullName': _studentName(data),
      'studentID': _studentId(data),
      'course': _studentCourse(data),
      'unionTotalPaid': _asInt(data['union_total_paid']),
      'unionBalance': _asInt(data['union_balance']),
      'storeBalance': _asInt(data['store_balance']),
      'role': data['role']?.toString() ?? '',
    };
  }

  String _studentName(Map<String, dynamic> data) =>
      (data['full_name'] ?? data['fullName'] ?? 'Unknown').toString();

  String _studentId(Map<String, dynamic> data) =>
      (data['student_id'] ?? data['studentID'] ?? '').toString();

  String _studentCourse(Map<String, dynamic> data) =>
      (data['course'] ?? data['class_name'] ?? 'N/A').toString();

  void _showTxDialog(String name, String id, bool isDeposit) {
    final amountController = TextEditingController();
    final themeColor = isDeposit
        ? FinanceTheme.incomeGreen
        : FinanceTheme.expenseRed;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isDeposit ? Icons.add_circle : Icons.remove_circle,
              color: themeColor,
            ),
            const SizedBox(width: 10),
            Text(isDeposit ? "Deposit" : "Withdraw"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "ID: $id",
              style: const TextStyle(color: FinanceTheme.textSub, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount",
                prefixIcon: const Icon(Icons.currency_rupee_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final amount = int.tryParse(amountController.text.trim()) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter a valid amount.")),
                );
                return;
              }
              Navigator.pop(ctx);
              await _controller.updateSavings(
                context: context,
                studentID: id,
                amount: amount,
                isDeposit: isDeposit,
              );
              await _refreshStudents();
            },
            child: Text(isDeposit ? "Deposit" : "Withdraw"),
          ),
        ],
      ),
    );
  }

  Future<_SavingsReportInputs> _loadSavingsReportInputs() async {
    final students = await _fetchReportStudents();
    final treasury = await Supabase.instance.client
        .from('treasury')
        .select('student_id, amount, type, date, created_at');
    final treasuryList = List<Map<String, dynamic>>.from(treasury);
    return _SavingsReportInputs(
      students: students,
      treasuryDocs: treasuryList,
    );
  }

  Widget _buildReportsTab() {
    return FutureBuilder<_SavingsReportInputs>(
      future: _loadSavingsReportInputs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildReportLoadError(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final inputs =
            snapshot.data ??
            const _SavingsReportInputs(students: [], treasuryDocs: []);
        final reports = _buildSavingsReports(
          inputs.students,
          inputs.treasuryDocs,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              AdminSupportToolCard(
                icon: Icons.picture_as_pdf_rounded,
                title: "Download Full Report PDF",
                subtitle: "Complete student-wise savings report",
                color: AppColors.primaryGreen,
                onTap: () => _downloadSavingsReport(reports.students),
              ),
              const SizedBox(height: 12),
              AdminSupportToolCard(
                icon: Icons.group_rounded,
                title: "Course-wise Summary",
                subtitle: "View vault balance by course",
                color: AppColors.primaryGreen,
                onTap: () => _showClassSummary(reports.classTotals),
              ),
              const SizedBox(height: 12),
              AdminSupportToolCard(
                icon: Icons.check_circle_rounded,
                title: "Paid Students Report",
                subtitle: "Students with active savings balance",
                color: AppColors.primaryGreen,
                onTap: () => _showActiveStudentsReport(reports.students),
              ),
              const SizedBox(height: 12),
              AdminSupportToolCard(
                icon: Icons.history_rounded,
                title: "Payment History",
                subtitle: "Full transaction records",
                color: AppColors.primaryGreen,
                onTap: () => _showPaymentHistory(inputs.treasuryDocs),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportLoadError(String message) {
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
            const Text(
              "Could not load reports",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  _SavingsReports _buildSavingsReports(
    List<Map<String, dynamic>> studentRows,
    List<Map<String, dynamic>> treasuryDocs,
  ) {
    final Map<String, _SavingsStudentReport> byStudentId = {};

    for (final data in studentRows) {
      final studentID = _studentId(data).trim();
      if (studentID.isEmpty) continue;

      byStudentId[studentID] = _SavingsStudentReport(
        name: _studentName(data),
        studentID: studentID,
        course: _studentCourse(data),
      );
    }

    for (final data in treasuryDocs) {
      final studentID = (data['student_id'] ?? data['studentID'] ?? '').toString().trim();
      if (studentID.isEmpty) continue;

      final report = byStudentId.putIfAbsent(
        studentID,
        () => _SavingsStudentReport(
          name: (data['student_name'] ?? data['studentName'] ?? 'Unknown').toString(),
          studentID: studentID,
          course: 'N/A',
        ),
      );

      final amount = _asInt(data['amount']);
      if (data['type'] == 'income') {
        report.deposits += amount;
      } else {
        report.withdrawals += amount;
      }
    }

    final students = byStudentId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final Map<String, _SavingsClassReport> classTotals = {};
    for (final student in students) {
      final className = student.course.trim().isEmpty ? 'N/A' : student.course;
      final total = classTotals.putIfAbsent(
        className,
        () => _SavingsClassReport(className),
      );
      total.studentCount += 1;
      total.deposits += student.deposits;
      total.withdrawals += student.withdrawals;
    }

    return _SavingsReports(students: students, classTotals: classTotals);
  }

  Future<void> _downloadSavingsReport(
    List<_SavingsStudentReport> students,
  ) async {
    final pdf = pw.Document();
    final activeStudents = students
        .where((student) => student.hasActivity)
        .toList();
    final rows = activeStudents.map((student) {
      return [
        student.name,
        student.studentID,
        student.course,
        student.deposits.toString(),
        student.withdrawals.toString(),
        student.balance.toString(),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            "Vault & Savings Report",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            "Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}",
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              "Name",
              "Student ID",
              "Course",
              "Deposit",
              "Withdraw",
              "Balance",
            ],
            data: rows,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Vault_Savings_Report',
    );
  }

  void _showClassSummary(Map<String, _SavingsClassReport> classTotals) {
    final classes = classTotals.values.toList()
      ..sort(
        (a, b) =>
            a.className.toLowerCase().compareTo(b.className.toLowerCase()),
      );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Course-wise Summary"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: classes.map((total) {
                return ListTile(
                  title: Text(
                    total.className,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${total.studentCount} students  |  Deposit: Rs ${total.deposits}  Withdraw: Rs ${total.withdrawals}",
                  ),
                  trailing: Text(
                    "Rs ${total.balance}",
                    style: TextStyle(
                      color: total.balance >= 0
                          ? AppColors.accentTeal
                          : AppColors.alertRed,
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

  void _showActiveStudentsReport(List<_SavingsStudentReport> students) {
    final activeStudents = students
        .where((student) => student.balance > 0)
        .toList();

    _showReportSheet(
      title: "Paid Students Report",
      emptyText: "No active savings accounts found.",
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: activeStudents.length,
        itemBuilder: (context, index) {
          final student = activeStudents[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primaryGreen,
              ),
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${student.studentID} | ${student.course}"),
            trailing: Text(
              "Rs ${student.balance}",
              style: const TextStyle(
                color: AppColors.accentTeal,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
      itemCount: activeStudents.length,
    );
  }

  void _showPaymentHistory(List<Map<String, dynamic>> treasuryDocs) {
    final transactions = treasuryDocs.toList()
      ..sort((a, b) {
        final aDate = _asDate(a['date'] ?? a['created_at']);
        final bDate = _asDate(b['date'] ?? b['created_at']);
        return bDate.compareTo(aDate);
      });

    _showReportSheet(
      title: "Payment History",
      emptyText: "No payment history found.",
      itemCount: transactions.length,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final data = transactions[index];
          final isIncome = data['type'] == 'income';
          final amount = _asInt(data['amount']);
          final studentID = (data['student_id'] ?? data['studentID'] ?? 'N/A').toString();
          final date = _formatDate(data['date'] ?? data['created_at']);
          final color = isIncome ? AppColors.accentTeal : AppColors.alertRed;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(
                isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: color,
              ),
            ),
            title: Text(
              isIncome ? "Deposit" : "Withdraw",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Student ID: $studentID\n$date"),
            trailing: Text(
              "${isIncome ? '+' : '-'} Rs $amount",
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          );
        },
      ),
    );
  }

  void _showReportSheet({
    required String title,
    required Widget child,
    required int itemCount,
    required String emptyText,
  }) {
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: itemCount == 0 ? Center(child: Text(emptyText)) : child,
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

  DateTime _asDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    final date = _asDate(value);
    if (date.millisecondsSinceEpoch == 0) return "Pending sync";
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}

class _SavingsReports {
  final List<_SavingsStudentReport> students;
  final Map<String, _SavingsClassReport> classTotals;

  const _SavingsReports({required this.students, required this.classTotals});
}

class _SavingsReportInputs {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> treasuryDocs;

  const _SavingsReportInputs({
    required this.students,
    required this.treasuryDocs,
  });
}

class _SavingsStudentReport {
  final String name;
  final String studentID;
  final String course;
  int deposits = 0;
  int withdrawals = 0;

  _SavingsStudentReport({
    required this.name,
    required this.studentID,
    required this.course,
  });

  int get balance => deposits - withdrawals;
  bool get hasActivity => deposits > 0 || withdrawals > 0;
}

class _SavingsClassReport {
  final String className;
  int studentCount = 0;
  int deposits = 0;
  int withdrawals = 0;

  _SavingsClassReport(this.className);

  int get balance => deposits - withdrawals;
}
