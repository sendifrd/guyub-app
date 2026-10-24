// Layar Profil dasar. Menu yang belum aktif dilengkapi di F3–F6.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/sesi.dart';
import '../../../widgets/guyub_button.dart';
import '../../../widgets/guyub_card.dart';
import '../../../widgets/status_badge.dart';

class ProfilPage extends ConsumerWidget {
  const ProfilPage({super.key});

  Future<void> _keluar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Keluar dari Guyub?'),
        content: const Text('Kamu perlu masuk lagi dengan email dan kata sandi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Keluar', style: const TextStyle(color: GuyubColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(sesiProvider).keluar();
  }

  void _segera(BuildContext context, String fitur) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$fitur dibuat di tahap berikutnya.')));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(sesiProvider).pengguna;
    if (p == null) return const SizedBox.shrink();

    final peran = <(String, BadgeTone)>[
      if (p.mahasiswa) ('Mahasiswa', BadgeTone.hijau),
      if (p.dosen) ('Dosen', BadgeTone.biru),
      if (p.mengelolaKelas) (p.dosen ? 'Pengampu' : 'Ketua kelas', BadgeTone.biru),
      if (p.punyaToko) ('Punya toko', BadgeTone.kuning),
    ];

    return Scaffold(
      backgroundColor: GuyubColors.kapur,
      appBar: AppBar(title: const Text('Profil')),
      body: RefreshIndicator(
        color: GuyubColors.primary,
        onRefresh: () => ref.read(sesiProvider).segarkan(),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
          GuyubCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: GuyubColors.primaryTint,
                  foregroundImage: p.fotoUrl != null ? NetworkImage(p.fotoUrl!) : null,
                  child: Text(inisial(p.nama), style: GuyubText.cardTitle.copyWith(color: GuyubColors.primary, fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.nama, style: GuyubText.pageTitle.copyWith(fontSize: 18)),
                    Text(p.email, style: GuyubText.secondary),
                  ]),
                ),
              ]),
              if (peran.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final (l, t) in peran) StatusBadge(l, tone: t)]),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1, color: GuyubColors.line),
              const SizedBox(height: 10),
              if (p.nim != null) _Data('NIM', p.nim!, mono: true),
              if (p.prodi != null) _Data('Program studi', p.prodi!),
              if (p.angkatan != null) _Data('Angkatan', '${p.angkatan}'),
              _Data('WhatsApp', p.noWhatsapp ?? 'Belum diisi', mono: p.noWhatsapp != null),
            ]),
          ),
          const SizedBox(height: 18),
          Text('AKTIVITAS', style: GuyubText.label),
          const SizedBox(height: 8),
          GuyubCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _Menu(ikon: Icons.groups_outlined, label: 'Kelompok saya', onTap: () => context.go('/tim')),
              _Menu(ikon: Icons.calendar_today_outlined, label: 'Booking saya', onTap: () => context.go('/ruang')),
              if (p.mengelolaKelas) _Menu(ikon: Icons.event_repeat_outlined, label: 'Kuliah pengganti', onTap: () => _segera(context, 'Kuliah pengganti')),
              _Menu(ikon: Icons.receipt_long_outlined, label: 'Pesanan saya', onTap: () => _segera(context, 'Pesanan')),
              _Menu(
                ikon: Icons.storefront_outlined,
                label: p.punyaToko ? 'Toko saya' : 'Buka toko',
                onTap: () => _segera(context, 'Toko'),
                akhir: true,
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Text('AKUN', style: GuyubText.label),
          const SizedBox(height: 8),
          GuyubCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _Menu(ikon: Icons.edit_outlined, label: 'Ubah profil', onTap: () => _segera(context, 'Ubah profil')),
              _Menu(ikon: Icons.notifications_none_rounded, label: 'Notifikasi', onTap: () => context.push('/notifikasi'), akhir: true),
            ]),
          ),
          const SizedBox(height: 24),
          GuyubButton(
            label: 'Keluar',
            icon: Icons.logout_rounded,
            variant: GuyubButtonVariant.danger,
            expand: true,
            onPressed: () => _keluar(context, ref),
          ),
          const SizedBox(height: 12),
          Center(child: Text('Guyub v0.3 · F3', style: GuyubText.secondary.copyWith(color: GuyubColors.inkFaint))),
        ]),
      ),
    );
  }
}

class _Data extends StatelessWidget {
  const _Data(this.label, this.nilai, {this.mono = false});
  final String label;
  final String nilai;
  final bool mono;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 110, child: Text(label, style: GuyubText.secondary)),
          Expanded(child: Text(nilai, style: mono ? GuyubText.mono(size: 13.5) : GuyubText.body.copyWith(fontSize: 13.5))),
        ]),
      );
}

class _Menu extends StatelessWidget {
  const _Menu({required this.ikon, required this.label, required this.onTap, this.akhir = false});
  final IconData ikon;
  final String label;
  final VoidCallback onTap;
  final bool akhir;

  @override
  Widget build(BuildContext context) => Column(children: [
        ListTile(
          leading: Icon(ikon, color: GuyubColors.inkBody),
          title: Text(label, style: GuyubText.fieldLabel.copyWith(fontSize: 14)),
          trailing: const Icon(Icons.chevron_right_rounded, color: GuyubColors.inkFaint),
          onTap: onTap,
          minTileHeight: 52,
        ),
        if (!akhir) const Divider(height: 1, indent: 56, color: GuyubColors.line),
      ]);
}
