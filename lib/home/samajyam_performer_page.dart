import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SamajyamPerformerPage extends StatelessWidget {
  final String teamName;
  const SamajyamPerformerPage({super.key, required this.teamName});

  // 🟢 Dynamically assigns colors based on the real event name from the database
  Color _getEventColor(String eventName) {
    String lowerEvent = eventName.toLowerCase();
    if (lowerEvent.contains("quran") || lowerEvent.contains("qira")) return Colors.blue[800]!;
    if (lowerEvent.contains("speech") || lowerEvent.contains("welcome")) return Colors.orange[800]!;
    if (lowerEvent.contains("elocution") || lowerEvent.contains("debate")) return Colors.teal[800]!;
    if (lowerEvent.contains("song") || lowerEvent.contains("nasheed") || lowerEvent.contains("story")) return Colors.purple[800]!;
    return const Color(0xFF2E7D32); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text("$teamName Performers", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      // 🟢 THIS IS THE DATABASE CONNECTION! It constantly listens for new uploads.
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('samajyam_performances')
            .stream(primaryKey: ['id'])
            .order('date', ascending: false)
            .map((rows) => rows
                .where((r) =>
                    (r['team']?.toString().trim().toLowerCase() ?? '') ==
                    teamName.trim().toLowerCase())
                .toList()),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final docs = snapshot.data ?? [];

          // 3. Empty State (Shows if the Admin hasn't added anything yet)
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 15),
                  Text("No performances found for $teamName", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Text("Admins haven't uploaded the schedule yet.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          // 4. Building the Live List
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index];
              
              String event = data['event_name'] ?? data['eventName'] ?? "Event";
              String topic = data['topic'] ?? "Topic pending...";
              String performer = data['performer'] ?? "TBA";
              
              DateTime dt = data['date'] != null
                  ? (DateTime.tryParse(data['date'].toString()) ?? DateTime.now())
                  : DateTime.now();
              String dateString = DateFormat('EEEE, dd MMM yyyy').format(dt);

              return _buildEventBanner(event, topic, performer, dateString, _getEventColor(event));
            },
          );
        },
      ),
    );
  }

  // 🟢 The Banner Widget that displays the live data
  Widget _buildEventBanner(String event, String topic, String name, String date, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                child: Text(date, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            topic,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24, height: 20),
          Row(
            children: [
              const Icon(Icons.person_pin, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                "Performer: $name",
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}