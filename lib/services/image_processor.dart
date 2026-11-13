import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:find_it/domain/report_rules.dart';

/// Kompresi foto di perangkat agar ≤ 2 MB per foto (NFR-05).
class ImageProcessor {
  const ImageProcessor._();

  /// Menurunkan kualitas bertahap sampai ukuran ≤ [maxBytes].
  /// [force] = true memaksa decode dan encode ulang meski ukuran sudah kecil.
  static Future<Uint8List> compressToLimit(
    Uint8List bytes, {
    int maxBytes = ReportRules.maxPhotoBytes,
    bool force = false,
  }) async {
    if (!force && bytes.lengthInBytes <= maxBytes) return bytes;

    final originalCodec = await ui.instantiateImageCodec(bytes);
    late final int originalWidth;
    late final int originalHeight;
    try {
      final frame = await originalCodec.getNextFrame();
      originalWidth = frame.image.width;
      originalHeight = frame.image.height;
      frame.image.dispose();
    } finally {
      originalCodec.dispose();
    }

    final longestSide =
        originalWidth > originalHeight ? originalWidth : originalHeight;
    for (final maxSide in const [1280, 1024, 800, 640, 480, 320]) {
      final scale = maxSide / longestSide;
      final width = (originalWidth * scale).round().clamp(1, originalWidth);
      final height = (originalHeight * scale).round().clamp(1, originalHeight);
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: width,
        targetHeight: height,
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          final data = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (data == null) continue;
          final result = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          if (result.lengthInBytes <= maxBytes) return result;
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    }
    throw StateError('Ukuran foto masih lebih dari 2 MB. Pilih foto lain.');
  }
}
