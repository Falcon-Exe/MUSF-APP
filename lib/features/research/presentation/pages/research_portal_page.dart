// lib/features/research/presentation/pages/research_portal_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../home/student_notification_badge.dart';
import '../../logic/research_controller.dart';
import '../widgets/research_theme.dart';
import '../widgets/research_paper_card.dart';
import '../widgets/research_submission_dialog.dart';
import 'my_submissions_page.dart';

class ResearchPortalPage extends StatefulWidget {
  const ResearchPortalPage({super.key});

  @override
  State<ResearchPortalPage> createState() => _ResearchPortalPageState();
}

class _ResearchPortalPageState extends State<ResearchPortalPage> {
  static const String _committeeName = 'Research';
  final ResearchController _controller = ResearchController();
  final int _publicationsRefreshKey = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchPublishedPapers() async {
    final response = await supabase.Supabase.instance.client
        .from('research_works')
        .select()
        .eq('status', 'published');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: ResearchTheme.background,
      appBar: _buildHeader(context),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ResearchTheme.brandPrimary,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                ResearchSubmissionDialog(controller: _controller),
          );
        },
        icon: const Icon(
          Icons.upload_file_rounded,
          color: ResearchTheme.accentGold,
        ),
        label: const Text(
          "Submit Paper",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: 32,
            horizontal: isDesktop
                ? MediaQuery.of(context).size.width * 0.12
                : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 32),
              _buildSearchAndFilters(),
              const SizedBox(height: 48),
              _buildSectionTitle(),
              const SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey('$_committeeName-$_publicationsRefreshKey'),
                future: _fetchPublishedPapers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: ResearchTheme.brandPrimary,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || (snapshot.data ?? []).isEmpty) {
                    return _buildEmptyState(
                      "No published research available yet.",
                    );
                  }

                  final publications = snapshot.data ?? [];
                  if (publications.isEmpty) {
                    return _buildEmptyState(
                      "No published research available yet.",
                    );
                  }

                  final docs = publications.where((publication) {
                    final data = _publicationToResearchData(publication);
                    final title = (data['title'] ?? '')
                        .toString()
                        .toLowerCase();
                    final author = (data['author'] ?? '')
                        .toString()
                        .toLowerCase();
                    final category = (data['field'] ?? 'Science').toString();

                    final matchesCat =
                        _controller.selectedCategory == 'All' ||
                        category == _controller.selectedCategory;
                    final matchesSearch =
                        title.contains(_controller.searchQuery.toLowerCase()) ||
                        author.contains(_controller.searchQuery.toLowerCase());

                    return matchesCat && matchesSearch;
                  }).toList();

                  if (docs.isEmpty) {
                    return _buildEmptyState(
                      "No papers match your search criteria.",
                    );
                  }

                  return Column(
                    children: docs.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final publication = entry.value;
                      final docId = publication['id']?.toString() ?? '';
                      final data = _publicationToResearchData(publication);
                      return AnimatedEntrance(
                        delay: 100 * idx,
                        child: ResearchPaperCard(
                          docId: docId,
                          data: data,
                          controller: _controller,
                          onLike:
                              null, // research_works does not track likes here
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _publicationToResearchData(Map<String, dynamic> data) {
    final desc = data['description']?.toString() ?? '';
    final regExp = RegExp(r'^\[(.*?)\] (.*)$');
    final match = regExp.firstMatch(desc);
    final category =
        data['category']?.toString() ??
        (match != null ? match.group(1) : 'General');
    final abstractText = match != null ? match.group(2) : desc;

    return {
      ...data,
      'title': data['title'],
      'author': data['author_name'] ?? 'Unknown',
      'abstract': abstractText,
      'field': category,
      'likes': 0,
      'date': _parsePublicationDate(data['created_at']),
    };
  }

  DateTime _parsePublicationDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: ResearchTheme.brandPrimary,
      elevation: 0,
      toolbarHeight: 90,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white70,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "RESEARCH HUB",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 24,
            decoration: BoxDecoration(
              color: ResearchTheme.accentGold,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
      actions: [
        const StudentNotificationBadge(
          committeeName: "Research",
          themeColor: Color(0xFF0D9488),
        ),
        IconButton(
          icon: const Icon(
            Icons.assignment_ind_outlined,
            color: Colors.white70,
          ),
          tooltip: "My Submissions",
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MySubmissionsPage(controller: _controller),
            ),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Principal Researcher",
          style: TextStyle(
            color: ResearchTheme.accentGold,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Global Academic Archives",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: ResearchTheme.brandPrimary,
            letterSpacing: -1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: ResearchTheme.border),
          ),
          child: TextField(
            onChanged: _controller.updateSearch,
            decoration: const InputDecoration(
              hintText: "Search title or author...",
              hintStyle: TextStyle(
                color: ResearchTheme.textLight,
                fontSize: 14,
              ),
              icon: Icon(
                Icons.search_rounded,
                color: ResearchTheme.accentGold,
                size: 20,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children:
                [
                  'All',
                  'Science',
                  'Technology',
                  'Social',
                  'Literature',
                  'Arts',
                ].map((cat) {
                  final isSelected = _controller.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) => _controller.setCategory(cat),
                      selectedColor: ResearchTheme.brandPrimary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? ResearchTheme.brandPrimary
                            : ResearchTheme.brandPrimary.withValues(
                                alpha: 0.45,
                              ),
                        width: 1.1,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : ResearchTheme.brandPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Recent Submissions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: ResearchTheme.brandPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.library_books_outlined,
            size: 60,
            color: ResearchTheme.border,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: ResearchTheme.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
