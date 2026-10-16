// lib/core/widgets/custom_text_input.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTextInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;

  const CustomTextInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
  });

  @override
  State<CustomTextInput> createState() => _CustomTextInputState();
}

class _CustomTextInputState extends State<CustomTextInput> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _isObscured : false,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon, color: palette.accent),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                    color: palette.textMuted,
                  ),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
