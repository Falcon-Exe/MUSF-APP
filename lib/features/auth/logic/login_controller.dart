// lib/features/auth/logic/login_controller.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../data/repositories/auth_repository.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository _authRepository;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  LoginController({AuthRepository? authRepository})
    : _authRepository = authRepository ?? SupabaseAuthRepository();

  bool get isLoading => _isLoading;

  Future<void> login(BuildContext context) async {
    String inputId = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (inputId.isEmpty || password.isEmpty) {
      _showError(context, "Please fill in all fields");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Format Email for Auth (If they just typed "12345", it becomes "12345@gmail.com")
      String email = inputId.contains('@') ? inputId : "$inputId@gmail.com";

      // 2. Supabase Auth login using Repository
      await _authRepository.signIn(email, password);

      // 3. AuthGate in main.dart will notice the successful login
      // and handle fetching student details and navigation automatically.
    } on supabase.AuthException catch (e) {
      debugPrint(e.message);
      if (context.mounted) _showError(context, e.message);
    } catch (e) {
      if (context.mounted) _showError(context, "Error: ${e.toString()}");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
