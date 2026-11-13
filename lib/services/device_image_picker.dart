import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:find_it/services/location_service.dart';
import 'package:find_it/services/image_processor.dart';

/// Foto hasil kamera beserta metadata untuk validasi FR-R11.
class CapturedPhoto {
  final Uint8List bytes;
  final DateTime takenAt;
  final double? latitude;
  final double? longitude;

  const CapturedPhoto({
    required this.bytes,
    required this.takenAt,
    this.latitude,
    this.longitude,
  });
}

/// Kesalahan akses kamera/galeri dengan pesan yang ramah pengguna (NFR-03).
class PhotoAccessException implements Exception {
  final String message;

  /// True bila kamera memang tidak dapat dipakai (izin ditolak / tidak ada
  /// kamera), sehingga form boleh menawarkan galeri sebagai cadangan.
  final bool cameraUnavailable;

  const PhotoAccessException(this.message, {this.cameraUnavailable = false});

  @override
  String toString() => message;
}

class DeviceImagePicker {
  const DeviceImagePicker({this.locationService = const LocationService()});

  final LocationService locationService;

  /// Kompatibilitas dengan kode lama.
  Future<Uint8List?> pickImage() => pickFromGallery();

  /// Galeri: laporan Lost, atau cadangan laporan Found bila kamera tidak
  /// dapat dipakai. Foto selalu di-encode ulang sehingga metadata EXIF
  /// (termasuk lokasi GPS tempat foto diambil) terhapus, lalu dikompres
  /// ≤ 2 MB (NFR-05).
  Future<Uint8List?> pickFromGallery() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return null;
      return await ImageProcessor.compressToLimit(
        await image.readAsBytes(),
        force: true,
      );
    } on PlatformException catch (error) {
      throw _mapError(error);
    }
  }

  /// Kamera: wajib untuk laporan Found (FR-R02). Waktu dan posisi dicatat
  /// segera setelah foto diambil agar server dapat memvalidasinya (FR-R11).
  Future<CapturedPhoto?> captureWithCamera() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return null;
      final takenAt = DateTime.now();
      final position = await locationService.currentPosition();
      final bytes = await ImageProcessor.compressToLimit(
        await image.readAsBytes(),
        force: true,
      );
      return CapturedPhoto(
        bytes: bytes,
        takenAt: takenAt,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
    } on PlatformException catch (error) {
      throw _mapError(error);
    }
  }

  static PhotoAccessException _mapError(PlatformException error) {
    switch (error.code) {
      case 'camera_access_denied':
      case 'camera_access_restricted':
        return const PhotoAccessException(
          'Izin kamera ditolak. Aktifkan izin kamera di Pengaturan, atau '
          'gunakan foto dari galeri.',
          cameraUnavailable: true,
        );
      case 'no_available_camera':
        return const PhotoAccessException(
          'Kamera tidak tersedia di perangkat ini. Gunakan foto dari galeri.',
          cameraUnavailable: true,
        );
      case 'photo_access_denied':
      case 'photo_access_restricted':
        return const PhotoAccessException(
          'Izin galeri ditolak. Aktifkan izin foto di Pengaturan.',
        );
      default:
        return PhotoAccessException(
          'Gagal mengambil foto: ${error.message ?? error.code}',
        );
    }
  }
}
