// Layar T3 (menunggu acak otomatis) dan T4 (hasil kelompok + bukti pengacakan).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/format.dart';
import '../../../core/sesi.dart';
import '../../../widgets/alert_box.dart';
import '../../../widgets/guyub_button.dart';
import '../../../widgets/guyub_card.dart';
import '../../../widgets/keadaan.dart';
import '../../../widgets/status_badge.dart';
import '../../beranda/data/beranda_repository.dart';
import '../data/tim_repository.dart';

class HasilKelompokPage extends ConsumerWidget {
  const HasilKelompokPage({super.key, required this.sesiId});
  final int sesiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(detailSesiProvider(sesiId));

    return Scaffold(
      backgroundColor: GuyubColors.kapur,
      appBar: AppBar(title: Text(detail.valueOrNull?.judul ?? 'Sesi kelompok')),
      body: RefreshIndicator(
        color: GuyubColors.primary,
        onRefresh: () => ref.refresh(detailSesiProvider(sesiId).future),
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            KeadaanGalat(
              pesan: e is ApiException ? e.message : 'Sesi gagal dimuat.',
              onCobaLagi: () => ref.invalidate(detailSesiProvider(sesiId)),
            ),
          ]),
          data: (d) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: d.dikunci ? _hasil(context, ref, d) : [_Menunggu(detail: d)],
          ),
        ),
      ),
    );
  }

  List<Widget> _hasil(BuildContext context, WidgetRef ref, DetailSesi d) {
    final k = d.kelompokSaya;
    final nimSaya = ref.read(sesiProvider).pengguna?.nim;
    return [
      Row(children: [
        Expanded(child: Text(d.matkul.label, style: GuyubText.secondary)),
        const StatusBadge('Dikunci'),
      ]),
      const SizedBox(height: 12),
      if (k == null)
        AlertBox(
          switch (d.statusSaya) {
            'terlambat_menunggu' => 'Permintaan gabung terlambatmu sedang menunggu persetujuan. Jika disetujui, sistem menempatkanmu ke kelompok yang anggotanya paling sedikit.',
            'terlambat_ditolak' => 'Permintaan gabung terlambatmu ditolak. Hubungi dosen atau ketua kelas.',
            _ => 'Kamu tidak termasuk di kelompok mana pun pada sesi ini.',
          },
          tone: d.statusSaya == 'terlambat_ditolak' ? AlertTone.galat : AlertTone.info,
        )
      else ...[
        _KartuKelompokSaya(sesi: d, kelompok: k, nimSaya: nimSaya),
        const SizedBox(height: 12),
        GuyubButton(
          label: 'Booking ruang untuk kerja kelompok',
          icon: Icons.calendar_today_outlined,
          variant: GuyubButtonVariant.secondary,
          expand: true,
          onPressed: () => context.go('/ruang'),
        ),
      ],
      if (d.bukti != null) ...[
        const SizedBox(height: 22),
        Text('BUKTI PENGACAKAN', style: GuyubText.label),
        const SizedBox(height: 8),
        _KartuBukti(sesi: d, bukti: d.bukti!),
      ],
      if (d.kelompok.length > 1) ...[
        const SizedBox(height: 22),
        Text('SEMUA KELOMPOK (${d.kelompok.length})', style: GuyubText.label),
        const SizedBox(height: 8),
        GuyubCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final g in d.kelompok)
              ExpansionTile(
                shape: const Border(),
                title: Text(g.nama, style: GuyubText.fieldLabel),
                subtitle: Text('${g.anggota.length} anggota${g.id == d.kelompokSayaId ? ' · kelompokmu' : ''}', style: GuyubText.secondary),
                children: [
                  for (final a in g.anggota)
                    ListTile(
                      dense: true,
                      title: Text(a.nama, style: GuyubText.body.copyWith(fontSize: 13.5)),
                      trailing: a.nim == null ? null : Text(a.nim!, style: GuyubText.mono(size: 12.5, color: GuyubColors.inkMuted)),
                    ),
                ],
              ),
          ]),
        ),
      ],
    ];
  }
}

/// T3 · status terbuka: hitung mundur ke batas gabung + sidik jari.
class _Menunggu extends ConsumerStatefulWidget {
  const _Menunggu({required this.detail});
  final DetailSesi detail;

  @override
  ConsumerState<_Menunggu> createState() => _MenungguState();
}

