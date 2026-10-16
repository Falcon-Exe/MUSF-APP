// lib/features/sports/presentation/widgets/sports_event_card.dart

import 'package:flutter/material.dart';

class SportsEventCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool Function(dynamic) isMyId;

  const SportsEventCard({
    super.key,
    required this.data,
    required this.isMyId,
  });

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? 'Unknown Event';
    Color rankColor = Colors.grey;
    String rank = "Result Published";

    if (isMyId(data['firstPlaceId']) || isMyId(data['firstPlace'])) {
      rank = "🥇 1st Place";
      rankColor = Colors.green;
    } else if (isMyId(data['secondPlaceId']) || isMyId(data['secondPlace'])) {
      rank = "🥈 2nd Place";
      rankColor = Colors.blue;
    } else if (isMyId(data['thirdPlaceId']) || isMyId(data['thirdPlace'])) {
      rank = "🥉 3rd Place";
      rankColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(Icons.stars, color: rankColor, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          rank,
          style: TextStyle(color: rankColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
