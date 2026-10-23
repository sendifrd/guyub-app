import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';

/// Chip filter (pil, tinggi 36). Terpilih = hijau penuh, teks putih.
class GuyubChip extends StatelessWidget {
  const GuyubChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? GuyubColors.primary : GuyubColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? GuyubColors.primary : GuyubColors.lineInput)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : GuyubColors.inkBody,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
