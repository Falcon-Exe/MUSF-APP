import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:intl/intl.dart';
import '../features/literary/data/repositories/supabase_publications_repository.dart';
import 'student_notification_badge.dart';

// --- Executive Literary Theme (Midnight & Gold) ---
class _HubColors {
  static const Color brandPrimary = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFC5A059);
  static const Color metallicShine = Colors.white; // Centered shine highlight
  static const Color lightGoldPlate = Color(
    0xFFFBF4E6,
  ); // Content Plate background
  static const Color background = Color(0xFFF1F5F9);
  static const Color textMain = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color rose = Color(0xFFEF4444);
}

class LiteraryStudentPage extends StatefulWidget {
  const LiteraryStudentPage({super.key});

  @override
  State<LiteraryStudentPage> createState() => _LiteraryStudentPageState();
}

class _LiteraryStudentPageState extends State<LiteraryStudentPage> {
  static const String _committeeName = 'Literary';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabasePublicationsRepository _publicationsRepository =
      SupabasePublicationsRepository();
  String _selectedCategory = 'All';
  int _bottomNavIndex = 0;
  int _publicationsRefreshKey = 0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController =
      TextEditingController(); // 🟢 NEW: For receiving Admin Notifications
  final TextEditingController _contentController = TextEditingController();
  String _submittingCategory = "Poetry";

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _studentIdController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // UI WRAPPER: Golden Plate Frame with Centered White Shine
  // ===========================================================================
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
          colors: [
            _HubColors.accentGold,
            _HubColors.metallicShine, // White Shine in center
            _HubColors.accentGold,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.3, 0.5, 0.7], // Locks white shine to the center line
        ),
        boxShadow: [
          BoxShadow(
            color: _HubColors.accentGold.withValues(alpha: 0.25),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          // Dialog uses the golden parchment color, cards use white
          color: isDialog ? _HubColors.lightGoldPlate : Colors.white,
          borderRadius: BorderRadius.circular(radius - 2),
        ),
        child: child,
      ),
    );
  }

  // ===========================================================================
  // SUBMISSION LOGIC: Dialog is now a Full Golden Plate
  // ===========================================================================
  void _showSubmitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: _goldenPlateFrame(
            isDialog: true, // Applies the golden parchment background
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
                          color: _HubColors.brandPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(color: _HubColors.accentGold, thickness: 1),
                  Expanded(
                    child: ListView(
                      children: [
                        const SizedBox(height: 15),
                        _buildSubmissionField(
                          _titleController,
                          "Masterpiece Title",
                        ),
                        const SizedBox(height: 15),
                        _buildSubmissionField(_nameController, "Your Pen Name"),
                        const SizedBox(height: 15),
                        _buildSubmissionField(
                          _studentIdController,
                          "Your Official Student ID (e.g. 17208)",
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          initialValue: _submittingCategory,
                          dropdownColor: _HubColors.lightGoldPlate,
                          decoration: _submissionInputDecoration("Category"),
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
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setSheetState(() => _submittingCategory = val!),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _contentController,
                          maxLines: 12,
                          decoration: _submissionInputDecoration(
                            "Write your content here...",
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Borderless button - focus is on the Gold Plate Dialog Frame
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _HubColors.brandPrimary,
                              elevation: 0, // No extra shadow to keep it clean
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: _submitToAdmin,
                            child: const Text(
                              "SEND TO UNION",
                              style: TextStyle(
                                color: _HubColors.accentGold,
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

  Widget _buildSubmissionField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: _submissionInputDecoration(hint),
    );
  }

  InputDecoration _submissionInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withValues(
        alpha: 0.5,
      ), // Semi-transparent to let the gold tint peek through
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

  // ===========================================================================
  // DATA ACTIONS
  // ===========================================================================
  Future<void> _submitToAdmin() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _studentIdController.text.isEmpty) {
      return;
    }
    if (!context.mounted) return;
    final navigator = Navigator.of(context);

    await FirebaseFirestore.instance.collection('literary_requests').add({
      'title': _titleController.text.trim(),
      'author': _nameController.text.trim(),
      'studentID': _studentIdController.text
          .trim(), // 🟢 Save this to target the push notification!
      'content': _contentController.text.trim(),
      'category': _submittingCategory,
      'authorId': supabase.Supabase.instance.client.auth.currentUser?.id,
      'status': 'pending',
      'date': FieldValue.serverTimestamp(),
    });

    _titleController.clear();
    _contentController.clear();
    _nameController.clear();
    _studentIdController.clear();
    navigator.pop();
  }

  Future<void> _incrementLike(String docId, int currentLikes) async {
    final uid = supabase.Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    await _publicationsRepository.updateLikeCount(
      id: docId,
      likesCount: currentLikes + 1,
    );
    if (mounted) setState(() => _publicationsRefreshKey++);
  }

  // ===========================================================================
  // MAIN SCAFFOLD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _HubColors.background,
      appBar: AppBar(
        backgroundColor: _HubColors.brandPrimary,
        elevation: 0,
        title: const Text(
          "LITERARY HUB",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          StudentNotificationBadge(
            committeeName: "Literary",
            themeColor: Color(0xFF0891B2),
          ),
          SizedBox(width: 10),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        selectedItemColor: _HubColors.brandPrimary,
        onTap: (i) => setState(() => _bottomNavIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories_rounded),
            label: "Library",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu_rounded),
            label: "My Status",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitSheet,
        backgroundColor: _HubColors.brandPrimary,
        icon: const Icon(Icons.edit_note_rounded, color: _HubColors.accentGold),
        label: const Text(
          "Write",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _bottomNavIndex == 0 ? _buildLibraryTab() : _buildStatusTab(),
    );
  }

  Widget _buildLibraryTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
          child: Text(
            "Archive Collection",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _HubColors.brandPrimary,
            ),
          ),
        ),
        _buildFilters(),
        Expanded(child: _buildRealTimeFeed()),
      ],
    );
  }

  Widget _buildStatusTab() {
    final uid = supabase.Supabase.instance.client.auth.currentUser?.id;
    return StreamBuilder<QuerySnapshot>(
      // 🟢 FIX: Removed orderBy('date') because it requires a Firestore composite index alongside where('authorId')
      stream: FirebaseFirestore.instance
          .collection('literary_requests')
          .where('authorId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🟢 FIX: Sort locally to avoid Firebase Index errors!
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          Timestamp dateA =
              (a.data() as Map<String, dynamic>)['date'] ?? Timestamp.now();
          Timestamp dateB =
              (b.data() as Map<String, dynamic>)['date'] ?? Timestamp.now();
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String docId = docs[index].id;
            String status = data['status'] ?? 'pending';
            Color statusColor = status == 'rejected'
                ? Colors.red
                : (status == 'published' ? Colors.green : Colors.orange);

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _goldenPlateFrame(
                radius: 12,
                child: ListTile(
                  title: Text(
                    data['title'] ?? "Untitled",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Author: ${data['author']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => FirebaseFirestore.instance
                            .collection('literary_requests')
                            .doc(docId)
                            .delete(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRealTimeFeed() {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
        final filteredDocs = (snapshot.data ?? [])
            .where(
              (publication) =>
                  _selectedCategory == 'All' ||
                  publication['category'] == _selectedCategory,
            )
            .toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text("No publications found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index];
            final String docId = data['id']?.toString() ?? '';
            final int likesCount =
                int.tryParse(data['likes_count']?.toString() ?? '') ?? 0;
            final String dateStr = _formatPublicationDate(data['created_at']);

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _goldenPlateFrame(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['category'].toString().toUpperCase(),
                            style: const TextStyle(
                              color: _HubColors.accentGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: _HubColors.textLight,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data['title'] ?? "",
                        style: const TextStyle(
                          fontSize: 22,
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
                        data['content'] ?? "",
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          height: 1.4,
                          color: _HubColors.textMain,
                        ),
                      ),
                      const Divider(height: 30),
                      Row(
                        children: [
                          IconButton(
                            onPressed: docId.isEmpty
                                ? null
                                : () => _incrementLike(docId, likesCount),
                            icon: const Icon(
                              Icons.favorite_border,
                              color: _HubColors.rose,
                            ),
                          ),
                          Text(
                            "$likesCount",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _showFull(data),
                            child: const Text(
                              "READ FULL TEXT",
                              style: TextStyle(
                                color: _HubColors.brandPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFull(Map data) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          data['title'] ?? "Work",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            data['content'] ?? "",
            style: const TextStyle(height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  String _formatPublicationDate(dynamic rawDate) {
    if (rawDate == null) return "Recent";
    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return "Recent";
    return DateFormat('dd MMM').format(parsed.toLocal());
  }

  Widget _buildFilters() {
    final List<String> cats = [
      "All",
      "Poetry",
      "Story",
      "Mini Story",
      "Essay",
      "Report",
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: cats
            .map(
              (cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: _selectedCategory == cat
                          ? Colors.white
                          : _HubColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: _selectedCategory == cat,
                  onSelected: (v) => setState(() => _selectedCategory = cat),
                  selectedColor: _HubColors.brandPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
