// Layar K1 · Sesi yang dikelola (dosen pengampu dan ketua kelas).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/api_client.dart';
import '../../../../core/format.dart';
import '../../../../widgets/guyub_card.dart';
import '../../../../widgets/keadaan.dart';
import '../../../../widgets/status_badge.dart';
import '../../data/kelola_repository.dart';

class DaftarSesiKelolaPage extends ConsumerWidget {
  const DaftarSesiKelolaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(daftarKelolaProvider);
    final kelas = ref.watch(kelasKelolaProvider).valueOrNull ?? const [];

    final ketua = kelas.where((k) => !k.dosen).map((k) => '${k.matkul.kode} Kelas ${k.matkul.kelas}').toList();
    final dosen = kelas.where((k) => k.dosen).map((k) => '${k.matkul.kode} Kelas ${k.matkul.kelas}').toList();

    return Scaffold(
      backgroundColor: GuyubColors.kapur,
      appBar: AppBar(title: const Text('Kelola sesi kelompok')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GuyubColors.primary,
        foregroundColor: Colors.white,
        onPressed: kelas.isEmpty
            ? null
            : () async {
                await context.push('/tim/kelola/baru');
                if (context.mounted) ref.invalidate(daftarKelolaProvider);
              },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat sesi'),
      ),
      body: RefreshIndicator(
        color: GuyubColors.primary,
        onRefresh: () async {
          ref.invalidate(kelasKelolaProvider);
          await ref.refresh(daftarKelolaProvider.future);
        },
        child: daftar.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            KeadaanGalat(pesan: e is ApiException ? e.message : 'Daftar sesi gagal dimuat.', onCobaLagi: () => ref.invalidate(daftarKelolaProvider)),
          ]),
          data: (list) {
            final aktif = list.where((s) => !s.dikunci).toList();
            final dikunci = list.where((s) => s.dikunci).toList();
            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
              if (list.isEmpty)
                const GuyubCard(
                  child: KeadaanKosong(ikon: Icons.groups_outlined, pesan: 'Belum ada sesi. Ketuk "Buat sesi" untuk membagi kelas menjadi kelompok.'),
                ),
              if (aktif.isNotEmpty) ...[
                _Judul('TERBUKA (${aktif.length})'),
                for (final s in aktif) _KartuSesiKelola(sesi: s),
              ],
              if (dikunci.isNotEmpty) ...[
                _Judul('DIKUNCI (${dikunci.length})'),
                for (final s in dikunci) _KartuSesiKelola(sesi: s),
              ],
              if (kelas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  [
                    if (dosen.isNotEmpty) 'Kamu dosen pengampu ${dosen.join(', ')}.',
                    if (ketua.isNotEmpty) 'Kamu ketua kelas ${ketua.join(', ')}.',
                  ].join(' '),
                  style: GuyubText.secondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ]);
          },
        ),
      ),
    );
  }
}

class _Judul extends StatelessWidget {
  const _Judul(this.teks);
  final String teks;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(teks, style: GuyubText.label));
}

class _KartuSesiKelola extends ConsumerWidget {
  const _KartuSesiKelola({required this.sesi});
  final SesiKelola sesi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = sesi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GuyubCard(
        onTap: () async {
          await context.push('/tim/kelola/${s.id}');
          if (context.mounted) ref.invalidate(daftarKelolaProvider);
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(s.judul, style: GuyubText.cardTitle)),
            const SizedBox(width: 8),
            StatusBadge(s.dikunci ? 'Dikunci' : 'Terbuka'),
          ]),
          const SizedBox(height: 2),
          Text(s.matkul.label, style: GuyubText.secondary),
          const SizedBox(height: 10),
          Row(children: [
            Text('${s.jumlahBergabung}', style: GuyubText.cardTitle.copyWith(fontSize: 18)),
            Text(' / ${s.jumlahMahasiswa} gabung', style: GuyubText.secondary),
            const Spacer(),
            if (!s.dikunci) ...[
              Text('Tutup ${tanggalPendek(s.batasJoin)}', style: GuyubText.secondary),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: GuyubColors.primaryTint, borderRadius: BorderRadius.circular(6)),
                child: Text(s.kode, style: GuyubText.mono(size: 13, weight: FontWeight.w600, color: GuyubColors.primary)),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}
