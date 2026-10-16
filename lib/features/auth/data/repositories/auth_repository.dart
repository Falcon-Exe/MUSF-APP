// lib/features/auth/data/repositories/auth_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter/foundation.dart';

abstract class AuthRepository {
  Future<supabase.AuthResponse> signIn(String email, String password);
}

class SupabaseAuthRepository implements AuthRepository {
  final supabase.SupabaseClient _client;

  SupabaseAuthRepository({supabase.SupabaseClient? client})
    : _client = client ?? supabase.Supabase.instance.client;

  @override
  Future<supabase.AuthResponse> signIn(String email, String password) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on supabase.AuthException catch (e) {
      debugPrint(e.message);
      rethrow;
    }
  }
}
