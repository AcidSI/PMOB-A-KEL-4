import 'package:flutter/material.dart';

import 'package:find_it/widgets/report/report_theme.dart';

/// Tab navigasi bawah Beranda.
enum HomeTab { home, map, matching, account }

/// Navigasi bawah: Beranda · Peta · [+] · Matching · Akun.
/// Tombol + di tengah sedikit terangkat seperti di desain.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.current,
    required this.onTabSelected,
    required this.onCreate,
    this.matchingBadge = 0,
  });

  final HomeTab current;
  final ValueChanged<HomeTab> onTabSelected;
  final VoidCallback onCreate;
  final int matchingBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ReportColors.surface,
        border: Border(top: BorderSide(color: Color(0xFFDCE6E1))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _item(HomeTab.home, Icons.home_rounded, 'Beranda'),
              _item(HomeTab.map, Icons.map_outlined, 'Peta'),
              Expanded(
                child: Center(child: _CreateButton(onTap: onCreate)),
              ),
              _item(
                HomeTab.matching,
                Icons.link,
                'Matching',
                badge: matchingBadge,
              ),
              _item(HomeTab.account, Icons.person_outline, 'Akun'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(HomeTab tab, IconData icon, String label, {int badge = 0}) {
    final selected = tab == current;
    final color = selected ? ReportColors.green : const Color(0xFF52676B);
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          key: Key('home-nav-${tab.name}'),
          onTap: () => onTabSelected(tab),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text(badge > 9 ? '9+' : '$badge'),
                backgroundColor: ReportColors.lost,
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Tooltip(
        message: 'Buat laporan',
        child: Material(
          color: ReportColors.green,
          elevation: 6,
          shadowColor: ReportColors.green.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: ReportColors.background, width: 4),
          ),
          child: InkWell(
            key: const Key('home-create'),
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onTap: onTap,
            child: const SizedBox(
              width: 58,
              height: 58,
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
