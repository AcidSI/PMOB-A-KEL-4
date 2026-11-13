import 'package:flutter/material.dart';

import 'package:find_it/widgets/report/report_theme.dart';

/// Komponen tampilan yang dipakai bersama oleh layar Modul 1
/// (form laporan, detail, Laporan Saya).

/// Header halaman: tombol kembali berbingkai, judul, subjudul, dan
/// widget opsional di kanan (mis. label jenis laporan).
class ReportHeader extends StatelessWidget {
  const ReportHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Null = `Navigator.maybePop`.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ReportColors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ReportColors.line)),
          ),
          child: Row(
            children: [
              ReportIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Kembali',
                onPressed: onBack ?? () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ReportColors.ink,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ReportColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon 44×44 berbingkai (kembali, ubah, dll.).
class ReportIconButton extends StatelessWidget {
  const ReportIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// True = latar putih dengan bayangan (di atas foto).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        foregroundColor: ReportColors.ink,
        backgroundColor: filled ? ReportColors.surface : Colors.transparent,
        elevation: filled ? 2 : 0,
        shadowColor: Colors.black26,
        side: filled ? null : const BorderSide(color: Color(0xFFD4E0DA)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Label kecil berwarna (Hilang, Ditemukan, Segera berakhir, ...).
class ReportTag extends StatelessWidget {
  const ReportTag(
    this.label, {
    super.key,
    required this.foreground,
    required this.background,
  });

  factory ReportTag.type(bool isFound, {Key? key, bool solid = true}) {
    return ReportTag(
      isFound ? 'Ditemukan' : 'Hilang',
      key: key,
      foreground: solid ? Colors.white : ReportColors.typeColor(isFound),
      background: solid
          ? ReportColors.typeColor(isFound)
          : ReportColors.typeTint(isFound),
    );
  }

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Kartu bagian form. [step] menampilkan nomor bulat di depan judul.
/// [dark] = kartu hijau tua untuk data privat / foto Found.
class ReportSectionCard extends StatelessWidget {
  const ReportSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.step,
    this.subtitle,
    this.icon,
    this.trailing,
    this.dark = false,
  });

  final String title;
  final List<Widget> children;
  final int? step;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? Colors.white : ReportColors.ink;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? ReportColors.greenDeep : ReportColors.surface,
        borderRadius: BorderRadius.circular(ReportRadius.card),
        border: dark ? null : Border.all(color: ReportColors.line),
      ),
      child: Theme(
        // Teks input di kartu gelap tetap terbaca.
        data: dark
            ? Theme.of(context).copyWith(
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: ReportColors.lime,
                ),
              )
            : Theme.of(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (step != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ReportColors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: dark ? ReportColors.limeText : ReportColors.green,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: dark ? ReportColors.onDeepMuted : ReportColors.muted,
                ),
              ),
            ],
            const SizedBox(height: 14),
            ..._spaced(children),
          ],
        ),
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> children) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) result.add(const SizedBox(height: 14));
      result.add(children[i]);
    }
    return result;
  }
}

/// Label + field + teks bantuan.
class ReportField extends StatelessWidget {
  const ReportField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.helper,
    this.dark = false,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? helper;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFE5484D)),
                ),
            ],
          ),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : ReportColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: dark ? ReportColors.onDeepMuted : ReportColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Chip pilihan berbentuk pil (kategori, filter).
