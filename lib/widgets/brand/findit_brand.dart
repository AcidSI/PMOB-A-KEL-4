import 'package:flutter/material.dart';

/// Identitas visual Find!t, diambil langsung dari logo
/// (`assets/images/logo.png`). Dipakai oleh Splash, Onboarding, dan Login.
class BrandColors {
  BrandColors._();

  /// Hijau utama (lingkar kaca pembesar & tombol).
  static const green = Color(0xFF086644);

  /// Hijau tua (huruf "Find!t", judul).
  static const greenDeep = Color(0xFF034B2D);

  /// Kuning (gagang kaca pembesar & titik "!").
  static const yellow = Color(0xFFFCBC01);
  static const onYellow = Color(0xFF3A2A00);

  /// Hijau daun (daun pada huruf "F").
  static const leaf = Color(0xFF4E9A4A);

  static const mint = Color(0xFFEAF4EC);
  static const mintStrong = Color(0xFFD6EBDA);
  static const cream = Color(0xFFFFF6D9);
  static const creamStrong = Color(0xFFFCE7A3);
  static const ink = Color(0xFF12301F);
  static const body = Color(0xFF3F5A4A);
  static const muted = Color(0xFF5B6B6E);
  static const outline = Color(0xFFCBD9CF);
  static const dotInactive = Color(0xFFCFE0D4);
}

/// Path aset logo. Daftarkan folder `assets/images/` di `pubspec.yaml`.
class BrandAssets {
  BrandAssets._();
  static const logo = 'assets/images/logo.png';
  static const icon = 'assets/images/logo_icon.png';
  static const wordmark = 'assets/images/logo_wordmark.png';
}

enum FinditLogoVariant { full, icon, wordmark }

/// Logo Find!t dengan cadangan ikon bila aset belum terdaftar.
class FinditLogo extends StatelessWidget {
  const FinditLogo({
    super.key,
    this.variant = FinditLogoVariant.full,
    this.width,
    this.height,
  });

  final FinditLogoVariant variant;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final path = switch (variant) {
      FinditLogoVariant.full => BrandAssets.logo,
      FinditLogoVariant.icon => BrandAssets.icon,
      FinditLogoVariant.wordmark => BrandAssets.wordmark,
    };
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Find!t',
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: width,
        height: height,
        child: const FittedBox(
          child: Icon(Icons.manage_search, color: BrandColors.green),
        ),
      ),
    );
  }
}

/// Hiasan cincin kuning (dari gagang kaca pembesar).
class BrandRing extends StatelessWidget {
  const BrandRing({super.key, this.size = 40, this.stroke = 8});
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: BrandColors.yellow, width: stroke),
        ),
      ),
    );
  }
}

/// Hiasan daun (dari huruf "F" pada logo).
class BrandLeaf extends StatelessWidget {
  const BrandLeaf({super.key, this.width = 34, this.color = BrandColors.leaf});
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final height = width * 0.62;
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: -0.42,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(height),
              bottomRight: Radius.circular(height),
              topRight: const Radius.circular(3),
              bottomLeft: const Radius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lingkaran polos untuk latar dekoratif.
class BrandBlob extends StatelessWidget {
  const BrandBlob({super.key, required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Tombol utama berwarna hijau merek.
class BrandPrimaryButton extends StatelessWidget {
  const BrandPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.expand = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool expand;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: BrandColors.green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: BrandColors.green.withValues(alpha: 0.7),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 26),
        elevation: 4,
        shadowColor: BrandColors.green.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 10),
                  Icon(trailingIcon, size: 20),
                ],
              ],
            ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Dekorasi field formulir autentikasi.
InputDecoration brandInputDecoration({
  String? hint,
  IconData? icon,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1.5]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: BrandColors.muted, fontSize: 14),
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    prefixIconColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.focused)
          ? BrandColors.green
          : BrandColors.muted,
    ),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(BrandColors.outline),
    enabledBorder: border(BrandColors.outline),
    focusedBorder: border(BrandColors.green, 2),
    errorBorder: border(const Color(0xFFB42318)),
    focusedErrorBorder: border(const Color(0xFFB42318), 2),
  );
}
