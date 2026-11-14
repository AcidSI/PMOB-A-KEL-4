import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:find_it/routes/app_routes.dart';
import 'package:find_it/services/app_session.dart';
import 'package:find_it/services/onboarding_service.dart';
import 'package:find_it/widgets/brand/findit_brand.dart';

/// Layar pembuka: logo muncul dengan animasi, bilah muat berjalan, lalu
/// otomatis menuju Beranda (sudah masuk), Masuk (sudah onboarding), atau
/// Onboarding (pertama kali).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.duration = const Duration(seconds: 2)});

  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goNext();
      })
      ..forward();
    final intro = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.35, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1).animate(intro);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_navigated) return;
    _navigated = true;
    final String route;
    if (AppSession.userId != null) {
      route = AppRoutes.home;
    } else if (await OnboardingService.isCompleted()) {
      route = AppRoutes.login;
    } else {
      route = AppRoutes.onboarding;
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ---- Hiasan latar
            const Positioned(
              right: -90,
              top: -90,
              child: BrandBlob(size: 260, color: BrandColors.mint),
            ),
            const Positioned(
              right: 40,
              top: 70,
              child: BrandRing(size: 64, stroke: 10),
            ),
            const Positioned(
              left: -80,
              right: -80,
              bottom: -150,
              height: 320,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: BrandColors.green,
                  shape: OvalBorder(),
                ),
              ),
            ),
            const Positioned(
              left: 44,
              bottom: 182,
              child: BrandLeaf(width: 46),
            ),

            // ---- Logo & tagline
            Center(
              child: FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FinditLogo(width: 230),
                      SizedBox(height: 18),
                      SizedBox(
                        width: 250,
                        child: Text(
                          'Temukan kembali barangmu di lingkungan kampus.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: BrandColors.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---- Bilah muat & nama kampus
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => LinearProgressIndicator(
                            value: _controller.value,
                            minHeight: 6,
                            color: BrandColors.yellow,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.25,
                            ),
                            semanticsLabel: 'Memuat aplikasi',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'UNIVERSITAS ANDALAS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
