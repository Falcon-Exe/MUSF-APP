import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'reel_upload_page.dart';
import 'event_management_page.dart';
import '../features/prd/presentation/pages/prd_request_desk_page.dart';
import 'admin_committee_prize.dart';
import 'purchase_request_page.dart';
import '../core/utils/pdf_text_helpers.dart';
import '../features/literary/data/repositories/supabase_publications_repository.dart';

// --- Literary Hub Admin Theme ---
class _HubColors {
  static const Color brandPrimary = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFC5A059);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color background = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textMain = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color emerald = Color(0xFF10B981);
  static const Color rose = Color(0xFFEF4444);
}

class LiteraryStudentPage extends StatefulWidget {
  final VoidCallback? onBack; // 🟢 Add this
  const LiteraryStudentPage({super.key, this.onBack});

  @override
  State<LiteraryStudentPage> createState() => _LiteraryStudentPageState();
}

class _LiteraryStudentPageState extends State<LiteraryStudentPage> {
  static const String _committeeName = 'Literary';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabasePublicationsRepository _publicationsRepository =
      SupabasePublicationsRepository();

  int _selectedIndex = 0;
  int _publicationsRefreshKey = 0;
  String _selectedFilterCategory = 'All';
  String _submittingCategory = "Poetry";
  final List<String> _categories = [
    "Poetry",
    "Story",
    "Mini Story",
    "Essay",
    "Report",
    "Research - Science",
    "Research - Social",
  ];

  // Controllers for direct publishing
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController =
      TextEditingController(); // Controller for Author name
  final TextEditingController _contentController = TextEditingController();