class _MenungguState extends ConsumerState<_Menunggu> {
  Timer? _timer;
  bool _sudahMuatUlang = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      // Scheduler mengunci kelompok tepat di batas waktu; muat ulang sekali beberapa detik setelahnya.
      final lewat = DateTime.now().difference(widget.detail.batasJoin);
      if (!_sudahMuatUlang && lewat.inSeconds >= 5) {
        _sudahMuatUlang = true;
        ref.invalidate(detailSesiProvider(widget.detail.id));
        ref.invalidate(sesiSayaProvider);
        ref.invalidate(berandaProvider);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _sisa() {
    final s = widget.detail.batasJoin.difference(DateTime.now());
    if (s.isNegative) return 'Sedang diacak…';
    final h = s.inDays;
    final j = s.inHours % 24;
    final m = s.inMinutes % 60;
    final d = s.inSeconds % 60;
    String dua(int x) => x.toString().padLeft(2, '0');
    return h > 0 ? '$h hari ${dua(j)}:${dua(m)}:${dua(d)}' : '${dua(j)}:${dua(m)}:${dua(d)}';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final terlambat = d.statusSaya == 'terlambat_menunggu';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(d.matkul.label, style: GuyubText.secondary),
      const SizedBox(height: 12),
      GuyubCard(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: GuyubColors.primaryTint, shape: BoxShape.circle),
            child: const Icon(Icons.hourglass_top_rounded, color: GuyubColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          const StatusBadge('Menunggu pengacakan', tone: BadgeTone.kuning),
          const SizedBox(height: 10),
          Text(terlambat ? 'Permintaanmu sedang ditinjau' : 'Kamu sudah masuk sesi', style: GuyubText.cardTitle.copyWith(fontSize: 17)),
          const SizedBox(height: 4),
          Text(
            terlambat
                ? 'Dosen atau ketua kelas akan meninjau permintaan gabung terlambatmu.'
                : 'Sistem mengacak dan mengunci kelompok otomatis saat batas gabung. Kami kabari lewat notifikasi.',
            textAlign: TextAlign.center,
            style: GuyubText.secondary.copyWith(color: GuyubColors.inkBody),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Waktu tersisa sampai pengacakan',
            child: Text(_sisa(), style: GuyubText.mono(size: 26, weight: FontWeight.w600, color: GuyubColors.primary)),
          ),
          Text('menuju ${tanggalPendek(d.batasJoin)}, ${jam(d.batasJoin)} WIB', style: GuyubText.secondary),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _Stat(label: 'Peserta', nilai: '${d.jumlahPeserta}')),
        const SizedBox(width: 10),
        Expanded(child: _Stat(label: 'Aturan', nilai: d.aturan)),
      ]),
      const SizedBox(height: 12),
      _SidikJari(nilai: d.sidikJari),
      const SizedBox(height: 16),
      Text(
        'Salah masuk sesi? Hubungi dosen atau ketua kelas untuk dikeluarkan.',
        textAlign: TextAlign.center,
        style: GuyubText.secondary,
      ),
    ]);
  }
}

class _KartuKelompokSaya extends ConsumerWidget {
  const _KartuKelompokSaya({required this.sesi, required this.kelompok, this.nimSaya});
  final DetailSesi sesi;
  final Kelompok kelompok;
  final String? nimSaya;

  Future<void> _ubahNama(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController(text: kelompok.nama);
    final nama = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti nama kelompok'),
        content: TextField(controller: c, autofocus: true, maxLength: 60, decoration: const InputDecoration(hintText: 'Contoh: Tim Relasi')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Simpan')),
        ],
      ),
    );
    if (nama == null || nama.trim() == kelompok.nama || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(timRepositoryProvider).ubahNama(kelompok.id, nama);
      ref.invalidate(detailSesiProvider(sesi.id));
      ref.invalidate(sesiSayaProvider);
      ref.invalidate(berandaProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Nama kelompok disimpan.')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.field('nama') ?? e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = kelompok;
    return GuyubCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: const BoxDecoration(
            color: GuyubColors.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(GuyubRadius.card)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kelompok ${k.nomor}', style: GuyubText.caption.copyWith(color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.6)),
                Text(k.nama, style: GuyubText.pageTitle.copyWith(color: Colors.white, fontSize: 19)),
                Text('${sesi.judul} · ${k.anggota.length} anggota', style: GuyubText.secondary.copyWith(color: Colors.white.withValues(alpha: 0.9))),
              ]),
            ),
            IconButton(
              tooltip: 'Ganti nama kelompok',
              onPressed: () => _ubahNama(context, ref),
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
          ]),
        ),
        for (var i = 0; i < k.anggota.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 64, color: GuyubColors.line),
          _BarisAnggota(anggota: k.anggota[i], saya: k.anggota[i].nim != null && k.anggota[i].nim == nimSaya),
        ],
      ]),
    );
  }
}

class _BarisAnggota extends StatelessWidget {
  const _BarisAnggota({required this.anggota, required this.saya});
  final Anggota anggota;
  final bool saya;

