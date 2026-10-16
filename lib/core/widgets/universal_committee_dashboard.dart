// lib/core/widgets/universal_committee_dashboard.dart

import 'package:flutter/material.dart';
import 'admin_shared_components.dart';
import '../../../../admin/event_management_page.dart';
import '../../../../features/reels/presentation/pages/reel_upload_page.dart';
import '../../../../admin/admin_committee_prize.dart';
import '../../../../admin/purchase_request_page.dart';
import '../../../../features/prd/presentation/pages/prd_request_desk_page.dart';
import '../../../../admin/treasurer_inbox_page.dart';
import '../theme/app_colors.dart';
import '../theme/committee_theme.dart';
import '../../../../features/leadership/presentation/widgets/executive_notices_section.dart';
import '../supabase/supabase_publications_repository.dart';
import '../../features/literary/presentation/widgets/publication_card.dart';

class CommitteeTabConfig {
  final String label;
  final IconData icon;
  final String key;
  final Widget content;

  CommitteeTabConfig({
    required this.label,
    required this.icon,
    required this.key,
    required this.content,
  });
}

class CommitteeSpecialFeature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? targetTabKey;

  CommitteeSpecialFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.targetTabKey,
  });
}

class UniversalCommitteeDashboard extends StatefulWidget {
  final String committeeName;
  final String? displayTitle;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<CommitteeTabConfig> extraTabs;
  final List<CommitteeSpecialFeature> specialFeatures;
  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onPdfDownload;
  final Widget? summaryRow;
  final Widget? customDashboard;
  final Color? themeColor;
  final String? initialTabKey;

  const UniversalCommitteeDashboard({
    super.key,
    required this.committeeName,
    this.displayTitle,
    this.subtitle,
    this.onBack,
    this.extraTabs = const [],
    this.specialFeatures = const [],
    this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.onPdfDownload,
    this.summaryRow,
    this.customDashboard,
    this.themeColor,
    this.initialTabKey,
  });

  @override
  State<UniversalCommitteeDashboard> createState() =>
      _UniversalCommitteeDashboardState();
}

