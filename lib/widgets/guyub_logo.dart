import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';

/// Logo kincir tiga bilah. onDark = versi untuk latar hijau atau sidebar gelap.
class GuyubLogo extends StatelessWidget {
  const GuyubLogo({super.key, this.size = 32, this.onDark = false, this.wordmark = false});

  final double size;
  final bool onDark;
  final bool wordmark;

  @override
  Widget build(BuildContext context) {
    final mark = Semantics(
      label: 'Logo Guyub',
      child: CustomPaint(size: Size.square(size), painter: _KincirPainter(onDark: onDark)),
    );
    if (!wordmark) return mark;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      mark,
      SizedBox(width: size * 0.28),
      Text(
        'guyub',
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.62,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.03 * size * 0.62,
          color: onDark ? Colors.white : GuyubColors.ink,
        ),
      ),
    ]);
  }
}

class _KincirPainter extends CustomPainter {
  _KincirPainter({required this.onDark});
  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 200; // desain asli memakai kotak 200 x 200
    canvas.scale(s);
    const c = Offset(100, 100);
    final colors = onDark
        ? const [Colors.white, GuyubColors.pasar, GuyubColors.ruangSoft]
        : const [GuyubColors.primary, GuyubColors.pasar, GuyubColors.ruang];
    // bilah atas, lalu diputar 120 derajat dua kali (kanan bawah, kiri bawah)
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * 2 * math.pi / 3);
      canvas.translate(-c.dx, -c.dy);
      final blade = Path()
        ..moveTo(100, 100)
        ..lineTo(100, 20)
        ..arcToPoint(const Offset(100, 100), radius: const Radius.circular(40), clockwise: true)
        ..close();
      canvas.drawPath(blade, Paint()..color = colors[i]);
      canvas.restore();
    }
    canvas.drawCircle(c, 11, Paint()..color = onDark ? GuyubColors.primary : GuyubColors.ink);
  }

  @override
  bool shouldRepaint(covariant _KincirPainter old) => old.onDark != onDark;
}
