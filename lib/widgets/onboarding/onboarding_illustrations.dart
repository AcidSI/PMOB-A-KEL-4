import 'package:flutter/material.dart';

import 'package:find_it/widgets/brand/findit_brand.dart';

/// Ilustrasi onboarding. Masing-masing digambar pada kanvas tetap
/// [OnboardingIllustration.designSize] lalu diskalakan (FittedBox), sehingga
/// proporsinya sama di HP kecil maupun besar.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.background,
    required this.children,
  });

  static const designSize = Size(342, 400);

  final Color background;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: ColoredBox(
          color: background,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox.fromSize(
              size: designSize,
              child: Stack(clipBehavior: Clip.hardEdge, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Halaman 1

/// "Laporkan dalam hitungan menit": ponsel berisi form laporan.
class ReportIllustration extends StatelessWidget {
  const ReportIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingIllustration(
      background: BrandColors.mint,
      children: [
        Positioned(
          right: -40,
          top: -40,
          child: BrandBlob(size: 160, color: BrandColors.mintStrong),
        ),
        Positioned(left: 22, bottom: 30, child: BrandLeaf()),
        Positioned(left: 86, top: 40, child: _PhoneMock()),
        Positioned(
          left: 226,
          top: 150,
          child: _FloatingChip(
            icon: Icons.location_on_outlined,
            caption: 'Lokasi',
            value: 'Kantin FT',
          ),
        ),
        Positioned(left: 30, top: 92, child: _Badge(text: '!')),
      ],
    );
  }
}

class _PhoneMock extends StatelessWidget {
  const _PhoneMock();

  @override
  Widget build(BuildContext context) {
    Widget line(double widthFactor, Color color) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
    return Container(
      width: 170,
      height: 320,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: BrandColors.greenDeep, width: 6),
        boxShadow: [
          BoxShadow(
            color: BrandColors.greenDeep.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEFE0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              size: 40,
              color: BrandColors.green,
            ),
          ),
          const SizedBox(height: 10),
          line(0.8, const Color(0xFFD6E4DA)),
          const SizedBox(height: 10),
          line(0.6, const Color(0xFFE3EEE6)),
          const SizedBox(height: 14),
          const Row(
            children: [
              _MiniPill(label: 'Dompet', selected: true),
              SizedBox(width: 6),
              _MiniPill(label: 'Tas'),
            ],
          ),
          const SizedBox(height: 14),
          line(0.7, const Color(0xFFE3EEE6)),
          const Spacer(),
          Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BrandColors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Publikasikan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? BrandColors.green : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: selected ? null : Border.all(color: const Color(0xFFD6E4DA)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : BrandColors.ink,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Halaman 2

/// "Dicocokkan otomatis": kartu Hilang & Ditemukan disambung.
class MatchIllustration extends StatelessWidget {
  const MatchIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingIllustration(
      background: BrandColors.greenDeep,
      children: [
        Positioned(
          left: -60,
          bottom: -60,
          child: BrandBlob(size: 200, color: BrandColors.green),
        ),
        Positioned(right: 28, top: 28, child: BrandRing()),
        Positioned(
          left: 24,
          top: 70,
          child: _ReportCard(
            isFound: false,
            title: 'Tumbler hijau',
            meta: 'Perpustakaan · 10.00–13.00',
          ),
        ),
        Positioned(
          left: 118,
          top: 236,
          child: _ReportCard(
            isFound: true,
            title: 'Botol hijau',
            meta: 'Perpustakaan · 13.40',
          ),
        ),
        Positioned(left: 150, top: 158, child: _LinkBadge()),
        Positioned(left: 228, top: 170, child: _ScorePill(text: 'Cocok 86%')),
        Positioned(left: 24, bottom: 26, child: _NotificationHint()),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.isFound,
    required this.title,
    required this.meta,
  });

  final bool isFound;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final color = isFound ? BrandColors.green : const Color(0xFFB42318);
    final tint = isFound ? const Color(0xFFDCEFE0) : const Color(0xFFFDE7E5);
    return Container(
      width: 205,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_drink_outlined, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFound ? 'DITEMUKAN' : 'HILANG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.ink,
                  ),
                ),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: BrandColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkBadge extends StatelessWidget {
  const _LinkBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: BrandColors.yellow,
        shape: BoxShape.circle,
        border: Border.all(color: BrandColors.greenDeep, width: 6),
      ),
      child: const Icon(Icons.link, size: 28, color: BrandColors.onYellow),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: BrandColors.greenDeep,
        ),
      ),
    );
  }
}

class _NotificationHint extends StatelessWidget {
  const _NotificationHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 16, color: BrandColors.yellow),
          SizedBox(width: 8),
          Text(
            'Ada barang yang mungkin milik Anda',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BrandColors.mint,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Halaman 3

/// "Kembali ke pemilik yang sah": perisai + tiga tahap klaim.
class ReturnIllustration extends StatelessWidget {
  const ReturnIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingIllustration(
      background: BrandColors.cream,
      children: [
        const Positioned(
          right: -50,
          bottom: -50,
          child: BrandBlob(size: 190, color: BrandColors.creamStrong),
        ),
        const Positioned(left: 26, top: 26, child: BrandLeaf()),
        Positioned(
          left: 101,
          top: 54,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: BrandColors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BrandColors.green.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 66,
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          left: 226,
          top: 52,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: BrandColors.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: BrandColors.cream, width: 4),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 16,
              color: BrandColors.onYellow,
            ),
          ),
        ),
        const Positioned(left: 30, right: 30, top: 222, child: _StepsCard()),
      ],
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    Widget step(int number, String label, {required bool done}) {
      return Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? BrandColors.green : BrandColors.yellow,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: done ? Colors.white : BrandColors.onYellow,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: BrandColors.ink,
              ),
            ),
          ),
          if (done) const Icon(Icons.check, size: 18, color: BrandColors.green),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F3A2A00),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          step(1, 'Sebut ciri rahasia barang', done: true),
          const SizedBox(height: 10),
          step(2, 'Penemu menyetujui klaim', done: true),
          const SizedBox(height: 10),
          step(3, 'Serah terima dikonfirmasi', done: false),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Umum

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.icon,
    required this.caption,
    required this.value,
  });

  final IconData icon;
  final String caption;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: BrandColors.greenDeep.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: BrandColors.yellow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: BrandColors.onYellow),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: const TextStyle(fontSize: 10, color: BrandColors.muted),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: BrandColors.yellow,
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: BrandColors.onYellow,
        ),
      ),
    );
  }
}
