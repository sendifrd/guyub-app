import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Kolom isian berlabel (label 13/600 di atas, tinggi 44, radius 12).
/// errorText diisi dari pesan error 422 API untuk kolom yang sama.
class GuyubInput extends StatelessWidget {
  const GuyubInput({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.obscure = false,
    this.mono = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.onSubmitted,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool obscure;
  final bool mono;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: GuyubText.fieldLabel),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          maxLines: obscure ? 1 : maxLines,
          style: mono ? GuyubText.mono() : GuyubText.body,
          decoration: InputDecoration(hintText: hint, errorText: errorText, suffixIcon: suffix),
        ),
        if (helper != null && errorText == null) ...[
          const SizedBox(height: 6),
          Text(helper!, style: GuyubText.secondary),
        ],
      ],
    );
  }
}
