import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:union_interface/main.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _appLoaded = false;

  // Animation Controller for the Lottie animation
  late final AnimationController _lottieController;

  static const Color _kNavy = Color(0xFF1c2e54);

  @override
  void initState() {
    super.initState();

    // Set up Lottie controller
    _lottieController = AnimationController(vsync: this);
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tryNavigate();
      }
    });

    _loadApp();
  }

  Future<void> _loadApp() async {
    // Artificial min delay for visual grace
    final stopwatch = Stopwatch()..start();

    // Pre-cache session check if needed
    try {
      final session = supabase.Supabase.instance.client.auth.currentSession;
      if (session != null && session.isExpired) {
        await supabase.Supabase.instance.client.auth.refreshSession();
      }
    } catch (e) {
      debugPrint("Pre-load error: $e");
    }

    if (stopwatch.elapsedMilliseconds < 1500) {
      await Future.delayed(
        Duration(milliseconds: 1500 - stopwatch.elapsedMilliseconds),
      );
    }

    _appLoaded = true;
    _tryNavigate(); // in case animation finishes before load
  }

  void _tryNavigate() {
    if (_appLoaded && _lottieController.isCompleted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(opacity: animation, child: const AuthGate()),
      ),
    );
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy, // Navy Blue
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Lottie.asset(
            'assets/animations/logo.json',
            controller: _lottieController,
            repeat: false,
            onLoaded: (composition) {
              // Configure the AnimationController with the duration of the
              // Lottie file and start the animation.
              _lottieController.duration = composition.duration;
              // Make sure to match the exact start condition, since the user
              // asked for no repeat.
              _lottieController.forward();
            },
            fit: BoxFit.contain, // Guarantee it fits nicely
          ),
        ),
      ),
    );
  }
}
