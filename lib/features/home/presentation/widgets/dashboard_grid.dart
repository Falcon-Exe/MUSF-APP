// lib/features/home/presentation/widgets/dashboard_grid.dart

import 'package:flutter/material.dart';

import '../../../../home/library_student_page.dart';
import '../pages/awards_selection_page.dart';
import '../pages/lit_research_selection_page.dart';
import '../pages/finance_selection_page.dart';
import '../../../../home/samajyam_teams_page.dart';
import '../../../../home/bank_management_page.dart';
import '../../../../home/wsf_notice_page.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardGrid extends StatelessWidget {
  final String studentID;
  final String studentName;
  final bool isFlipped;
  final bool isAdmin;

  const DashboardGrid({
    super.key,
    required this.studentID,
    required this.studentName,
    required this.isFlipped,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> committees = _getCommittees();

    final palette = context.palette;
    final primaryDark = palette.brand;
    final pageBackground = palette.pageBackground;

    return Container(
      color: pageBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 24) / 3;
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 14,
                children: List.generate(
                  committees.length,
                  (index) => SizedBox(
                    width: itemWidth,
                    child: _buildExecutiveTile(
                      context,
                      committees[index],
                      primaryDark,
                      index,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveTile(
    BuildContext context,
    Map<String, dynamic> item,
    Color color,
    int index,
  ) {
    IconData getBetterIcon(String title) {
      switch (title) {
        case 'WSF':
          return Icons.handshake_rounded;

        case 'My Awards':
          return Icons.emoji_events_rounded;

        case 'Samajyam':
          return Icons.groups_rounded;

        case 'Finance':
          return Icons.account_balance_wallet_rounded;

        case 'Lit & Research':
          return Icons.menu_book_rounded;

        default:
          return item['icon'];
      }
    }

    return AnimatedEntrance(
      delay: 50 * (index + 1),
      child: GestureDetector(
        onTap: () {
          if (item['title'] == 'Finance') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FinanceSelectionPage(
                  studentID: studentID,
                  studentName: studentName,
                ),
              ),
            );
          } else if (item['title'] == 'Lit & Research') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LitResearchSelectionPage(isAdmin: isAdmin),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['page']),
            );
          }
        },
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.palette.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.18
                      : 0.035,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(getBetterIcon(item['title']), color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                item['title'],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: color.withValues(alpha: 0.9),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getCommittees() {
    return [
      {
        'title': 'WSF',
        'icon': Icons.local_florist_rounded,
        'page': const WsfNotice(),
      },
      {
        'title': 'My Awards',
        'icon': Icons.stars_rounded,
        'page': AwardsSelectionPage(studentID: studentID),
      },
      {
        'title': 'Samajyam',
        'icon': Icons.groups_3_rounded,
        'page': const SamajyamTeamsPage(),
      },
      {
        'title': 'Finance',
        'icon': Icons.account_balance_wallet_rounded,
        'page': BankManagementPage(
          studentID: studentID,
          studentName: studentName,
        ),
      },
      {
        'title': 'Lit & Research',
        'icon': Icons.auto_stories_rounded,
        'page': const StudentLibraryPage(),
      },
    ];
  }
}
