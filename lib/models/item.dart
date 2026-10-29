import 'dart:typed_data';
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
  final bool isOwner;
  final double? latitude;
  final double? longitude;

  const Item({
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
    this.isOwner = false,
    this.latitude,
    this.longitude,
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
}
