import 'package:flutter/material.dart';

import '../app/theme.dart';

enum BadgeTone { hijau, kuning, merah, abu, biru }

/// Badge status (pil 11/700). Warna dipilih dari teks status bila tone tidak diisi.
/// StatusBadge('Menunggu')  StatusBadge('Ruang', tone: BadgeTone.biru)
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone});

  final String label;
  final BadgeTone? tone;

  static const _map = <BadgeTone, List<String>>{
    BadgeTone.hijau: ['disetujui', 'dikunci', 'aktif', 'siap diambil', 'dibayar', 'cocok', 'terbuka'],
    BadgeTone.kuning: ['menunggu', 'menunggu bayar', 'dikomplain', 'diproses', 'terlambat'],
    BadgeTone.merah: ['ditolak', 'dibatalkan', 'habis stok', 'gagal', 'bukan peserta kelas'],
    BadgeTone.abu: ['selesai', 'kedaluwarsa'],
  };

  BadgeTone get _tone {
    if (tone != null) return tone!;
    final key = label.toLowerCase();
    for (final e in _map.entries) {
      if (e.value.contains(key)) return e.key;
    }
    return BadgeTone.abu;
  }

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (_tone) {
      BadgeTone.hijau => (GuyubColors.primaryTint, GuyubColors.primary),
      BadgeTone.kuning => (GuyubColors.pasarTint, GuyubColors.pasarText),
      BadgeTone.merah => (GuyubColors.dangerTint, GuyubColors.danger),
      BadgeTone.abu => (GuyubColors.neutralTint, GuyubColors.inkBody),
      BadgeTone.biru => (GuyubColors.ruangTint, GuyubColors.ruang),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: GuyubText.caption.copyWith(color: fg, height: 1)),
    );
  }
}
