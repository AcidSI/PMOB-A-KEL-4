import 'dart:math' as math;

import 'package:find_it/models/item.dart';
import 'package:find_it/models/report_category.dart';

/// Aturan bisnis Modul 1 (Reporting & Item Management) sebagai fungsi murni,
/// tanpa Flutter, agar mudah diuji dan nantinya padanannya dijalankan juga
/// di server (validasi sisi klien bukan satu-satunya pengaman).
class ReportRules {
  ReportRules._();

  // ------------------------------------------------------------- Parameter
  static const int maxPhotos = 3; // FR-R02
  static const int maxPhotoBytes = 2 * 1024 * 1024; // NFR-05
  static const Duration foundPhotoMaxAge = Duration(minutes: 30); // FR-R11
  static const double foundPhotoMaxDistanceMeters = 500; // FR-R11
  static const int expiryDays = 90; // FR-R10
  static const int expiryReminderDays = 7; // FR-R10 / FR-R06
  static const int minNameLength = 3;
  static const int maxNameLength = 60;
  static const int maxDescriptionLength = 300;
  static const int maxSecretDetailLength = 150;
  static const int maxReportsPerDay = 5; // anti-spam
  static const Duration duplicateWindow = Duration(hours: 24);
  static const double duplicateNameSimilarity = 0.6;

  // ---------------------------------------------------------------- Lokasi

