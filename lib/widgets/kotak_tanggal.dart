import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/format.dart';

/// Kotak tanggal biru (KAM / 22 / Okt) untuk kartu booking.
class KotakTanggal extends StatelessWidget {
  const KotakTanggal(this.tanggal, {super.key});
  final DateTime tanggal;

  @override
  Widget build(BuildContext context) {
    final d = tanggal.toLocal();
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(color: GuyubColors.ruangTint, borderRadius: BorderRadius.circular(GuyubRadius.small)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(hariSingkat(d).toUpperCase(), style: GuyubText.caption.copyWith(color: GuyubColors.ruang)),
        Text('${d.day}', style: GuyubText.pageTitle.copyWith(fontSize: 22, height: 1.1)),
        Text(bulanSingkat(d), style: GuyubText.secondary.copyWith(fontSize: 11, color: GuyubColors.inkBody)),
      ]),
    );
  }
}
