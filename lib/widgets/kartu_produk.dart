import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../features/beranda/data/beranda_repository.dart';

/// Kartu produk 2 kolom (Beranda, katalog Pasar). Foto dari URL; kalau gagal dimuat, kotak warna + ikon.
class KartuProduk extends StatelessWidget {
  const KartuProduk({super.key, required this.produk, this.onTap});
  final ProdukRingkas produk;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = produk;
    final cadangan = Container(
      color: switch (p.tipe) { 'jasa' => GuyubColors.ruangTint, 'digital' => GuyubColors.primaryTint, _ => GuyubColors.pasarTint },
      alignment: Alignment.center,
      child: Icon(
        switch (p.tipe) { 'jasa' => Icons.design_services_outlined, 'digital' => Icons.description_outlined, _ => Icons.shopping_bag_outlined },
        size: 32,
        color: GuyubColors.inkMuted,
      ),
    );
    return Material(
      color: GuyubColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GuyubRadius.card), side: const BorderSide(color: GuyubColors.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(fit: StackFit.expand, children: [
              p.fotoUrl == null
                  ? cadangan
                  : Image.network(p.fotoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => cadangan),
              if (p.habis)
                Container(color: Colors.white.withValues(alpha: 0.6), alignment: Alignment.center, child: Text('Habis', style: GuyubText.cardTitle.copyWith(color: GuyubColors.danger))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nama, maxLines: 2, overflow: TextOverflow.ellipsis, style: GuyubText.body.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
              const SizedBox(height: 2),
              Text(p.tokoNama, maxLines: 1, overflow: TextOverflow.ellipsis, style: GuyubText.secondary),
              const SizedBox(height: 4),
              Text(rupiah(p.harga), style: GuyubText.cardTitle.copyWith(color: p.habis ? GuyubColors.inkFaint : GuyubColors.primary, fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
      ),
    );
  }
}
