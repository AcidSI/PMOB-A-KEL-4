import 'package:flutter/material.dart';

import 'package:find_it/widgets/report/report_theme.dart';

/// Header hijau Beranda: sapaan, lokasi kampus, tombol notifikasi, dan
/// kolom pencarian. Ikut bergulir bersama isi halaman. Lengkungan bawahnya
/// dibuat oleh [HomeHeaderOverlap] agar kartu aksi cepat bisa menumpang.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.displayName,
    required this.initials,
    required this.unreadCount,
    required this.searchController,
    required this.onSearchChanged,
    required this.onNotificationsTap,
    required this.onAdvancedSearchTap,
    this.campusLabel = 'Kampus Limau Manis',
  });

  final String greeting;
  final String displayName;
  final String initials;
  final int unreadCount;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNotificationsTap;
  final VoidCallback onAdvancedSearchTap;
  final String campusLabel;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 20),
      color: ReportColors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(initials: initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ReportColors.onDeepMuted,
                      ),
                    ),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _NotificationButton(
                count: unreadCount,
                onPressed: onNotificationsTap,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Color(0xFFD6EFDB),
              ),
              const SizedBox(width: 4),
              Text(
                campusLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFFD6EFDB)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SearchField(
            controller: searchController,
            onChanged: onSearchChanged,
            onAdvancedSearchTap: onAdvancedSearchTap,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ReportColors.lime,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0A3D24),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('home-notifications'),
      tooltip: count == 0 ? 'Notifikasi' : 'Notifikasi, $count baru',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        backgroundColor: const Color(0xFF0E6A3F),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF2E7A52)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 9 ? '9+' : '$count'),
        backgroundColor: const Color(0xFFF2A33A),
        textColor: const Color(0xFF2B1A00),
        child: const Icon(Icons.notifications_none),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onAdvancedSearchTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdvancedSearchTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: const Color(0x2E04281A),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: Color(0xFF52676B)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('home-search'),
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Cari dompet, kunci, botol…',
                  hintStyle: TextStyle(fontSize: 14, color: ReportColors.muted),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                key: const Key('home-advanced-search'),
                tooltip: 'Pencarian lanjutan',
                onPressed: onAdvancedSearchTap,
                style: IconButton.styleFrom(
                  fixedSize: const Size(40, 40),
                  backgroundColor: const Color(0xFFE3F2E7),
                  foregroundColor: ReportColors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kelanjutan header: pita hijau berlengkung di BELAKANG [child], sehingga
/// [child] (kartu aksi cepat) tampak menumpang di tepi bawah header tanpa
/// tertutup. Semuanya satu widget, jadi urutan gambarnya pasti benar.
class HomeHeaderOverlap extends StatelessWidget {
  const HomeHeaderOverlap({
    super.key,
    required this.child,
    this.overlap = 56,
    this.horizontalPadding = 20,
  });

  final Widget child;
  final double overlap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: overlap,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: ReportColors.green,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ],
    );
  }
}
