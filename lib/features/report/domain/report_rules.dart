import 'dart:math' as math;

import 'package:find_it/features/report/models/report.dart';
import 'package:find_it/features/report/models/report_category.dart';

/// Aturan bisnis Modul 1 sebagai fungsi murni (tanpa Flutter) agar mudah diuji
/// dan nantinya padanannya dijalankan juga di server.
class ReportRules {
  ReportRules._();

  // Parameter (PRD NFR-12: nantinya dibaca dari konfigurasi server).
  static const int maxPhotos = 3; // FR-R02
  static const int maxPhotoBytes = 2 * 1024 * 1024; // NFR-05
  static const Duration foundPhotoMaxAge = Duration(minutes: 30); // FR-R11
  static const double foundPhotoMaxDistanceMeters = 500; // FR-R11
  static const int expiryDays = 90; // FR-R10
  static const int expiryReminderDays = 7; // FR-R10
  static const int maxDescriptionLength = 300;

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
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(a)));
  }

  // ------------------------------------------------------------ Foto Found

  /// FR-R11: foto Found harus diambil dengan kamera, paling lama 30 menit
  /// sebelum dikirim, dan (jika koordinat tersedia) ≤ 500 m dari titik
  /// laporan. Mengembalikan pesan error, atau null jika lolos.
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
      final distance = haversineMeters(photoLat, photoLng, reportLat, reportLng);
      if (distance > foundPhotoMaxDistanceMeters) {
        return 'Lokasi foto berjarak ${distance.round()} m dari titik laporan '
            '(maksimal ${foundPhotoMaxDistanceMeters.round()} m). '
            'Ambil ulang foto di lokasi penemuan.';
      }
    }
    return null;
  }

  // ----------------------------------------------------------- Input form

  /// Waktu kejadian tidak boleh di masa depan.
  static String? validateEventTime(DateTime eventTime, DateTime now) {
    if (eventTime.isAfter(now)) {
      return 'Waktu kejadian tidak boleh melewati waktu sekarang.';
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

  // ------------------------------------------------------ Status & hak akses

  /// FR-R09: laporan yang sedang diverifikasi tidak boleh diubah field
  /// intinya (kategori, lokasi, detail pembeda).
  static bool canEditCoreFields(Item item) => item.status == ReportStatus.active;

  /// Pemilik boleh mengedit field non-inti selama laporan aktif/diverifikasi.
  static bool canEdit(Item item) =>
      item.isOwner &&
      (item.status == ReportStatus.active ||
          item.status == ReportStatus.inVerification);

  /// FR-R09: laporan dengan klaim Pending tidak dapat dihapus.
  static bool canDelete(Item item) =>
      item.isOwner &&
      (item.status == ReportStatus.active ||
          item.status == ReportStatus.expired);

  static bool canExtend(Item item) =>
      item.isOwner &&
      (item.status == ReportStatus.active ||
          item.status == ReportStatus.expired);

  // --------------------------------------------------------------- Kedaluwarsa

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
}
