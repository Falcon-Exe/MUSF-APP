import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../features/social_affairs/data/repositories/supabase_social_repository.dart';
import 'student_notification_badge.dart';

class SocialAffairsStudent extends StatefulWidget {
  const SocialAffairsStudent({super.key});

  @override
  State<SocialAffairsStudent> createState() => _SocialAffairsStudentState();
}

class _SocialAffairsStudentState extends State<SocialAffairsStudent> {
  static const _blue = Color(0xFF002147);
  static const _surface = Color(0xFFF8FAFC);

  late final Stream<List<Map<String, dynamic>>> _cssWorksStream;
  late final Stream<List<Map<String, dynamic>>> _examsStream;

  String _activeTab = 'css';

  @override
  void initState() {
    super.initState();
    final repo = SupabaseSocialRepository();
    _cssWorksStream = repo.getCssWorksStream();
    _examsStream = repo.getExamsStream();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _Header(
            topPadding: topPadding,
            activeTab: _activeTab,
            onBack: () => Navigator.pop(context),
            onTabChanged: (tab) => setState(() => _activeTab = tab),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _activeTab == 'css'
                  ? _CssWorksList(stream: _cssWorksStream)
                  : _ExamsList(stream: _examsStream),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.topPadding,
    required this.activeTab,
    required this.onBack,
    required this.onTabChanged,
  });

  final double topPadding;
  final String activeTab;
  final VoidCallback onBack;
  final ValueChanged<String> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _SocialAffairsStudentState._blue,
      padding: EdgeInsets.only(
        top: topPadding + 14,
        left: 20,
        right: 20,
        bottom: 18,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _IconCircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
              const Expanded(
                child: Column(
                  children: [
                    Text(
                      'Social Affairs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Programs and exam updates',
                      style: TextStyle(color: Color(0xFFBBD7F5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const StudentNotificationBadge(
                committeeName: 'Social Affairs',
                themeColor: Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF003366),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _TabButton(
                  label: 'CSS Works',
                  icon: Icons.groups_rounded,
                  isActive: activeTab == 'css',
                  onTap: () => onTabChanged('css'),
                ),
                _TabButton(
                  label: 'Exams',
                  icon: Icons.calendar_month_rounded,
                  isActive: activeTab == 'exams',
                  onTap: () => onTabChanged('exams'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CssWorksList extends StatelessWidget {
  const _CssWorksList({required this.stream});

  final Stream<List<Map<String, dynamic>>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState(message: 'Loading programs...');
        }

        if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load programs',
            message: 'Please check your connection and try again.',
          );
        }

        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.volunteer_activism_rounded,
            title: 'No CSS works yet',
            message: 'New programs assigned by the admin will appear here.',
          );
        }

        return ListView.builder(
          key: const PageStorageKey('social-css-list'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          itemCount: docs.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _SectionTitle(
                title: 'Upcoming Programs',
                subtitle: 'Latest updates from Social Affairs',
              );
            }

            final data = docs[index - 1];
            return _CssWorkCard(data: data);
          },
        );
      },
    );
  }
}

class _ExamsList extends StatelessWidget {
  const _ExamsList({required this.stream});

  final Stream<List<Map<String, dynamic>>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState(message: 'Loading exams...');
        }

        if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load exams',
            message: 'Please check your connection and try again.',
          );
        }

        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.event_available_rounded,
            title: 'No exams scheduled',
            message: 'Exam dates and venues will appear here when published.',
          );
        }

        return ListView.builder(
          key: const PageStorageKey('social-exams-list'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          itemCount: docs.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _SectionTitle(
                title: 'Examination Schedule',
                subtitle: 'Dates and venues in one place',
              );
            }

            final data = docs[index - 1];
            return _ExamCard(data: data, colorIndex: index - 1);
          },
        );
      },
    );
  }
}

class _CssWorkCard extends StatelessWidget {
  const _CssWorkCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final start = _formatDate(data['startDate'], 'MMM dd, yyyy');
    final end = _formatDate(data['endDate'], 'MMM dd, yyyy');
    final posted = _formatDate(data['dateAdded'], 'MMM dd');

    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconTile(
                icon: Icons.volunteer_activism_rounded,
                color: Color(0xFF7C3AED),
                background: Color(0xFFF3E8FF),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title']?.toString() ?? 'Unnamed Program',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['instruction']?.toString() ?? 'No details provided.',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetaLine(
                  icon: Icons.date_range_rounded,
                  text: '$start to $end',
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Posted $posted',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.data, required this.colorIndex});

  final Map<String, dynamic> data;
  final int colorIndex;

  static const _colors = [
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
  ];

  @override
  Widget build(BuildContext context) {
    final date = _toDate(data['date']) ?? DateTime.now();
    final color = _colors[colorIndex % _colors.length];

    return _AppCard(
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(date),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(date),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['subject']?.toString() ?? 'Unknown Subject',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                _MetaLine(
                  icon: Icons.location_on_rounded,
                  text: data['location']?.toString() ?? 'TBD',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? _SocialAffairsStudentState._blue
                      : const Color(0xFFBBD7F5),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? _SocialAffairsStudentState._blue
                        : const Color(0xFFBBD7F5),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime? _toDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _formatDate(dynamic value, String pattern) {
  final date = _toDate(value);
  return date == null ? 'TBD' : DateFormat(pattern).format(date);
}
