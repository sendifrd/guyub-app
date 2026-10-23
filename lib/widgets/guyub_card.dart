import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Kartu Guyub: putih, garis #DDE3DE, radius 14, padding 14, tanpa bayangan.
class GuyubCard extends StatelessWidget {
  const GuyubCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GuyubRadius.card),
      side: const BorderSide(color: GuyubColors.line),
    );
    return Material(
      color: GuyubColors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}
