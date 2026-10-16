import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/library_controller.dart';
import '../widgets/library_theme.dart';
import '../../data/repositories/firestore_library_repository.dart';
import '../../../../home/student_notification_badge.dart';
import 'dart:async';

class StudentLibraryPage extends StatefulWidget {
  final String studentID;
  const StudentLibraryPage({super.key, this.studentID = ""});

  @override
  State<StudentLibraryPage> createState() => _StudentLibraryPageState();
}

class _StudentLibraryPageState extends State<StudentLibraryPage> {
  late final LibraryController _controller;
  final PageController _pageController = PageController();
  int _currentSlide = 0;
  Timer? _slideTimer;

  @override
  void initState() {
    super.initState();
    _controller = LibraryController(FirestoreLibraryRepository());
    _startSlideshow();
  }

  void _startSlideshow() {
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentSlide = (_currentSlide + 1) % 4; // Arbitrary cap or safe range
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryTheme.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSlideshow(),
            const SizedBox(height: 30),
            _buildFineCard(),
            const SizedBox(height: 30),
            _buildCatalogWorkspace(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: LibraryTheme.primary,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text("Student Library", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: const [
        StudentNotificationBadge(
          committeeName: "Library",
          themeColor: Colors.white,
        ),
        SizedBox(width: 20),
      ],
    );
  }

  Widget _buildSlideshow() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: LibraryTheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _controller.getBooksCatalogStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.take(4).toList();
          if (docs.isEmpty) return const Center(child: Text("No Books Added", style: TextStyle(color: Colors.white)));

          return PageView.builder(
            controller: _pageController,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Stack(fit: StackFit.expand, children: [
                if (data['imageUrl'] != null) Image.network(data['imageUrl'], fit: BoxFit.cover, errorBuilder: (c, e, s) => Container()),
                Container(color: Colors.black.withValues(alpha: 0.4)),
                Center(child: Text(data['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
              ]);
            },
          );
        },
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
          padding: const EdgeInsets.all(24),
          decoration: LibraryTheme.cardDecoration,
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 40, color: LibraryTheme.alert),
              const SizedBox(height: 10),
              const Text("OUTSTANDING BALANCE", style: TextStyle(color: LibraryTheme.textMuted, fontSize: 12)),
              Text("₹$fine", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: LibraryTheme.textMain)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showHistory(),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: LibraryTheme.error)),
                  child: const Text("View Breakdown", style: TextStyle(color: LibraryTheme.error, fontWeight: FontWeight.bold)),
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

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("History Details"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: _controller.getHistoryStream(widget.studentID),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("No history logs"));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text("${data['type']}: ₹${data['amount']}"),
                    subtitle: Text(data['date'] != null ? DateFormat('dd MMM').format((data['date'] as Timestamp).toDate()) : ''),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogWorkspace() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: LibraryTheme.cardDecoration,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Research Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Enter research thoughts...",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
