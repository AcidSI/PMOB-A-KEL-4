import 'dart:typed_data';

enum ReportStatus { active, inVerification, resolved, expired, removed }

class Item {
  final String id;
  final String nameItem;
  final String subtitle;
  final String description;
  final String location;
  final bool isFound;
  final String category;
  final DateTime? eventDate;
  final Uint8List? imageData;
  final String? assetPath;
  final String? color;
  final String? brand;
  final String? reporter;
  final String? iconCategory;
  final String? category2;
  final String? ownerId;
  final List<String> verificationDetails;
  final String? whatsapp;
  final double? latitude;
  final double? longitude;
  ReportStatus status;
  final bool isOwner;

  Item({
    required this.id,
    required this.nameItem,
    required this.subtitle,
    required this.description,
    required this.location,
    required this.isFound,
    required this.category,
    this.eventDate,
    this.imageData,
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
    this.status = ReportStatus.active,
    this.isOwner = false,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get eventDateLabel {
    final date = eventDate;
    if (date == null) return 'Belum dicantumkan';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String get statusLabel => switch (status) {
    ReportStatus.active => isFound ? 'Ditemukan' : 'Kehilangan',
    ReportStatus.inVerification => 'Dalam Verifikasi',
    ReportStatus.resolved => 'Selesai',
    ReportStatus.expired => 'Kedaluwarsa',
    ReportStatus.removed => 'Disembunyikan',
  };
}
