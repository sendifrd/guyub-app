// Tema Guyub, diturunkan dari DESIGN.md. Semua warna dan ukuran diambil dari sini;
// jangan menulis kode warna langsung di layar.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GuyubColors {
  GuyubColors._();

  // Hijau Guyub: aksi utama, menu aktif, Cari Tim
  static const primary = Color(0xFF0B6E5B);
  static const primaryHover = Color(0xFF08513F);
  static const primaryTint = Color(0xFFE1F0EB);
  static const primaryOnDark = Color(0xFF2FA585);

  // Kunyit: aksen Pasar. Jangan dipakai untuk teks di atas putih, jangan dengan teks putih.
  static const pasar = Color(0xFFF2A93B);
  static const pasarTint = Color(0xFFFCEFD8);
  static const pasarText = Color(0xFF7A4800);

  // Biru Serambi: aksen Ruang
  static const ruang = Color(0xFF2F6FB0);
  static const ruangTint = Color(0xFFDCE8F5);
  static const ruangSoft = Color(0xFF9CC3EA);

  // Tinta dan teks
  static const ink = Color(0xFF16211D);
  static const inkBody = Color(0xFF3F4A45);
  static const inkMuted = Color(0xFF55625C);
  static const inkFaint = Color(0xFF9AA59F);

  // Latar dan garis
  static const kapur = Color(0xFFF2F4F1);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF7F8F6);
  static const line = Color(0xFFDDE3DE);
  static const lineInput = Color(0xFFC9D2CC);

  // Status
  static const danger = Color(0xFFB3261E);
  static const dangerTint = Color(0xFFFBE4E2);
  static const dangerBorder = Color(0xFFE3B6B2);
  static const neutralTint = Color(0xFFECEFEC);
  static const kuliah = Color(0xFFE6E3DA);
}

class GuyubRadius {
  GuyubRadius._();
  static const small = 10.0; // slot jam
  static const interactive = 12.0; // tombol, input
  static const card = 14.0; // kartu
}

class GuyubText {
  GuyubText._();
  static TextStyle get pageTitle => GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: GuyubColors.ink);
  static TextStyle get greeting => GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: GuyubColors.ink);
  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: GuyubColors.ink);
  static TextStyle get body => GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: GuyubColors.ink, height: 1.5);
  static TextStyle get secondary => GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w400, color: GuyubColors.inkMuted, height: 1.45);
  static TextStyle get label => GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: GuyubColors.inkMuted, letterSpacing: 0.72);
  static TextStyle get caption => GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700);
  static TextStyle get fieldLabel => GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: GuyubColors.ink);

  /// IBM Plex Mono: hanya untuk kode sesi, jam, kode pesanan, dan NIM.
  static TextStyle mono({double size = 14, FontWeight weight = FontWeight.w500, Color color = GuyubColors.ink}) =>
      GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color);
}

ThemeData buildGuyubTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: GuyubColors.ink,
    displayColor: GuyubColors.ink,
  );
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(GuyubRadius.interactive),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: GuyubColors.primary,
      primary: GuyubColors.primary,
      onPrimary: Colors.white,
      secondary: GuyubColors.ruang,
      error: GuyubColors.danger,
      surface: GuyubColors.surface,
      onSurface: GuyubColors.ink,
    ),
    scaffoldBackgroundColor: GuyubColors.kapur,
    textTheme: text,
    dividerColor: GuyubColors.line,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: GuyubColors.surface,
      foregroundColor: GuyubColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: GuyubColors.ink),
      shape: const Border(bottom: BorderSide(color: GuyubColors.line)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GuyubColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: GuyubColors.inkFaint),
      errorStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: GuyubColors.danger),
      border: border(GuyubColors.lineInput),
      enabledBorder: border(GuyubColors.lineInput),
      focusedBorder: border(GuyubColors.primary, 1.5),
      errorBorder: border(GuyubColors.danger),
      focusedErrorBorder: border(GuyubColors.danger, 1.5),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: GuyubColors.ink,
      contentTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GuyubRadius.interactive)),
    ),
  );
}
