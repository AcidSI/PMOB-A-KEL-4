import 'package:flutter/material.dart';

/// Token warna & dekorasi Modul 1, mengikuti kanvas desain
/// "Find!t — Desain UI Lengkap". Semua layar laporan memakai nilai dari
/// sini, jadi perubahan warna cukup dilakukan di satu tempat.
class ReportColors {
  ReportColors._();

  // Merek
  static const green = Color(0xFF0A5934);
  static const greenDeep = Color(0xFF0E3B28);
  static const greenDeepField = Color(0xFF134A33);
  static const greenDeepBorder = Color(0xFF2E6B4D);
  static const lime = Color(0xFF73C47A);
  static const limeText = Color(0xFF9BDDA4);
  static const onDeepMuted = Color(0xFFBFE3C6);

  // Permukaan & teks
  static const background = Color(0xFFF3F7F4);
  static const surface = Colors.white;
  static const surfaceSoft = Color(0xFFF6FAF7);
  static const mint = Color(0xFFEEF6F1);
  static const ink = Color(0xFF14282C);
  static const body = Color(0xFF44575B);
  static const muted = Color(0xFF5B6B6E);
  static const line = Color(0xFFE2EBE6);
  static const outline = Color(0xFFCBD6D1);
  static const track = Color(0xFFE3ECE7);

  // Status
  static const lost = Color(0xFFB42318);
  static const lostTint = Color(0xFFFDE7E5);
  static const found = green;
  static const foundTint = Color(0xFFDCEFE0);
  static const warn = Color(0xFF7A4A00);
  static const warnTint = Color(0xFFFCE3B4);
  static const warnSurface = Color(0xFFFFF7E8);
  static const warnBorder = Color(0xFFF3D9A8);
  static const info = Color(0xFF1D4ED8);
  static const infoTint = Color(0xFFDBEAFE);
  static const neutral = Color(0xFF64748B);

  static Color typeColor(bool isFound) => isFound ? found : lost;
  static Color typeTint(bool isFound) => isFound ? foundTint : lostTint;
}

class ReportRadius {
  ReportRadius._();
  static const field = 14.0;
  static const card = 20.0;
  static const button = 18.0;
}

/// Dekorasi input standar. [dark] untuk kartu hijau tua ("Data privat").
InputDecoration reportInputDecoration({
  String? hint,
  bool dark = false,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(ReportRadius.field),
    borderSide: BorderSide(
      color: dark ? ReportColors.greenDeepBorder : ReportColors.outline,
      width: dark ? 1 : 1.5,
    ),
  );
  return InputDecoration(
    hintText: hint,
    hintMaxLines: 2,
    hintStyle: TextStyle(
      fontSize: 13,
      color: dark ? ReportColors.onDeepMuted : ReportColors.muted,
    ),
    filled: true,
    fillColor: dark ? ReportColors.greenDeepField : ReportColors.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    counterStyle: TextStyle(
      fontSize: 11,
      color: dark ? ReportColors.onDeepMuted : ReportColors.muted,
    ),
    border: border,
    enabledBorder: border,
    disabledBorder: border.copyWith(
      borderSide: BorderSide(
        color: dark ? ReportColors.greenDeepBorder : ReportColors.line,
      ),
    ),
    focusedBorder: border.copyWith(
      borderSide: BorderSide(
        color: dark ? ReportColors.lime : ReportColors.green,
        width: 2,
      ),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: ReportColors.lost, width: 1.5),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: ReportColors.lost, width: 2),
    ),
    errorStyle: TextStyle(
      color: dark ? const Color(0xFFFFB4AB) : ReportColors.lost,
    ),
  );
}
