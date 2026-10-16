import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:intl/intl.dart';
import 'reel_upload_page.dart';
import 'event_management_page.dart';
import '../features/prd/presentation/pages/prd_request_desk_page.dart';
import 'admin_committee_prize.dart';
import 'purchase_request_page.dart';

class NumberedLedgerPage extends StatefulWidget {
  final String departmentName;
  final VoidCallback? onBack; // 🟢 Add this
  const NumberedLedgerPage({
    super.key,
    required this.departmentName,
    this.onBack,
  });

  @override
  State<NumberedLedgerPage> createState() => _NumberedLedgerPageState();
}

class _NumberedLedgerPageState extends State<NumberedLedgerPage> {
  static const int _studentPageSize = 20;
  static const String _studentSelect =
      'student_id,cic_no,full_name,course,class_name,phone,union_total_paid,union_balance,store_balance,designation,assigned_role';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _deptScrollController = ScrollController();
  final ScrollController _studentScrollController = ScrollController();
  final List<Map<String, dynamic>> _students = [];
  Timer? _searchDebounce;

  late String currentDepartment;

  // Logic states
  bool _isProcessRunning = false;
  bool _isExecutiveOrManager = false;
  bool _isLoadingPermissions = true;
  bool _isInitialStudentLoading = true;
  bool _isLoadingMoreStudents = false;
  bool _hasMoreStudents = true;
  Object? _studentLoadError;
  int _nextStudentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentDepartment = widget.departmentName;
    _studentScrollController.addListener(_onStudentScroll);
    _checkPermissions();
    unawaited(_loadStudents(reset: true));
  }

  // --- Fixed Role Check Logic ---
  Future<void> _checkPermissions() async {
    try {
      final user = supabase.Supabase.instance.client.auth.currentUser;
      if (user != null) {
        Map<String, dynamic>? data;
        final email = user.email?.trim().toLowerCase() ?? '';

        if (email.isNotEmpty) {
          data = await supabase.Supabase.instance.client
              .from('students')
              .select('role,designation,assigned_role,auth_email,email')
              .or('auth_email.eq.$email,email.eq.$email')
              .maybeSingle();
        }

        if (data != null) {
          final String role = data['role']?.toString().toLowerCase() ?? '';
          final String designation =
              data['designation']?.toString().toLowerCase() ?? '';
          final String assignedRole =
              data['assigned_role']?.toString().toLowerCase() ?? '';

          // Updated logic: Check both 'role' and 'designation' fields
          if (role == 'executive' ||
              role == 'bankmanager' ||
              designation == 'executive' ||
              designation == 'bankmanager' ||
              assignedRole == 'executive' ||
              assignedRole == 'bankmanager') {
            if (mounted) {
              setState(() {
                _isExecutiveOrManager = true;
                _isLoadingPermissions = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Permission check error: $e");
    }
    if (mounted) {
      setState(() => _isLoadingPermissions = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _deptScrollController.dispose();
    _studentScrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onStudentScroll() {
    if (!_studentScrollController.hasClients ||
        _isLoadingMoreStudents ||
        _isInitialStudentLoading ||
        !_hasMoreStudents) {
      return;
    }

    final position = _studentScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 260) {
      unawaited(_loadStudents());
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) unawaited(_loadStudents(reset: true));
    });
  }

  Future<void> _loadStudents({bool reset = false}) async {
    if (_isLoadingMoreStudents || (_isInitialStudentLoading && !reset)) return;

    if (reset) {
      setState(() {
        _students.clear();
        _nextStudentIndex = 0;
        _hasMoreStudents = true;
        _studentLoadError = null;
        _isInitialStudentLoading = true;
        _isLoadingMoreStudents = false;
      });
    } else {
      if (!_hasMoreStudents) return;
      setState(() => _isLoadingMoreStudents = true);
    }

    try {
      final page = await _fetchStudentPage(
        start: _nextStudentIndex,
        limit: _studentPageSize,
      );
      if (!mounted) return;
      setState(() {
        _students.addAll(page);
        _nextStudentIndex += page.length;
        _hasMoreStudents = page.length == _studentPageSize;
        _isInitialStudentLoading = false;
        _isLoadingMoreStudents = false;
        _studentLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _studentLoadError = e;
        _isInitialStudentLoading = false;
        _isLoadingMoreStudents = false;
      });
    }
  }

  Future<void> _refreshStudents() async {
    await _loadStudents(reset: true);
  }

  Future<List<Map<String, dynamic>>> _fetchStudentPage({
    required int start,
    required int limit,
  }) async {
    final end = start + limit - 1;
    var query = supabase.Supabase.instance.client
        .from('students')
        .select(_studentSelect)
        .ilike('course', currentDepartment);

    final search = _searchController.text.trim();
    if (search.isNotEmpty) {
      final escaped = search.replaceAll(',', r'\,');
      query = query.or(
        'full_name.ilike.%$escaped%,student_id.eq.$escaped,cic_no.eq.$escaped',
      );
    }

    final rows = await query.order('full_name').range(start, end);
    return List<Map<String, dynamic>>.from(
      rows.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _buildVaultStream(),
          Expanded(
            child: _isLoadingPermissions
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildSectionHeader("Department Overview"),
                        _buildDepartmentGrid(),
                        const SizedBox(height: 15),
                        _buildSearchBar(),
                        _buildSectionHeader(
                          "Quick Student Check-In ($currentDepartment)",
                        ),
                        _buildFilteredStudentList(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('treasury').snapshots(),
      builder: (context, snapshot) {
        double totalBalance = 0.0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              if (data['type'] == 'income') {
                totalBalance += amount;
              } else {
                totalBalance -= amount;
              }
            } catch (e) {
              debugPrint("Error parsing vault document: $e");
            }
          }
        }
        return _buildVaultHeader(totalBalance);
      },
    );
  }

  Widget _buildVaultHeader(double balance) {
    final String formattedBalance =
        "₹ ${NumberFormat('#,##,###').format(balance)}";

    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Treasury Control",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: Colors.white,
                onSelected: (value) {
                  if (value == 'purchase') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PurchaseRequestPage(committeeName: 'Bank'),
                      ),
                    );
                  } else if (value == 'menu') {
                    _showManagementOptions(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'purchase',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Purchase Requests'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'menu',
                    child: Row(
                      children: [
                        Icon(Icons.menu, size: 18),
                        SizedBox(width: 10),
                        Text('Management Options'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Total Vault",
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formattedBalance,
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: "Search student name...",
            prefixIcon: Icon(Icons.search, color: Colors.blueGrey, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentGrid() {
    final List<String> departments = [
      "THAMHEEDIYYA ULA",
      "THAMHEEDIYYA SANIYA",
      "ALIYA ULA",
      "ALIYA SANIYA",
      "ALIYA SALISA",
    ];

    return SizedBox(
      height: 125,
      child: ListView.builder(
        controller: _deptScrollController,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final String currentDep = departments[index];
          final bool isSelected =
              currentDepartment.toLowerCase() == currentDep.toLowerCase();

          return GestureDetector(
            onTap: () {
              setState(() {
                currentDepartment = currentDep;
                _searchController.clear();
              });
              unawaited(_loadStudents(reset: true));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 165,
              margin: const EdgeInsets.only(right: 15, bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF334155)],
                      )
                    : const LinearGradient(
                        colors: [Colors.white, Colors.white],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF0F172A).withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: isSelected
                    ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          size: 18,
                          color: isSelected ? Colors.white : Colors.blueGrey,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.greenAccent,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    currentDep,
                    maxLines: 2,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 4,
                    width: isSelected ? 40 : 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00E676)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
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

  Widget _buildFilteredStudentList() {
    if (_isInitialStudentLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_studentLoadError != null && _students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Could not load students: $_studentLoadError",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => unawaited(_loadStudents(reset: true)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshStudents,
        child: SizedBox(
          height: 220,
          child: ListView(
            controller: _studentScrollController,
            children: const [
              SizedBox(height: 70),
              Center(child: Text("No students found in this course.")),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.58,
      child: RefreshIndicator(
        onRefresh: _refreshStudents,
        child: ListView.builder(
          controller: _studentScrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _students.length + 1,
          itemBuilder: (context, index) {
            if (index == _students.length) return _buildStudentListFooter();

            final data = _students[index];
            final String studentName =
                data['full_name']?.toString().trim().isNotEmpty == true
                ? data['full_name'].toString()
                : "Unknown";
            final String studentID =
                data['student_id']?.toString().trim().isNotEmpty == true
                ? data['student_id'].toString()
                : (data['cic_no'] ?? "N/A").toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : "?",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("ID: $studentID"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: _isExecutiveOrManager
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onPressed: () => _handleOpenDialog(
                        context,
                        studentName,
                        studentID,
                        true,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle,
                        color: _isExecutiveOrManager ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _handleOpenDialog(
                        context,
                        studentName,
                        studentID,
                        false,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStudentListFooter() {
    if (_isLoadingMoreStudents) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_studentLoadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: OutlinedButton.icon(
          onPressed: () => unawaited(_loadStudents()),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text("Load more"),
        ),
      );
    }

    if (!_hasMoreStudents) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            "All loaded",
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }

  void _handleOpenDialog(
    BuildContext context,
    String name,
    String id,
    bool isDeposit,
  ) {
    if (!_isExecutiveOrManager) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only Executive or Bank Manager can modify savings."),
        ),
      );
      return;
    }
    if (_isProcessRunning) return;
    _showTransactionDialog(context, name, id, isDeposit);
  }

  void _showManagementOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "${widget.departmentName} Management",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.video_call, color: Colors.redAccent),
                title: Text("Upload ${widget.departmentName} Reel"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ReelUploadPage(committeeName: "Bank"),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_note, color: Colors.teal),
                title: const Text("Manage Schedule Events"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EventManagementPage(
                        initialCommittee: "Library",
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFC5A059),
                ),
                title: const Text("Sub-Committee Prizes"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminCommitteeDashboard(
                        initialCommittee: "Library",
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.campaign_rounded,
                  color: Colors.orange,
                ),
                title: const Text("PRD Request Desk"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 🟢 THE FIX: Passed "Bank" so the form locks perfectly!
                      builder: (context) =>
                          const PrdRequestDeskPage(initialCommittee: "Bank"),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTransactionDialog(
    BuildContext context,
    String studentName,
    String studentID,
    bool isDeposit,
  ) {
    final TextEditingController amountController = TextEditingController();
    final Color themeColor = isDeposit
        ? const Color(0xFF00E676)
        : const Color(0xFFFF5252);
    final String title = isDeposit
        ? "Deposit to Savings"
        : "Withdraw from Savings";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Icon(
                    isDeposit ? Icons.savings_rounded : Icons.money_off_rounded,
                    color: themeColor,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Account: $studentName",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent History",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isProcessRunning
                              ? null
                              : () {
                                  Navigator.of(
                                    dialogContext,
                                    rootNavigator: true,
                                  ).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StudentHistoryPage(
                                        studentName: studentName,
                                        studentID: studentID,
                                        canDelete: _isExecutiveOrManager,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text(
                            "View Passbook",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 110,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('treasury')
                            .where('studentID', isEqualTo: studentID)
                            .orderBy('date', descending: true)
                            .limit(2)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                "Syncing...",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }

                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                "No records yet.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              final double amt =
                                  (data['amount'] as num?)?.toDouble() ?? 0.0;
                              final bool isInc = data['type'] == 'income';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isInc ? "Deposit" : "Withdraw",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "₹${amt.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isInc
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      enabled: !_isProcessRunning,
                      decoration: InputDecoration(
                        labelText: "Enter Amount (₹)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessRunning
                      ? null
                      : () => Navigator.of(
                          dialogContext,
                          rootNavigator: true,
                        ).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isProcessRunning
                      ? null
                      : () async {
                          final String val = amountController.text.trim();
                          final double? amt = double.tryParse(val);

                          if (val.isEmpty || amt == null || amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Enter a valid amount"),
                              ),
                            );
                            return;
                          }

                          setModalState(() => _isProcessRunning = true);
                          FocusScope.of(context).unfocus();

                          try {
                            await FirebaseFirestore.instance
                                .collection('treasury')
                                .add({
                                  'amount': amt,
                                  'type': isDeposit ? 'income' : 'expense',
                                  'date': FieldValue.serverTimestamp(),
                                  'studentID': studentID,
                                  'studentName': studentName,
                                })
                                .timeout(const Duration(seconds: 12));

                            if (context.mounted) {
                              Navigator.of(
                                dialogContext,
                                rootNavigator: true,
                              ).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Vault Updated Successfully"),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModalState(() => _isProcessRunning = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: ${e.toString()}"),
                                ),
                              );
                            }
                          } finally {
                            setModalState(() => _isProcessRunning = false);
                          }
                        },
                  child: _isProcessRunning
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isDeposit ? "Confirm Deposit" : "Confirm Withdrawal",
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) setState(() => _isProcessRunning = false);
    });
  }
}

class StudentHistoryPage extends StatelessWidget {
  final String studentName;
  final String studentID;
  final bool canDelete;

  const StudentHistoryPage({
    super.key,
    required this.studentName,
    required this.studentID,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text("$studentName's Passbook"),
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('treasury')
            .where('studentID', isEqualTo: studentID)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  "Database Error: Check index settings.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          double totalIn = 0;
          double totalOut = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            if (data['type'] == 'income') {
              totalIn += amount;
            } else {
              totalOut += amount;
            }
          }

          return Column(
            children: [
              _buildSavingsSummary(totalIn, totalOut, totalIn - totalOut),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text("No transaction history found."))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(15),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final double amount =
                              (data['amount'] as num?)?.toDouble() ?? 0.0;
                          final bool isDeposit = data['type'] == 'income';
                          final String docId = docs[index].id;

                          DateTime? dt;
                          if (data['date'] != null) {
                            dt = (data['date'] as Timestamp).toDate();
                          }
                          String dateStr = dt != null
                              ? DateFormat('dd/MM/yyyy HH:mm').format(dt)
                              : "Pending...";

                          return GestureDetector(
                            onLongPress: canDelete
                                ? () => _confirmDelete(context, docId)
                                : null,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDeposit
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFEBEE),
                                  child: Icon(
                                    isDeposit
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isDeposit
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  isDeposit ? "Deposit" : "Withdrawal",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: Text(
                                  "${isDeposit ? '+' : '-'} ₹${amount.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    color: isDeposit
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Record?"),
        content: const Text(
          "Are you sure you want to permanently delete this transaction?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('treasury')
                  .doc(docId)
                  .delete();
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Entry deleted")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsSummary(double totalIn, double totalOut, double net) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "NET SAVINGS",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "₹ ${net.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem("Total In", totalIn, Colors.green),
              _summaryItem("Total Out", totalOut, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double val, Color col) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          "₹${val.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: col,
          ),
        ),
      ],
    );
  }
}
