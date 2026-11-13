import 'dart:typed_data';

class ReportPhotoEntry {
  Uint8List bytes;
  final DateTime? takenAt;
  final double? latitude;
  final double? longitude;
  bool blurred;

  ReportPhotoEntry(
    this.bytes, {
    this.takenAt,
    this.latitude,
    this.longitude,
    this.blurred = false,
  });
}
