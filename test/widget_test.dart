import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guyub_app/app/theme.dart';
import 'package:guyub_app/core/sesi.dart';
import 'package:guyub_app/widgets/guyub_button.dart';
import 'package:guyub_app/widgets/slot_waktu.dart';
import 'package:guyub_app/widgets/status_badge.dart';

Widget _wrap(Widget child) => MaterialApp(theme: buildGuyubTheme(), home: Scaffold(body: Center(child: child)));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Tombol nonaktif tidak bisa ditekan', (tester) async {
    await tester.pumpWidget(_wrap(const GuyubButton(label: 'Acak ulang', onPressed: null)));
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('Badge memilih warna dari teks status', (tester) async {
    await tester.pumpWidget(_wrap(const StatusBadge('Ditolak')));
    final box = tester.widget<Container>(find.descendant(of: find.byType(StatusBadge), matching: find.byType(Container))).decoration as BoxDecoration;
    expect(box.color, GuyubColors.dangerTint);
  });

  testWidgets('Slot kuliah tidak bisa dipilih', (tester) async {
    var dipilih = false;
    await tester.pumpWidget(_wrap(SlotWaktu(jam: '07.00', status: SlotStatus.kuliah, onTap: () => dipilih = true)));
    await tester.tap(find.text('07.00'));
    expect(dipilih, isFalse);
  });

  test('Pengguna dibaca dari JSON GET /me', () {
    final p = Pengguna.fromJson({
      'id': 7,
      'name': 'Rina Aulia',
      'email': 'rina.aulia@mhs.kampus.ac.id',
      'nim': '2410512034',
      'angkatan': 2024,
      'email_verified_at': '2026-10-20T10:00:00.000000Z',
      'peran': ['mahasiswa'],
      'punya_toko': true,
      'mengelola_kelas': true,
    });
    expect(p.namaDepan, 'Rina');
    expect(p.terverifikasi, isTrue);
    expect(p.mahasiswa, isTrue);
    expect(p.punyaToko, isTrue);
  });

  test('Akun baru belum terverifikasi', () {
    final p = Pengguna.fromJson({'id': 1, 'name': 'Baru', 'email': 'baru@mhs.kampus.ac.id', 'email_verified_at': null, 'peran': []});
    expect(p.terverifikasi, isFalse);
  });
}
