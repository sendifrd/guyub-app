// Layar Notifikasi. Dibuka dari lonceng di Beranda.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/format.dart';
import '../../beranda/data/beranda_repository.dart';
import '../../../widgets/keadaan.dart';
import '../data/notifikasi_repository.dart';

class NotifikasiPage extends ConsumerWidget {
  const NotifikasiPage({super.key});

  Future<void> _bacaSemua(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pesan = await ref.read(notifikasiRepositoryProvider).bacaSemua();
      ref.invalidate(notifikasiProvider);
      ref.invalidate(berandaProvider);
      messenger.showSnackBar(SnackBar(content: Text(pesan)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _buka(BuildContext context, WidgetRef ref, Notifikasi n) async {
    if (!n.dibaca) {
      try {
        await ref.read(notifikasiRepositoryProvider).baca(n.id);
        ref.invalidate(notifikasiProvider);
        ref.invalidate(berandaProvider);
      } on ApiException catch (_) {
        // Gagal menandai dibaca tidak menghalangi navigasi.
      }
    }
    if (!context.mounted) return;
    // Tautan dari server yang sudah ada layarnya di aplikasi dibuka langsung.
    final link = n.link;
    if (link != null && RegExp(r'^/tim/sesi/\d+$').hasMatch(link)) {
      context.push(link);
      return;
    }
    final tujuan = switch (n.kategori) {
      'kelompok' => '/tim',
      'booking' => '/ruang',
      'pesanan' => '/pasar',
      _ => null,
    };
    if (tujuan != null) context.go(tujuan);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(notifikasiProvider);
    final adaBelum = daftar.valueOrNull?.any((n) => !n.dibaca) ?? false;

    return Scaffold(
      backgroundColor: GuyubColors.kapur,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (adaBelum)
            TextButton(
              onPressed: () => _bacaSemua(context, ref),
              child: Text('Tandai dibaca', style: GuyubText.fieldLabel.copyWith(color: GuyubColors.primary)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: GuyubColors.primary,
        onRefresh: () => ref.refresh(notifikasiProvider.future),
        child: daftar.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            KeadaanGalat(
              pesan: e is ApiException ? e.message : 'Notifikasi gagal dimuat.',
              onCobaLagi: () => ref.invalidate(notifikasiProvider),
            ),
          ]),
          data: (list) => list.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 80),
                  KeadaanKosong(ikon: Icons.notifications_none_rounded, pesan: 'Belum ada notifikasi.'),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: GuyubColors.line),
                  itemBuilder: (_, i) => _Baris(notifikasi: list[i], onTap: () => _buka(context, ref, list[i])),
                ),
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({required this.notifikasi, required this.onTap});
  final Notifikasi notifikasi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notifikasi;
    final (IconData ikon, Color bg, Color fg) = switch (n.kategori) {
      'kelompok' => (Icons.groups_outlined, GuyubColors.primaryTint, GuyubColors.primary),
      'booking' => (Icons.calendar_today_outlined, GuyubColors.ruangTint, GuyubColors.ruang),
      'pesanan' => (Icons.shopping_bag_outlined, GuyubColors.pasarTint, GuyubColors.pasarText),
      _ => (Icons.notifications_none_rounded, GuyubColors.neutralTint, GuyubColors.inkMuted),
    };
    return Material(
      color: n.dibaca ? GuyubColors.kapur : GuyubColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(GuyubRadius.interactive)),
              child: Icon(ikon, color: fg, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Text(n.judul,
                        style: GuyubText.cardTitle.copyWith(fontSize: 14, fontWeight: n.dibaca ? FontWeight.w600 : FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Text(waktuRelatif(n.waktu), style: GuyubText.secondary.copyWith(fontSize: 11.5)),
                ]),
                const SizedBox(height: 3),
                Text(n.isi, style: GuyubText.secondary.copyWith(color: GuyubColors.inkBody)),
              ]),
            ),
            if (!n.dibaca)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 6),
                child: Semantics(
                  label: 'Belum dibaca',
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: GuyubColors.primary, shape: BoxShape.circle)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
