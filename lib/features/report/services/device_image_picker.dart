import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'package:find_it/core/services/location_service.dart';
import 'package:find_it/features/report/services/image_processor.dart';

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

class DeviceImagePicker {
  const DeviceImagePicker({this.locationService = const LocationService()});

  final LocationService locationService;

  /// Galeri: dipakai laporan Lost (FR-R02). Hasil sudah dikompres ≤ 2 MB.
  Future<Uint8List?> pickImage() => pickFromGallery();

  Future<Uint8List?> pickFromGallery() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (image == null) return null;
    return ImageProcessor.compressToLimit(await image.readAsBytes());
  }

  /// Kamera: wajib untuk laporan Found (FR-R02). Waktu dan posisi dicatat
  /// segera setelah foto diambil agar server dapat memvalidasinya (FR-R11).
  Future<CapturedPhoto?> captureWithCamera() async {
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
    );
    return CapturedPhoto(
      bytes: bytes,
      takenAt: takenAt,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
  }
}
