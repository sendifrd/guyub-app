// Layar T1 · Cari Tim (+ kondisi khusus T5). Tautan /j/{kode} membuka layar ini dengan kode terisi.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/format.dart';
import '../../../core/sesi.dart';
import '../../../widgets/guyub_button.dart';
import '../../../widgets/guyub_card.dart';
import '../../../widgets/keadaan.dart';
import '../../../widgets/status_badge.dart';
import '../data/tim_repository.dart';
import 'konfirmasi_gabung_sheet.dart';

class CariTimPage extends ConsumerStatefulWidget {
  const CariTimPage({super.key, this.kodeAwal});

  /// Diisi dari tautan undangan /j/{kode}.
  final String? kodeAwal;

  @override
  ConsumerState<CariTimPage> createState() => _CariTimPageState();
}

class _CariTimPageState extends ConsumerState<CariTimPage> {
  final _kode = TextEditingController();
  String? _galat;
  bool _mencari = false;

  @override
  void initState() {
    super.initState();
    final k = widget.kodeAwal?.trim().toUpperCase();
    if (k != null && k.isNotEmpty) {
      _kode.text = k;
      WidgetsBinding.instance.addPostFrameCallback((_) => _cari());
    }
  }

  @override
  void dispose() {
    _kode.dispose();
    super.dispose();
  }

  Future<void> _cari() async {
    final kode = _kode.text.trim().toUpperCase();
    if (kode.length != 6) {
      setState(() => _galat = 'Kode sesi terdiri dari 6 karakter.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _galat = null;
      _mencari = true;
    });
    try {
      final p = await ref.read(timRepositoryProvider).cariKode(kode);
      if (!mounted) return;
      setState(() => _mencari = false);
      final hasil = await tampilkanKonfirmasiGabung(context, p);
      if (!mounted || hasil == null) return;
      _kode.clear();
      ref.invalidate(sesiSayaProvider);
      if (hasil.pesan != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hasil.pesan!)));
      context.push('/tim/sesi/${hasil.sesiId}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _mencari = false;
        _galat = e.field('kode') ?? (e.status == 404 ? 'Kode tidak ditemukan. Periksa lagi huruf dan angkanya.' : e.message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(sesiProvider).pengguna;
    final daftar = ref.watch(sesiSayaProvider);

    return Scaffold(
      backgroundColor: GuyubColors.kapur,
      appBar: AppBar(
        title: const Text('Cari Tim'),
        actions: [
          if (p?.mengelolaKelas ?? false)
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Kelola sesi untuk dosen dan ketua kelas dibuat di tahap F3b.'))),
              child: Text('Kelola sesi', style: GuyubText.fieldLabel.copyWith(color: GuyubColors.primary)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: GuyubColors.primary,
        onRefresh: () => ref.refresh(sesiSayaProvider.future),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
          GuyubCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Gabung sesi kelompok', style: GuyubText.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 4),
              Text('Masukkan kode 6 karakter dari dosen atau ketua kelas.', style: GuyubText.secondary),
              const SizedBox(height: 14),
              Text('Kode sesi', style: GuyubText.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _kode,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                  TextInputFormatter.withFunction((_, b) => b.copyWith(text: b.text.toUpperCase())),
                ],
                onSubmitted: (_) => _cari(),
                onChanged: (_) {
                  if (_galat != null) setState(() => _galat = null);
                },
                style: GuyubText.mono(size: 22, weight: FontWeight.w600).copyWith(letterSpacing: 6),
                decoration: InputDecoration(hintText: 'K7Q2PX', counterText: '', errorText: _galat, errorMaxLines: 3),
              ),
              const SizedBox(height: 12),
              GuyubButton(label: 'Cari sesi', icon: Icons.search_rounded, expand: true, loading: _mencari, onPressed: _cari),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 10),
            child: Text('SESI SAYA', style: GuyubText.label),
          ),
          daftar.when(
            loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => KeadaanGalat(
              pesan: e is ApiException ? e.message : 'Daftar sesi gagal dimuat.',
              onCobaLagi: () => ref.invalidate(sesiSayaProvider),
            ),
            data: (list) => list.isEmpty
                ? const GuyubCard(
                    child: KeadaanKosong(
                      ikon: Icons.groups_outlined,
                      pesan: 'Belum ikut sesi apa pun. Minta kode sesi dari dosen atau ketua kelas, lalu masukkan di atas.',
                    ),
                  )
                : Column(children: [
                    for (final s in list)
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: _KartuSesi(sesi: s)),
                  ]),
          ),
        ]),
      ),
    );
  }
}

class _KartuSesi extends StatelessWidget {
  const _KartuSesi({required this.sesi});
  final SesiSaya sesi;

  @override
  Widget build(BuildContext context) {
    final s = sesi;
    final (String badge, BadgeTone tone, String info) = switch (s.statusSaya) {
      'terlambat_menunggu' => ('Menunggu', BadgeTone.kuning, 'Permintaan gabung terlambat menunggu persetujuan.'),
      'terlambat_ditolak' => ('Ditolak', BadgeTone.merah, 'Permintaan gabung terlambat ditolak.'),
      _ when s.dikunci && s.kelompokNomor != null => (
          'Dikunci',
          BadgeTone.hijau,
          'Kamu di Kelompok ${s.kelompokNomor}${s.kelompokNama != null && s.kelompokNama != 'Kelompok ${s.kelompokNomor}' ? ' · ${s.kelompokNama}' : ''}'
        ),
      _ when s.dikunci => ('Dikunci', BadgeTone.hijau, 'Kelompok sudah dikunci.'),
      _ => ('Menunggu', BadgeTone.kuning, 'Diacak otomatis ${tanggalPendek(s.batasJoin)}, ${jam(s.batasJoin)} WIB'),
    };
    return GuyubCard(
      onTap: () => context.push('/tim/sesi/${s.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(s.judul, style: GuyubText.cardTitle)),
          const SizedBox(width: 8),
          StatusBadge(badge, tone: tone),
        ]),
        const SizedBox(height: 2),
        Text(s.matkul.label, style: GuyubText.secondary),
        const SizedBox(height: 8),
        Row(children: [
          Icon(s.kelompokNomor != null ? Icons.people_alt_outlined : Icons.schedule_rounded, size: 16, color: GuyubColors.inkMuted),
          const SizedBox(width: 6),
          Expanded(child: Text(info, style: GuyubText.secondary.copyWith(color: GuyubColors.inkBody))),
        ]),
      ]),
    );
  }
}
