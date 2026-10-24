// Layar K7 · Permintaan gabung terlambat. Pengelola hanya menyetujui/menolak; sistem yang memilih kelompok.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/api_client.dart';
import '../../../../core/format.dart';
import '../../../../widgets/alert_box.dart';
import '../../../../widgets/guyub_button.dart';
import '../../../../widgets/guyub_card.dart';
import '../../../../widgets/keadaan.dart';
import '../../../../widgets/status_badge.dart';
import '../../data/kelola_repository.dart';

class TerlambatPage extends ConsumerStatefulWidget {
  const TerlambatPage({super.key, required this.sesiId});
  final int sesiId;

  @override
  ConsumerState<TerlambatPage> createState() => _TerlambatPageState();
}

class _TerlambatPageState extends ConsumerState<TerlambatPage> {
  final _proses = <int>{};

  Future<void> _jalankan(PermintaanTerlambat p, Future<String> Function() f) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _proses.add(p.id));
    try {
      messenger.showSnackBar(SnackBar(content: Text(await f())));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.fieldErrors.values.firstOrNull ?? e.message)));
    }
    if (!mounted) return;
    setState(() => _proses.remove(p.id));
    ref.invalidate(terlambatProvider(widget.sesiId));
    ref.invalidate(detailKelolaProvider(widget.sesiId));
    ref.invalidate(daftarKelolaProvider);
  }

  Future<void> _tolak(PermintaanTerlambat p) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tolak ${p.mahasiswa.nama}?'),
        content: TextField(
          controller: c,
          maxLength: 200,
          decoration: const InputDecoration(hintText: 'Catatan untuk mahasiswa (opsional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tolak', style: TextStyle(color: GuyubColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _jalankan(p, () => ref.read(kelolaRepositoryProvider).tolak(p.id, catatan: c.text));
  }

  @override
  Widget build(BuildContext context) {
    final daftar = ref.watch(terlambatProvider(widget.sesiId));
    return Scaffold(
      backgroundColor: GuyubColors.kapur,
      appBar: AppBar(title: const Text('Gabung terlambat')),
      body: RefreshIndicator(
        color: GuyubColors.primary,
        onRefresh: () => ref.refresh(terlambatProvider(widget.sesiId).future),
        child: daftar.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            KeadaanGalat(pesan: e is ApiException ? e.message : 'Daftar gagal dimuat.', onCobaLagi: () => ref.invalidate(terlambatProvider(widget.sesiId))),
          ]),
          data: (list) {
            final menunggu = list.where((p) => p.menunggu).toList();
            final selesai = list.where((p) => !p.menunggu).toList();
            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
              const AlertBox(
                'Kamu hanya menyetujui atau menolak. Sistem yang memilih kelompok: yang anggotanya paling sedikit, diundi bila ada yang sama.',
              ),
              const SizedBox(height: 16),
              Text('MENUNGGU PERSETUJUAN (${menunggu.length})', style: GuyubText.label),
              const SizedBox(height: 8),
              if (menunggu.isEmpty) const GuyubCard(child: KeadaanKosong(ikon: Icons.inbox_outlined, pesan: 'Tidak ada permintaan yang menunggu.')),
              for (final p in menunggu)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GuyubCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _Identitas(p),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: GuyubButton(
                            label: 'Tolak',
                            size: GuyubButtonSize.sm,
                            variant: GuyubButtonVariant.danger,
                            onPressed: _proses.contains(p.id) ? null : () => _tolak(p),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GuyubButton(
                            label: 'Setujui',
                            size: GuyubButtonSize.sm,
                            loading: _proses.contains(p.id),
                            onPressed: () => _jalankan(p, () => ref.read(kelolaRepositoryProvider).setujui(p.id)),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),
              if (selesai.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('SUDAH DIPROSES (${selesai.length})', style: GuyubText.label),
                const SizedBox(height: 8),
                for (final p in selesai)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GuyubCard(child: _Identitas(p)),
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                'Permintaan dibuka sampai 7 hari setelah kelompok dikunci. Setiap persetujuan dicatat di riwayat sesi.',
                style: GuyubText.secondary,
                textAlign: TextAlign.center,
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _Identitas extends StatelessWidget {
  const _Identitas(this.p);
  final PermintaanTerlambat p;

  @override
  Widget build(BuildContext context) {
    final m = p.mahasiswa;
    final (String label, BadgeTone tone) = switch (p.status) {
      'terlambat_disetujui' => ('Disetujui', BadgeTone.hijau),
      'terlambat_ditolak' => ('Ditolak', BadgeTone.merah),
      _ => ('Menunggu', BadgeTone.kuning),
    };
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: GuyubColors.pasarTint,
        child: Text(inisial(m.nama), style: GuyubText.caption.copyWith(color: GuyubColors.pasarText, fontSize: 12)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.nama, style: GuyubText.fieldLabel),
          if (m.nim != null) Text(m.nim!, style: GuyubText.mono(size: 12.5, color: GuyubColors.inkMuted)),
          const SizedBox(height: 4),
          Text(
            'Minta gabung ${tanggalPendek(p.diajukanPada)}, ${jam(p.diajukanPada)}${p.catatan != null ? ' · "${p.catatan}"' : ''}',
            style: GuyubText.secondary,
          ),
        ]),
      ),
      StatusBadge(label, tone: tone),
    ]);
  }
}
