import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

const Color _studentGreen = Color(0xFF39544B);
const Color _studentDarkGreen = Color(0xFF233A31);
const Color _studentPageBg = Color(0xFFF6F8FB);
const Color _studentBorder = Color(0xFFE5E7EB);
const Color _studentText = Color(0xFF111827);
const Color _studentMuted = Color(0xFF6B7280);

Future<void> showAddStudentOptionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
        decoration: const BoxDecoration(
          color: _studentPageBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 42,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const Text(
              'Add Student',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _studentText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add manually or import from sheet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _studentMuted,
              ),
            ),
            const SizedBox(height: 18),
            _AddStudentChoiceCard(
              icon: Icons.edit_note_rounded,
              title: 'Manual Entry',
              subtitle: 'Create one student profile',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddStudentManualPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _AddStudentChoiceCard(
              icon: Icons.table_chart_rounded,
              title: 'Import from Sheet',
              subtitle: 'Upload multiple students from CSV or JSON',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentSheetImportPage(),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _AddStudentChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddStudentChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _studentBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: _studentGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: _studentGreen, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _studentText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: _studentMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _studentGreen.withValues(alpha: 0.72),
            ),
          ],
        ),
      ),
    );
  }
}

class AddStudentManualPage extends StatefulWidget {
  const AddStudentManualPage({super.key});

  @override
  State<AddStudentManualPage> createState() => _AddStudentManualPageState();
}

class _AddStudentManualPageState extends State<AddStudentManualPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCourse = 'Aliya Salisa';
  bool _isSaving = false;

  static const List<String> _courses = [
    'Thamheediyya Ula',
    'Thamheediyya Saniya',
    'Aliya Ula',
    'Aliya Saniya',
    'Aliya Salisa',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final fullName = _nameController.text.trim();
    final studentId = _studentIdController.text.trim();

    try {
      await supabase.Supabase.instance.client.from('students').upsert({
        'full_name': fullName,
        'student_id': studentId,
        'course': _selectedCourse,
        'class_name': _selectedCourse,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'role': 'student',
      }, onConflict: 'student_id');

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('$fullName added successfully.')),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to add student: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _studentPageBg,
      appBar: AppBar(
        title: const Text('Manual Entry'),
        backgroundColor: _studentGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_studentGreen, _studentDarkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create student profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Student ID is used as the unique key.',
                          style: TextStyle(
                            color: Color(0xFFDDE7E3),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _studentBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _ExecutiveTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.badge_rounded,
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    _ExecutiveTextField(
                      controller: _studentIdController,
                      label: 'Student ID',
                      icon: Icons.confirmation_number_rounded,
                      keyboardType: TextInputType.number,
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourse,
                      decoration: _fieldDecoration(
                        'Course',
                        Icons.school_rounded,
                      ),
                      items: _courses
                          .map(
                            (course) => DropdownMenuItem(
                              value: course,
                              child: Text(course),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCourse = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    _ExecutiveTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _ExecutiveTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.call_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _ExecutiveTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveStudent,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _isSaving ? 'Saving Student' : 'Save Student',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _studentGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _studentGreen.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }
}

class _ExecutiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ExecutiveTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _fieldDecoration(label, icon),
    );
  }
}

InputDecoration _fieldDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _studentGreen),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _studentBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _studentBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _studentGreen, width: 1.4),
    ),
  );
}

class StudentSheetImportPage extends StatefulWidget {
  const StudentSheetImportPage({super.key});

  @override
  State<StudentSheetImportPage> createState() => _StudentSheetImportPageState();
}

class _StudentSheetImportPageState extends State<StudentSheetImportPage> {
  bool _isUploading = false;
  int _uploadedCount = 0;
  int _totalRows = 0;

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final rows = const CsvToListConverter(
      eol: '\n',
    ).convert(utf8.decode(result.files.single.bytes!));

    if (rows.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sheet has no data rows.')));
      return;
    }

