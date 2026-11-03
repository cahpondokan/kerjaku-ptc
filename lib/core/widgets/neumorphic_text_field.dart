import 'package:flutter/material.dart';
import 'package:lembur/app/theme/app_colors.dart';

class NeumorphicTextField extends StatelessWidget {
  const NeumorphicTextField({
    required this.controller,
    required this.label,
    super.key,
    this.hint,
    this.icon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primary),
      ),
    );
  }
}
