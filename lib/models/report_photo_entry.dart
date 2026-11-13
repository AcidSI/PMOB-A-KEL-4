import 'dart:typed_data';

/// Foto di dalam form laporan (sebelum dikirim).
class ReportPhotoEntry {
  Uint8List bytes;
  final DateTime? takenAt;
  final double? latitude;
  final double? longitude;
  bool blurred;

  /// Foto lama dari laporan yang sedang diedit (sudah lolos validasi).
  final bool isExisting;

  /// Foto laporan Found yang dipilih dari galeri karena kamera tidak bisa
  /// dipakai. Laporan akan diberi tanda "foto tidak diambil langsung".
  final bool isUnverified;

  ReportPhotoEntry(
    this.bytes, {
    this.takenAt,
    this.latitude,
    this.longitude,
    this.blurred = false,
    this.isExisting = false,
    this.isUnverified = false,
  });

  bool get isFromCamera => takenAt != null;
}
