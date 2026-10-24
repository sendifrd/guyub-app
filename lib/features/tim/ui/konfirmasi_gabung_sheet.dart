// Layar T2 · Konfirmasi gabung (bottom sheet), termasuk kondisi T5: sudah tergabung & sesi sudah dikunci.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/format.dart';
import '../../../core/sesi.dart';
import '../../../widgets/alert_box.dart';
import '../../../widgets/guyub_button.dart';
import '../../../widgets/status_badge.dart';
import '../../beranda/data/beranda_repository.dart';
import '../data/tim_repository.dart';

/// Hasil sheet: sesi yang dibuka, plus pesan dari server bila baru bergabung.
typedef HasilGabung = ({int sesiId, String? pesan});

Future<HasilGabung?> tampilkanKonfirmasiGabung(BuildContext context, PratinjauKode p) => showModalBottomSheet<HasilGabung>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: GuyubColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _KonfirmasiGabung(pratinjau: p),
    );

class _KonfirmasiGabung extends ConsumerStatefulWidget {
  const _KonfirmasiGabung({required this.pratinjau});
  final PratinjauKode pratinjau;

  @override
  ConsumerState<_KonfirmasiGabung> createState() => _KonfirmasiGabungState();
}

class _KonfirmasiGabungState extends ConsumerState<_KonfirmasiGabung> {
  bool _kirim = false;
  String? _galat;

  Future<void> _gabung() async {
    setState(() {
      _kirim = true;
      _galat = null;
    });
    try {
      final r = await ref.read(timRepositoryProvider).gabung(widget.pratinjau.kode);
      ref.invalidate(berandaProvider);
      if (mounted) Navigator.pop<HasilGabung>(context, (sesiId: r.sesiId, pesan: r.pesan));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _kirim = false;
          _galat = e.field('kode') ?? e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pratinjau;
    final saya = ref.watch(sesiProvider).pengguna;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: GuyubColors.line, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text(p.sudahGabung ? 'Sesi kamu' : 'Konfirmasi gabung', style: GuyubText.pageTitle.copyWith(fontSize: 18)),
            const Spacer(),
            Text(p.kode, style: GuyubText.mono(size: 15, weight: FontWeight.w600, color: GuyubColors.primary).copyWith(letterSpacing: 2)),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: GuyubColors.surfaceSubtle, borderRadius: BorderRadius.circular(GuyubRadius.card), border: Border.all(color: GuyubColors.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(p.judul, style: GuyubText.cardTitle)),
                StatusBadge(p.akanTerlambat ? 'Dikunci' : 'Terbuka', tone: p.akanTerlambat ? BadgeTone.abu : BadgeTone.hijau),
              ]),
              const SizedBox(height: 2),
              Text(p.matkul.label, style: GuyubText.secondary),
              const SizedBox(height: 12),
              _Baris('Peserta saat ini', '${p.jumlahPeserta} orang'),
              _Baris('Batas gabung', '${tanggalPendek(p.batasJoin)}, ${jam(p.batasJoin)} WIB'),
            ]),
          ),
          const SizedBox(height: 14),
          if (p.sudahGabung) ...[
            AlertBox(switch (p.statusSaya) {
                'terlambat_menunggu' => 'Permintaan gabung terlambatmu sedang menunggu persetujuan dosen atau ketua kelas.',
                'terlambat_ditolak' => 'Permintaan gabung terlambatmu ditolak. Hubungi dosen atau ketua kelas.',
                _ => 'Kamu sudah ada di sesi ini.',
              },
              tone: p.statusSaya == 'terlambat_ditolak' ? AlertTone.galat : AlertTone.info,
            ),
            const SizedBox(height: 16),
            GuyubButton(label: 'Buka sesi', expand: true, onPressed: () => Navigator.pop<HasilGabung>(context, (sesiId: p.id, pesan: null))),
          ] else ...[
            if (saya != null) ...[
              Text('Kamu akan gabung sebagai', style: GuyubText.secondary),
              const SizedBox(height: 8),
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: GuyubColors.primaryTint,
                  child: Text(inisial(saya.nama), style: GuyubText.caption.copyWith(color: GuyubColors.primary, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(saya.nama, style: GuyubText.fieldLabel)),
                if (saya.nim != null) Text(saya.nim!, style: GuyubText.mono(size: 13, color: GuyubColors.inkMuted)),
              ]),
              const SizedBox(height: 14),
            ],
            AlertBox(p.akanTerlambat
                  ? 'Sesi ini sudah dikunci. Kirim permintaan gabung terlambat. Jika dosen atau ketua kelas menyetujui, sistem menempatkanmu ke kelompok yang anggotanya paling sedikit.'
                  : 'Setelah gabung, kamu tidak bisa keluar sendiri. Kelompok diacak otomatis oleh sistem saat batas gabung, tidak bisa memilih teman.',
              tone: p.akanTerlambat ? AlertTone.peringatan : AlertTone.info,
            ),
            if (_galat != null) ...[
              const SizedBox(height: 10),
              AlertBox(_galat!, tone: AlertTone.galat),
            ],
            const SizedBox(height: 16),
            GuyubButton(
              label: p.akanTerlambat ? 'Minta gabung terlambat' : 'Gabung sesi',
              expand: true,
              loading: _kirim,
              onPressed: _gabung,
            ),
            const SizedBox(height: 8),
            GuyubButton(
              label: 'Bukan sesi ini',
              variant: GuyubButtonVariant.neutral,
              expand: true,
              onPressed: _kirim ? null : () => Navigator.pop(context),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris(this.label, this.nilai);
  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label, style: GuyubText.secondary)),
          Text(nilai, style: GuyubText.fieldLabel.copyWith(fontSize: 13)),
        ]),
      );
}
