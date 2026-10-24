import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guyub_app/app/theme.dart';
import 'package:guyub_app/core/sesi.dart';
import 'package:guyub_app/features/beranda/data/beranda_repository.dart';
import 'package:guyub_app/features/notifikasi/data/notifikasi_repository.dart';
import 'package:guyub_app/features/tim/data/tim_repository.dart';
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

  test('Beranda membaca respons GET /beranda', () {
    final d = BerandaData.fromJson({
      'sapaan': 'Selamat pagi, Rina',
      'notifikasi_belum_dibaca': 3,
      'booking_berikutnya': {'id': 7, 'kode': 'BK-20261023-0001', 'status': 'disetujui', 'ruang': 'B-201', 'gedung': 'Gedung B', 'mulai': '2026-10-24T09:00:00+07:00', 'selesai': '2026-10-24T11:00:00+07:00'},
      'tim': {
        'sesi_terbuka': [{'id': 2, 'judul': 'Tugas besar', 'mata_kuliah': 'RPL A', 'batas_join': '2026-10-25T23:59:00+07:00', 'sudah_bergabung': false}],
        'kelompok_terbaru': null,
      },
      'pasar': {
        'pesanan_aktif': 1,
        'toko': {'nama': 'Rina Print', 'saldo': 125000, 'perlu_diproses': 2},
        'produk_baru': [
          {'slug': 'kaos', 'nama': 'Kaos', 'tipe': 'fisik', 'harga': 85000, 'stok': 4, 'habis': false, 'foto': [], 'toko': {'slug': 'x', 'nama': 'Toko X'}},
        ],
      },
    });
    expect(d.belumDibaca, 3);
    expect(d.booking!.ruang, 'B-201');
    expect(d.kelompok, isNull);
    expect(d.sesiTerbuka.single.sudahBergabung, isFalse);
    expect(d.toko!.perluDiproses, 2);
    expect(d.produkBaru.single.fotoUrl, isNull);
  });

  test('Notifikasi membaca item GET /notifikasi', () {
    final n = Notifikasi.fromJson({'id': 5, 'tipe': 'booking_disetujui', 'kategori': 'booking', 'judul': 'Booking disetujui', 'isi': 'B-201', 'link': null, 'dibaca': false, 'waktu': '2026-10-23T08:00:00+07:00'});
    expect(n.kategori, 'booking');
    expect(n.dibaca, isFalse);
  });

  test('Sesi saya membaca GET /tim/sesi', () {
    final s = SesiSaya.fromJson({
      'id': 3, 'judul': 'Tugas Besar ERD', 'mata_kuliah': {'kode': 'IF2103', 'nama': 'Basis Data', 'kelas': 'B'},
      'status': 'dikunci', 'batas_join': '2026-10-15T10:00:00+07:00', 'status_saya': 'tepat_waktu',
      'kelompok_saya': {'nomor': 3, 'nama': 'Kelompok 3'},
    });
    expect(s.dikunci, isTrue);
    expect(s.kelompokNomor, 3);
    expect(s.matkul.label, 'IF2103 Basis Data · Kelas B');
  });

  test('Detail sesi dikunci memuat kelompok saya dan bukti', () {
    final d = DetailSesi.fromJson({
      'id': 3, 'judul': 'Tugas Besar ERD', 'mata_kuliah': {'kode': 'IF2103', 'nama': 'Basis Data', 'kelas': 'B'},
      'status': 'dikunci', 'mode': 'ukuran', 'nilai': 5, 'batas_join': '2026-10-15T10:00:00+07:00',
      'sidik_jari': '6240a5cd00a38060', 'jumlah_peserta': 23, 'status_saya': 'tepat_waktu',
      'dikunci_pada': '2026-10-15T10:00:02+07:00', 'kelompok_saya_id': 12,
      'kelompok': [
        {'id': 11, 'nomor': 1, 'nama': 'Kelompok 1', 'anggota': [{'nama': 'Dimas', 'nim': '2410512011', 'prodi': 'TI', 'no_whatsapp': null}]},
        {'id': 12, 'nomor': 2, 'nama': 'Tim Relasi', 'anggota': [{'nama': 'Rina', 'nim': '2410512034', 'prodi': 'TI', 'no_whatsapp': '0812'}]},
      ],
      'bukti': {'seed': 58210377, 'kode': 'K7Q2PX', 'sidik_jari': '6240a5cd00a38060', 'cocok': true, 'rumus': 'r', 'algoritma': 'a', 'riwayat': []},
    });
    expect(d.kelompokSaya!.nama, 'Tim Relasi');
    expect(d.aturan, 'Kelompok 5 orang');
    expect(d.bukti!.seed, '58210377');
    expect(d.bukti!.cocok, isTrue);
  });
}
