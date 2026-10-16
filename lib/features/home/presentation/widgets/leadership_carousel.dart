// lib/features/home/presentation/widgets/leadership_carousel.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'glass_leader_card.dart';

class LeadershipCarousel extends StatelessWidget {
  const LeadershipCarousel({super.key});

  static const Set<String> _executiveRoles = {
    'chairman',
    'general secretary',
    'treasurer',
    'cuc',
    'president',
    'secretary',
    'vice president',
    'joint secretary',
  };

  Future<List<Map<String, dynamic>>> _loadLeadershipMembers() async {
    final rows = await Supabase.instance.client
        .from('students')
        .select(
          'full_name,designation,assigned_role,role_description,profile_image_url',
        )
        .order('full_name');

    final students = rows
        .map((row) => Map<String, dynamic>.from(row))
        .where((student) {
          final designation = _normalize(student['designation']);
          final assignedRole = _normalize(student['assigned_role']);
          return _executiveRoles.contains(designation) ||
              _executiveRoles.contains(assignedRole);
        })
        .take(4)
        .toList();

    return students;
  }

  String _normalize(dynamic value) =>
      (value ?? '').toString().toLowerCase().trim();

  String _text(Map<String, dynamic> data, String key, {String fallback = ''}) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _leaderRole(Map<String, dynamic> data) {
    final designation = _text(data, 'designation');
    if (designation.isNotEmpty) return designation;
    return _text(data, 'assigned_role', fallback: 'Member');
  }

  IconData _iconForRole(String role) {
    switch (_normalize(role)) {
      case 'chairman':
      case 'president':
        return Icons.gavel_rounded;
      case 'general secretary':
      case 'secretary':
      case 'joint secretary':
        return Icons.history_edu_rounded;
      case 'treasurer':
        return Icons.account_balance_wallet_rounded;
      case 'cuc':
        return Icons.verified_user_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color _colorForRole(String role) {
    switch (_normalize(role)) {
      case 'chairman':
      case 'president':
        return const Color(0xFF0F766E);
      case 'general secretary':
      case 'secretary':
      case 'joint secretary':
        return const Color(0xFF2563EB);
      case 'treasurer':
        return const Color(0xFFB45309);
      case 'cuc':
        return const Color(0xFF7C3AED);
      case 'vice president':
        return const Color(0xFFBE123C);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadLeadershipMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 250,
            child: Center(
              child: Text(
                'Could not load leadership',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final leaders = snapshot.data ?? const <Map<String, dynamic>>[];
        if (leaders.isEmpty) {
          return const SizedBox(
            height: 250,
            child: Center(child: Text('No leadership members assigned yet.')),
          );
        }

        return SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: leaders.length,
            itemBuilder: (context, index) {
              final data = leaders[index];
              final role = _leaderRole(data);

              return GlassLeaderCard(
                name: _text(data, 'full_name', fallback: 'Unknown Student'),
                role: role,
                color: _colorForRole(role),
                icon: _iconForRole(role),
                imageUrl: _text(data, 'profile_image_url'),
                description: _text(data, 'role_description'),
              );
            },
          ),
        );
      },
    );
  }
}
