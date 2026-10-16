// lib/features/home/presentation/widgets/glass_student_card.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'student_profile_dialog.dart';
import '../../../../core/theme/app_colors.dart';

class GlassStudentCard extends StatefulWidget {
  final String studentID;
  final String studentName;
  final Map<String, dynamic>? studentData;

  const GlassStudentCard({
    super.key,
    required this.studentID,
    required this.studentName,
    this.studentData,
  });

  @override
  State<GlassStudentCard> createState() => _GlassStudentCardState();
}

class _GlassStudentCardState extends State<GlassStudentCard> {
  void _showStudentProfile(BuildContext context, Map<String, dynamic> data) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Student Profile",
      barrierColor: Colors.black54,
      pageBuilder: (context, anim1, anim2) {
        return StudentProfileDialog(data: data);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10 * anim1.value,
            sigmaY: 10 * anim1.value,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: anim1, child: child),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.studentData ?? {};
    final name =
        data['full_name'] ??
        data['fullName'] ??
        data['name'] ??
        widget.studentName;
    final id =
        data['student_id'] ??
        data['studentID'] ??
        data['cic_no'] ??
        widget.studentID;
    final course =
        data['course'] ??
        data['class_name'] ??
        data['class'] ??
        'Academic Program';

    return InkWell(
      onTap: () => _showStudentProfile(context, data),
      borderRadius: BorderRadius.circular(32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),

              gradient: AppColors.identityGradient,

              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),

              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white10,
                    child: Icon(
                      Icons.person_3_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        course.toString(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          "STUDENT ID: #$id",
                          style: const TextStyle(
                            color: AppColors.accentTeal,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.white.withValues(alpha: 0.14),
                  size: 45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
