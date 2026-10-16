import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../logic/literary_controller.dart';
import '../../data/repositories/firestore_literary_repository.dart';
import '../../data/repositories/supabase_publications_repository.dart';
import '../widgets/publication_card.dart';

class StudentLiteraryPage extends StatefulWidget {
  final bool isAdmin;
  final String committeeName;
  const StudentLiteraryPage({
    super.key,
    this.isAdmin = false,
    this.committeeName = 'Literary',
  });

  @override
  State<StudentLiteraryPage> createState() => _StudentLiteraryPageState();
}

class _StudentLiteraryPageState extends State<StudentLiteraryPage> {
  late final LiteraryController _controller;
  late final SupabasePublicationsRepository _publicationsRepository;
  int _bottomNavIndex = 0;
  late Future<List<Map<String, dynamic>>> _publicationsFuture;
  List<Map<String, dynamic>> publications = <Map<String, dynamic>>[];
  final Set<String> _deletingPublicationIds = <String>{};

  @override
  void initState() {
    super.initState();
    _controller = LiteraryController(FirestoreLiteraryRepository());
    _publicationsRepository = SupabasePublicationsRepository();
    _publicationsFuture = fetchPublications();
  }

  @override
  void didUpdateWidget(covariant StudentLiteraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.committeeName != widget.committeeName) {
      publications = <Map<String, dynamic>>[];
      _publicationsFuture = fetchPublications();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color dark = Color(0xFF39544B);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: dark,
          title: const Text(
            "LITERARY HUB",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: const [],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          selectedItemColor: dark,
          onTap: (i) => setState(() => _bottomNavIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_rounded),
              label: "Feed",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_rounded),
              label: "My Posts",
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showSubmitSheet,
          backgroundColor: dark,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        body: _bottomNavIndex == 0 ? _buildFeed() : _buildMyPosts(),
      ),
    );
  }

  Widget _buildFeed() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _publicationsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Could not load publications: ${snapshot.error}"),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final visiblePublications = snapshot.data ?? publications;
        if (visiblePublications.isEmpty) {
          return const Center(child: Text("No Publications Found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: visiblePublications.length,
          itemBuilder: (context, index) {
            final data = visiblePublications[index];
            final docId = data['id']?.toString() ?? '';
            final likesCount =
                int.tryParse(data['likes_count']?.toString() ?? '') ?? 0;
            return PublicationCard(
              title: data['title'] ?? '',
              author: data['author_name'] ?? 'Student',
              category: data['category'] ?? 'General',
              content: data['content'] ?? '',
              date: _parseDate(data['created_at']),
              likesCount: likesCount,
              isLiked: false,
              onLike: docId.isEmpty
                  ? () {}
                  : () async {
                      await _publicationsRepository.updateLikeCount(
                        id: docId,
                        likesCount: likesCount + 1,
                      );
                      if (mounted) {
                        setState(
                          () => _publicationsFuture = fetchPublications(),
                        );
                      }
                    },
              onReadFull: () => _showReadFullDialog(context, data),
              onDelete: (widget.isAdmin == true && docId.isNotEmpty)
                  ? () => _showDeleteConfirm(docId)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildMyPosts() {
    final uid = supabase.Supabase.instance.client.auth.currentUser?.id ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getStudentRequestsStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text("You haven't submitted any posts yet."),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  data['title'] ?? 'Untitled',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Status: ${status.toString().toUpperCase()}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _controller.deleteRequest(docs[index].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Executive Theme Styling ---
  static const Color brandPrimary = Color(0xFF39544B);
  static const Color accentGold = Color(0xFFC5A059);

  Widget _goldenPlateFrame({
    required Widget child,
    double radius = 16,
    bool isDialog = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [accentGold, brandPrimary, accentGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.3, 0.5, 0.7],
        ),
        boxShadow: [
          BoxShadow(
            color: brandPrimary.withValues(alpha: 0.25),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDialog ? const Color(0xFFFBF4E6) : Colors.white,
          borderRadius: BorderRadius.circular(radius - 2),
        ),
        child: child,
      ),
    );
  }

  void _showSubmitSheet() {
    final titleCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String category = "Poetry";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
          child: _goldenPlateFrame(
            isDialog: true,
            radius: 30,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "NEW SUBMISSION",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: brandPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              titleCtrl.clear();
                              nameCtrl.clear();
                              idCtrl.clear();
                              contentCtrl.clear();
                              setSheetState(() {});
                            },
                            icon: const Icon(
                              Icons.delete_sweep_rounded,
                              color: Colors.redAccent,
                            ),
                            tooltip: "Clear All",
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: accentGold, thickness: 1),
                  Expanded(
                    child: ListView(
                      children: [
                        const SizedBox(height: 15),
                        _buildInputField(titleCtrl, "Masterpiece Title"),
                        const SizedBox(height: 15),
                        _buildInputField(nameCtrl, "Your Pen Name"),
                        const SizedBox(height: 15),
                        _buildInputField(idCtrl, "Student ID (e.g. 17208)"),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          initialValue: category,
                          dropdownColor: const Color(0xFFFBF4E6),
                          style: const TextStyle(
                            color: brandPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          iconEnabledColor: brandPrimary,
                          decoration: _inputDecoration("Category"),
                          items:
                              [
                                    "Poetry",
                                    "Story",
                                    "Mini Story",
                                    "Essay",
                                    "Report",
                                  ]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                          color: brandPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setSheetState(() => category = val!),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: contentCtrl,
                          maxLines: 10,
                          decoration: _inputDecoration(
                            "Write your content here...",
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              if (titleCtrl.text.isNotEmpty &&
                                  contentCtrl.text.isNotEmpty) {
                                _controller.submitRequest(
                                  title: titleCtrl.text,
                                  author: nameCtrl.text.isEmpty
                                      ? 'Student'
                                      : nameCtrl.text,
                                  studentID: idCtrl.text.isEmpty
                                      ? 'N/A'
                                      : idCtrl.text,
                                  content: contentCtrl.text,
                                  category: category,
                                  authorId: supabase
                                      .Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser
                                      ?.id,
                                );
                              }
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "SEND TO UNION",
                              style: TextStyle(
                                color: accentGold,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
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
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String hint) {
    return TextField(controller: ctrl, decoration: _inputDecoration(hint));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: brandPrimary.withValues(alpha: 0.72),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white70),
      ),
    );
  }

  void _showDeleteConfirm(String docId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        var isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Delete Publication"),
            content: const Text(
              "Are you sure you want to permanently delete this publication from the hub?",
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        await _deletePublication(docId, dialogContext);
                        if (dialogContext.mounted) {
                          setDialogState(() => isDeleting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchPublications() async {
    final rows = await _publicationsRepository.fetchPublications(
      committeeName: widget.committeeName,
    );
    publications = List<Map<String, dynamic>>.from(rows);
    return publications;
  }

  Future<void> _deletePublication(
    String publicationId,
    BuildContext dialogContext,
  ) async {
    if (_deletingPublicationIds.contains(publicationId)) return;
    setState(() => _deletingPublicationIds.add(publicationId));

    try {
      await _publicationsRepository.deletePublication(publicationId);
      if (!mounted) return;
      if (dialogContext.mounted) Navigator.pop(dialogContext);
      setState(() {
        _deletingPublicationIds.remove(publicationId);
        publications.removeWhere(
          (item) => item['id']?.toString() == publicationId,
        );
        _publicationsFuture = Future<List<Map<String, dynamic>>>.value(
          List<Map<String, dynamic>>.from(publications),
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Publication deleted")));
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingPublicationIds.remove(publicationId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  void _showReadFullDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: brandPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                "By ${data['author_name'] ?? 'Student'} | ${data['category'] ?? 'General'}",
                style: const TextStyle(
                  color: accentGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Divider(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    data['content'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
