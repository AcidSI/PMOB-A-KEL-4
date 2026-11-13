import 'dart:typed_data';

/// Siklus status laporan. Dipakai bersama oleh Modul 1, 2, dan 3.
///
/// Catatan: "ditutup pemilik" (barang ketemu sendiri / batal) memakai status
/// [resolved] + [Item.closedReason], sehingga enum ini tidak berubah dan
/// `switch` di modul lain tetap lengkap.
enum ReportStatus { active, inVerification, resolved, expired, removed }

/// Keberadaan barang temuan saat ini (FR-R01, khusus laporan Found).
enum ItemKeeping {
  withFinder('Dibawa penemu'),
  atSecurityPost('Dititipkan di pos keamanan / TU');

  const ItemKeeping(this.label);
  final String label;
}

/// Satu entri riwayat edit (FR-R04). Yang dicatat hanya NAMA field yang
/// berubah, bukan nilai lamanya, agar transparan tanpa membocorkan data.
class ReportEdit {
  final DateTime at;
  final List<String> fields;
  const ReportEdit({required this.at, required this.fields});
}

/// Model laporan tunggal (Lost/Found) untuk seluruh aplikasi.
class Item {
  final String id;
  final String nameItem;
  final String subtitle;
  final String description;
  final String location;
  final bool isFound;
  final String category;

  /// Waktu kejadian. Untuk laporan Lost ini adalah AWAL rentang waktu.
  final DateTime? eventDate;

  /// Akhir rentang waktu kejadian (opsional, umumnya laporan Lost).
  final DateTime? eventEndDate;

  /// 0–3 foto laporan; foto pertama dipakai sebagai sampul.
  final List<Uint8List> photos;
  final String? assetPath;
  final String? color;
  final String? brand;
  final String? reporter;
  final String? iconCategory;
  final String? category2;
  final String? ownerId;

  /// Detail pembeda rahasia. Hanya untuk verifikasi klaim (Modul 3).
  final List<String> verificationDetails;
  final String? whatsapp;
  final double? latitude;
  final double? longitude;

  /// True bila titik lokasi hanya perkiraan (pelapor tidak yakin / tanpa pin).
  final bool isLocationApproximate;

  ReportStatus status;
  final bool isOwner;

  // ---- Field khusus laporan Found ----
  final ItemKeeping? keeping;

  /// Keterangan tempat penitipan, mis. "Pos satpam Gedung F".
  final String? keepingNote;

  /// Metadata foto kamera pertama (validasi FR-R11).
  final DateTime? photoTakenAt;
  final double? photoLat;
  final double? photoLng;

  /// True bila ada foto Found yang tidak diambil langsung dengan kamera.
  final bool hasUnverifiedPhoto;

  // ---- Metadata siklus hidup ----
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  /// Alasan laporan ditutup oleh pemilik (status [ReportStatus.resolved]).
  final String? closedReason;
  final List<ReportEdit> editHistory;

  Item({
    required this.id,
    required this.nameItem,
    required this.subtitle,
    required this.description,
    required this.location,
    required this.isFound,
    required this.category,
    this.eventDate,
    this.eventEndDate,
    List<Uint8List> photos = const [],
    Uint8List? imageData,
    this.assetPath,
    this.color,
    this.brand,
    this.reporter,
    this.iconCategory,
    this.category2,
    this.ownerId,
    this.verificationDetails = const [],
    this.whatsapp,
    this.latitude,
    this.longitude,
    this.isLocationApproximate = false,
    this.status = ReportStatus.active,
    this.isOwner = false,
    this.keeping,
    this.keepingNote,
    this.photoTakenAt,
    this.photoLat,
    this.photoLng,
    this.hasUnverifiedPhoto = false,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.closedReason,
    this.editHistory = const [],
  }) : photos = photos.isNotEmpty
           ? List.unmodifiable(photos)
           : (imageData == null ? const [] : List.unmodifiable([imageData]));

