import 'package:flutter/material.dart';

import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/widgets/report/report_components.dart';
import 'package:find_it/widgets/report/report_theme.dart';

/// Bagian-bagian isi Beranda. Semua widget di sini hanya menampilkan data
/// dan meneruskan ketukan lewat callback; logika ada di `HomeScreen`.

/// Judul bagian + tautan opsional di kanan.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ReportColors.ink,
            ),
          ),
        ),
        if (trailing != null) trailing!,
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: ReportColors.green,
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

/// Banner gelap "N kemungkinan cocok" (data dari Modul 3).
class HomeMatchBanner extends StatelessWidget {
  const HomeMatchBanner({
    super.key,
    required this.count,
    required this.itemName,
    required this.onTap,
  });

  final int count;
  final String itemName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ReportColors.greenDeep,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('home-match-banner'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ReportColors.lime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.link, color: Color(0xFF0A3D24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count kemungkinan cocok',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'untuk laporan "$itemName" Anda',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ReportColors.onDeepMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Lihat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ReportColors.limeText,
                ),
              ),
              const Icon(Icons.chevron_right, color: ReportColors.limeText),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dua kartu ringkas "Laporan saya" (prioritas yang segera berakhir).
class HomeMyReportsStrip extends StatelessWidget {
  const HomeMyReportsStrip({
    super.key,
    required this.reports,
    required this.onOpen,
  });

  final List<Item> reports;
  final ValueChanged<Item> onOpen;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < reports.length && i < 2; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _MiniReportCard(
              item: reports[i],
              expiring: ReportRules.needsExpiryReminder(reports[i], now),
              days: ReportRules.daysUntilExpiry(reports[i], now),
              onTap: () => onOpen(reports[i]),
            ),
          ),
        ],
        if (reports.length == 1) const Expanded(child: SizedBox()),
      ],
    );
  }
}

class _MiniReportCard extends StatelessWidget {
  const _MiniReportCard({
    required this.item,
    required this.expiring,
    required this.days,
    required this.onTap,
  });

  final Item item;
  final bool expiring;
  final int? days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final verifying = item.status == ReportStatus.inVerification;
    final (tag, tagFg, tagBg) = expiring
        ? ('Segera berakhir', ReportColors.warn, ReportColors.warnTint)
        : verifying
        ? ('Diverifikasi', ReportColors.warn, ReportColors.warnTint)
        : (
            item.isFound ? 'Ditemukan · Aktif' : 'Hilang · Aktif',
            ReportColors.typeColor(item.isFound),
            ReportColors.typeTint(item.isFound),
          );
    final caption = expiring
        ? '$days hari lagi · perpanjang'
        : verifying
        ? 'Ada klaim masuk'
        : days != null
        ? 'Berlaku $days hari lagi'
        : item.location;
    return Material(
      color: expiring ? ReportColors.warnSurface : ReportColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: expiring ? ReportColors.warnBorder : ReportColors.line,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportTag(tag, foreground: tagFg, background: tagBg),
              const SizedBox(height: 6),
              Text(
                item.nameItem,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ReportColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: expiring
                      ? const Color(0xFF6E4B10)
                      : ReportColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris pil kategori yang bisa digulir. `null` = Semua.
class HomeCategoryBar extends StatelessWidget {
  const HomeCategoryBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  /// Padding di dalam daftar gulir, agar pil pertama tidak terpotong tepi.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final entries = <String?>[null, ...categories];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        key: const Key('home-category-bar'),
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = entries[index];
          return Center(
            child: ReportChoicePill(
              label: value ?? 'Semua',
              selected: selected == value,
              onSelected: (_) => onSelected(value),
            ),
          );
        },
      ),
    );
  }
}

/// Saklar tersegmentasi Semua / Hilang / Ditemukan, selebar layar.
class HomeTypeSegment extends StatelessWidget {
  const HomeTypeSegment({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ReportColors.track,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                selected: option == selected,
                button: true,
                child: Material(
                  color: option == selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    key: Key('home-type-$option'),
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => onChanged(option),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 36),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: option == selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: option == selected
                              ? ReportColors.ink
                              : ReportColors.body,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu laporan di daftar "Laporan terbaru".
class HomeReportCard extends StatelessWidget {
  const HomeReportCard({
    super.key,
    required this.item,
    required this.timeLabel,
    required this.onTap,
  });

  final Item item;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = item.isLocationApproximate
        ? '${item.location} (perkiraan)'
        : item.location;
    final keeping = item.keeping == ItemKeeping.atSecurityPost
        ? ' · dititipkan'
        : '';
    return Material(
      color: ReportColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: ReportColors.line),
      ),
      child: InkWell(
        key: Key('home-report-${item.id}'),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _Thumbnail(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _statusTag(),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            timeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: ReportColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.nameItem,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ReportColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: ReportColors.muted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '$location$keeping',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ReportColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTag() {
    return switch (item.status) {
      ReportStatus.inVerification => const ReportTag(
        'Dalam verifikasi',
        foreground: ReportColors.warn,
        background: ReportColors.warnTint,
      ),
      ReportStatus.resolved => ReportTag(
        item.statusLabel,
        foreground: Colors.white,
        background: ReportColors.neutral,
      ),
      ReportStatus.expired => const ReportTag(
        'Kedaluwarsa',
        foreground: Colors.white,
        background: ReportColors.neutral,
      ),
      _ => ReportTag.type(item.isFound),
    };
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});
  final Item item;

  @override
  Widget build(BuildContext context) {
    const size = 76.0;
    final image = item.imageData;
    final asset = item.assetPath;
    if (image != null || asset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: image != null
              ? Image.memory(image, fit: BoxFit.cover)
              : Image.asset(asset!, fit: BoxFit.cover),
        ),
      );
    }
    return ReportArtwork(
      isFound: item.isFound,
      category: item.category,
      size: size,
    );
  }
}
