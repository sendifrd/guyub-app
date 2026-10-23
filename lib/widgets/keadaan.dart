import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'guyub_button.dart';

/// Layar galat dengan tombol Coba lagi (misalnya server mati).
class KeadaanGalat extends StatelessWidget {
  const KeadaanGalat({super.key, required this.pesan, required this.onCobaLagi});
  final String pesan;
  final VoidCallback onCobaLagi;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: GuyubColors.inkFaint),
            const SizedBox(height: 12),
            Text(pesan, textAlign: TextAlign.center, style: GuyubText.body.copyWith(color: GuyubColors.inkBody)),
            const SizedBox(height: 16),
            GuyubButton(label: 'Coba lagi', variant: GuyubButtonVariant.secondary, onPressed: onCobaLagi),
          ]),
        ),
      );
}

/// Kondisi kosong di dalam kartu atau daftar.
class KeadaanKosong extends StatelessWidget {
  const KeadaanKosong({super.key, required this.ikon, required this.pesan, this.aksi});
  final IconData ikon;
  final String pesan;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ikon, size: 32, color: GuyubColors.inkFaint),
          const SizedBox(height: 8),
          Text(pesan, textAlign: TextAlign.center, style: GuyubText.secondary),
          if (aksi != null) ...[const SizedBox(height: 12), aksi!],
        ]),
      );
}
