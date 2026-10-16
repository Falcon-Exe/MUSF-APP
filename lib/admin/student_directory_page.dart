import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../services/cloud_storage_service.dart';
import 'add_student_page.dart';

class StudentDirectoryPage extends StatefulWidget {
  const StudentDirectoryPage({super.key});

  @override
  State<StudentDirectoryPage> createState() => _StudentDirectoryPageState();
}

class _StudentDirectoryPageState extends State<StudentDirectoryPage> {
  static const int _pageSize = 30;
  static const String _studentSelect =
      'id,student_id,cic_no,full_name,course,class_name,email,phone,role,assigned_role,designation,role_description,profile_image_url,committee_name,is_admin,union_total_paid,union_balance,store_balance';

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _students = [];
  Timer? _searchDebounce;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreStudents = true;
  Object? _loadError;
  int _nextStudentIndex = 0;
  String _selectedCourse = 'All';

  static const List<String> _courseFilters = [
    'All',
    'Thamheediyya Ula',
    'Thamheediyya Saniya',
    'Aliya Ula',
    'Aliya Saniya',
    'Aliya Salisa',
    'Graduated',
  ];

  static const Map<String, String> _rolesMap = {
    'None': 'None',
    'God Mode 👑': 'God',
    'Chairman': 'Chairman',
    'General Secretary': 'General Secretary',
    'Treasurer': 'Treasurer',
    'CUC': 'CUC',
    'Vice President': 'Vice President',
    'Joint Secretary': 'Joint Secretary',
    'President': 'President',
    'Secretary': 'Secretary',
    'Literary': 'Literary Coordinator',
    'Fine Arts': 'Fine Arts Coordinator',
    'Social Affairs': 'Social Affairs Officer',
    'Bank': 'Bank Manager',
    'Research': 'Research Coordinator',
    'PRD': 'Public Relations Officer',
    'Garden': 'Garden Supervisor',
    'Medical': 'Medical Coordinator',
    'Sports': 'Sports Coordinator',
    'Store': 'Store Keeper',
    'Library': 'Library coordinator',
    'Union Director': 'Union Director',
  };

