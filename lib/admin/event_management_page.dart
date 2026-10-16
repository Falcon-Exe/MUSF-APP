import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Required for Date Formatting
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../services/cloud_storage_service.dart';
import '../features/schedule/data/repositories/schedule_repository.dart';
import '../features/schedule/data/repositories/supabase_schedule_repository.dart';

class EventManagementPage extends StatefulWidget {
  final String? initialCommittee;
  const EventManagementPage({super.key, this.initialCommittee});

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage> {
  final ScheduleRepository _scheduleRepo = SupabaseScheduleRepository();

  final String appId = "union-hostel-app";
  final Color primaryDark = const Color(0xFF102A43);
  final Color accentGreen = const Color(0xFF00E676);
  final Color bgLight = const Color(0xFFF1F5F9);

  bool _isAuthComplete = false;
  late String _selectedCommittee;

  @override
  void initState() {
    super.initState();
    // Locks the page to the passed committee. Defaults to "General" if null.
    _selectedCommittee = widget.initialCommittee ?? "General";
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final user = supabase.Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint("Supabase Auth Initialization error: no active user.");
      }
    } catch (e) {
      debugPrint("Supabase Auth Initialization error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAuthComplete = true;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          _buildBackgroundCircle(),
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: !_isAuthComplete
                    ? Center(
                        child: CircularProgressIndicator(color: primaryDark),
                      )
                    : _buildEventList(),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isAuthComplete
            ? () => _showAddEventBottomSheet(context)
            : null,
        backgroundColor: _isAuthComplete ? primaryDark : Colors.grey[400],
        elevation: 8,
        child: Icon(Icons.add_rounded, color: accentGreen, size: 35),
      ),
    );
  }

  Widget _buildBackgroundCircle() {
    return Positioned(
      top: -50,
      right: -50,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accentGreen.withValues(alpha: 0.04),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 35, left: 15, right: 15),
      decoration: BoxDecoration(
        color: primaryDark,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              _buildAdminBadge(),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Manage Events",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "$_selectedCommittee Department",
                  style: TextStyle(
                    color: accentGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: accentGreen, size: 14),
          const SizedBox(width: 8),
          Text(
            "ADMIN",
            style: TextStyle(
              color: accentGreen,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _scheduleRepo.getEventsStream(committee: _selectedCommittee),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryDark));
        }

        final filtered = snapshot.data ?? [];

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 15),
                Text(
                  "No events scheduled for $_selectedCommittee",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(25, 20, 25, 100),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final data = filtered[index];
            final docId = data['id']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                title: Text(
                  data['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          data['dateString'] ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Icon(
                          Icons.access_time_filled_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          data['timeString'] ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDelete(docId),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddEventBottomSheet(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String eventImageUrl = '';
    bool isUploadingImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              top: 20,
              left: 30,
              right: 30,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  "New $_selectedCommittee Event",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Event Title",
                    filled: true,
                    fillColor: bgLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.title, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 15),

                OutlinedButton.icon(
                  onPressed: isUploadingImage
                      ? null
                      : () async {
                          setModalState(() => isUploadingImage = true);
                          try {
                            final upload = await CloudStorageService()
                                .uploadImage(
                                  folder: CloudStorageFolder.eventPhotos,
                                  fileNamePrefix:
                                      nameController.text.trim().isEmpty
                                      ? 'event_photo'
                                      : nameController.text.trim(),
                                );
                            if (upload == null) return;
                            setModalState(() => eventImageUrl = upload.url);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Event photo upload failed: $e'),
                              ),
                            );
                          } finally {
                            setModalState(() => isUploadingImage = false);
                          }
                        },
                  icon: isUploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_rounded),
                  label: Text(
                    eventImageUrl.isEmpty
                        ? 'Upload Event Photo'
                        : 'Event Photo Uploaded',
                  ),
                ),
                const SizedBox(height: 15),

                // Date Picker Button
                InkWell(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: primaryDark,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setModalState(() => selectedDate = pickedDate);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: bgLight,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          selectedDate == null
                              ? "Select Date"
                              : DateFormat('dd/MM/yyyy').format(selectedDate!),
                          style: TextStyle(
                            color: selectedDate == null
                                ? Colors.grey[600]
                                : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Time Picker Button
                InkWell(
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: primaryDark,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedTime != null) {
                      setModalState(() => selectedTime = pickedTime);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: bgLight,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled_rounded,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          selectedTime == null
                              ? "Select Time"
                              : selectedTime!.format(context),
                          style: TextStyle(
                            color: selectedTime == null
                                ? Colors.grey[600]
                                : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty &&
                          selectedDate != null &&
                          selectedTime != null) {
                        await _scheduleRepo.addEvent(
                          title: nameController.text.trim(),
                          dateString: DateFormat(
                            'dd/MM/yyyy',
                          ).format(selectedDate!),
                          timeString: selectedTime!.format(context),
                          committee: _selectedCommittee,
                          imageUrl: eventImageUrl,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all fields!"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "PUBLISH EVENT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await _scheduleRepo.deleteEvent(docId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
