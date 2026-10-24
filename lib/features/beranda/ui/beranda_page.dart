// Layar B1 · Beranda. Acuan visual: png/B1-Beranda.png dan prototype klik (B1).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/format.dart';
import '../../../core/sesi.dart';
import '../../../widgets/guyub_button.dart';
import '../../../widgets/guyub_card.dart';
import '../../../widgets/guyub_logo.dart';
import '../../../widgets/kartu_produk.dart';
import '../../../widgets/keadaan.dart';
import '../../../widgets/kotak_tanggal.dart';
import '../../../widgets/status_badge.dart';
import '../data/beranda_repository.dart';

class BerandaPage extends ConsumerWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(sesiProvider).pengguna;
    final beranda = ref.watch(berandaProvider);
    if (p == null) return const SizedBox.shrink();

    Future<void> segarkan() => ref.refresh(berandaProvider.future);

    final info = [
      if (p.prodi != null) p.prodi!,
      if (p.angkatan != null) 'Angkatan ${p.angkatan}',
    ].join(' · ');

    final header = Container(
      color: GuyubColors.primary,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 12, 12, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const GuyubLogo(size: 30, onDark: true, wordmark: true),
          const Spacer(),
          _TombolLonceng(
            adaBaru: (beranda.valueOrNull?.belumDibaca ?? 0) > 0,
            onTap: () async {
              await context.push('/notifikasi');
              ref.invalidate(berandaProvider);
            },
          ),
        ]),
        const SizedBox(height: 16),
        Text(beranda.valueOrNull?.sapaan ?? 'Halo, ${p.namaDepan}',
            style: GuyubText.greeting.copyWith(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 4),
        Text.rich(TextSpan(style: GuyubText.secondary.copyWith(color: Colors.white.withValues(alpha: 0.92), fontSize: 13), children: [
          if (info.isNotEmpty) TextSpan(text: p.nim != null ? '$info · NIM ' : info),
          if (info.isEmpty && p.nim != null) const TextSpan(text: 'NIM '),
          if (p.nim != null) TextSpan(text: p.nim, style: GuyubText.mono(size: 13, weight: FontWeight.w600, color: Colors.white)),
        ])),
      ]),
    );

    return Scaffold(
      body: RefreshIndicator(
        color: GuyubColors.primary,
        onRefresh: segarkan,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            header,
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: beranda.when(
                loading: () => const Padding(padding: EdgeInsets.only(top: 48), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => KeadaanGalat(
                  pesan: e is ApiException ? e.message : 'Beranda gagal dimuat.',
                  onCobaLagi: () => ref.invalidate(berandaProvider),
                ),
                data: (d) => _Isi(data: d),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.data});
  final BerandaData data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: _AksiCepat(ikon: Icons.groups_outlined, label: 'Gabung sesi', bg: GuyubColors.primaryTint, fg: GuyubColors.primary, onTap: () => context.go('/tim'))),
        const SizedBox(width: 10),
        Expanded(child: _AksiCepat(ikon: Icons.calendar_today_outlined, label: 'Booking ruang', bg: GuyubColors.ruangTint, fg: GuyubColors.ruang, onTap: () => context.go('/ruang'))),
        const SizedBox(width: 10),
        Expanded(child: _AksiCepat(ikon: Icons.shopping_bag_outlined, label: 'Belanja', bg: GuyubColors.pasarTint, fg: GuyubColors.pasarText, onTap: () => context.go('/pasar'))),
      ]),
      const _Label('Kelompok aktif'),
      _KartuKelompok(data: d),
      const _Label('Booking berikutnya'),
      _KartuBooking(booking: d.booking),
      if (d.toko != null) ...[
        const _Label('Toko saya'),
        GuyubCard(
          onTap: () => context.go('/profil'),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: GuyubColors.pasarTint, borderRadius: BorderRadius.circular(GuyubRadius.interactive)),
              child: const Icon(Icons.storefront_outlined, color: GuyubColors.pasarText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.toko!.nama, style: GuyubText.cardTitle),
                Text('Saldo ${rupiah(d.toko!.saldo)}', style: GuyubText.secondary),
              ]),
            ),
            if (d.toko!.perluDiproses > 0) StatusBadge('${d.toko!.perluDiproses} perlu diproses', tone: BadgeTone.kuning),
          ]),
        ),
      ],
      if (d.produkBaru.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Row(children: [
            Expanded(child: Text('DARI TOKO MAHASISWA', style: GuyubText.label)),
            TextButton(onPressed: () => context.go('/pasar'), child: Text('Lihat semua', style: GuyubText.fieldLabel.copyWith(color: GuyubColors.primary))),
          ]),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
          children: [for (final p in d.produkBaru.take(4)) KartuProduk(produk: p, onTap: () => context.go('/pasar'))],
        ),
      ],
    ]);
  }
}

