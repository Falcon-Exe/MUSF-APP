import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class UnionPortalHomePage extends StatefulWidget {
  const UnionPortalHomePage({super.key});

  @override
  State<UnionPortalHomePage> createState() => _UnionPortalHomePageState();
}

class _UnionPortalHomePageState extends State<UnionPortalHomePage> {
  late Future<List<UnionMember>> _membersFuture;

  static const Set<String> _executiveRoles = {
    'chairman',
    'general secretary',
    'treasurer',
    'cuc',
    'vice president',
    'joint secretary',
    'president',
    'secretary',
  };

  static const List<CommitteeInfo> _committees = [
    CommitteeInfo(
      title: 'Library Committee',
      icon: Icons.menu_book,
      objective: 'Manage library resources and promote reading culture.',
    ),
    CommitteeInfo(
      title: 'Literary Committee',
      icon: Icons.edit_note,
      objective: 'Organize writing workshops and annual publications.',
    ),
    CommitteeInfo(
      title: 'Fine Arts Committee',
      icon: Icons.palette,
      objective: 'Nurturing artistic talent through exhibitions.',
    ),
    CommitteeInfo(
      title: 'Social Affairs',
      icon: Icons.diversity_3,
      objective: 'Addressing social concerns and outreach programs.',
    ),
    CommitteeInfo(
      title: 'Bank Committee',
      icon: Icons.savings,
      objective: 'Managing welfare funds and financial literacy.',
    ),
    CommitteeInfo(
      title: 'Research Committee',
      icon: Icons.science,
      objective: 'Spearheading data collection and academic surveys.',
    ),
    CommitteeInfo(
      title: 'PRD Committee',
      icon: Icons.campaign,
      objective: "Maintaining the union's brand and digital presence.",
    ),
    CommitteeInfo(
      title: 'Garden Committee',
      icon: Icons.energy_savings_leaf,
      objective: 'Beautification and sustainable environment practices.',
    ),
    CommitteeInfo(
      title: 'Medical Committee',
      icon: Icons.medical_services,
      objective: 'Supporting student health and medical assistance.',
    ),
    CommitteeInfo(
      title: 'Sports Committee',
      icon: Icons.emoji_events,
      objective: 'Organizing meets and managing facilities.',
    ),
    CommitteeInfo(
      title: 'Store Committee',
      icon: Icons.shopping_bag,
      objective: 'Overseeing cooperative store and fair pricing.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _membersFuture = _fetchUnionMembers();
  }

  Future<List<UnionMember>> _fetchUnionMembers() async {
    final rows = await supabase.Supabase.instance.client
        .from('students')
        .select(
          'full_name,student_id,designation,assigned_role,role_description,profile_image_url,committee_name',
        )
        .order('full_name');

    final members = List<Map<String, dynamic>>.from(
      rows,
    ).map(UnionMember.fromRow).where((member) => member.hasAssignment).toList();
    return members;
  }

  Future<void> _refresh() async {
    setState(() => _membersFuture = _fetchUnionMembers());
    await _membersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<List<UnionMember>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final members = snapshot.data ?? const <UnionMember>[];
          final executives = members
              .where((member) => _isExecutive(member))
              .toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                _buildHeader(),
                if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildCenteredMessage(
                      'Could not load union members: ${snapshot.error}',
                    ),
                  )
                else if (isLoading && members.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildSectionHeader(
                        'Executive Committee',
                        executives.isEmpty
                            ? 'No members assigned yet.'
                            : '${executives.length} members leading the vision',
                      ),
                    ),
                  ),
                  if (executives.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildEmptyCard(),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              childAspectRatio: 0.74,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              ExecutiveCard(member: executives[index]),
                          childCount: executives.length,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildSectionHeader(
                        'Sub Committees',
                        'Assigned coordinators and members',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final committee = _committees[index];
                        final committeeMembers = members
                            .where(
                              (member) =>
                                  !_isExecutive(member) &&
                                  _matchesCommittee(member, committee.title),
                            )
                            .toList();
                        return CommitteeListItem(
                          committee: committee,
                          members: committeeMembers,
                        );
                      }, childCount: _committees.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1E3A8A),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Union Executive Portal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.account_balance,
                      size: 50,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Dedicated to excellence, service, and the representation of our community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        ),
        Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCenteredMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.blueGrey),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        'No members assigned yet.',
        style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
      ),
    );
  }

  bool _isExecutive(UnionMember member) {
    return member.roleCandidates.any(
      (role) => _executiveRoles.contains(_normalize(role)),
    );
  }

  bool _matchesCommittee(UnionMember member, String committeeName) {
    final normalizedCommittee = _normalize(committeeName);
    if (_normalize(member.committeeName) == normalizedCommittee) return true;

    final role = _normalize(member.roleCandidates.join(' '));
    final committeeKeyword = normalizedCommittee
        .replaceAll(' committee', '')
        .trim();
    if (committeeKeyword.isEmpty) return false;
    if (role.contains(committeeKeyword)) return true;
    if (committeeKeyword == 'prd' && role.contains('public relations')) {
      return true;
    }
    if (committeeKeyword == 'bank' && role.contains('bank manager')) {
      return true;
    }
    return false;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class UnionMember {
  final String name;
  final String designation;
  final String assignedRole;
  final String role;
  final String description;
  final String photoUrl;
  final String committeeName;

  const UnionMember({
    required this.name,
    required this.designation,
    required this.assignedRole,
    required this.role,
    required this.description,
    required this.photoUrl,
    required this.committeeName,
  });

  factory UnionMember.fromRow(Map<String, dynamic> row) {
    final designation = _value(row['designation']);
    final assignedRole = _value(row['assigned_role']);
    final role = designation.isNotEmpty ? designation : assignedRole;
    return UnionMember(
      name: _value(row['full_name'], fallback: 'Unknown Student'),
      designation: designation,
      assignedRole: assignedRole,
      role: role,
      description: _value(row['role_description']),
      photoUrl: _value(row['profile_image_url']),
      committeeName: _committeeValue(row['committee_name']),
    );
  }

  bool get hasAssignment => role.isNotEmpty || committeeName.isNotEmpty;

  List<String> get roleCandidates => [
    designation,
    assignedRole,
    role,
  ].where((value) => value.trim().isNotEmpty).toList();

  static String _value(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _committeeValue(dynamic value) {
    final text = _value(value);
    return text.toLowerCase() == 'none' ? '' : text;
  }
}

class CommitteeInfo {
  final String title;
  final String objective;
  final IconData icon;

  const CommitteeInfo({
    required this.title,
    required this.objective,
    required this.icon,
  });
}

class ExecutiveCard extends StatelessWidget {
  final UnionMember member;
  const ExecutiveCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UnionAvatar(member: member, radius: 35),
          const SizedBox(height: 10),
          Text(
            member.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            member.role.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.bold,
              fontSize: 9,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              member.description.isEmpty
                  ? 'No description provided.'
                  : member.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class CommitteeListItem extends StatelessWidget {
  final CommitteeInfo committee;
  final List<UnionMember> members;
  const CommitteeListItem({
    super.key,
    required this.committee,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(committee.icon, color: const Color(0xFF3B82F6)),
        ),
        title: Text(
          committee.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          members.isEmpty
              ? 'No members assigned yet.'
              : '${members.length} assigned member${members.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  committee.objective,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                if (members.isEmpty)
                  const Text(
                    'No members assigned yet.',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  ...members.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CommitteeMemberRow(member: member),
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

class CommitteeMemberRow extends StatelessWidget {
  final UnionMember member;
  const CommitteeMemberRow({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnionAvatar(member: member, radius: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                member.role.isEmpty ? 'Committee Member' : member.role,
                style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
              ),
              if (member.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    member.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 11,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class UnionAvatar extends StatelessWidget {
  final UnionMember member;
  final double radius;
  const UnionAvatar({super.key, required this.member, required this.radius});

  @override
  Widget build(BuildContext context) {
    final photoUrl = member.photoUrl;
    if (photoUrl.isEmpty) return _initialsAvatar();

    return ClipOval(
      child: Image.network(
        photoUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _initialsAvatar(),
      ),
    );
  }

  Widget _initialsAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEFF6FF),
      child: Text(
        _initials(member.name),
        style: TextStyle(
          color: const Color(0xFF1E40AF),
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.46,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}
