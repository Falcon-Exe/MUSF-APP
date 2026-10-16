import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Ensure these filenames match your project files
import 'reel_upload_page.dart';
import 'event_management_page.dart';
import '../features/prd/presentation/pages/prd_request_desk_page.dart';
import 'admin_committee_prize.dart';
import 'purchase_request_page.dart';

class SocialAffairsAdminPage extends StatefulWidget {
  final VoidCallback? onBack; // 🟢 Add this
  const SocialAffairsAdminPage({super.key, this.onBack});

  @override
  State<SocialAffairsAdminPage> createState() => _SocialAffairsAdminPageState();
}

class _SocialAffairsAdminPageState extends State<SocialAffairsAdminPage> {
  String _activeTab = 'css'; // 'css' or 'exams'

  // --- MODALS & DIALOGS ---

  void _showPortalMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildPortalMenu(),
    );
  }

  // --- CSS WORK ADD DIALOG (Now uses Dates instead of Time) ---
  void _showAddCssDialog() {
    final titleController = TextEditingController();
    final instructionController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add CSS",
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) => _buildGlassDialog(
            title: "New CSS Program",
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputLabel("Program Name"),
                TextField(
                  controller: titleController,
                  decoration: _inputDecoration("e.g. Campus Clean Drive"),
                ),
                const SizedBox(height: 16),
                _buildInputLabel("Instructions / Details"),
                TextField(
                  controller: instructionController,
                  maxLines: 2,
                  decoration: _inputDecoration("Brief instructions..."),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel("Start Date"),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => startDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                startDate != null
                                    ? DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(startDate!)
                                    : "Select Start",
                                style: TextStyle(
                                  color: startDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel("End Date"),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: startDate ?? DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => endDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                endDate != null
                                    ? DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(endDate!)
                                    : "Select End",
                                style: TextStyle(
                                  color: endDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          if (titleController.text.isNotEmpty &&
                              startDate != null &&
                              endDate != null) {
                            await FirebaseFirestore.instance
                                .collection('social_css_works')
                                .add({
                                  'title': titleController.text.trim(),
                                  'instruction': instructionController.text
                                      .trim(),
                                  'startDate': startDate,
                                  'endDate': endDate,
                                  'dateAdded': FieldValue.serverTimestamp(),
                                });
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          "Post Work",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- EXAM ADD DIALOG ---
  void _showAddExamDialog() {
    final subjectController = TextEditingController();
    final locationController = TextEditingController();
    DateTime? selectedDate;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add Exam",
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) => _buildGlassDialog(
            title: "Schedule New Exam",
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputLabel("Subject Name"),
                TextField(
                  controller: subjectController,
                  decoration: _inputDecoration("e.g. Political Science"),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel("Date"),
                          TextField(
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                            decoration: _inputDecoration(
                              selectedDate != null
                                  ? DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(selectedDate!)
                                  : "Select Date",
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel("Location"),
                          TextField(
                            controller: locationController,
                            decoration: _inputDecoration("Hall B-02"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          if (subjectController.text.isNotEmpty &&
                              selectedDate != null) {
                            await FirebaseFirestore.instance
                                .collection('social_exams')
                                .add({
                                  'subject': subjectController.text.trim(),
                                  'date': selectedDate,
                                  'location': locationController.text.trim(),
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: _activeTab == 'css'
          ? FloatingActionButton.extended(
              onPressed: _showAddCssDialog,
              backgroundColor: const Color(0xFF0F172A),
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: const Text(
                "Add CSS",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _activeTab == 'css' ? _buildCssTab() : _buildExamsTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _iconButton(Icons.chevron_left_rounded, () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pop(context);
                }
              }),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Social Affairs",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      "Track CSS Works & Exams",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Purchase Requests',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PurchaseRequestPage(
                      committeeName: 'Social Affairs',
                    ),
                  ),
                ),
              ),

              _iconButton(Icons.menu_rounded, _showPortalMenu),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _buildTabButton("CSS Works", Icons.people_alt_rounded, 'css'),
                _buildTabButton("Exams", Icons.calendar_today_rounded, 'exams'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FIREBASE CSS TAB ---
  Widget _buildCssTab() {
    return Column(
      key: const ValueKey('css_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('social_css_works')
              .orderBy('dateAdded', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No CSS works scheduled."));
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                // Format the timestamps back to readable dates
                String startStr = data['startDate'] != null
                    ? DateFormat(
                        'MMM dd',
                      ).format((data['startDate'] as Timestamp).toDate())
                    : 'TBD';
                String endStr = data['endDate'] != null
                    ? DateFormat(
                        'MMM dd',
                      ).format((data['endDate'] as Timestamp).toDate())
                    : 'TBD';

                return WorkBannerCard(
                  docId: doc.id,
                  eventName: data['title'] ?? 'Unnamed',
                  detail: data['instruction'] ?? 'No instructions',
                  dateSlot: "$startStr - $endStr", // Updated variable
                  color: const Color(0xFF6366F1),
                  icon: Icons.volunteer_activism_rounded,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- FIREBASE EXAMS TAB ---
  Widget _buildExamsTab() {
    return Column(
      key: const ValueKey('exams_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            TextButton.icon(
              onPressed: _showAddExamDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Add New"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('social_exams')
              .orderBy('date')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No exams scheduled."));
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ExamCard(
                  docId: doc.id,
                  subject: data['subject'] ?? 'Unknown',
                  date: (data['date'] as Timestamp).toDate(),
                  location: data['location'] ?? 'TBD',
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- COMPONENT HELPERS ---

  Widget _buildTabButton(String label, IconData icon, String tabKey) {
    bool active = _activeTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tabKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? const Color(0xFF0F172A) : Colors.white38,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? const Color(0xFF0F172A) : Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildPortalMenu() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Portal Menu",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 25),

          _menuItem(
            Icons.video_library_rounded,
            "Upload Reels",
            "Manage community video content",
            const Color(0xFF6366F1),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ReelUploadPage(committeeName: "Social Affairs"),
                ),
              );
            },
          ),
          _menuItem(
            Icons.event_available_rounded,
            "Event Management",
            "Schedule & track department events",
            const Color(0xFF38BDF8),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EventManagementPage(
                    initialCommittee: "Social Affairs",
                  ),
                ),
              );
            },
          ),
          _menuItem(
            Icons.stars_rounded,
            "Committee Prizes",
            "Manage winners & honor rolls",
            const Color(0xFFC5A059),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminCommitteeDashboard(
                    initialCommittee: "Social Affairs",
                  ),
                ),
              );
            },
          ),
          _menuItem(
            Icons.admin_panel_settings_rounded,
            "PRD Request Desk",
            "Request PRD posters & videos",
            const Color(0xFF10B981),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrdRequestDeskPage(
                    initialCommittee: "Social Affairs",
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String sub,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassDialog({required String title, required Widget child}) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// --- FIREBASE SUB-WIDGETS WITH SECURE DELETE ALERTS ---

class WorkBannerCard extends StatelessWidget {
  final String eventName, detail, dateSlot, docId;
  final Color color;
  final IconData icon;

  const WorkBannerCard({
    super.key,
    required this.eventName,
    required this.detail,
    required this.dateSlot,
    required this.color,
    required this.icon,
    required this.docId,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete CSS Program?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          "Are you sure you want to permanently delete '$eventName'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('social_css_works')
                  .doc(docId)
                  .delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  tooltip: "Delete CSS Program",
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              eventName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(detail, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  size: 16,
                  color: Colors.grey,
                ), // Updated Icon
                const SizedBox(width: 8),
                Text(
                  dateSlot,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ), // Show Date Slot
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExamCard extends StatelessWidget {
  final String subject, location, docId;
  final DateTime date;

  const ExamCard({
    super.key,
    required this.subject,
    required this.date,
    required this.location,
    required this.docId,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Exam?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          "Are you sure you want to permanently delete the exam '$subject'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('social_exams')
                  .doc(docId)
                  .delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            "${date.day}",
            style: const TextStyle(color: Colors.blue),
          ),
        ),
        title: Text(
          subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${DateFormat('MMM yyyy').format(date)} • $location"),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: "Delete Exam",
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }
}
