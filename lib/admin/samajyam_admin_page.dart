import 'package:flutter/material.dart';
import 'samajyam_team_dashboard.dart'; // Make sure to import the new page below

class SamajyamAdminPage extends StatelessWidget {
  const SamajyamAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "Select Your Team",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32), // Dark green theme
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          int teamNumber = index + 1;
          String teamName = "Team $teamNumber";

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                child: Text(
                  "$teamNumber",
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              title: Text(
                teamName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: const Text(
                "Upload performances & view history",
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey,
              ),
              onTap: () {
                // Passes the selected team name to the next page!
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SamajyamTeamDashboard(teamName: teamName),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
