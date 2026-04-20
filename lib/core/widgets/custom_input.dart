import 'package:flutter/material.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';

class CustomInput extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final IconData? icon;

  const CustomInput({
    super.key,
    required this.label,
    required this.placeholder,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: placeholder,
              prefixIcon: icon != null ? Icon(icon, color: AppTheme.textSecondary, size: 20) : null,
              hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: icon != null ? 15 : 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
