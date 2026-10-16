import 'package:flutter/material.dart';
import 'samajyam_performer_page.dart'; 
import '../core/widgets/animated_entrance.dart';

class SamajyamTeamsPage extends StatelessWidget {
  const SamajyamTeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Samajyam Teams", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          int teamNum = index + 1;
          return AnimatedEntrance(
            delay: 100 * index,
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                child: Text("$teamNum", style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w900, fontSize: 18)),
              ),
              title: Text("Team $teamNum", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: const Text("View Weekly Performers"),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SamajyamPerformerPage(teamName: "Team $teamNum")),
                );
              },
            ),
          ),
        );
      },
      ),
    );
  }
}