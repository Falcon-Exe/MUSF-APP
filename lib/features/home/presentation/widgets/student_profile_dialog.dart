// lib/features/home/presentation/widgets/student_profile_dialog.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';

class StudentProfileDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const StudentProfileDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final fullName = _value([
      'full_name',
      'fullName',
      'name',
    ], fallback: 'Majlis Student');
    final displayCourse = _value([
      'course',
      'class_name',
      'class',
    ], fallback: 'Not Specified')!;
    final displayStudentId = _value([
      'student_id',
      'studentID',
      'cic_no',
      'cicNo',
    ], fallback: 'N/A')!;
    final email = _value([
      'email',
      'personal_email',
      'personalEmail',
      'auth_email',
      'authEmail',
    ], fallback: 'No email linked')!;
    final phone = _value(['phone'], fallback: 'N/A')!;
    final address = _value([
      'address',
    ], fallback: 'College Campus, Residential Hub')!;
    final role = _value(['role'], fallback: 'Union Member')!;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(45),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.darkNavy.withValues(alpha: 0.9),
                    AppColors.primaryGreen.withValues(alpha: 0.78),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(45),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "OFFICIAL ID",
                            style: TextStyle(
                              color: AppColors.accentTeal,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white10,
                      child: Icon(
                        Icons.person_3_rounded,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      fullName!.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: const TextStyle(
                        color: AppColors.accentTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      height: 1,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white24,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _profileField("Course", displayCourse),
                    _profileField("Student ID", displayStudentId),
                    _profileField("Email", email),
                    _profileField("Phone", phone),
                    _profileField(
                      "Access Valid Till",
                      data['validityDate'] ?? "March 2026",
                    ),
                    _profileField("Home Address", address),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () {
                        _showQRDetail(context, displayStudentId);
                      },
                      child: QrImageView(
                        data: [
                          'MUSF STUDENT UNION',
                          '─────────────────',
                          'Name   : $fullName',
                          'ID     : $displayStudentId',
                          'Course : $displayCourse',
                          'Email  : ${email == "No email linked" ? "N/A" : email}',
                          'Role   : $role',
                          'Valid  : ${data['validityDate'] ?? 'March 2026'}',
                        ].join('\n'),
                        version: QrVersions.auto,
                        size: 65,
                        backgroundColor: Colors.transparent,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.white,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap QR to view ID',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _value(List<String> keys, {required String? fallback}) {
    for (final key in keys) {
      final raw = data[key];
      if (raw == null) continue;
      final value = raw.toString().trim();
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  void _showQRDetail(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Student ID',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          id,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.accentTeal,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