    final headers = rows.first
        .map((header) => _normalizeHeader(header.toString()))
        .toList();
    final dataRows = rows.sublist(1);
    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
      _totalRows = dataRows.length;
    });

    final List<String> errors = [];
    final List<Map<String, dynamic>> students = [];

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final parsedRow = <String, dynamic>{};
      for (int column = 0; column < headers.length; column++) {
        if (headers[column].isEmpty) continue;
        parsedRow[headers[column]] = column < row.length ? row[column] : null;
      }
      debugPrint('Row ${i + 2} parsed keys: ${parsedRow.keys.join(', ')}');

      final fullName = _valueFor(parsedRow, _fullNameHeaders);
      final studentId = _valueFor(parsedRow, _studentIdHeaders);
      final course = _valueFor(parsedRow, _courseHeaders);
      final email = _valueFor(parsedRow, _emailHeaders);
      final phoneNo = _valueFor(parsedRow, _phoneHeaders);
      final address = _valueFor(parsedRow, _addressHeaders);
      final cicNo = _valueFor(parsedRow, _cicNoHeaders);
      final currentYear = _valueFor(parsedRow, _currentYearHeaders);
      final totalCourseYears = _valueFor(parsedRow, _totalCourseYearsHeaders);
      final enterDate = _valueFor(parsedRow, _enterDateHeaders);
      final courseEndDate = _valueFor(parsedRow, _courseEndDateHeaders);
      final bloodGroup = _valueFor(parsedRow, _bloodGroupHeaders);
      final designation = _valueFor(parsedRow, _designationHeaders);
      final assignedRole = _valueFor(parsedRow, _assignedRoleHeaders);

      if (fullName.isEmpty || studentId.isEmpty) {
        errors.add('Row ${i + 2} missing student_id/full_name');
        continue;
      }

      final student = <String, dynamic>{
        'full_name': fullName,
        'student_id': studentId,
        'role': 'student',
      };

      if (course.isNotEmpty) {
        student['course'] = course;
        student['class_name'] = course;
      }
      if (email.isNotEmpty) student['email'] = email;
      if (phoneNo.isNotEmpty) student['phone'] = phoneNo;
      if (address.isNotEmpty) student['address'] = address;
      if (cicNo.isNotEmpty) student['cic_no'] = cicNo;
      if (currentYear.isNotEmpty) student['current_year'] = currentYear;
      if (totalCourseYears.isNotEmpty) {
        student['total_course_years'] = totalCourseYears;
      }
      if (enterDate.isNotEmpty) student['enter_date'] = enterDate;
      if (courseEndDate.isNotEmpty) student['course_end_date'] = courseEndDate;
      if (bloodGroup.isNotEmpty) student['blood_group'] = bloodGroup;
      if (designation.isNotEmpty) student['designation'] = designation;
      if (assignedRole.isNotEmpty) student['assigned_role'] = assignedRole;

      students.add(student);
    }

    if (!mounted) return;
    if (students.isEmpty) {
      setState(() => _isUploading = false);
      _showImportResult(0, errors);
      return;
    }

    try {
      await supabase.Supabase.instance.client
          .from('students')
          .upsert(students, onConflict: 'student_id');
      await _reloadStudentsFromSupabase();
      if (mounted) setState(() => _uploadedCount = students.length);
    } catch (e) {
      errors.add('Supabase import failed: $e');
    }

    if (!mounted) return;
    setState(() => _isUploading = false);
    _showImportResult(errors.isEmpty ? students.length : 0, errors);
  }

  Future<void> _pickAndImportJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final List<Map<String, dynamic>> students;
    try {
      students = _decodeJsonStudents(result.files.single.bytes!);
    } on FormatException catch (e) {
      if (!mounted) return;
      _showImportError('Invalid JSON format: ${e.message}');
      return;
    } catch (e) {
      if (!mounted) return;
      _showImportError('Invalid JSON format: $e');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
      _totalRows = students.length;
    });

    try {
      await supabase.Supabase.instance.client
          .from('students')
          .upsert(students, onConflict: 'student_id');
      await _reloadStudentsFromSupabase();

      if (!mounted) return;
      setState(() => _uploadedCount = students.length);
      _showImportResult(students.length, const []);
    } catch (e) {
      if (!mounted) return;
      _showImportError('Failed to import JSON file: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  List<Map<String, dynamic>> _decodeJsonStudents(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! List) {
      throw const FormatException('File must contain a JSON array.');
    }
    if (decoded.isEmpty) {
      throw const FormatException('File has no students to import.');
    }

    final students = <Map<String, dynamic>>[];
    for (int i = 0; i < decoded.length; i++) {
      final raw = decoded[i];
      if (raw is! Map) {
        throw FormatException('Student item ${i + 1} must be an object.');
      }

      final normalizedRaw = _normalizeMapKeys(raw);
      debugPrint(
        'JSON student item ${i + 1} parsed keys: ${normalizedRaw.keys.join(', ')}',
      );

      final fullName = _valueFor(normalizedRaw, _fullNameHeaders);
      final studentId = _valueFor(normalizedRaw, _studentIdHeaders);
      if (fullName.isEmpty || studentId.isEmpty) {
        throw FormatException('Row ${i + 1} missing student_id/full_name');
      }

      final course = _valueFor(normalizedRaw, _courseHeaders);
      final email = _valueFor(normalizedRaw, _emailHeaders);
      final phone = _valueFor(normalizedRaw, _phoneHeaders);
      final address = _valueFor(normalizedRaw, _addressHeaders);
      final role = _valueFor(normalizedRaw, const ['role']);
      final cicNo = _valueFor(normalizedRaw, _cicNoHeaders);
      final currentYear = _valueFor(normalizedRaw, _currentYearHeaders);
      final totalCourseYears = _valueFor(normalizedRaw, _totalCourseYearsHeaders);
      final enterDate = _valueFor(normalizedRaw, _enterDateHeaders);
      final courseEndDate = _valueFor(normalizedRaw, _courseEndDateHeaders);
      final bloodGroup = _valueFor(normalizedRaw, _bloodGroupHeaders);
      final designation = _valueFor(normalizedRaw, _designationHeaders);
      final assignedRole = _valueFor(normalizedRaw, _assignedRoleHeaders);

      final student = <String, dynamic>{
        'full_name': fullName,
        'student_id': studentId,
        'role': role.isEmpty ? 'student' : role,
      };

      if (course.isNotEmpty) {
        student['course'] = course;
        student['class_name'] = course;
      }
      if (email.isNotEmpty) student['email'] = email;
      if (phone.isNotEmpty) student['phone'] = phone;
      if (address.isNotEmpty) student['address'] = address;
      if (cicNo.isNotEmpty) student['cic_no'] = cicNo;
      if (currentYear.isNotEmpty) student['current_year'] = currentYear;
      if (totalCourseYears.isNotEmpty) {
        student['total_course_years'] = totalCourseYears;
      }
      if (enterDate.isNotEmpty) student['enter_date'] = enterDate;
      if (courseEndDate.isNotEmpty) student['course_end_date'] = courseEndDate;
      if (bloodGroup.isNotEmpty) student['blood_group'] = bloodGroup;
      if (designation.isNotEmpty) student['designation'] = designation;
      if (assignedRole.isNotEmpty) student['assigned_role'] = assignedRole;

      students.add(student);
    }

    return students;
  }

  static const List<String> _studentIdHeaders = [
    'student_id',
    'studentid',
    'id',
    'cic_no',
    'admission_no',
  ];

  static const List<String> _cicNoHeaders = ['cic_no', 'cic'];

  static const List<String> _fullNameHeaders = [
    'full_name',
    'name',
    'student_name',
  ];

  static const List<String> _phoneHeaders = [
    'phone',
    'phone_no',
    'mobile',
    'mobile_no',
  ];

  static const List<String> _courseHeaders = ['course', 'class_name'];

  static const List<String> _emailHeaders = ['email', 'personal_email'];

  static const List<String> _addressHeaders = ['address', 'home_address'];

  static const List<String> _currentYearHeaders = ['current_year', 'year'];

  static const List<String> _totalCourseYearsHeaders = [
    'total_course_years',
    'course_years',
  ];

  static const List<String> _enterDateHeaders = [
    'enter_date',
    'entry_date',
    'admission_date',
  ];

  static const List<String> _courseEndDateHeaders = [
    'course_end_date',
    'end_date',
  ];

  static const List<String> _bloodGroupHeaders = ['blood_group'];

  static const List<String> _designationHeaders = ['designation'];

  static const List<String> _assignedRoleHeaders = [
    'assigned_role',
    'assignedrole',
  ];

  Future<List<Map<String, dynamic>>> _reloadStudentsFromSupabase() async {
    final rows = await supabase.Supabase.instance.client
        .from('students')
        .select()
        .order('course')
        .order('full_name');
    return List<Map<String, dynamic>>.from(
      rows.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  Map<String, dynamic> _normalizeMapKeys(Map raw) {
    final normalized = <String, dynamic>{};
    raw.forEach((key, value) {
      final normalizedKey = _normalizeHeader(key.toString());
      if (normalizedKey.isEmpty) return;
      normalized[normalizedKey] = value;
    });
    return normalized;
  }

  String _valueFor(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = _textValue(row[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _normalizeHeader(String header) {
    return header
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^\d+\s*[\.\)]\s*'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  String _textValue(Object? value) => value?.toString().trim() ?? '';

  void _showImportError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showImportResult(int successCount, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              errors.isEmpty ? Icons.check_circle : Icons.warning_rounded,
              color: errors.isEmpty ? _studentGreen : Colors.orange,
            ),
            const SizedBox(width: 10),
            const Text('Import Complete'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Successfully imported: $successCount students.'),
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '${errors.length} row(s) failed:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...errors
                    .take(8)
                    .map(
                      (error) => Text(
                        error,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                if (errors.length > 8)
                  Text(
                    '+ ${errors.length - 8} more',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _studentGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _studentPageBg,
      appBar: AppBar(
        title: const Text('Import from Sheet'),
        backgroundColor: _studentGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _studentBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 74,
                        width: 74,
                        decoration: BoxDecoration(
                          color: _studentGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.table_chart_rounded,
                          color: _studentGreen,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Upload student sheet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _studentText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose a CSV sheet or JSON list to import student records.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: _studentMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _ImportOptionCard(
                  icon: Icons.upload_file_rounded,
                  title: 'Choose CSV File',
                  subtitle:
                      'Columns: Full Name, Course, Email, Phone No, Student ID',
                  onTap: _isUploading ? null : _pickAndImport,
                ),
                const SizedBox(height: 12),
                _ImportOptionCard(
                  icon: Icons.data_object_rounded,
                  title: 'Choose JSON File',
                  subtitle:
                      'JSON array with full_name, student_id, and optional details',
                  onTap: _isUploading ? null : _pickAndImportJson,
                ),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.52),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: _studentGreen),
                      const SizedBox(height: 18),
                      const Text(
                        'Importing Students',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$_uploadedCount / $_totalRows',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _studentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ImportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: isEnabled ? 1 : 0.58,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _studentBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: _studentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: _studentGreen, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _studentText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: _studentMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _studentGreen.withValues(alpha: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