class ReportChoicePill extends StatelessWidget {
  const ReportChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.tooltip,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: onSelected,
      labelStyle: TextStyle(
        color: selected ? Colors.white : ReportColors.ink,
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
      backgroundColor: ReportColors.surface,
      selectedColor: ReportColors.green,
      disabledColor: ReportColors.surface,
      side: BorderSide(
        color: selected ? ReportColors.green : const Color(0xFFD3E0DA),
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

enum ReportBannerTone { info, warning, danger, success }

/// Kotak pemberitahuan ber-ikon.
class ReportBanner extends StatelessWidget {
  const ReportBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.tone = ReportBannerTone.warning,
    this.action,
  });

  final String text;
  final IconData icon;
  final ReportBannerTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (tone) {
      ReportBannerTone.warning => (
        ReportColors.warnSurface,
        ReportColors.warnBorder,
        const Color(0xFF5C3A06),
      ),
      ReportBannerTone.info => (
        ReportColors.mint,
        ReportColors.mint,
        const Color(0xFF2F4A3B),
      ),
      ReportBannerTone.danger => (
        const Color(0xFFFDF1F0),
        const Color(0xFFF6CFCB),
        const Color(0xFF7A1F17),
      ),
      ReportBannerTone.success => (
        ReportColors.foundTint,
        ReportColors.foundTint,
        ReportColors.greenDeep,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(fontSize: 12, height: 1.45, color: fg),
                ),
                if (action != null) ...[const SizedBox(height: 6), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bilah tombol utama di bagian bawah layar.
class ReportBottomBar extends StatelessWidget {
  const ReportBottomBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel = 'Memproses...',
    this.leading,
    this.buttonKey,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String busyLabel;

  /// Tombol tambahan di kiri (mis. ikon chat).
  final Widget? leading;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: const BoxDecoration(
          color: ReportColors.surface,
          border: Border(top: BorderSide(color: ReportColors.line)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  key: buttonKey,
                  onPressed: busy ? null : onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: ReportColors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ReportColors.green.withValues(
                      alpha: 0.7,
                    ),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ReportRadius.button),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: busy
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(busyLabel),
                          ],
                        )
                      : Text(label, textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak info kecil (label abu-abu + nilai tebal), dipakai di detail.
class ReportInfoTile extends StatelessWidget {
  const ReportInfoTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ReportColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: ReportColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ReportColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bilah sisa masa berlaku laporan (0..1).
class ReportProgressBar extends StatelessWidget {
  const ReportProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.semanticsLabel,
  });

  final double value;
  final Color color;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: 6,
        color: color,
        backgroundColor: color.withValues(alpha: 0.15),
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}

/// Ilustrasi pengganti foto: kotak berwarna dengan ikon kategori.
class ReportArtwork extends StatelessWidget {
  const ReportArtwork({
    super.key,
    required this.isFound,
    required this.category,
    this.size = 64,
    this.radius = 14,
  });

  final bool isFound;
  final String category;
  final double size;
  final double radius;

  static IconData iconFor(String category) => switch (category) {
    'Elektronik' => Icons.laptop_mac_outlined,
    'Dompet & Kartu' => Icons.account_balance_wallet_outlined,
    'Tas & Ransel' => Icons.backpack_outlined,
    'Kunci & Kendaraan' => Icons.vpn_key_outlined,
    'Dokumen & Perlengkapan Kuliah' => Icons.menu_book_outlined,
    'Pakaian & Aksesori' => Icons.checkroom_outlined,
    'Botol & Perlengkapan Makan' => Icons.local_drink_outlined,
    'Perlengkapan Ibadah' => Icons.mosque_outlined,
    'Perlengkapan Olahraga' => Icons.sports_soccer_outlined,
    _ => Icons.inventory_2_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ReportColors.typeTint(isFound),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        iconFor(category),
        size: size * 0.42,
        color: ReportColors.typeColor(isFound),
      ),
    );
  }
}

/// Petak tanggal/jam yang bisa diketuk.
class ReportDateTimeTile extends StatelessWidget {
  const ReportDateTimeTile({
    super.key,
    required this.caption,
    required this.value,
    required this.onTap,
  });

  final String caption;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: ReportColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: const BorderSide(color: ReportColors.outline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReportRadius.field),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: const TextStyle(fontSize: 11, color: ReportColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Kartu pilihan berikon (mis. keberadaan barang temuan).
class ReportOptionCard extends StatelessWidget {
  const ReportOptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? ReportColors.mint : ReportColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? ReportColors.green : const Color(0xFFD3E0DA),
            width: selected ? 2 : 1.5,
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
                Icon(
                  icon,
                  color: selected ? ReportColors.green : ReportColors.body,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ReportColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
