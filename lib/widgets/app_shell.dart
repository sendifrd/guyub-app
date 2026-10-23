import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';

/// Kerangka layar utama dengan navigasi bawah 5 menu (Beranda, Tim, Pasar, Ruang, Profil).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _items = [
    (path: '/', label: 'Beranda', icon: Icons.home_outlined),
    (path: '/tim', label: 'Tim', icon: Icons.groups_outlined),
    (path: '/pasar', label: 'Pasar', icon: Icons.shopping_bag_outlined),
    (path: '/ruang', label: 'Ruang', icon: Icons.calendar_today_outlined),
    (path: '/profil', label: 'Profil', icon: Icons.person_outline),
  ];

  int get _index {
    for (var i = _items.length - 1; i > 0; i--) {
      if (location.startsWith(_items[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _index;
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: GuyubColors.surface,
          border: Border(top: BorderSide(color: GuyubColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => context.go(_items[i].path),
                  child: Semantics(
                    selected: i == current,
                    button: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 9, bottom: 12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_items[i].icon, size: 22, color: i == current ? GuyubColors.primary : GuyubColors.inkMuted),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: i == current ? FontWeight.w700 : FontWeight.w600,
                            color: i == current ? GuyubColors.primary : GuyubColors.inkMuted,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
