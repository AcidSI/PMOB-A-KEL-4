import 'dart:typed_data';

import 'package:find_it/models/item.dart';

/// Isian form laporan yang belum terkirim (NFR-06: isian tidak hilang saat
/// koneksi putus atau pengguna keluar dari form).
///
/// Disimpan di memori selama aplikasi berjalan. Untuk bertahan setelah
/// aplikasi ditutup, ganti isi [ReportDraftStore] dengan penyimpanan lokal
/// (mis. `shared_preferences`/sqflite) tanpa mengubah form.
class ReportDraft {
  final bool isFound;
  final String name;
  final String description;
  final String location;
  final String? category;
  final String? category2;
  final String color;
  final String brand;
  final String secretDetail;
  final String whatsapp;
  final String keepingNote;
  final ItemKeeping? keeping;
  final double? latitude;
  final double? longitude;
  final bool isLocationApproximate;
  final DateTime eventStart;
  final DateTime? eventEnd;

  /// Hanya foto galeri yang ikut disimpan. Foto kamera Found tidak disimpan
  /// karena harus segar (FR-R11: ≤ 30 menit).
  final List<Uint8List> galleryPhotos;
  final DateTime savedAt;

  const ReportDraft({
    required this.isFound,
    required this.name,
    required this.description,
    required this.location,
    required this.category,
    required this.category2,
    required this.color,
    required this.brand,
    required this.secretDetail,
    required this.whatsapp,
    required this.keepingNote,
    required this.keeping,
    required this.latitude,
    required this.longitude,
    required this.isLocationApproximate,
    required this.eventStart,
    required this.eventEnd,
    required this.galleryPhotos,
    required this.savedAt,
  });

  bool get isMeaningful =>
      name.trim().isNotEmpty ||
      description.trim().isNotEmpty ||
      location.trim().isNotEmpty ||
      galleryPhotos.isNotEmpty;
}

class ReportDraftStore {
  final Map<bool, ReportDraft> _drafts = {};

  ReportDraft? read({required bool isFound}) => _drafts[isFound];

  void save(ReportDraft draft) {
    if (!draft.isMeaningful) return;
    _drafts[draft.isFound] = draft;
  }

  void clear({required bool isFound}) => _drafts.remove(isFound);
}
