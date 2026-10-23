import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';

enum AlertTone { sukses, galat, info, peringatan }

/// Kotak pesan di dalam layar (bukan dialog).
class AlertBox extends StatelessWidget {
  const AlertBox(this.message, {super.key, this.tone = AlertTone.info});

  final String message;
  final AlertTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = switch (tone) {
      AlertTone.sukses => (GuyubColors.primaryTint, GuyubColors.primary, Icons.check_rounded),
      AlertTone.galat => (GuyubColors.dangerTint, GuyubColors.danger, Icons.error_outline_rounded),
      AlertTone.info => (GuyubColors.ruangTint, GuyubColors.inkBody, Icons.info_outline_rounded),
      AlertTone.peringatan => (GuyubColors.pasarTint, GuyubColors.pasarText, Icons.warning_amber_rounded),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(GuyubRadius.interactive)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: fg, height: 1.4)),
          ),
        ]),
      ),
    );
  }
}