  static const List<String> _committeeNames = [
    'None',
    'Library Committee',
    'Literary Committee',
    'Fine Arts Committee',
    'Social Affairs',
    'Bank Committee',
    'Research Committee',
    'PRD Committee',
    'Garden Committee',
    'Medical Committee',
    'Sports Committee',
    'Store Committee',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadStudents(reset: true));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        _isInitialLoading ||
        !_hasMoreStudents) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      unawaited(_loadStudents());
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) unawaited(_loadStudents(reset: true));
    });
  }

  void _selectCourse(String course) {
    if (_selectedCourse == course) return;
    setState(() => _selectedCourse = course);
    unawaited(_loadStudents(reset: true));
  }

  Future<void> _loadStudents({bool reset = false}) async {
    if (_isLoadingMore || (_isInitialLoading && !reset)) return;

    if (reset) {
      setState(() {
        _students.clear();
        _nextStudentIndex = 0;
        _hasMoreStudents = true;
        _loadError = null;
        _isInitialLoading = true;
        _isLoadingMore = false;
      });
    } else {
      if (!_hasMoreStudents) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final page = await _fetchStudentPage(
        start: _nextStudentIndex,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _students.addAll(page);
        _nextStudentIndex += page.length;
        _hasMoreStudents = page.length == _pageSize;
        _isInitialLoading = false;
        _isLoadingMore = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshStudents() async {
    await _loadStudents(reset: true);
  }

  Future<List<Map<String, dynamic>>> _fetchStudentPage({
    required int start,
    required int limit,
  }) async {
    final end = start + limit - 1;
    final client = supabase.Supabase.instance.client;
    var query = client.from('students').select(_studentSelect);

    if (_selectedCourse != 'All') {
      query = query.eq('course', _selectedCourse);
    }

    final search = _searchController.text.trim();
    if (search.isNotEmpty) {
      final escaped = search.replaceAll(',', r'\,');
      query = query.or(
        'full_name.ilike.%$escaped%,student_id.eq.$escaped,cic_no.eq.$escaped',
      );
    }

    final rows = await query
        .order('course')
        .order('full_name')
        .range(start, end);

    return List<Map<String, dynamic>>.from(
      rows.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  Future<int> _updateStudentsByCourse(String course, String nextCourse) async {
    final rows = await supabase.Supabase.instance.client
        .from('students')
        .update({'course': nextCourse, 'class_name': nextCourse})
        .ilike('course', course)
        .select('student_id');

    return List<Map<String, dynamic>>.from(rows).length;
  }

  Future<List<Map<String, dynamic>>> _fetchStudentsInCourse(
    String courseName,
  ) async {
    final rows = await supabase.Supabase.instance.client
        .from('students')
        .select('id,student_id')
        .eq('course', courseName)
        .order('course')
        .order('full_name');

    return List<Map<String, dynamic>>.from(
      rows.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  String _text(Map<String, dynamic> student, String key) =>
      student[key]?.toString().trim() ?? '';

  String _studentName(Map<String, dynamic> student) {
    final name = _text(student, 'full_name');
    return name.isEmpty ? 'Unknown Student' : name;
  }

  String _studentId(Map<String, dynamic> student) {
    final id = _text(student, 'student_id');
    return id.isEmpty ? 'No ID' : id;
  }

  String _courseName(Map<String, dynamic> student) {
    final course = _text(student, 'course');
    return course.isEmpty ? 'Not Specified' : course;
  }

  String _roleBadge(Map<String, dynamic> student) {
    final designation = _text(student, 'designation');
    if (designation.isNotEmpty) return designation;
    return _text(student, 'assigned_role');
  }

  String _safeDropdownValue(
    String rawValue,
    Iterable<String> allowedValues, {
    String fallback = 'None',
  }) {
    final normalizedRaw = rawValue.trim().toLowerCase();
    for (final value in allowedValues) {
      if (value.trim().toLowerCase() == normalizedRaw) return value;
    }
    return allowedValues.contains(fallback) ? fallback : allowedValues.first;
  }

  Widget _studentDetailLine(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      '$label: $value',
      style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
    );
  }

  Future<void> _deleteStudentRow(Map<String, dynamic> student) async {
    final id = _text(student, 'id');
    final studentId = _text(student, 'student_id');
    final query = supabase.Supabase.instance.client.from('students').delete();

    if (id.isNotEmpty) {
      await query.eq('id', id);
      return;
    }
    if (studentId.isNotEmpty) {
      await query.eq('student_id', studentId);
    }
  }

  Future<void> _updateStudentRow(
    Map<String, dynamic> student,
    Map<String, dynamic> values,
  ) async {
    final id = _text(student, 'id');
    final studentId = _text(student, 'student_id');
    final query = supabase.Supabase.instance.client
        .from('students')
        .update(values);

    if (id.isNotEmpty) {
      await query.eq('id', id);
      return;
    }
    if (studentId.isNotEmpty) {
      await query.eq('student_id', studentId);
    }
  }

  Future<void> _deleteCourse(
    String courseName,
    List<Map<String, dynamic>> students,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entire Course'),
        content: Text(
          'Are you sure you want to permanently delete all students in $courseName? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final courseStudents = await _fetchStudentsInCourse(courseName);
      for (final student in courseStudents) {
        await _deleteStudentRow(student);
      }
      if (!mounted) return;
      navigator.pop();
      unawaited(_refreshStudents());
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Course deleted!')),
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteStudent(Map<String, dynamic> student) async {
    final name = _studentName(student);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to remove $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await _deleteStudentRow(student);
    unawaited(_refreshStudents());
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Student deleted!')),
    );
  }

  void _editStudent(Map<String, dynamic> student) {
    final nameController = TextEditingController(text: _studentName(student));
    final idController = TextEditingController(
      text: _text(student, 'student_id'),
    );
    final emailController = TextEditingController(
      text: _text(student, 'email'),
    );
    final phoneController = TextEditingController(
      text: _text(student, 'phone'),
    );

    final List<String> allowedCourses = [
      'Thamheediyya Ula',
      'Thamheediyya Saniya',
      'Aliya Ula',
      'Aliya Saniya',
      'Aliya Salisa',
    ];

    final currentCourse = _courseName(student);
    if (currentCourse != 'Not Specified' &&
        !allowedCourses.contains(currentCourse)) {
      allowedCourses.insert(0, currentCourse);
    }
    String selectedCourse = currentCourse == 'Not Specified'
        ? allowedCourses.first
        : currentCourse;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Student Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCourse,
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                      ),
                      items: allowedCourses
                          .map(
                            (course) => DropdownMenuItem(
                              value: course,
                              child: Text(course),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => selectedCourse = value);
                        }
                      },
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final newId = idController.text.trim();
                    if (newName.isEmpty || newId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and Student ID are required.'),
                        ),
                      );
                      return;
                    }

                    try {
                      await _updateStudentRow(student, {
                        'full_name': newName,
                        'student_id': newId,
                        'course': selectedCourse,
                        'class_name': selectedCourse,
                        'email': emailController.text.trim(),
                        'phone': phoneController.text.trim(),
                      });

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      unawaited(_refreshStudents());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Student details updated!'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _assignRole(Map<String, dynamic> student) {
    final currentRoleRaw = _roleBadge(student);
    String selectedDept = 'None';
    for (final entry in _rolesMap.entries) {
      if (entry.value.trim().toLowerCase() ==
          currentRoleRaw.trim().toLowerCase()) {
        selectedDept = entry.key;
        break;
      }
    }
    selectedDept = _safeDropdownValue(selectedDept, _rolesMap.keys);
    String selectedCommittee = _safeDropdownValue(
      _text(student, 'committee_name'),
      _committeeNames,
    );
    final descriptionController = TextEditingController(
      text: _text(student, 'role_description'),
    );
    final photoUrlController = TextEditingController(
      text: _text(student, 'profile_image_url'),
    );
    bool isUploadingPhoto = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Assign Role'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedDept,
                      decoration: const InputDecoration(
                        labelText: 'Role / Designation',
                        border: OutlineInputBorder(),
                      ),
                      items: _rolesMap.keys.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(
                            dept == 'None'
                                ? 'None (Remove Role)'
                                : _rolesMap[dept]!,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => selectedDept = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCommittee,
                      decoration: const InputDecoration(
                        labelText: 'Committee Name',
                        border: OutlineInputBorder(),
                      ),
                      items: _committeeNames.map((committee) {
                        return DropdownMenuItem(
                          value: committee,
                          child: Text(
                            committee == 'None'
                                ? 'None (No committee)'
                                : committee,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() => selectedCommittee = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: photoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Photo URL optional',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isUploadingPhoto
                            ? null
                            : () async {
                                final studentId = _text(student, 'student_id');
                                if (studentId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Student ID is required to upload a photo.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setStateDialog(() => isUploadingPhoto = true);
                                try {
                                  final uploadedUrl = await _pickAndUploadPhoto(
                                    context,
                                    studentId,
                                  );
                                  if (uploadedUrl == null) return;
                                  photoUrlController.text = uploadedUrl;
                                  await supabase.Supabase.instance.client
                                      .from('students')
                                      .update({
                                        'profile_image_url': uploadedUrl,
                                      })
                                      .eq('student_id', studentId);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Photo uploaded.'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Photo upload failed: $e'),
                                    ),
                                  );
                                } finally {
                                  if (context.mounted) {
                                    setStateDialog(
                                      () => isUploadingPhoto = false,
                                    );
                                  }
                                }
                              },
                        icon: isUploadingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file_rounded),
                        label: Text(
                          isUploadingPhoto ? 'Uploading...' : 'Upload Photo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    descriptionController.dispose();
                    photoUrlController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final studentId = _text(student, 'student_id');
                    if (studentId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Student ID is required to assign a role.',
                          ),
                        ),
                      );
                      return;
                    }

                    final updateRole = selectedDept == 'None'
                        ? ''
                        : _rolesMap[selectedDept]!;
                    final updateCommittee = selectedCommittee == 'None'
                        ? 'None'
                        : selectedCommittee;
                    final profileImageUrl = photoUrlController.text.trim();

                    final String lowerRole = updateRole.toLowerCase();
                    final bool isGodRole = lowerRole.contains('god') || lowerRole.contains('super admin');
                    final bool isExecOrAdmin = isGodRole ||
                        lowerRole.contains('admin') ||
                        lowerRole.contains('executive') ||
                        lowerRole.contains('president') ||
                        lowerRole.contains('secretary') ||
                        lowerRole.contains('treasurer');

                    await supabase.Supabase.instance.client
                        .from('students')
                        .update({
                          'assigned_role': updateRole,
                          'designation': updateRole,
                          if (isGodRole) 'role': 'god' else if (isExecOrAdmin) 'role': 'admin',
                          if (isExecOrAdmin || isGodRole) 'is_admin': true,
                          'committee_name': updateCommittee,
                          'role_description': descriptionController.text.trim(),
                          'profile_image_url': profileImageUrl.isEmpty
                              ? null
                              : profileImageUrl,
                        })
                        .eq('student_id', studentId);

                    if (!context.mounted) return;
                    descriptionController.dispose();
                    photoUrlController.dispose();
                    Navigator.pop(context);
                    unawaited(_refreshStudents());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Role updated!')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _pickAndUploadPhoto(
    BuildContext context,
    String studentId,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read image file.')),
        );
      }
      return null;
    }

    const maxImageBytes = 2 * 1024 * 1024;
    if (bytes.length > maxImageBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload image below 2MB.')),
        );
      }
      return null;
    }

    final extension = file.extension?.toLowerCase().trim();
    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    final safeStudentId = studentId.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    final fileName =
        '${safeStudentId}_${DateTime.now().millisecondsSinceEpoch}.${extension?.isEmpty == false ? extension : 'jpg'}';

    final upload = await CloudStorageService().uploadBytes(
      bytes: bytes,
      folder: CloudStorageFolder.studentProfileImages,
      fileName: fileName,
      contentType: contentType,
    );
    return upload.url;
  }

  Future<void> _promoteStudents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote All Students'),
        content: const Text(
          'Are you sure you want to promote all students to the next class? '
          '(e.g., Thamheediyya Ula -> Thamheediyya Saniya). '
          'Students in Aliya Salisa will be marked as "Graduated".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Promote All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _shiftStudents(_promotionMap, 'promoted');
    }
  }

  Future<void> _depromoteStudents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Promotions (Depromote)'),
        content: const Text(
          'Are you sure you want to revert all students to their previous class?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Depromote All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _shiftStudents(_depromotionMap, 'depromoted');
    }
  }

  static const Map<String, String> _promotionMap = {
    'thamheediyya ula': 'Thamheediyya Saniya',
    'thamheediyya saniya': 'Aliya Ula',
    'aliya ula': 'Aliya Saniya',
    'aliya saniya': 'Aliya Salisa',
    'aliya salisa': 'Graduated',
  };

  static const Map<String, String> _depromotionMap = {
    'thamheediyya saniya': 'Thamheediyya Ula',
    'aliya ula': 'Thamheediyya Saniya',
    'aliya saniya': 'Aliya Ula',
    'aliya salisa': 'Aliya Saniya',
    'graduated': 'Aliya Salisa',
  };

  Future<void> _shiftStudents(
    Map<String, String> courseMap,
    String actionLabel,
  ) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      int changedCount = 0;

      for (final entry in courseMap.entries) {
        changedCount += await _updateStudentsByCourse(entry.key, entry.value);
      }

      if (!mounted) return;
      navigator.pop();
      unawaited(_refreshStudents());
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Successfully $actionLabel $changedCount students!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error during $actionLabel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Directory'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Student',
            onPressed: () => showAddStudentOptionsSheet(
              context,
            ).then((_) => _refreshStudents()),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_double_arrow_down_rounded),
            tooltip: 'Depromote Students',
            onPressed: _depromoteStudents,
          ),
          IconButton(
            icon: const Icon(Icons.upgrade_rounded),
            tooltip: 'Promote Students',
            onPressed: _promoteStudents,
          ),
        ],
      ),
      body: _buildDirectoryBody(),
    );
  }

  Widget _buildDirectoryBody() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(child: _buildStudentList()),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name, ID, or CIC no',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _courseFilters.map((course) {
                final selected = _selectedCourse == course;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(course),
                    selected: selected,
                    onSelected: (_) => _selectCourse(course),
                    selectedColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.blueGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load students: $_loadError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => unawaited(_loadStudents(reset: true)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final rows = _directoryRows();
    if (rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshStudents,
        child: ListView(
          controller: _scrollController,
          children: const [
            SizedBox(height: 180),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No students found',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Import students from sheet or add manually',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshStudents,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: rows.length + 1,
        itemBuilder: (context, index) {
          if (index == rows.length) return _buildListFooter();

          final row = rows[index];
          if (row.courseName != null) {
            return _buildCourseHeader(row.courseName!);
          }
          return _buildStudentCard(row.student!);
        },
      ),
    );
  }

  List<_DirectoryRow> _directoryRows() {
    final rows = <_DirectoryRow>[];
    String? lastCourse;

    for (final student in _students) {
      final course = _courseName(student);
      if (course != lastCourse) {
        rows.add(_DirectoryRow.course(course));
        lastCourse = course;
      }
      rows.add(_DirectoryRow.student(student));
    }

    return rows;
  }

  Widget _buildCourseHeader(String courseName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        onLongPress: () => _deleteCourse(courseName, const []),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1E293B).withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.school_rounded,
                size: 20,
                color: Color(0xFF1E293B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  courseName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                'Loaded',
                style: TextStyle(
                  color: Colors.blueGrey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final name = _studentName(student);
    final studentId = _studentId(student);
    final courseName = _courseName(student);
    final roleBadge = _roleBadge(student);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onLongPress: () => _deleteStudent(student),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: $studentId',
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            Text(
              'Course: $courseName',
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            _studentDetailLine('CIC No', _text(student, 'cic_no')),
            _studentDetailLine('Phone', _text(student, 'phone')),
            _studentDetailLine('Class', _text(student, 'class_name')),
            _studentDetailLine('Current Year', _text(student, 'current_year')),
            _studentDetailLine(
              'Total Course Years',
              _text(student, 'total_course_years'),
            ),
            _studentDetailLine('Enter Date', _text(student, 'enter_date')),
            _studentDetailLine(
              'Course End Date',
              _text(student, 'course_end_date'),
            ),
            _studentDetailLine('Blood Group', _text(student, 'blood_group')),
            _studentDetailLine('Role', _text(student, 'role')),
            _studentDetailLine('Designation', _text(student, 'designation')),
            _studentDetailLine(
              'Assigned Role',
              _text(student, 'assigned_role'),
            ),
            if (roleBadge.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  roleBadge,
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'assign') {
              _assignRole(student);
            } else if (value == 'edit') {
              _editStudent(student);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Edit Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'assign',
              child: Row(
                children: [
                  Icon(Icons.assignment_ind_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Assign Role'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: OutlinedButton.icon(
          onPressed: () => unawaited(_loadStudents()),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Load more'),
        ),
      );
    }

    if (!_hasMoreStudents) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            'All loaded',
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}

class _DirectoryRow {
  const _DirectoryRow.course(this.courseName) : student = null;
  const _DirectoryRow.student(this.student) : courseName = null;

  final String? courseName;
  final Map<String, dynamic>? student;
}