  @override
  Widget build(BuildContext context) {
    final a = anggota;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: saya ? GuyubColors.primary : GuyubColors.primaryTint,
          child: Text(inisial(a.nama), style: GuyubText.caption.copyWith(color: saya ? Colors.white : GuyubColors.primary, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(style: GuyubText.fieldLabel, children: [
              TextSpan(text: a.nama),
              if (saya) TextSpan(text: '  (kamu)', style: GuyubText.secondary),
            ])),
            if (a.nim != null) Text(a.nim!, style: GuyubText.mono(size: 12.5, color: GuyubColors.inkMuted)),
          ]),
        ),
        if (a.noWhatsapp != null && !saya)
          IconButton(
            tooltip: 'Salin nomor WhatsApp ${a.nama}',
            icon: const Icon(Icons.chat_outlined, color: GuyubColors.primary, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: a.noWhatsapp!));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nomor WhatsApp ${a.nama} disalin: ${a.noWhatsapp}')));
            },
          ),
      ]),
    );
  }
}

class _KartuBukti extends StatelessWidget {
  const _KartuBukti({required this.sesi, required this.bukti});
  final DetailSesi sesi;
  final BuktiAcak bukti;

  @override
  Widget build(BuildContext context) {
    final b = bukti;
    final waktu = sesi.dikunciPada;
    return GuyubCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(b.cocok ? Icons.verified_outlined : Icons.error_outline, color: b.cocok ? GuyubColors.primary : GuyubColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(b.cocok ? 'Pengacakan terbukti adil' : 'Bukti tidak cocok', style: GuyubText.cardTitle)),
          StatusBadge(b.cocok ? 'Cocok' : 'Gagal'),
        ]),
        const SizedBox(height: 8),
        if (waktu != null)
          Text('Diacak otomatis oleh sistem ${tanggalPendek(waktu)}, ${jam(waktu)} WIB.', style: GuyubText.secondary.copyWith(color: GuyubColors.inkBody)),
        const SizedBox(height: 10),
        _NilaiMono('Seed', b.seed ?? '-'),
        _NilaiMono('Kode', b.kode),
        _NilaiMono('Sidik jari', b.sidikJari, potong: true),
        const SizedBox(height: 8),
        Text(b.rumus, style: GuyubText.secondary),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 4),
            title: Text('Cara memeriksa sendiri', style: GuyubText.fieldLabel.copyWith(color: GuyubColors.primary)),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.algoritma, style: GuyubText.secondary.copyWith(color: GuyubColors.inkBody)),
              if (b.riwayat.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Riwayat pengacakan', style: GuyubText.fieldLabel),
                for (final r in b.riwayat)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Putaran ${r.putaran} · ${r.jenis.replaceAll('_', ' ')} · ${r.jumlahPeserta} peserta · ${tanggalPendek(r.waktu)} ${jam(r.waktu)}'
                      '${r.alasan != null ? '\nAlasan: ${r.alasan}' : ''}',
                      style: GuyubText.secondary,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

class _SidikJari extends StatelessWidget {
  const _SidikJari({required this.nilai});
  final String nilai;

  @override
  Widget build(BuildContext context) => GuyubCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.fingerprint_rounded, color: GuyubColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Sidik jari pengacakan', style: GuyubText.cardTitle.copyWith(fontSize: 14))),
          ]),
          const SizedBox(height: 6),
          _NilaiMono('SHA-256', nilai, potong: true),
          const SizedBox(height: 4),
          Text(
            'Seed rahasia sudah dikunci dengan sidik jari ini sejak sesi dibuat. Setelah diacak, seed dibuka supaya siapa pun bisa memeriksa hasilnya.',
            style: GuyubText.secondary,
          ),
        ]),
      );
}

class _NilaiMono extends StatelessWidget {
  const _NilaiMono(this.label, this.nilai, {this.potong = false});
  final String label;
  final String nilai;
  final bool potong;

  @override
  Widget build(BuildContext context) {
    final tampil = potong && nilai.length > 16 ? '${nilai.substring(0, 8)}…${nilai.substring(nilai.length - 6)}' : nilai;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: nilai));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label disalin.')));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 80, child: Text(label, style: GuyubText.secondary)),
          Expanded(child: Text(tampil, style: GuyubText.mono(size: 13.5, weight: FontWeight.w600))),
          const Icon(Icons.copy_rounded, size: 15, color: GuyubColors.inkFaint),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.nilai});
  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) => GuyubCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GuyubText.secondary),
          const SizedBox(height: 2),
          Text(nilai, style: GuyubText.cardTitle),
        ]),
      );
}