  bool _isExecutiveOrManager = false;
  bool _isLoadingAuth = true;
  bool _isPublishing = false;
  final Set<String> _deletedPublicationIds = <String>{};
  final Set<String> _deletingPublicationIds = <String>{};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final user = supabase.Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Handshake logic with 10s timeout to prevent infinite loading
        final doc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.id)
            .get()
            .timeout(const Duration(seconds: 10));

        Map<String, dynamic>? data = doc.data();
        if (!doc.exists || data == null) {
          final email = user.email ?? '';
          final searchId = email.contains('@') ? email.split('@')[0] : email;
          final query = await FirebaseFirestore.instance
              .collection('students')
              .where('studentID', isEqualTo: searchId.trim())
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 10));
          if (query.docs.isNotEmpty) {
            data = query.docs.first.data();
          }
        }

        if (data != null) {
          final String role = data['role']?.toString().toLowerCase() ?? '';
          final String designation =
              data['designation']?.toString().toLowerCase() ?? '';

          if (role == 'executive' ||
              role == 'bankmanager' ||
              designation == 'executive' ||
              designation == 'bankmanager') {
            if (mounted) setState(() => _isExecutiveOrManager = true);
          }
        }
      }
    } catch (e) {
      debugPrint("Auth error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAuth = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAuth) {
      return const Scaffold(
        backgroundColor: _HubColors.brandPrimary,
        body: Center(
          child: CircularProgressIndicator(color: _HubColors.accentGold),
        ),
      );
    }

    if (!_isExecutiveOrManager) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(
          child: Text("Only Executives can access the Admin Literary Hub."),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _HubColors.background,
      appBar: AppBar(
        backgroundColor: _HubColors.brandPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "LITERARY ADMIN HUB",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
            tooltip: 'Purchase Requests',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const PurchaseRequestPage(committeeName: 'Literary'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _showManagementOptions(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [_buildAddPage(), _buildLibraryPage(), _buildRequestsPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: _HubColors.brandPrimary,
        unselectedItemColor: _HubColors.textLight,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Post Content",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: "Library",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: "Approvals",
          ),
        ],
      ),
    );
  }

  // --- TAB 1: ADD CONTENT (Direct Admin Posting) ---
  Widget _buildAddPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PUBLISH NEW CONTENT",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: _HubColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final bool isSelected =
                    _submittingCategory == _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(_categories[index]),
                    selected: isSelected,
                    onSelected: (bool val) => setState(
                      () => _submittingCategory = _categories[index],
                    ),
                    selectedColor: _HubColors.brandPrimary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? _HubColors.accentGold
                          : _HubColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: _HubColors.border,
                      ), // CORRECT SYNTAX
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 25),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration("Document Title"),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _authorController,
            decoration: _inputDecoration("Author Name (Student name)"),
          ), // NEW AUTHOR FIELD
          const SizedBox(height: 15),
          TextField(
            controller: _contentController,
            maxLines: 12,
            decoration: _inputDecoration("Write content here..."),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _HubColors.brandPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isPublishing ? null : _publishContent,
              child: _isPublishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: _HubColors.accentGold,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "PUBLISH DIRECTLY",
                      style: TextStyle(
                        color: _HubColors.accentGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    hintText: label,
    hintStyle: const TextStyle(color: _HubColors.textLight),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _HubColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _HubColors.border),
    ),
  );

  Future<void> _publishContent() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      return;
    }
    setState(() => _isPublishing = true);
    try {
      await _publicationsRepository.createPublication(
        committeeName: _committeeName,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _submittingCategory,
        authorName: _authorController.text.trim().isEmpty
            ? "Admin"
            : _authorController.text.trim(),
      );
      _titleController.clear();
      _authorController.clear();
      _contentController.clear();
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _selectedIndex = 1;
          _publicationsRefreshKey++;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  // --- TAB 2: LIBRARY VIEW ---
  Widget _buildLibraryPage() {
    return Column(
      children: [
        _buildLibraryCategoryFilter(),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('$_committeeName-$_publicationsRefreshKey'),
            future: _publicationsRepository.fetchPublications(
              committeeName: _committeeName,
            ),
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

              final docs = (snapshot.data ?? []).where((data) {
                final id = data['id']?.toString() ?? '';
                if (_deletedPublicationIds.contains(id)) return false;
                return _selectedFilterCategory == 'All' ||
                    data['category'] == _selectedFilterCategory;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("No publications found."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index];
                  final String docId = data['id']?.toString() ?? '';

                  final String dateStr = _formatPublicationDate(
                    data['created_at'],
                  );

                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: _HubColors.border,
                      ), // CORRECT SYNTAX
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['category']?.toString().toUpperCase() ??
                                    "GENERAL",
                                style: const TextStyle(
                                  color: _HubColors.accentIndigo,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: _HubColors.textLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data['title']?.toString() ?? "Untitled",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _HubColors.textMain,
                            ),
                          ),
                          Text(
                            "By ${data['author_name'] ?? 'Admin'}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: _HubColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            data['content']?.toString() ?? "",
                            style: const TextStyle(
                              color: _HubColors.textMain,
                              height: 1.5,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: docId.isEmpty
                                    ? null
                                    : () => _showEditDialog(docId, data),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                label: const Text(
                                  "Edit",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed:
                                    docId.isEmpty ||
                                        _deletingPublicationIds.contains(docId)
                                    ? null
                                    : () => _deleteWork(docId),
                                icon: _deletingPublicationIds.contains(docId)
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                        color: _HubColors.rose,
                                      ),
                                label: const Text(
                                  "Delete",
                                  style: TextStyle(color: _HubColors.rose),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 🟢 LOGIC: GENERATE AND DOWNLOAD PDF FOR SELECTED CATEGORY
  String _formatPublicationDate(dynamic rawDate) {
    if (rawDate == null) return "Recent";
    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return "Recent";
    return DateFormat('dd MMM yyyy').format(parsed.toLocal());
  }

  Future<void> _generateCategoryPdf(List<Map<String, dynamic>> docs) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    // Process items in chunks (for large exports, we split into multiple pages smoothly)
    final pdfDocs = docs;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Literary Archive - ${_selectedFilterCategory.toUpperCase()}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo800,
                    ),
                  ),
                  pw.Text(
                    dateStr,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Generate list of works
            ...pdfDocs.map((data) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      data['title']?.toString() ?? "Untitled",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "By ${data['author_name'] ?? 'Admin'}",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    ...buildPdfTextBlocks(data['content']?.toString() ?? ""),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    String fileNameCat = _selectedFilterCategory.replaceAll(" ", "_");
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Literary_Works_${fileNameCat}_$dateStr.pdf',
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> currentData) {
    final TextEditingController editTitle = TextEditingController(
      text: currentData['title'],
    );
    final TextEditingController editAuthor = TextEditingController(
      text: currentData['author_name'],
    );
    final TextEditingController editContent = TextEditingController(
      text: currentData['content'],
    );
    String editCategory = currentData['category'] ?? "Poetry";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _HubColors.border),
          ),
          title: const Text(
            "Edit Publication",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: editCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setModalState(() => editCategory = val!),
                  decoration: const InputDecoration(
                    labelText: "Update Category",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: editTitle,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: editAuthor,
                  decoration: const InputDecoration(
                    labelText: "Author",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: editContent,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: "Content",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _HubColors.brandPrimary,
              ),
              onPressed: () async {
                await _publicationsRepository.updatePublication(
                  id: docId,
                  title: editTitle.text.trim(),
                  content: editContent.text.trim(),
                  category: editCategory,
                  authorName: editAuthor.text.trim().isEmpty
                      ? 'Admin'
                      : editAuthor.text.trim(),
                );
                if (context.mounted) {
                  if (mounted) setState(() => _publicationsRefreshKey++);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Publication Updated!"),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
              child: const Text(
                "Save Changes",
                style: TextStyle(color: _HubColors.accentGold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteWork(String docId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        var isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Delete Work?"),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        final deleted = await _deletePublication(docId);
                        if (deleted && dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        } else if (dialogContext.mounted) {
                          setDialogState(() => isDeleting = false);
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _deletePublication(String docId) async {
    if (_deletingPublicationIds.contains(docId)) return false;
    setState(() => _deletingPublicationIds.add(docId));

    try {
      await _publicationsRepository.deletePublication(docId);
      if (!mounted) return true;
      setState(() {
        _deletedPublicationIds.add(docId);
        _deletingPublicationIds.remove(docId);
        _publicationsRefreshKey++;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Publication deleted")));
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _deletingPublicationIds.remove(docId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      return false;
    }
  }

  // --- TAB 3: APPROVALS LOGIC (With Tap-to-View Dialog) ---
  Widget _buildRequestsPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('literary_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No pending submissions."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data();
            final String docId = snapshot.data!.docs[index].id;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: _HubColors.border),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () =>
                    _showRequestDetailDialog(data, docId), // TAP TO VIEW LOGIC
                leading: const CircleAvatar(
                  backgroundColor: _HubColors.background,
                  child: Icon(
                    Icons.person_outline,
                    color: _HubColors.accentIndigo,
                  ),
                ),
                title: Text(
                  data['title'] ?? "Untitled",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  "By ${data['author'] ?? 'Student'} • ${data['category']}",
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: _HubColors.textLight,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRequestDetailDialog(Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Review Submission",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TITLE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _HubColors.textLight,
                ),
              ),
              Text(
                data['title'] ?? "Untitled",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _HubColors.textMain,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "AUTHOR (WHO WROTE IT)",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _HubColors.textLight,
                ),
              ),
              Text(
                data['author'] ?? "Unknown",
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "CONTENT",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _HubColors.textLight,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                data['content'] ?? "Empty content.",
                style: const TextStyle(height: 1.5, color: _HubColors.textMain),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _handleAdminDecision(docId, false, null);
              Navigator.pop(context);
            },
            child: const Text(
              "REJECT",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _HubColors.emerald,
            ),
            onPressed: () {
              _handleAdminDecision(docId, true, data);
              Navigator.pop(context);
            },
            child: const Text(
              "APPROVE & PUBLISH",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAdminDecision(
    String requestDocId,
    bool approve,
    Map<String, dynamic>? data,
  ) async {
    try {
      if (approve && data != null) {
        await _publicationsRepository.createPublication(
          committeeName: _committeeName,
          title: data['title']?.toString() ?? 'Untitled',
          content: data['content']?.toString() ?? '',
          category: data['category']?.toString() ?? 'Poetry',
          authorName: data['author']?.toString() ?? 'Student',
        );
        if (mounted) setState(() => _publicationsRefreshKey++);
      }
      // Update the request status so the student can track whether it was accepted or rejected!
      await FirebaseFirestore.instance
          .collection('literary_requests')
          .doc(requestDocId)
          .update({'status': approve ? 'published' : 'rejected'});

      // 🟢 Send Push Notification to the Student's Home Page
      if (data != null &&
          data['studentID'] != null &&
          data['studentID'].toString().isNotEmpty) {
        String title = approve
            ? "Literary Submission Approved! 🎉"
            : "Literary Submission Update";
        String message = approve
            ? "Your piece '${data['title']}' has been officially pushed to the Literary Hub!"
            : "Your piece '${data['title']}' was reviewed but not published.";

        await FirebaseFirestore.instance.collection('notifications').add({
          'studentID': data['studentID'],
          'title': title,
          'message': message,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Widget _buildLibraryCategoryFilter() {
    final List<String> filterCats = ["All", ..._categories];
    return Container(
      height: 60,
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filterCats.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedFilterCategory == filterCats[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(filterCats[index]),
                    selected: isSelected,
                    onSelected: (val) => setState(
                      () => _selectedFilterCategory = filterCats[index],
                    ),
                    selectedColor: _HubColors.brandPrimary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? _HubColors.accentGold
                          : _HubColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            tooltip: "Download PDF of $_selectedFilterCategory",
            onPressed: () async {
              try {
                final publications = await _publicationsRepository
                    .fetchPublications(committeeName: _committeeName);
                final docs = publications.where((doc) {
                  return _selectedFilterCategory == 'All' ||
                      doc['category'] == _selectedFilterCategory;
                }).toList();

                if (docs.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "No publications found for this category.",
                        ),
                      ),
                    );
                  }
                  return;
                }
                _generateCategoryPdf(docs);
              } catch (e) {
                debugPrint("Error generating PDF: $e");
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  void _showManagementOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.video_call, color: _HubColors.rose),
            title: const Text("Upload Reel"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => const ReelUploadPage(committeeName: "Literary"),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event, color: _HubColors.accentIndigo),
            title: const Text("Events"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) =>
                    const EventManagementPage(initialCommittee: "Library"),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.campaign, color: _HubColors.emerald),
            title: const Text("PRD Request Desk"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                // 🟢 THE FIX: Passed "Literary" so it locks perfectly!
                builder: (c) =>
                    const PrdRequestDeskPage(initialCommittee: "Literary"),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.stars, color: _HubColors.accentGold),
            title: const Text("Prizes"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) =>
                    const AdminCommitteeDashboard(initialCommittee: "Library"),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
