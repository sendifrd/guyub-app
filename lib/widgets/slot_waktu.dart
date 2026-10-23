import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';

enum SlotStatus { kosong, kuliah, dipesan, dipilih }

/// Kotak jam booking (grid 4 kolom, tinggi 48, radius 10).
class SlotWaktu extends StatelessWidget {
  const SlotWaktu({super.key, required this.jam, required this.status, this.onTap});

  final String jam;
  final SlotStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color? border, String label, bool enabled) = switch (status) {
      SlotStatus.kosong => (GuyubColors.surface, GuyubColors.ink, GuyubColors.lineInput, 'Kosong', true),
      SlotStatus.kuliah => (GuyubColors.kuliah, GuyubColors.inkMuted, null, 'Kuliah', false),
      SlotStatus.dipesan => (GuyubColors.pasarTint, GuyubColors.pasarText, null, 'Dipesan', false),
      SlotStatus.dipilih => (GuyubColors.primary, Colors.white, null, 'Dipilih', true),
    };
    return Semantics(
      button: enabled,
      selected: status == SlotStatus.dipilih,
      label: '$jam, $label',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GuyubRadius.small),
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(GuyubRadius.small),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: 48,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(jam, style: GuyubText.mono(size: 13, weight: FontWeight.w600, color: fg)),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}
