import 'dart:typed_data';

/// Siklus status laporan (PRD 2.4).
enum ReportStatus {
  active('Aktif'),
  inVerification('Dalam Verifikasi'),
  resolved('Selesai'),
  expired('Kedaluwarsa'),
  removed('Dihapus');

  const ReportStatus(this.label);
  final String label;
}

/// Keberadaan barang untuk laporan Found (FR-R01).
enum ItemKeeping {
  withFinder('Dibawa penemu'),
  atSecurityPost('Dititipkan di pos keamanan');

  const ItemKeeping(this.label);
  final String label;
}

class Item {
  final String id;
  final String nameItem;
  final String subtitle;
  final String description;
  final String location;
  final bool isFound;

  /// Nama kategori utama (lihat [ReportCategories]).
  final String category;

  /// Kategori kedua opsional untuk barang gabungan (FR-R12).
  final String? category2;
  final DateTime? eventDate;

  /// 1–3 foto laporan. Foto pertama dipakai sebagai sampul.
  final List<Uint8List> photos;
  final String? assetPath;
  final String? color;
  final String? brand;

  /// Detail pembeda tersembunyi (FR-R08). Jangan tampilkan ke publik.
  final String? secretDetail;
  final String? reporter;
  final String? iconCategory;
  final bool isOwner;

  final ReportStatus status;
  final ItemKeeping? keeping;

  /// Koordinat laporan (opsional; diisi GPS atau pin peta Modul 2).
  final double? latitude;
  final double? longitude;

  /// Metadata foto kamera untuk validasi FR-R11 (hanya laporan Found).
  final DateTime? photoTakenAt;
  final double? photoLat;
  final double? photoLng;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const Item({
    required this.id,
    required this.nameItem,
    required this.subtitle,
    required this.description,
    required this.location,
    required this.isFound,
    required this.category,
    this.category2,
    this.eventDate,
    this.photos = const [],
    this.assetPath,
    this.color,
    this.brand,
    this.secretDetail,
    this.reporter,
    this.iconCategory,
    this.isOwner = false,
    this.status = ReportStatus.active,
    this.keeping,
    this.latitude,
    this.longitude,
    this.photoTakenAt,
    this.photoLat,
    this.photoLng,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  /// Foto sampul (kompatibel dengan kode lama yang memakai `imageData`).
  Uint8List? get imageData => photos.isEmpty ? null : photos.first;

  String get eventDateLabel {
    final date = eventDate;
    if (date == null) return 'Belum dicantumkan';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Salinan dengan perubahan. Gunakan flag `clear...` untuk menghapus nilai
  /// opsional (karena `null` pada parameter berarti "tidak diubah").
  Item copyWith({
    String? nameItem,
    String? subtitle,
    String? description,
    String? location,
    String? category,
    String? category2,
    bool clearCategory2 = false,
    DateTime? eventDate,
    List<Uint8List>? photos,
    String? color,
    bool clearColor = false,
    String? brand,
    bool clearBrand = false,
    String? secretDetail,
    bool clearSecretDetail = false,
    ReportStatus? status,
    ItemKeeping? keeping,
    double? latitude,
    double? longitude,
    DateTime? photoTakenAt,
    double? photoLat,
    double? photoLng,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return Item(
      id: id,
      nameItem: nameItem ?? this.nameItem,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      location: location ?? this.location,
      isFound: isFound,
      category: category ?? this.category,
      category2: clearCategory2 ? null : (category2 ?? this.category2),
      eventDate: eventDate ?? this.eventDate,
      photos: photos ?? this.photos,
      assetPath: assetPath,
      color: clearColor ? null : (color ?? this.color),
      brand: clearBrand ? null : (brand ?? this.brand),
      secretDetail:
          clearSecretDetail ? null : (secretDetail ?? this.secretDetail),
      reporter: reporter,
      iconCategory: iconCategory,
      isOwner: isOwner,
      status: status ?? this.status,
      keeping: keeping ?? this.keeping,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoTakenAt: photoTakenAt ?? this.photoTakenAt,
      photoLat: photoLat ?? this.photoLat,
      photoLng: photoLng ?? this.photoLng,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
