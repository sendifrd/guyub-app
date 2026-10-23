import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';

enum GuyubButtonVariant { primary, secondary, neutral, danger, dangerSolid }

enum GuyubButtonSize { md, sm }

/// Tombol Guyub (DESIGN.md: radius 12, tinggi 48 atau 44, teks 15/700, tanpa bentuk pil).
///
/// GuyubButton(label: 'Setujui', onPressed: _setujui)
/// GuyubButton(label: 'Tolak', variant: GuyubButtonVariant.danger, onPressed: _tolak)
class GuyubButton extends StatelessWidget {
  const GuyubButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GuyubButtonVariant.primary,
    this.size = GuyubButtonSize.md,
    this.icon,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final GuyubButtonVariant variant;
  final GuyubButtonSize size;
  final IconData? icon;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final height = size == GuyubButtonSize.md ? 48.0 : 44.0;
    final (Color bg, Color fg, Color? borderColor) = switch (variant) {
      GuyubButtonVariant.primary => (GuyubColors.primary, Colors.white, null),
      GuyubButtonVariant.secondary => (GuyubColors.surface, GuyubColors.primary, GuyubColors.primary),
      GuyubButtonVariant.neutral => (GuyubColors.surface, GuyubColors.ink, GuyubColors.lineInput),
      GuyubButtonVariant.danger => (GuyubColors.surface, GuyubColors.danger, GuyubColors.dangerBorder),
      GuyubButtonVariant.dangerSolid => (GuyubColors.danger, Colors.white, null),
    };
    final disabled = onPressed == null || loading;

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(expand ? double.infinity : 0, height)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: size == GuyubButtonSize.md ? 20 : 16)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(GuyubRadius.interactive))),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? GuyubColors.surface : bg),
      foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? GuyubColors.inkMuted : fg),
      side: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return const BorderSide(color: GuyubColors.lineInput);
        return borderColor == null ? BorderSide.none : BorderSide(color: borderColor);
      }),
      textStyle: WidgetStatePropertyAll(GoogleFonts.plusJakartaSans(fontSize: size == GuyubButtonSize.md ? 15 : 14, fontWeight: FontWeight.w700)),
    );

    final child = loading
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]);

    return TextButton(onPressed: disabled ? null : onPressed, style: style, child: child);
  }
}
