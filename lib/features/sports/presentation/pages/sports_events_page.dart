// lib/features/sports/presentation/pages/sports_events_page.dart

import 'package:flutter/material.dart';
import '../../logic/sports_controller.dart';
import '../widgets/sports_event_card.dart';
import '../widgets/sports_medal_header.dart';
import '../../../../home/student_notification_badge.dart';

class SportsEventsPage extends StatefulWidget {
  final String studentId;
  const SportsEventsPage({super.key, required this.studentId});

  @override
  State<SportsEventsPage> createState() => _SportsEventsPageState();
}

class _SportsEventsPageState extends State<SportsEventsPage> {
  late final SportsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SportsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Sports Achievements",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: const [
          StudentNotificationBadge(
            committeeName: "Sports",
            themeColor: Color(0xFFF59E0B),
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

          int gold = 0, silver = 0, bronze = 0;
          for (var data in allDocs) {
            if (data['resultsPublished'] == true) {
              final first = data['firstPlaceId'];
              final second = data['secondPlaceId'];
              final third = data['thirdPlaceId'];

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
                  SportsMedalHeader(
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

      if (data['category'] != _controller.selectedCategory) return false;
      if (data['resultsPublished'] != true) return false;
      if (_controller.searchQuery.isNotEmpty &&
          !title.contains(_controller.searchQuery.toLowerCase())) {
        return false;
      }

      if (_controller.debugShowAll) return true;

      final first = data['firstPlaceId'];
      final second = data['secondPlaceId'];
      final third = data['thirdPlaceId'];

      return _controller.isMyId(first, widget.studentId) ||
          _controller.isMyId(second, widget.studentId) ||
          _controller.isMyId(third, widget.studentId);
    }).toList();

    if (filteredEvents.isEmpty) {
      return Center(
        child: Text(
          _controller.searchQuery.isEmpty ? "No trophies yet!" : "No results found",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final data = filteredEvents[index];
        return SportsEventCard(
          data: data,
          isMyId: (id) => _controller.isMyId(id, widget.studentId),
        );
      },
    );
  }
}