class _UniversalCommitteeDashboardState
    extends State<UniversalCommitteeDashboard> {
  final SupabasePublicationsRepository _publicationsRepository =
      SupabasePublicationsRepository();
  final TextEditingController _publicationTitleController =
      TextEditingController();
  final TextEditingController _publicationAuthorController =
      TextEditingController();
  final TextEditingController _publicationContentController =
      TextEditingController();
  final TextEditingController _publicationCategoryController =
      TextEditingController(text: 'General');
  final TextEditingController _publicationImageUrlController =
      TextEditingController();
  late String _activeTabKey;
  late Future<List<Map<String, dynamic>>> _publicationsFuture;
  List<Map<String, dynamic>> publications = <Map<String, dynamic>>[];
  final Set<String> _deletingPublicationIds = <String>{};

  @override
  void initState() {
    super.initState();
    _activeTabKey = _initialTabKey();
    _publicationsFuture = _isLiteraryCommittee
        ? fetchPublications()
        : Future<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
  }

  @override
  void didUpdateWidget(covariant UniversalCommitteeDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.committeeName != widget.committeeName) {
      publications = <Map<String, dynamic>>[];
      _publicationsFuture = _isLiteraryCommittee
          ? fetchPublications()
          : Future<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
      _activeTabKey = _initialTabKey();
    }
  }

  @override
  void dispose() {
    _publicationTitleController.dispose();
    _publicationAuthorController.dispose();
    _publicationContentController.dispose();
    _publicationCategoryController.dispose();
    _publicationImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = getCommitteeTheme(widget.committeeName);
    final headerColor = widget.themeColor ?? theme.headerColor;

    return Scaffold(
      backgroundColor: CommitteeTheme.pageBackground,
      body: Column(
        children: [
          AdminCommitteeHeader(
            committeeName: widget.displayTitle ?? widget.committeeName,
            subtitle: widget.subtitle ?? "Command Center",
            onBack: widget.onBack ?? () => Navigator.pop(context),
            searchHint: widget.searchHint ?? _defaultSearchHint(),
            searchController: widget.searchController,
            onSearchChanged: (value) {
              widget.onSearchChanged?.call(value);
              setState(() {});
            },
            tabToggles: _buildTabToggles(theme),
            summaryRow: widget.summaryRow,
            headerColor: headerColor,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildActiveContent(),
            ),
          ),
        ],
      ),
    );
  }

  String _defaultSearchHint() {
    final name = widget.committeeName.toLowerCase();
    if (name.contains('literary')) return 'Search content...';
    if (name.contains('fine arts')) return 'Search events...';
    if (name.contains('social')) return 'Search works...';
    if (name.contains('store')) return 'Search items...';
    return 'Search records...';
  }

  Widget _buildTabToggles(CommitteeTheme theme) {
    final tabs = _allTabs();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...tabs.map(
              (tab) => _buildTabButton(tab.label, tab.icon, tab.key, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    IconData icon,
    String tabKey,
    CommitteeTheme theme,
  ) {
    bool active = _activeTabKey == tabKey;
    return GestureDetector(
      onTap: () => setState(() => _activeTabKey = tabKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: active ? AppColors.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? theme.headerColor : Colors.white38,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? theme.headerColor : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContent() {
    final tabs = _allTabs();
    if (tabs.isEmpty) {
      return widget.customDashboard ?? _buildDashboardTab();
    }

    final tab = tabs.firstWhere(
      (t) => t.key == _activeTabKey,
      orElse: () => tabs[0],
    );
    return tab.content;
  }

  List<CommitteeTabConfig> _allTabs() {
    final dashboardTab = CommitteeTabConfig(
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
      key: 'dashboard',
      content: widget.customDashboard ?? _buildDashboardTab(),
    );

    final tabs = <CommitteeTabConfig>[dashboardTab];

    if (_isLiteraryCommittee) {
      tabs.add(_extraTab('post') ?? _publicationPostTab());
      tabs.add(_extraTab('hub') ?? _publicationHubTab());
      tabs.addAll(
        widget.extraTabs.where(
          (t) => t.key != 'post' && t.key != 'hub' && t.key != 'requests',
        ),
      );
    } else {
      tabs.addAll(widget.extraTabs.where((t) => t.key != 'requests'));
    }

    return tabs;
  }

  String _initialTabKey() {
    final requestedTabKey = widget.initialTabKey;
    if (requestedTabKey != null && _hasTabKey(requestedTabKey)) {
      return requestedTabKey;
    }
    return 'dashboard';
  }

  bool _hasTabKey(String key) {
    if (key == 'dashboard') return true;
    if (_isLiteraryCommittee && (key == 'post' || key == 'hub')) return true;
    return widget.extraTabs.any((tab) => tab.key == key);
  }

  String get _committeeKey => widget.committeeName.toLowerCase().trim();

  bool get _isLiteraryCommittee => _committeeKey == 'literary';

  CommitteeTabConfig? _extraTab(String key) {
    for (final tab in widget.extraTabs) {
      if (tab.key == key) return tab;
    }
    return null;
  }

  CommitteeTabConfig _publicationPostTab() {
    return CommitteeTabConfig(
      label: 'Post',
      icon: Icons.post_add_rounded,
      key: 'post',
      content: _buildPublicationPostTab(),
    );
  }

  CommitteeTabConfig _publicationHubTab() {
    return CommitteeTabConfig(
      label: 'Hub',
      icon: Icons.hub_rounded,
      key: 'hub',
      content: _buildPublicationHubTab(),
    );
  }

  Widget _buildPublicationPostTab() {
    final theme = getCommitteeTheme(widget.committeeName);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionTitle(title: "ADD PUBLICATION", color: theme.accentColor),
          const SizedBox(height: 18),
          _buildPublicationInput(
            controller: _publicationTitleController,
            label: "Title",
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 14),
          _buildPublicationInput(
            controller: _publicationAuthorController,
            label: "Author Name",
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          _buildPublicationInput(
            controller: _publicationCategoryController,
            label: "Category",
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 14),
          _buildPublicationInput(
            controller: _publicationImageUrlController,
            label: "Image URL",
            icon: Icons.image_outlined,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _publicationContentController,
            minLines: 7,
            maxLines: 12,
            decoration: _publicationInputDecoration(
              label: "Content",
              icon: Icons.notes_rounded,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _createPublication,
              icon: const Icon(Icons.publish_rounded),
              label: const Text(
                "PUBLISH",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.headerColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicationInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: _publicationInputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _publicationInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: CommitteeTheme.textMuted),
      filled: true,
      fillColor: AppColors.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: CommitteeTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: getCommitteeTheme(widget.committeeName).accentColor,
        ),
      ),
    );
  }

  Future<void> _createPublication() async {
    final title = _publicationTitleController.text.trim();
    final content = _publicationContentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and content are required.")),
      );
      return;
    }

    await _publicationsRepository.createPublication(
      committeeName: widget.committeeName,
      title: title,
      content: content,
      category: _publicationCategoryController.text.trim().isEmpty
          ? 'General'
          : _publicationCategoryController.text.trim(),
      authorName: _publicationAuthorController.text.trim().isEmpty
          ? 'Admin'
          : _publicationAuthorController.text.trim(),
      imageUrl: _publicationImageUrlController.text.trim().isEmpty
          ? null
          : _publicationImageUrlController.text.trim(),
    );

    _publicationTitleController.clear();
    _publicationAuthorController.clear();
    _publicationContentController.clear();
    _publicationImageUrlController.clear();
    _publicationCategoryController.text = 'General';

    if (!mounted) return;
    setState(() {
      _activeTabKey = 'hub';
      _publicationsFuture = fetchPublications();
    });
  }

  Future<List<Map<String, dynamic>>> fetchPublications() async {
    final rows = await _publicationsRepository.fetchPublications(
      committeeName: widget.committeeName,
    );
    publications = List<Map<String, dynamic>>.from(rows);
    return publications;
  }

  Widget _buildPublicationHubTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _publicationsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text("Could not load publications: ${snapshot.error}"),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final searchQuery =
            widget.searchController?.text.trim().toLowerCase() ?? '';
        final visiblePublications = (snapshot.data ?? publications).where((
          publication,
        ) {
          if (searchQuery.isEmpty) return true;
          final title = (publication['title'] ?? '').toString().toLowerCase();
          final author = (publication['author_name'] ?? '')
              .toString()
              .toLowerCase();
          final category = (publication['category'] ?? '')
              .toString()
              .toLowerCase();
          return title.contains(searchQuery) ||
              author.contains(searchQuery) ||
              category.contains(searchQuery);
        }).toList();

        if (visiblePublications.isEmpty) {
          return const Center(child: Text("No Publications Found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 50),
          itemCount: visiblePublications.length,
          itemBuilder: (context, index) {
            final data = visiblePublications[index];
            final docId = data['id']?.toString() ?? '';
            final likesCount =
                int.tryParse(data['likes_count']?.toString() ?? '') ?? 0;
            return PublicationCard(
              title: data['title']?.toString() ?? '',
              author: data['author_name']?.toString() ?? 'Admin',
              category: data['category']?.toString() ?? 'General',
              content: data['content']?.toString() ?? '',
              date: _parsePublicationDate(data['created_at']),
              likesCount: likesCount,
              isLiked: false,
              onLike: docId.isEmpty
                  ? () {}
                  : () => _updatePublicationLikes(docId, likesCount + 1),
              onReadFull: () => _showPublicationDialog(data),
              onDelete: docId.isEmpty
                  ? null
                  : () => _showPublicationDeleteConfirm(docId),
            );
          },
        );
      },
    );
  }

  Future<void> _updatePublicationLikes(String docId, int likesCount) async {
    await _publicationsRepository.updateLikeCount(
      id: docId,
      likesCount: likesCount,
    );
    if (!mounted) return;
    setState(() => _publicationsFuture = fetchPublications());
  }

  void _showPublicationDeleteConfirm(String docId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Publication"),
          content: const Text("Permanently delete this publication?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _deletePublication(docId, dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePublication(
    String publicationId,
    BuildContext dialogContext,
  ) async {
    if (_deletingPublicationIds.contains(publicationId)) return;

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }

    setState(() {
      _deletingPublicationIds.add(publicationId);
      publications.removeWhere(
        (item) => item['id']?.toString() == publicationId,
      );
      _publicationsFuture = Future<List<Map<String, dynamic>>>.value(
        List<Map<String, dynamic>>.from(publications),
      );
    });

    try {
      await _publicationsRepository.deletePublication(publicationId);
      if (!mounted) return;

      setState(() {
        _deletingPublicationIds.remove(publicationId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Publication deleted")));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deletingPublicationIds.remove(publicationId);
        _publicationsFuture = fetchPublications();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  void _showPublicationDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['title']?.toString() ?? 'Untitled',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: getCommitteeTheme(
                          widget.committeeName,
                        ).headerColor,
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
                "By ${data['author_name'] ?? 'Admin'} | ${data['category'] ?? 'General'}",
                style: TextStyle(
                  color: getCommitteeTheme(widget.committeeName).accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Divider(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    data['content']?.toString() ?? '',
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

  DateTime _parsePublicationDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  Widget _buildDashboardTab() {
    final theme = getCommitteeTheme(widget.committeeName);
    final dashboardTitle = widget.displayTitle ?? widget.committeeName;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          ExecutiveNoticesSection(committeeName: widget.committeeName),
          AdminSectionTitle(title: "CORE TOOLS", color: theme.accentColor),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: [
              AdminCoreToolCard(
                icon: Icons.event_available_rounded,
                label: "Events",
                subtitle: "Manage events",
                color: theme.accentColor,
                iconBackgroundColor: theme.lightColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventManagementPage(
                      initialCommittee: widget.committeeName,
                    ),
                  ),
                ),
              ),
              AdminCoreToolCard(
                icon: Icons.video_collection_rounded,
                label: "Reel Upload",
                subtitle: "Upload media",
                color: theme.accentColor,
                iconBackgroundColor: theme.lightColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReelUploadPage(committeeName: widget.committeeName),
                  ),
                ),
              ),
              AdminCoreToolCard(
                icon: Icons.emoji_events_rounded,
                label: "Prizes",
                subtitle: "Winners & rankings",
                color: theme.accentColor,
                iconBackgroundColor: theme.lightColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminCommitteeDashboard(
                      initialCommittee: widget.committeeName,
                    ),
                  ),
                ),
              ),
              if (widget.committeeName == "Treasurer")
                AdminCoreToolCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: "Fund Approval",
                  subtitle: "Approve or reject requests",
                  color: theme.accentColor,
                  iconBackgroundColor: theme.lightColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TreasurerInboxPage(),
                    ),
                  ),
                ),
            ],
          ),

          if (widget.specialFeatures.isNotEmpty) ...[
            const SizedBox(height: 35),
            AdminSectionTitle(
              title: "SPECIAL FEATURES",
              color: theme.accentColor,
            ),
            const SizedBox(height: 18),
            ...widget.specialFeatures.map(
              (feat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminSupportToolCard(
                  icon: feat.icon,
                  title: feat.title,
                  subtitle: feat.subtitle,
                  color: theme.accentColor,
                  iconBackgroundColor: theme.lightColor,
                  onTap: () => _openSpecialFeature(feat),
                ),
              ),
            ),
          ],

          const SizedBox(height: 35),
          AdminSectionTitle(title: "SUPPORT TOOLS", color: theme.accentColor),
          const SizedBox(height: 18),
          AdminSupportToolCard(
            icon: Icons.design_services_rounded,
            title: "PRD Request",
            subtitle: "Submit designs & posters",
            color: theme.accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PrdRequestDeskPage(initialCommittee: widget.committeeName),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.committeeName != "Treasurer") ...[
            AdminSupportToolCard(
              icon: Icons.account_balance_wallet_rounded,
              title: "Fund Request",
              subtitle: "Request fund from Treasurer",
              color: theme.accentColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PurchaseRequestPage(committeeName: widget.committeeName),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.onPdfDownload != null) ...[
            const SizedBox(height: 12),
            AdminSupportToolCard(
              icon: Icons.picture_as_pdf_rounded,
              title: "$dashboardTitle PDF",
              subtitle: "Generate $dashboardTitle report",
              color: theme.accentColor,
              onTap: widget.onPdfDownload!,
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _openSpecialFeature(CommitteeSpecialFeature feature) {
    final targetTabKey = feature.targetTabKey;
    if (targetTabKey != null) {
      final canOpen = _allTabs().any((tab) => tab.key == targetTabKey);
      if (canOpen) {
        setState(() => _activeTabKey = targetTabKey);
        return;
      }
    }

    feature.onTap?.call();
  }
}