  /// Foto sampul. Tetap tersedia agar kode Modul 2/3 yang membaca
  /// `imageData` tidak perlu diubah.
  Uint8List? get imageData => photos.isEmpty ? null : photos.first;

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Detail pembeda utama (bentuk tunggal dari [verificationDetails]).
  String? get secretDetail =>
      verificationDetails.isEmpty ? null : verificationDetails.first;

  /// Kepemilikan laporan: dibuat di sesi ini ([isOwner]) atau ownerId cocok.
  bool isOwnedBy(String? userId) =>
      isOwner || (userId != null && ownerId != null && ownerId == userId);

  bool get isClosedByOwner =>
      status == ReportStatus.resolved && closedReason != null;

  static String formatDateTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  String get eventDateLabel {
    final date = eventDate;
    if (date == null) return 'Belum dicantumkan';
    final end = eventEndDate;
    if (end == null) return formatDateTime(date);
    final sameDay =
        end.year == date.year && end.month == date.month && end.day == date.day;
    if (sameDay) {
      return '${formatDateTime(date)}–'
          '${end.hour.toString().padLeft(2, '0')}:'
          '${end.minute.toString().padLeft(2, '0')}';
    }
    return '${formatDateTime(date)} – ${formatDateTime(end)}';
  }

  String get statusLabel => switch (status) {
    ReportStatus.active => isFound ? 'Ditemukan' : 'Kehilangan',
    ReportStatus.inVerification => 'Dalam Verifikasi',
    ReportStatus.resolved => closedReason != null ? 'Ditutup' : 'Selesai',
    ReportStatus.expired => 'Kedaluwarsa',
    ReportStatus.removed => 'Disembunyikan',
  };

  /// Salinan dengan perubahan. Untuk mengosongkan nilai opsional gunakan
  /// flag `clear...`, karena `null` berarti "tidak diubah".
  Item copyWith({
    String? nameItem,
    String? subtitle,
    String? description,
    String? location,
    String? category,
    String? category2,
    bool clearCategory2 = false,
    DateTime? eventDate,
    DateTime? eventEndDate,
    bool clearEventEndDate = false,
    List<Uint8List>? photos,
    String? color,
    bool clearColor = false,
    String? brand,
    bool clearBrand = false,
    List<String>? verificationDetails,
    String? whatsapp,
    bool clearWhatsapp = false,
    double? latitude,
    double? longitude,
    bool? isLocationApproximate,
    ReportStatus? status,
    ItemKeeping? keeping,
    String? keepingNote,
    bool clearKeepingNote = false,
    DateTime? photoTakenAt,
    double? photoLat,
    double? photoLng,
    bool? hasUnverifiedPhoto,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    String? closedReason,
    List<ReportEdit>? editHistory,
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
      eventEndDate: clearEventEndDate
          ? null
          : (eventEndDate ?? this.eventEndDate),
      photos: photos ?? this.photos,
      assetPath: assetPath,
      color: clearColor ? null : (color ?? this.color),
      brand: clearBrand ? null : (brand ?? this.brand),
      reporter: reporter,
      iconCategory: iconCategory,
      ownerId: ownerId,
      verificationDetails: verificationDetails ?? this.verificationDetails,
      whatsapp: clearWhatsapp ? null : (whatsapp ?? this.whatsapp),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLocationApproximate:
          isLocationApproximate ?? this.isLocationApproximate,
      status: status ?? this.status,
      isOwner: isOwner,
      keeping: keeping ?? this.keeping,
      keepingNote: clearKeepingNote ? null : (keepingNote ?? this.keepingNote),
      photoTakenAt: photoTakenAt ?? this.photoTakenAt,
      photoLat: photoLat ?? this.photoLat,
      photoLng: photoLng ?? this.photoLng,
      hasUnverifiedPhoto: hasUnverifiedPhoto ?? this.hasUnverifiedPhoto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      closedReason: closedReason ?? this.closedReason,
      editHistory: editHistory ?? this.editHistory,
    );
  }
}