class _KartuKelompok extends StatelessWidget {
  const _KartuKelompok({required this.data});
  final BerandaData data;

  @override
  Widget build(BuildContext context) {
    final k = data.kelompok;
    if (k != null) {
      return GuyubCard(
        onTap: () => context.push('/tim/sesi/${k.sesiId}'),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${k.mataKuliah} · ${k.kelompok}', style: GuyubText.cardTitle),
              const SizedBox(height: 2),
              Text(k.judul, style: GuyubText.secondary),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.people_alt_outlined, size: 16, color: GuyubColors.inkMuted),
                const SizedBox(width: 6),
                Text('${k.jumlahAnggota} anggota', style: GuyubText.secondary),
              ]),
            ]),
          ),
          const StatusBadge('Dikunci'),
        ]),
      );
    }
    if (data.sesiTerbuka.isNotEmpty) {
      final s = data.sesiTerbuka.first;
      return GuyubCard(
        onTap: () {
          if (s.sudahBergabung) {
            context.push('/tim/sesi/${s.id}');
          } else {
            context.go('/tim');
          }
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(s.judul, style: GuyubText.cardTitle)),
            StatusBadge(s.sudahBergabung ? 'Sudah bergabung' : 'Terbuka', tone: s.sudahBergabung ? BadgeTone.biru : BadgeTone.hijau),
          ]),
          const SizedBox(height: 2),
          Text('${s.mataKuliah} · diacak ${tanggalPendek(s.batasJoin)}, ${jam(s.batasJoin)}', style: GuyubText.secondary),
          const SizedBox(height: 8),
          Text(
            s.sudahBergabung ? 'Kamu sudah bergabung. Kelompok diacak otomatis saat batas waktu tiba.' : 'Kamu belum bergabung. Masukkan kode dari ketua kelas.',
            style: GuyubText.secondary.copyWith(color: GuyubColors.inkBody),
          ),
        ]),
      );
    }
    return const GuyubCard(child: KeadaanKosong(ikon: Icons.groups_outlined, pesan: 'Belum ada sesi kelompok di kelasmu.'));
  }
}

class _KartuBooking extends StatelessWidget {
  const _KartuBooking({required this.booking});
  final BookingRingkas? booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    if (b == null) {
      return GuyubCard(
        child: KeadaanKosong(
          ikon: Icons.event_available_outlined,
          pesan: 'Belum ada booking ruangan.',
          aksi: GuyubButton(label: 'Cari ruangan', size: GuyubButtonSize.sm, variant: GuyubButtonVariant.secondary, onPressed: () => context.go('/ruang')),
        ),
      );
    }
    final label = b.status == 'menunggu' ? 'Menunggu' : 'Disetujui';
    return GuyubCard(
      onTap: () => context.go('/ruang'),
      child: Row(children: [
        KotakTanggal(b.mulai),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ruang ${b.ruang}', style: GuyubText.cardTitle),
            Text('${jam(b.mulai)}–${jam(b.selesai)} WIB', style: GuyubText.mono(size: 13.5, color: GuyubColors.inkBody)),
            Text(b.gedung, style: GuyubText.secondary),
          ]),
        ),
        StatusBadge(label),
      ]),
    );
  }
}

class _AksiCepat extends StatelessWidget {
  const _AksiCepat({required this.ikon, required this.label, required this.bg, required this.fg, required this.onTap});
  final IconData ikon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GuyubCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
        child: Column(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(GuyubRadius.interactive)),
            child: Icon(ikon, color: fg, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GuyubText.fieldLabel),
        ]),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.teks);
  final String teks;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 22, bottom: 10), child: Text(teks.toUpperCase(), style: GuyubText.label));
}

class _TombolLonceng extends StatelessWidget {
  const _TombolLonceng({required this.adaBaru, required this.onTap});
  final bool adaBaru;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(GuyubRadius.interactive),
        child: InkWell(
          borderRadius: BorderRadius.circular(GuyubRadius.interactive),
          onTap: onTap,
          child: Semantics(
            label: adaBaru ? 'Notifikasi, ada yang belum dibaca' : 'Notifikasi',
            button: true,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(alignment: Alignment.center, children: [
                const Icon(Icons.notifications_none_rounded, color: Colors.white),
                if (adaBaru)
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: GuyubColors.pasar, shape: BoxShape.circle)),
                  ),
              ]),
            ),
          ),
        ),
      );
}
