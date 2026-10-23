import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../widgets/guyub_logo.dart';

/// Tampil sebentar saat aplikasi memeriksa token login yang tersimpan.
class MemuatPage extends StatelessWidget {
  const MemuatPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: GuyubColors.primary,
        body: Center(child: GuyubLogo(size: 64, onDark: true)),
      );
}
