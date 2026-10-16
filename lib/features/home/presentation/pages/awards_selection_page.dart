import 'package:flutter/material.dart';
import '../../../../home/sub_committee_list_page.dart';
import '../../../arts/presentation/pages/arts_events_page.dart';
import '../../../sports/presentation/pages/sports_events_page.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/theme/app_colors.dart';

class AwardsSelectionPage extends StatelessWidget {
  final String studentID;

  const AwardsSelectionPage({super.key, required this.studentID});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final primaryColor = palette.brand;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "AWARDS HUB",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AnimatedEntrance(
              delay: 100,
              child: Text(
                "Select a category to view achievements and events",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSelectionTile(
              context,
              title: "Sports Gallery",
              subtitle: "Athletic events and winners",
              icon: Icons.sports_soccer_rounded,
              color: AppColors.accentTeal,
              index: 1,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SportsEventsPage(studentId: studentID),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSelectionTile(
              context,
              title: "Arts & Culture",
              subtitle: "Creative performances and results",
              icon: Icons.palette_rounded,
              color: AppColors.accentPurple,
              index: 2,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArtsEventsPage(studentId: studentID),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSelectionTile(
              context,
              title: "Subcommittee Awards",
              subtitle: "Your sub-committee achievements",
              icon: Icons.emoji_events_rounded,
              color: AppColors.accentAmber,
              index: 3,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SubCommitteeListPage(studentID: studentID),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int index,
    required VoidCallback onTap,
  }) {
    return AnimatedEntrance(
      delay: 150 * index,
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.surface,
          border: Border.all(color: context.palette.border),
          borderRadius: BorderRadius.circular(24),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: context.palette.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.palette.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey.shade300,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
