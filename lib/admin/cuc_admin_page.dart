import 'package:flutter/material.dart';
import '../features/cuc/logic/cuc_controller.dart';
import 'purchase_request_page.dart';

class CucAdminPage extends StatefulWidget {
  final VoidCallback? onBack; // 🟢 Add this
  const CucAdminPage({super.key, this.onBack});

  @override
  State<CucAdminPage> createState() => _CucAdminPageState();
}

class _CucAdminPageState extends State<CucAdminPage> {
  final CucController _cucController = CucController();

  // Controllers for input fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Removed mock data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("CUC Admin Control"),
        backgroundColor: const Color(0xFFD32F2F), // Red for Admin
        foregroundColor: Colors.white,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded),
            tooltip: 'Purchase Requests',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PurchaseRequestPage(committeeName: 'CUC'),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Post Important Message",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Title Input
                  _buildTextField(
                    controller: _titleController,
                    label: "Notice Title / Subject",
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 15),

                  // Content Input
                  _buildTextField(
                    controller: _contentController,
                    label: "Message Content",
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),

                  // Last Date Input (Row)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _dateController,
                          label: "Regular Last Date",
                          icon: Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Post Button
                      ElevatedButton(
                        onPressed: _postNotice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("POST"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Active Notices List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Active Notices",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showNoticeArchive,
                        icon: const Icon(
                          Icons.history,
                          size: 18,
                          color: Color(0xFFD32F2F),
                        ),
                        label: const Text(
                          "View Archive",
                          style: TextStyle(color: Color(0xFFD32F2F)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _cucController.getNoticesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data ?? [];
                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "No active notices right now.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return Column(
                        children: docs
                            .map(
                              (doc) => _buildNoticeTile(
                                doc['id']?.toString() ?? '',
                                doc,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFD32F2F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Admin Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Manage deadlines, fines, and university announcements.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildNoticeTile(String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), // Light Red bg
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.notifications_active,
            color: Color(0xFFD32F2F),
          ),
        ),
        title: Text(
          data['title'] ?? 'Notice',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['content'] != null &&
                data['content'].toString().isNotEmpty)
              Text(
                data['content'],
                style: const TextStyle(color: Color(0xFF333333), fontSize: 13),
              ),
            const SizedBox(height: 4),
            Text(
              "Last Date: ${data['date'] ?? 'N/A'}",
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: () async {
            await _cucController.deleteNotice(docId);
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Notice removed")));
            }
          },
        ),
      ),
    );
  }

  Future<void> _postNotice() async {
    if (_titleController.text.isNotEmpty && _dateController.text.isNotEmpty) {
      // Show loading
      showDialog(
        context: context,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      await _cucController.postNotice(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _dateController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // close loading
        setState(() {
          _titleController.clear();
          _contentController.clear();
          _dateController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notice Posted Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill Title and Date")),
      );
    }
  }

  void _showNoticeArchive() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Notice Archive",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _cucController.getNoticesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!;
                  if (docs.isEmpty) {
                    return const Center(child: Text("No notices found."));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index];
                      return ListTile(
                        leading: const Icon(Icons.history, color: Color(0xFFD32F2F)),
                        title: Text(data['title'] ?? 'Notice'),
                        subtitle: Text("Last Date: ${data['date'] ?? 'N/A'}"),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
