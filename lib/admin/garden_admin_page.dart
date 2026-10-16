import 'package:flutter/material.dart';

// Make sure these imports match your actual file names!
import 'reel_upload_page.dart';
import 'admin_committee_prize.dart';
import '../features/prd/presentation/pages/prd_request_desk_page.dart';
import 'event_management_page.dart'; // 🟢 Added import for Event Management
import 'purchase_request_page.dart';

class GardenAdminPage extends StatefulWidget {
  final VoidCallback? onBack; // 🟢 Add this
  const GardenAdminPage({super.key, this.onBack});

  @override
  State<GardenAdminPage> createState() => _GardenAdminPageState();
}

class _GardenAdminPageState extends State<GardenAdminPage> {
  final Color primaryDark = const Color(0xFF08233E);
  final Color accentGreen = const Color(0xFF4CAF50); // Leaf Green for Garden

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. PREMIUM HEADER
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryDark,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(45),
                bottomRight: Radius.circular(45),
              ),
            ),
          ),

          // 2. MAIN CONTENT (BLANK CANVAS)
          SafeArea(
            child: Column(
              children: [
                _buildTopActionBar(),

                // HEADER TEXT
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DEPARTMENT DASHBOARD",
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          fontSize: 11,
                        ),
                      ),
                      const Text(
                        "Garden Admin",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Manage Garden committee activities and requests.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // BLANK WORKSPACE PLACEHOLDER
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.eco_rounded,
                        size: 80,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Garden Workspace",
                        style: TextStyle(
                          color: Colors.black26,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Add your custom widgets here later",
                        style: TextStyle(color: Colors.black26, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildTopActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Spacer(),

          IconButton(
            icon: const Icon(
              Icons.shopping_cart_rounded,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'Purchase Requests',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const PurchaseRequestPage(committeeName: 'Garden'),
              ),
            ),
          ),

          // 🟢 HAMBURGER MENU ICON
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
            onPressed: () => _showManagementBottomMenu(context),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  // --- HAMBURGER MENU (BOTTOM SHEET) ---
  void _showManagementBottomMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "Garden Console",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF08233E),
                  ),
                ),
                const SizedBox(height: 30),

                // 1. UPLOAD REEL
                ListTile(
                  leading: const Icon(
                    Icons.video_call_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    "Upload Section Reel",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.black26,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ReelUploadPage(committeeName: "Garden"),
                      ),
                    );
                  },
                ),

                const Divider(height: 15, thickness: 0.5),

                // 2. 🟢 EVENT MANAGEMENT (NEWLY ADDED)
                ListTile(
                  leading: const Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF38BDF8),
                  ),
                  title: const Text(
                    "Event Management",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Schedule & track department events",
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.black26,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventManagementPage(
                          initialCommittee: "Garden",
                        ), // Securely locked to Garden
                      ),
                    );
                  },
                ),

                const Divider(height: 15, thickness: 0.5),

                // 3. COMMITTEE PRIZES
                ListTile(
                  leading: const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFFC5A059),
                  ), // Premium Gold
                  title: const Text(
                    "Committee Prizes",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Manage winners and participants registry",
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.black26,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminCommitteeDashboard(
                          initialCommittee: "Garden",
                        ),
                      ),
                    );
                  },
                ),

                const Divider(height: 15, thickness: 0.5),

                // 4. PRD REQUEST DESK
                ListTile(
                  leading: const Icon(
                    Icons.design_services_rounded,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    "PRD Request Desk",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Request posters and media from PRD",
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.black26,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrdRequestDeskPage(
                          initialCommittee: "Garden",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
