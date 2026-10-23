// Beranda sementara untuk F1: memastikan login, token, dan profil dari API sudah benar.
// Diganti dengan layar B1 lengkap di tahap F2.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/sesi.dart';
import '../../../widgets/guyub_button.dart';
import '../../../widgets/guyub_card.dart';
import '../../../widgets/guyub_logo.dart';
import '../../../widgets/status_badge.dart';

class BerandaPage extends ConsumerWidget {
  const BerandaPage({super.key});

  static const _namaPeran = {'mahasiswa': 'Mahasiswa', 'dosen': 'Dosen', 'admin_fakultas': 'Admin TU', 'admin_pusat': 'Admin pusat'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(sesiProvider).pengguna;
    if (p == null) return const SizedBox.shrink();
    final info = [
      if (p.prodi != null) p.prodi!,
      if (p.angkatan != null) 'Angkatan ${p.angkatan}',
    ].join(' · ');

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: GuyubColors.primary,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const GuyubLogo(size: 30, onDark: true, wordmark: true),
              const SizedBox(height: 18),
              Text('Halo, ${p.namaDepan}', style: GuyubText.greeting.copyWith(color: Colors.white, fontSize: 24)),
              const SizedBox(height: 4),
              Text.rich(TextSpan(style: GuyubText.secondary.copyWith(color: Colors.white.withValues(alpha: 0.92), fontSize: 13), children: [
                if (info.isNotEmpty) TextSpan(text: p.nim != null ? '$info · NIM ' : info),
                if (p.nim != null) TextSpan(text: p.nim, style: GuyubText.mono(size: 13, weight: FontWeight.w600, color: Colors.white)),
              ])),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              GuyubCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tersambung ke API', style: GuyubText.cardTitle),
                  const SizedBox(height: 4),
                  Text(apiBaseUrl, style: GuyubText.mono(size: 12.5, color: GuyubColors.inkMuted)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final r in p.peran) StatusBadge(_namaPeran[r] ?? r, tone: BadgeTone.abu),
                    if (p.mengelolaKelas) const StatusBadge('Mengelola kelas', tone: BadgeTone.hijau),
                    if (p.punyaToko) const StatusBadge('Punya toko', tone: BadgeTone.kuning),
                  ]),
                  const SizedBox(height: 12),
                  Text(p.email, style: GuyubText.secondary),
                ]),
              ),
              const SizedBox(height: 14),
              Text('Layar Beranda lengkap, Cari Tim, Pasar, dan Ruang dibuat di tahap berikutnya.', style: GuyubText.secondary),
              const SizedBox(height: 20),
              GuyubButton(
                label: 'Keluar',
                icon: Icons.logout_rounded,
                variant: GuyubButtonVariant.danger,
                expand: true,
                onPressed: () => ref.read(sesiProvider).keluar(),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
