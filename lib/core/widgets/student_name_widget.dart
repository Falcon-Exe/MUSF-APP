// lib/core/widgets/student_name_widget.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentNameWidget extends StatelessWidget {
  final String studentId;
  final TextStyle style;

  const StudentNameWidget({
    super.key,
    required this.studentId,
    required this.style,
  });

  Future<String> _fetchStudentName(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return "---";

    try {
      final res = await Supabase.instance.client
          .from('students')
          .select('full_name')
          .eq('student_id', cleanId)
          .maybeSingle();

      if (res != null && res['full_name'] != null) {
        return res['full_name'].toString();
      }
    } catch (_) {
      // Fallback below
    }
    return "Student ($cleanId)";
  }

  @override
  Widget build(BuildContext context) {
    if (studentId.isEmpty) return Text("---", style: style);

    return FutureBuilder<String>(
      future: _fetchStudentName(studentId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data!, style: style);
        }
        return Text("...", style: style);
      },
    );
  }
}

