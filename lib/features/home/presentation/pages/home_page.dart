// lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../logic/home_controller.dart';
import '../widgets/header_slider.dart';
import '../widgets/side_drawer.dart';
import '../widgets/glass_student_card.dart';
import '../widgets/leadership_carousel.dart';
import '../widgets/dashboard_grid.dart';
import '../../../../core/widgets/animated_entrance.dart'; // Core absolute

import '../../../../home/bfconstitution_page.dart';
import '../../../../core/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  final String studentID;
  final String studentName;
  final bool isAdmin;
  final Map<String, dynamic>? studentData;
  final Function(int)? onTabSwitch;

  const HomePage({
    super.key,
    required this.studentID,
    required this.studentName,
    this.isAdmin = false,
    this.studentData,
    this.onTabSwitch,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final HomeController _controller;
  StreamSubscription<QuerySnapshot>? _notifSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = HomeController(studentID: widget.studentID);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForNotifications();
    });
  }

  void _listenForNotifications() {
    _notifSubscription = _controller.unreadNotifStream.listen((snapshot) {
      final addedChanges = snapshot.docChanges
          .where((change) => change.type == DocumentChangeType.added)
          .toList();

      if (addedChanges.isEmpty) return;

      final firstData = addedChanges.first.doc.data() as Map<String, dynamic>;
      final title = firstData['title'] ?? 'New Notification';
      final message = firstData['message'] ?? '';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(message),
              ],
            ),
            backgroundColor: AppColors.accentTeal,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final change in addedChanges) {
        batch.update(change.doc.reference, {'isRead': true});
      }
      unawaited(batch.commit());
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.pageBackground,
      drawer: SideDrawer(
        isAdmin: widget.isAdmin,
        studentID: widget.studentID,
        studentData: widget.studentData,
        onTabSwitch: widget.onTabSwitch,
      ),
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (overscroll) {
          overscroll.disallowIndicator();
          return true;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExecutiveHeader(),
                  const SizedBox(height: 24),

                  AnimatedEntrance(
                    delay: 200,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassStudentCard(
                        studentID: widget.studentID,
                        studentName: widget.studentName,
                        studentData: widget.studentData,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  AnimatedEntrance(
                    delay: 400,
                    child: _buildSectionHeader(
                      "Union Leadership",
                      "Executive Council 2025-26",
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedEntrance(
                    delay: 500,
                    child: const LeadershipCarousel(),
                  ),

                  const SizedBox(height: 32),
                  AnimatedEntrance(
                    delay: 600,
                    child: _buildConstitutionFeature(context),
                  ),

                  const SizedBox(height: 32),
                  AnimatedEntrance(
                    delay: 700,
                    child: _buildSectionHeader(
                      "Campus Hub",
                      "Management & Activities",
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedEntrance(
                    delay: 800,
                    child: DashboardGrid(
                      studentID: widget.studentID,
                      studentName: widget.studentName,
                      isFlipped: _controller.isFlipped,
                      isAdmin: widget.isAdmin,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Removed footer as requested
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.palette.brand,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionPressed,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accentTeal.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: AppColors.accentTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    return Container(
      height: 340,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.palette.brandDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: const HeaderSlider(),
    );
  }

  Widget _buildConstitutionFeature(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PortalScreen(
              isAdmin: widget.isAdmin,
              studentID: widget.studentID,
              studentData: widget.studentData,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [context.palette.brand, context.palette.brandDark],
            ),
            boxShadow: [
              BoxShadow(
                color: context.palette.brand.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "THE UNION",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Bylaws and Member Rules",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
