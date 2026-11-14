import 'package:flutter/material.dart';

import 'package:find_it/routes/app_routes.dart';
import 'package:find_it/services/onboarding_service.dart';
import 'package:find_it/widgets/brand/findit_brand.dart';
import 'package:find_it/widgets/onboarding/onboarding_illustrations.dart';

/// Isi satu halaman onboarding.
class OnboardingPageData {
  final String title;
  final String body;
  final Widget illustration;

  const OnboardingPageData({
    required this.title,
    required this.body,
    required this.illustration,
  });
}

/// Onboarding 3 halaman: Laporkan → Dicocokkan → Kembali ke pemilik.
/// Bisa digeser atau memakai tombol; "Lewati"/"Mulai sekarang" menandai
/// onboarding selesai lalu menuju halaman Masuk.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const pages = [
    OnboardingPageData(
      title: 'Laporkan dalam hitungan menit',
      body:
          'Kehilangan atau menemukan barang? Isi nama, kategori, lokasi di '
          'kampus, dan foto. Selesai.',
      illustration: ReportIllustration(),
    ),
    OnboardingPageData(
      title: 'Dicocokkan otomatis',
      body:
          'Find!t membandingkan ciri, lokasi, dan waktu laporan hilang dengan '
          'barang temuan, lalu memberi tahu Anda saat ada yang mirip.',
      illustration: MatchIllustration(),
    ),
    OnboardingPageData(
      title: 'Kembali ke pemilik yang sah',
      body:
          'Klaim diverifikasi lewat ciri rahasia, kontak hanya dibagikan '
          'setelah disetujui, dan barang selesai saat kedua pihak '
          'mengonfirmasi.',
      illustration: ReturnIllustration(),
    ),
  ];

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageDuration = Duration(milliseconds: 320);

  final _controller = PageController();
  int _index = 0;

  List<OnboardingPageData> get _pages => OnboardingScreen.pages;
  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(duration: _pageDuration, curve: Curves.easeOutCubic);
  }

  void _previous() {
    _controller.previousPage(
      duration: _pageDuration,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    await OnboardingService.markCompleted();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                showBack: _index > 0,
                showSkip: !_isLast,
                onBack: _previous,
                onSkip: _finish,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  key: const Key('onboarding-pages'),
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) => _OnboardingPage(
                    data: _pages[index],
                    step: index + 1,
                    total: _pages.length,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _BottomControls(
                index: _index,
                total: _pages.length,
                isLast: _isLast,
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================= Widget privat

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showBack,
    required this.showSkip,
    required this.onBack,
    required this.onSkip,
  });

  final bool showBack;
  final bool showSkip;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              key: const Key('onboarding-back'),
              tooltip: 'Sebelumnya',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 20),
              style: IconButton.styleFrom(
                fixedSize: const Size(44, 44),
                foregroundColor: BrandColors.ink,
                side: const BorderSide(color: Color(0xFFD6E4DA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          else
            const FinditLogo(variant: FinditLogoVariant.wordmark, height: 26),
          const Spacer(),
          if (showSkip)
            TextButton(
              key: const Key('onboarding-skip'),
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: BrandColors.green,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Lewati'),
            ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.step,
    required this.total,
  });

  final OnboardingPageData data;
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: data.illustration),
        const SizedBox(height: 26),
        Text(
          'LANGKAH $step DARI $total',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: BrandColors.leaf,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.5,
            color: BrandColors.greenDeep,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.body,
          style: const TextStyle(
            fontSize: 15,
            height: 1.55,
            color: BrandColors.body,
          ),
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
  });

  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final dots = _PageDots(index: index, total: total);
    if (isLast) {
      return Column(
        children: [
          dots,
          const SizedBox(height: 14),
          BrandPrimaryButton(
            key: const Key('onboarding-start'),
            label: 'Mulai sekarang',
            onPressed: onNext,
          ),
        ],
      );
    }
    return Row(
      children: [
        dots,
        const Spacer(),
        BrandPrimaryButton(
          key: const Key('onboarding-next'),
          label: 'Lanjut',
          trailingIcon: Icons.arrow_forward,
          expand: false,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Halaman ${index + 1} dari $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? BrandColors.green : BrandColors.dotInactive,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
