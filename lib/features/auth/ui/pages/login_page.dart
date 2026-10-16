// lib/features/auth/ui/pages/login_page.dart

import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/theme/app_colors.dart';
import '../../logic/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: SingleChildScrollView(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              children: [
                // --- TOP HEADER DESIGN ---
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [palette.brandDark, palette.brand],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(100),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.brandDark,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/musf_logo.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                "LoginPage: Error loading logo: $error",
                              );
                              return const Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white70,
                                size: 50,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "WafyMajlis",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- LOGIN FORM ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 35,
                    vertical: 50,
                  ),
                  child: Column(
                    children: [
                      CustomTextInput(
                        controller: _controller.usernameController,
                        hint: "Student ID",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 25),
                      CustomTextInput(
                        controller: _controller.passwordController,
                        hint: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 40),

                      // --- LOGIN BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.brandDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          onPressed: _controller.isLoading
                              ? null
                              : () => _controller.login(context),
                          child: _controller.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "SIGN IN",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
