import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:find_it/features/report/domain/report_rules.dart';

/// Kompresi foto di perangkat agar ≤ 2 MB per foto (NFR-05).
class ImageProcessor {
  const ImageProcessor._();

  /// Menurunkan kualitas bertahap sampai ukuran ≤ [maxBytes].
  /// [force] = true memaksa konversi ke JPEG meski ukuran sudah kecil
  /// (dipakai setelah blur, karena hasil render berupa PNG besar).
  static Future<Uint8List> compressToLimit(
    Uint8List bytes, {
    int maxBytes = ReportRules.maxPhotoBytes,
    bool force = false,
  }) async {
    if (!force && bytes.lengthInBytes <= maxBytes) return bytes;
    var current = bytes;
    for (final quality in const [85, 70, 55, 40]) {
      current = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1280,
        minHeight: 1280,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (current.lengthInBytes <= maxBytes) return current;
    }
    throw StateError('Ukuran foto masih lebih dari 2 MB. Pilih foto lain.');
  }
}
