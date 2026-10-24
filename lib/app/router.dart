import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/sesi.dart';
import '../features/akun/ui/awal_page.dart';
import '../features/akun/ui/daftar_page.dart';
import '../features/akun/ui/lupa_sandi_page.dart';
import '../features/akun/ui/masuk_page.dart';
import '../features/akun/ui/memuat_page.dart';
import '../features/akun/ui/verifikasi_page.dart';
import '../features/beranda/ui/beranda_page.dart';
import '../features/notifikasi/ui/notifikasi_page.dart';
import '../features/profil/ui/profil_page.dart';
import '../features/tim/ui/cari_tim_page.dart';
import '../features/tim/ui/hasil_kelompok_page.dart';
import '../widgets/app_shell.dart';

/// Rute utama. Pengalihan otomatis mengikuti status Sesi:
/// belum siap → /memuat, belum login → /awal, email belum diverifikasi → /verifikasi, sudah login → /.
/// Layar yang belum dibuat memakai _Placeholder; diganti di F2–F6 mengikuti PETA-LAYAR.md.
final routerProvider = Provider<GoRouter>((ref) {
  final sesi = ref.read(sesiProvider);
  const tamu = {'/awal', '/masuk', '/daftar', '/lupa-sandi'};

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: sesi,
    redirect: (context, state) {
      final lokasi = state.matchedLocation;
      if (!sesi.siap) return lokasi == '/memuat' ? null : '/memuat';

      final p = sesi.pengguna;
      if (p == null) return tamu.contains(lokasi) ? null : '/awal';
      if (!p.terverifikasi) return lokasi == '/verifikasi' ? null : '/verifikasi';
      if (tamu.contains(lokasi) || lokasi == '/verifikasi' || lokasi == '/memuat') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/memuat', builder: (_, __) => const MemuatPage()),
      GoRoute(path: '/awal', builder: (_, __) => const AwalPage()),
      GoRoute(path: '/masuk', builder: (_, __) => const MasukPage()),
      GoRoute(path: '/daftar', builder: (_, __) => const DaftarPage()),
      GoRoute(path: '/lupa-sandi', builder: (_, __) => const LupaSandiPage()),
      GoRoute(path: '/verifikasi', builder: (_, __) => const VerifikasiPage()),
      GoRoute(path: '/notifikasi', builder: (_, __) => const NotifikasiPage()),
      // Tautan undangan sesi: guyub.test/j/K7Q2PX
      GoRoute(path: '/j/:kode', redirect: (_, s) => '/tim?kode=${s.pathParameters['kode']}'),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const BerandaPage()),
          GoRoute(
            path: '/tim',
            builder: (_, s) {
              final kode = s.uri.queryParameters['kode'];
              return CariTimPage(key: ValueKey(kode), kodeAwal: kode);
            },
            routes: [
              GoRoute(path: 'sesi/:id', builder: (_, s) => HasilKelompokPage(sesiId: int.parse(s.pathParameters['id']!))),
            ],
          ),
          GoRoute(path: '/pasar', builder: (_, __) => const _Placeholder('Pasar Mahasiswa', 'F5')),
          GoRoute(path: '/ruang', builder: (_, __) => const _Placeholder('Booking Ruang', 'F4')),
          GoRoute(path: '/profil', builder: (_, __) => const ProfilPage()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.judul, this.tahap);
  final String judul;
  final String tahap;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(judul)),
        body: Center(child: Text('Layar ini dibuat di tahap $tahap.')),
      );
}
