import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_notification_badge.dart';

// --- Premium Executive Theme (Public class to prevent unused warnings) ---
class LibraryColors {
  static const Color brandPrimary = Color(0xFF1E1B4B);
  static const Color accent = Color(0xFF6366F1);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);

  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);

  static const Color alert = Color(0xFFF59E0B);
  static const Color alertBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}

class StudentLibraryPage extends StatefulWidget {
  final String studentID;

  const StudentLibraryPage({super.key, this.studentID = ""});

  @override
  State<StudentLibraryPage> createState() => _StudentLibraryPageState();
}

class _StudentLibraryPageState extends State<StudentLibraryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final TextEditingController _noteController = TextEditingController();

  int _currentSlide = 0;
  bool _isSaved = true;
  Timer? _slideTimer;
  Timer? _saveTimer;

  int _totalBooks = 0;

  @override
  void initState() {
    super.initState();
    _noteController.text = "Remember to check out the new collection...";
    _startSlideshow();
  }

  void _startSlideshow() {
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _totalBooks > 1) {
        _currentSlide = (_currentSlide + 1) % _totalBooks;
        _pageController.animateToPage(
          _currentSlide,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _saveTimer?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onNoteChange(String val) {
    if (_isSaved) setState(() => _isSaved = false);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isSaved = true);
    });
  }

  // --- TRANSACTION HISTORY DIALOG ---
  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Payment History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('library_payments')
                .stream(primaryKey: ['id'])
                .eq('student_id', widget.studentID)
                .order('date', ascending: false),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text("No transaction history found."),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index];
                  DateTime dt = DateTime.tryParse(data['date']?.toString() ?? '') ??
                      DateTime.tryParse(data['created_at']?.toString() ?? '') ??
                      DateTime.now();
                  bool isAddition = data['type'] == 'Addition';

                  return ListTile(
                    leading: Icon(
                      isAddition ? Icons.add_circle : Icons.remove_circle,
                      color: isAddition
                          ? LibraryColors.error
                          : LibraryColors.success,
                    ),
                    title: Text("${data['type']}: ₹${data['amount']}"),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(dt),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 950;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: LibraryColors.background,
      appBar: _buildHeader(),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                _buildHero(), // CONNECTED SLIDESHOW
                const SizedBox(height: 32),
                _buildCatalogSection(),
                const SizedBox(height: 40),
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _buildFineCard()),
                          const SizedBox(width: 32),
                          Expanded(flex: 8, child: _buildWorkspace(isDesktop)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildFineCard(),
                          const SizedBox(height: 32),
                          _buildWorkspace(isDesktop),
                        ],
                      ),
                const SizedBox(height: 60),
                const Text(
                  "© 2026 City Library Portal • Version 3.1.2",
                  style: TextStyle(
                    color: LibraryColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: LibraryColors.brandPrimary,
      elevation: 0,
      toolbarHeight: 80,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white70,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Student Library",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: const [
        StudentNotificationBadge(
          committeeName: "Library",
          themeColor: Colors.white,
        ),
        SizedBox(width: 20),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('library_books')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false)
              .limit(3),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            var bookDocs = snapshot.data ?? [];
            if (bookDocs.isEmpty) {
              return Container(
                color: LibraryColors.brandPrimary,
                child: const Center(
                  child: Text(
                    "No Books Added",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            // Update the total books for the slideshow timer
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _totalBooks != bookDocs.length) {
                setState(() => _totalBooks = bookDocs.length);
              }
            });

            return PageView.builder(
              controller: _pageController,
              itemCount: bookDocs.length,
              itemBuilder: (context, index) {
                var data = bookDocs[index];
                String? imageUrl = data['image_url'] ?? data['imageUrl'];

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Container(color: LibraryColors.brandPrimary),
                          )
                        : Container(color: LibraryColors.brandPrimary),
                    Container(color: Colors.black.withValues(alpha: 0.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "RECOMMENDED READING",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            data['title'] ?? "Untitled",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "by ${data['author'] ?? 'Unknown Author'}",
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFineCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchSupabaseStudent(),
      builder: (context, snapshot) {
        int fine = 0;
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          fine = int.tryParse(data['library_fine']?.toString() ?? '0') ?? 0;
        }

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: LibraryColors.border),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                size: 40,
                color: LibraryColors.alert,
              ),
              const SizedBox(height: 20),
              const Text(
                "OUTSTANDING BALANCE",
                style: TextStyle(
                  color: LibraryColors.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "₹$fine",
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                  color: LibraryColors.textMain,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showHistoryDialog, // OPENS HISTORY DIALOG
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: LibraryColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "View Breakdown",
                    style: TextStyle(
                      color: LibraryColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchSupabaseStudent() async {
    final client = Supabase.instance.client;
    if (widget.studentID.trim().isNotEmpty) {
      return client
          .from('students')
          .select()
          .eq('student_id', widget.studentID.trim())
          .maybeSingle();
    }

    final email = client.auth.currentUser?.email;
    if (email == null || email.trim().isEmpty) return null;
    return client
        .from('students')
        .select()
        .eq('auth_email', email.trim().toLowerCase())
        .maybeSingle();
  }

  Widget _buildCatalogSection() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: LibraryColors.accent.withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _openCatalogWorkspace,
          icon: const Icon(Icons.auto_stories_rounded),
          label: const Text("Digital Catalog Workspace"),
          style: ElevatedButton.styleFrom(
            backgroundColor: LibraryColors.brandPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
      ),
    );
  }

  void _openCatalogWorkspace() {
    if (!_scrollController.hasClients) return;
    final target = MediaQuery.of(context).size.width > 950 ? 850.0 : 1180.0;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent).toDouble(),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildWorkspace(bool isDesktop) {
    return Container(
      constraints: BoxConstraints(minHeight: isDesktop ? 500 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LibraryColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Research Notes",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: LibraryColors.textMain,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isSaved
                            ? LibraryColors.success.withValues(alpha: 0.1)
                            : LibraryColors.alertBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isSaved ? "Saved" : "Syncing...",
                        style: TextStyle(
                          color: _isSaved
                              ? LibraryColors.success
                              : LibraryColors.alert,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  onChanged: _onNoteChange,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: "Enter research thoughts...",
                    filled: true,
                    fillColor: LibraryColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
}
