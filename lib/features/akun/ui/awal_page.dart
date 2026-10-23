// Layar A1 · Halaman awal. Acuan visual: png/A1-HalamanAwal.png di paket UI.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../widgets/guyub_button.dart';
import '../../../widgets/guyub_logo.dart';

class AwalPage extends StatelessWidget {
  const AwalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GuyubColors.primary,
      body: Column(children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            const CustomPaint(painter: _OrbitPainter()),
            SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const GuyubLogo(size: 96),
                    ),
                    const SizedBox(height: 20),
                    Text('guyub',
                        style: GoogleFonts.plusJakartaSans(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -2, height: 1)),
                    const SizedBox(height: 10),
                    Text('Kerja bareng, tumbuh bareng.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Text('Ruang kumpul digital untuk seluruh warga kampus.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), height: 1.45)),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        Container(
          decoration: const BoxDecoration(
            color: GuyubColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              GuyubButton(label: 'Masuk', icon: Icons.arrow_forward_rounded, expand: true, onPressed: () => context.push('/masuk')),
              const SizedBox(height: 12),
              GuyubButton(label: 'Daftar akun baru', variant: GuyubButtonVariant.secondary, expand: true, onPressed: () => context.push('/daftar')),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline_rounded, size: 16, color: GuyubColors.inkMuted),
                const SizedBox(width: 6),
                Text('Khusus pengguna email kampus', style: GuyubText.secondary),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Lingkaran orbit dan titik warna di latar hijau.
class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    final garis = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.14);
    for (final r in [100.0, 200.0, 300.0]) {
      canvas.drawCircle(c, r, garis);
    }
    const titik = [
      (200.0, -2.2, 9.0, GuyubColors.ruangSoft),
      (200.0, -0.5, 12.0, GuyubColors.pasar),
      (300.0, -1.9, 6.0, Color(0x8CFFFFFF)),
      (300.0, -1.05, 5.0, Color(0xFFC9A040)),
      (200.0, 2.5, 6.0, Color(0xBFFFFFFF)),
      (200.0, 0.4, 7.0, GuyubColors.ruangSoft),
      (300.0, 3.0, 5.0, Color(0xFFC9A040)),
    ];
    for (final (r, a, s, w) in titik) {
      canvas.drawCircle(c + Offset(math.cos(a) * r, math.sin(a) * r), s, Paint()..color = w);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