  /// Jarak Haversine dua koordinat, dalam meter.
  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(a)));
  }

  // ------------------------------------------------------------ Foto Found

  /// FR-R11: foto kamera pada laporan Found harus diambil paling lama
  /// 30 menit sebelum dikirim dan (jika koordinat tersedia) ≤ 500 m dari
  /// titik laporan. Mengembalikan pesan error, atau null jika lolos.
  static String? validateFoundPhoto({
    required DateTime? takenAt,
    required DateTime now,
    double? photoLat,
    double? photoLng,
    double? reportLat,
    double? reportLng,
  }) {
    if (takenAt == null) {
      return 'Foto barang ditemukan harus diambil langsung dengan kamera.';
    }
    if (now.difference(takenAt) > foundPhotoMaxAge) {
      return 'Foto diambil lebih dari 30 menit yang lalu. '
          'Ambil ulang foto barang.';
    }
    if (photoLat != null &&
        photoLng != null &&
        reportLat != null &&
        reportLng != null) {
      final distance = haversineMeters(
        photoLat,
        photoLng,
        reportLat,
        reportLng,
      );
      if (distance > foundPhotoMaxDistanceMeters) {
        return 'Lokasi foto berjarak ${distance.round()} m dari titik laporan '
            '(maksimal ${foundPhotoMaxDistanceMeters.round()} m). '
            'Ambil ulang foto di lokasi penemuan.';
      }
    }
    return null;
  }

  // ----------------------------------------------------------- Input form

  static String? validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nama barang wajib diisi';
    if (text.length < minNameLength) {
      return 'Nama barang minimal $minNameLength karakter';
    }
    if (text.length > maxNameLength) {
      return 'Nama barang maksimal $maxNameLength karakter';
    }
    return null;
  }

  /// Waktu kejadian tidak boleh di masa depan; akhir rentang (jika ada)
  /// tidak boleh sebelum awal rentang.
  static String? validateEventTime(
    DateTime start,
    DateTime now, {
    DateTime? end,
  }) {
    if (start.isAfter(now)) {
      return 'Waktu kejadian tidak boleh melewati waktu sekarang.';
    }
    if (end != null) {
      if (end.isAfter(now)) {
        return 'Akhir rentang waktu tidak boleh melewati waktu sekarang.';
      }
      if (end.isBefore(start)) {
        return 'Akhir rentang waktu harus setelah waktu mulai.';
      }
    }
    return null;
  }

  /// FR-R07: pada kategori sensitif, judul tidak boleh memuat nomor kartu atau
  /// dokumen (deretan ≥ 6 angka).
  static String? validateSensitiveTitle(String? categoryName, String title) {
    if (!ReportCategories.isSensitiveName(categoryName)) return null;
    final compact = title.replaceAll(RegExp(r'[\s\-.]'), '');
    if (RegExp(r'\d{6,}').hasMatch(compact)) {
      return 'Jangan cantumkan nomor kartu/dokumen pada judul. '
          'Cukup tulis jenis barang.';
    }
    return null;
  }

  /// Nomor WhatsApp opsional: 08xx / 628xx / +628xx, 10–15 digit.
  static String? validateWhatsapp(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final digits = text.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^(\+?62|0)8\d{8,12}$').hasMatch(digits)) {
      return 'Format nomor WhatsApp tidak valid (contoh: 081234567890)';
    }
    return null;
  }

  // ------------------------------------------------------ Status & hak akses

  /// FR-R09: field inti (kategori, lokasi, detail pembeda) hanya boleh
  /// diubah saat laporan Active.
  static bool canEditCoreFields(Item item) =>
      item.status == ReportStatus.active;

  /// Pemilik boleh mengedit field non-inti selama laporan aktif/diverifikasi.
  static bool canEdit(Item item, String? userId) =>
      item.isOwnedBy(userId) &&
      (item.status == ReportStatus.active ||
          item.status == ReportStatus.inVerification);

  /// FR-R09: laporan yang sedang diverifikasi klaim tidak dapat dihapus.
  static bool canDelete(Item item, String? userId) =>
      item.isOwnedBy(userId) &&
      (item.status == ReportStatus.active ||
          item.status == ReportStatus.expired ||
          item.status == ReportStatus.resolved);

  static bool canExtend(Item item, String? userId) =>
      item.isOwnedBy(userId) &&
      (item.status == ReportStatus.active ||
          item.status == ReportStatus.expired);

  /// Pemilik dapat menutup laporan (mis. barang ketemu sendiri) selama
  /// belum ada klaim yang diverifikasi.
  static bool canClose(Item item, String? userId) =>
      item.isOwnedBy(userId) &&
      (item.status == ReportStatus.active ||
          item.status == ReportStatus.expired);

  // ----------------------------------------------------------- Kedaluwarsa

  static DateTime expiryFrom(DateTime from) =>
      from.add(const Duration(days: expiryDays));

  /// Laporan aktif yang melewati `expiresAt` berstatus Expired.
  static bool isPastExpiry(Item item, DateTime now) {
    final expiresAt = item.expiresAt;
    return item.status == ReportStatus.active &&
        expiresAt != null &&
        now.isAfter(expiresAt);
  }

  /// Sisa hari (dibulatkan ke atas) sampai kedaluwarsa; null jika tak berlaku.
  static int? daysUntilExpiry(Item item, DateTime now) {
    final expiresAt = item.expiresAt;
    if (expiresAt == null) return null;
    final remaining = expiresAt.difference(now);
    if (remaining.isNegative) return 0;
    return (remaining.inMinutes / (60 * 24)).ceil();
  }

  /// FR-R10: pengingat 7 hari sebelum kedaluwarsa.
  static bool needsExpiryReminder(Item item, DateTime now) {
    if (item.status != ReportStatus.active) return false;
    final days = daysUntilExpiry(item, now);
    return days != null && days > 0 && days <= expiryReminderDays;
  }

  // -------------------------------------------------- Anti-spam & duplikat

  /// Batas jumlah laporan baru per pengguna dalam 24 jam terakhir.
  static String? checkRateLimit(
    Iterable<Item> items,
    String? userId,
    DateTime now,
  ) {
    if (userId == null) return null;
    final since = now.subtract(const Duration(hours: 24));
    final count = items.where((item) {
      final created = item.createdAt;
      return item.ownerId == userId &&
          created != null &&
          created.isAfter(since);
    }).length;
    if (count >= maxReportsPerDay) {
      return 'Anda sudah membuat $count laporan dalam 24 jam terakhir. '
          'Coba lagi nanti, atau perbarui laporan yang sudah ada.';
    }
    return null;
  }

  /// Mencari laporan milik pengguna yang sama yang kemungkinan duplikat:
  /// jenis & kategori sama, masih aktif, dibuat ≤ 24 jam, nama mirip.
  static Item? findPossibleDuplicate(
    Iterable<Item> items, {
    required String? userId,
    required bool isFound,
    required String category,
    required String name,
    required DateTime now,
    String? excludeId,
  }) {
    if (userId == null) return null;
    for (final item in items) {
      final created = item.createdAt;
      if (item.id == excludeId ||
          item.ownerId != userId ||
          item.isFound != isFound ||
          item.category != category ||
          item.status != ReportStatus.active ||
          created == null ||
          now.difference(created) > duplicateWindow) {
        continue;
      }
      if (nameSimilarity(item.nameItem, name) >= duplicateNameSimilarity) {
        return item;
      }
    }
    return null;
  }

  /// Kemiripan nama berbasis irisan kata (Jaccard), 0..1.
  static double nameSimilarity(String a, String b) {
    Set<String> tokens(String s) => s
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 1)
        .toSet();
    final ta = tokens(a);
    final tb = tokens(b);
    if (ta.isEmpty || tb.isEmpty) return 0;
    final inter = ta.intersection(tb).length;
    final union = ta.union(tb).length;
    return inter / union;
  }

  // ---------------------------------------------------------- Riwayat edit

  /// Nama field (untuk ditampilkan) yang berbeda antara [before] dan [after].
  static List<String> changedFields(Item before, Item after) {
    final changed = <String>[];
    void check(String label, Object? a, Object? b) {
      if (a != b) changed.add(label);
    }

    check('nama', before.nameItem, after.nameItem);
    check('deskripsi', before.description, after.description);
    check('kategori', before.category, after.category);
    check('kategori kedua', before.category2, after.category2);
    check('lokasi', before.location, after.location);
    check('titik peta', before.latitude, after.latitude);
    check('waktu', before.eventDate, after.eventDate);
    check('akhir rentang waktu', before.eventEndDate, after.eventEndDate);
    check('warna', before.color, after.color);
    check('merek', before.brand, after.brand);
    check('keberadaan barang', before.keeping, after.keeping);
    check('keterangan penitipan', before.keepingNote, after.keepingNote);
    check('WhatsApp', before.whatsapp, after.whatsapp);
    check(
      'detail pembeda',
      before.verificationDetails.join('\n'),
      after.verificationDetails.join('\n'),
    );
    if (!_samePhotos(before, after)) changed.add('foto');
    return changed;
  }

  static bool _samePhotos(Item a, Item b) {
    if (a.photos.length != b.photos.length) return false;
    for (var i = 0; i < a.photos.length; i++) {
      // Foto yang tidak diubah memakai objek byte yang sama.
      if (!identical(a.photos[i], b.photos[i])) return false;
    }
    return true;
  }
}
