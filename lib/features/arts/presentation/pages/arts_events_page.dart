// lib/features/arts/presentation/pages/arts_events_page.dart

import 'package:flutter/material.dart';

import '../../logic/arts_controller.dart';
import '../widgets/arts_event_card.dart';
import '../widgets/arts_medal_header.dart';
import '../../../../home/student_notification_badge.dart';

class ArtsEventsPage extends StatefulWidget {
  final String studentId;
  const ArtsEventsPage({super.key, required this.studentId});

  @override
  State<ArtsEventsPage> createState() => _ArtsEventsPageState();
}

class _ArtsEventsPageState extends State<ArtsEventsPage> {
  late final ArtsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ArtsController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Arts Achievements",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: const [
          StudentNotificationBadge(
            committeeName: "Fine Arts",
            themeColor: Color(0xFF8B5CF6),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _controller.eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data ?? [];

          // Calculate Medal Counts
          int gold = 0, silver = 0, bronze = 0;
          for (var data in allDocs) {
            if (data['resultsPublished'] == true) {
              final first = data['firstPlaceId'] ?? data['firstPlace'];
              final second = data['secondPlaceId'] ?? data['secondPlace'];
              final third = data['thirdPlaceId'] ?? data['thirdPlace'];

              if (_controller.isMyId(first, widget.studentId)) gold++;
              if (_controller.isMyId(second, widget.studentId)) silver++;
              if (_controller.isMyId(third, widget.studentId)) bronze++;
            }
          }

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                children: [
                  ArtsMedalHeader(
                    gold: gold,
                    silver: silver,
                    bronze: bronze,
                    selectedCategory: _controller.selectedCategory,
                    onSearchChanged: _controller.updateSearch,
                    onCategoryChanged: _controller.setCategory,
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildEventList(allDocs)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> allDocs) {
    final filteredEvents = allDocs.where((data) {
      final String title = (data['title'] ?? "").toString().toLowerCase();

      if (ArtsController.normalizeCategory(data['type']) !=
          _controller.selectedCategory) {
        return false;
      }
      if (data['resultsPublished'] != true) return false;
      if (_controller.searchQuery.isNotEmpty &&
          !title.contains(_controller.searchQuery.toLowerCase())) {
        return false;
      }

      if (_controller.debugShowAll) return true;

      final first = data['firstPlaceId'] ?? data['firstPlace'];
      final second = data['secondPlaceId'] ?? data['secondPlace'];
      final third = data['thirdPlaceId'] ?? data['thirdPlace'];

      return _controller.isMyId(first, widget.studentId) ||
          _controller.isMyId(second, widget.studentId) ||
          _controller.isMyId(third, widget.studentId);
    }).toList();

    if (filteredEvents.isEmpty) {
      return const Center(
        child: Text(
          "No trophies yet!",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final data = filteredEvents[index];
        return ArtsEventCard(
          data: data,
          isMyId: (id) => _controller.isMyId(id, widget.studentId),
        );
      },
    );
  }
}
