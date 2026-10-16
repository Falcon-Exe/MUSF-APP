import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class SamajyamTeamDashboard extends StatefulWidget {
  final String teamName; // Receives "Team 1", "Team 2", etc.

  const SamajyamTeamDashboard({super.key, required this.teamName});

  @override
  State<SamajyamTeamDashboard> createState() => _SamajyamTeamDashboardState();
}

class _SamajyamTeamDashboardState extends State<SamajyamTeamDashboard> {
  final Color primaryGreen = const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(
            "${widget.teamName} Portal",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryGreen,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.add_task_rounded), text: "Upload Entry"),
              Tab(icon: Icon(Icons.history_edu_rounded), text: "Team History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: FORM
            _SamajyamEntryForm(teamName: widget.teamName),

            // TAB 2: HISTORY
            _SamajyamHistoryList(teamName: widget.teamName),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// TAB 1: THE ENTRY FORM (LOCKED TO THE SELECTED TEAM)
// ----------------------------------------------------------------------
class _SamajyamEntryForm extends StatefulWidget {
  final String teamName;
  const _SamajyamEntryForm({required this.teamName});

  @override
  State<_SamajyamEntryForm> createState() => _SamajyamEntryFormState();
}

class _SamajyamEntryFormState extends State<_SamajyamEntryForm> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(
    hour: 19,
    minute: 30,
  ); // Default 07:30 PM
  final TextEditingController _venueController = TextEditingController();

  // ULA State
  List<Map<String, dynamic>> ulaEvents = [
    {
      'topic': "QUIRA'ATH",
      'controller': TextEditingController(),
      'studentId': '',
    },
    {
      'topic': "SPEECH MALAYALAM",
      'controller': TextEditingController(),
      'studentId': '',
    },
    {
      'topic': "SPEECH ENGLISH",
      'controller': TextEditingController(),
      'studentId': '',
    },
    {
      'topic': "TABLE TALK ENGLISH",
      'controller': TextEditingController(),
      'studentId': '',
    },
    {
      'topic': "SCRIPT WRITING",
      'controller': TextEditingController(),
      'studentId': '',
    },
    {
      'topic': "REEL CREATION",
      'controller': TextEditingController(),
      'studentId': '',
    },
  ];

  // ALIYA State
  List<Map<String, dynamic>> aliyaEvents = [
    {
      'topic': "THINK TALK",
      'controller': TextEditingController(),
      'studentId': '',
    },
    {
      'topic': "1V1 DEBATE",
      'controller': TextEditingController(),
      'studentId': '',
    },
    {
      'topic': "INSPIRING TALK ENGLISH",
      'controller': TextEditingController(),
      'studentId': '',
    },
    {
      'topic': "REEL CREATION",
      'controller': TextEditingController(),
      'studentId': '',
    },
    {
      'topic': "PROMPT WRITING",
      'controller': TextEditingController(),
      'studentId': '',
    },
    {
      'topic': "DISCUSSION ENGLISH",
      'controller': TextEditingController(),
      'studentId': '',
    },
  ];

  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  // Helper method to fetch students for autocomplete
  Future<List<Map<String, dynamic>>> _getStudentSuggestions(
    String query,
  ) async {
    if (query.isEmpty) return [];

    final rows = await Supabase.instance.client
        .from('students')
        .select('full_name, student_id');

    final q = query.toLowerCase();
    var results = rows.where((data) {
      final name = (data['full_name'] ?? '').toString().toLowerCase();
      final id = (data['student_id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).map((r) => {
      'fullName': r['full_name'],
      'studentID': r['student_id'],
    }).toList();

    return results;
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      DateTime finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      String venue = _venueController.text.trim().isEmpty
          ? "TBD"
          : _venueController.text.trim();

      final List<Map<String, dynamic>> toInsert = [];

      void processEvents(List<Map<String, dynamic>> events, String category) {
        for (var ev in events) {
          String performerName = ev['controller'].text.trim();
          if (performerName.isNotEmpty) {
            String topicName = ev['isCustom'] == true ? ev['topic'] : category;
            toInsert.add({
              'date': finalDateTime.toUtc().toIso8601String(),
              'category': category,
              'team': widget.teamName,
              'venue': venue,
              'event_name': ev['topic'],
              'topic': topicName,
              'performer': performerName,
              'performer_id': ev['studentId'],
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            });
          }
        }
      }

      processEvents(ulaEvents, "ULA");
      processEvents(aliyaEvents, "ALIYA");

      if (toInsert.isNotEmpty) {
        await Supabase.instance.client
            .from('samajyam_performances')
            .insert(toInsert);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Literary Summit Uploaded Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        // Reset Logic
        _venueController.clear();
        for (var e in ulaEvents) {
          e['controller'].clear();
          e['studentId'] = '';
        }
        for (var e in aliyaEvents) {
          e['controller'].clear();
          e['studentId'] = '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...events.map((ev) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ev['isCustom'] == true
                      ? TextField(
                          controller: ev['topicController'],
                          onChanged: (val) => ev['topic'] = val,
                          decoration: const InputDecoration(
                            hintText: "Enter Topic Name",
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        )
                      : Text(
                          "♦️ ${ev['topic']}:",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TypeAheadField<Map<String, dynamic>>(
                    suggestionsCallback: (pattern) =>
                        _getStudentSuggestions(pattern),
                    builder: (context, controller, focusNode) {
                      controller.text = ev['controller'].text;
                      controller.addListener(() {
                        ev['controller'].text = controller.text;
                      });

                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          hintText: "Select Performer",
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(
                          suggestion['fullName'] ??
                              suggestion['name'] ??
                              'Unknown',
                        ),
                        subtitle: Text(suggestion['studentID'] ?? ''),
                      );
                    },
                    onSelected: (suggestion) {
                      setState(() {
                        ev['controller'].text =
                            suggestion['fullName'] ?? suggestion['name'] ?? '';
                        ev['studentId'] = suggestion['studentID'] ?? '';
                      });
                    },
                    emptyBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("No students found"),
                    ),
                    loadingBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Loading..."),
                    ),
                    errorBuilder: (context, error) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Error: $error"),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: () => setState(() => events.remove(ev)),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            setState(() {
              events.add({
                'topic': "Custom Topic",
                'isCustom': true,
                'topicController': TextEditingController(),
                'controller': TextEditingController(),
                'studentId': '',
              });
            });
          },
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
          label: const Text(
            "Add Custom Topic",
            style: TextStyle(color: Color(0xFF2E7D32)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "LITERARY SUMMIT ENTRY",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Divider(height: 30),

                // TOP SETTINGS: Date, Time, Venue, Group
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          "Date",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        subtitle: Text(
                          DateFormat('dd-MM-yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 18),
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          "Time",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        subtitle: Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.access_time, size: 18),
                        onTap: () => _selectTime(context),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _venueController,
                        decoration: const InputDecoration(
                          labelText: "VENUE",
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        "GROUP: ${widget.teamName.replaceAll('Team ', '')}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- ULA SECTION ---
                _buildSection("ULA", ulaEvents),

                // --- ALIYA SECTION ---
                _buildSection("ALIYA", aliyaEvents),

                const SizedBox(height: 20),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveEntry,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Upload Summit Entry",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// TAB 2: THE HISTORY LIST
// ----------------------------------------------------------------------
class _SamajyamHistoryList extends StatelessWidget {
  final String teamName;
  const _SamajyamHistoryList({required this.teamName});

  DateTime _asDateTime(dynamic val) {
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  Future<void> _deleteEntry(BuildContext context, String docId) async {
    final messenger = ScaffoldMessenger.of(context);
    await Supabase.instance.client
        .from('samajyam_performances')
        .delete()
        .eq('id', docId);
    messenger.showSnackBar(
      const SnackBar(
        content: Text("Entry Deleted"),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _sendNotificationForDate(
    BuildContext context,
    String dateString,
    List<Map<String, dynamic>> events,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final List<Map<String, dynamic>> notifs = [];

    for (var ev in events) {
      String studentId = (ev['performer_id'] ?? ev['performerId'] ?? '').toString();
      String eventName = (ev['event_name'] ?? ev['eventName'] ?? 'an event').toString();
      String topic = (ev['topic'] ?? 'Literary Summit').toString();
      String date = dateString;

      if (studentId.isNotEmpty) {
        notifs.add({
          'student_id': studentId,
          'title': 'Samajyam Notice ($topic)',
          'message':
              'You have been assigned to $eventName ($topic) on $date. Please be prepared!',
          'type': 'samajyam_summit',
        });
      }
    }

    if (notifs.isNotEmpty) {
      await Supabase.instance.client.from('notifications').insert(notifs);
      messenger.showSnackBar(
        SnackBar(
          content: Text("Successfully sent ${notifs.length} notifications!"),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("No valid students found to notify."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('samajyam_performances')
          .stream(primaryKey: ['id'])
          .eq('team', teamName.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Database Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              "No performances recorded for $teamName yet.",
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          );
        }

        // Group the documents by formatted Date String
        Map<String, List<Map<String, dynamic>>> groupedByDate = {};
        for (var data in docs) {
          DateTime dt = _asDateTime(data['date']);
          String formattedDate = DateFormat('dd MMM yyyy').format(dt.toLocal());
          groupedByDate.putIfAbsent(formattedDate, () => []).add(data);
        }

        List<String> sortedDates = groupedByDate.keys.toList();
        sortedDates.sort((a, b) {
          DateTime dateA = DateFormat('dd MMM yyyy').parse(a);
          DateTime dateB = DateFormat('dd MMM yyyy').parse(b);
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            String dateString = sortedDates[index];
            List<Map<String, dynamic>> dateDocs = groupedByDate[dateString]!;

            // Extract general Info from the first doc of the day
            var firstDocData = dateDocs.first;
            DateTime dt = _asDateTime(firstDocData['date']);
            String timeString = DateFormat('hh:mm a').format(dt.toLocal());
            String venueString = (firstDocData['venue'] ?? 'TBD').toString();

            // Split into ULA and ALIYA
            List<Map<String, dynamic>> ulaDocs = dateDocs
                .where((d) => d['category'] == 'ULA')
                .toList();
            List<Map<String, dynamic>> aliyaDocs = dateDocs
                .where((d) => d['category'] == 'ALIYA')
                .toList();

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "LITERARY SUMMIT",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.date_range,
                                    color: Color(0xFF2E7D32),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateString,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timeString,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    venueString,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            _sendNotificationForDate(
                              context,
                              dateString,
                              dateDocs,
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_active,
                            size: 16,
                          ),
                          label: const Text("Notify"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),

                    // --- ULA EVENTS ---
                    if (ulaDocs.isNotEmpty) ...[
                      const Center(
                        child: Text(
                          "ULA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...ulaDocs.map((doc) => _buildEventRow(context, doc)),
                      const SizedBox(height: 15),
                    ],

                    // --- ALIYA EVENTS ---
                    if (aliyaDocs.isNotEmpty) ...[
                      const Center(
                        child: Text(
                          "ALIYA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...aliyaDocs.map((doc) => _buildEventRow(context, doc)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventRow(BuildContext context, Map<String, dynamic> data) {
    String docId = data['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.star, color: Color(0xFF2E7D32), size: 14),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              data['event_name'] ?? data['eventName'] ?? "Unknown Event",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const Text(":", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              data['performer'] ?? "Unknown",
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            onPressed: () => _deleteEntry(context, docId),
            tooltip: "Delete Entry",
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
