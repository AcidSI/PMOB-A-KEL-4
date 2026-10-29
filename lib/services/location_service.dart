import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/item.dart';
import '../utils/campus_locations.dart';

/// Status izin dan pembacaan GPS perangkat
enum LocationAccessStatus {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

/// Hasil pembacaan GPS perangkat
class UserLocationResult {
  final LatLng? position;
  final LocationAccessStatus status;
  final String message;

  const UserLocationResult({
    required this.position,
    required this.status,
    required this.message,
  });

  bool get isSuccess => status == LocationAccessStatus.ready && position != null;
}

/// Service untuk menangani GPS dan komputasi berbasis lokasi (FR-L01, FR-L06)
class LocationService {
  const LocationService();

  /// Meminta izin dan membaca koordinat GPS perangkat secara aman (FR-L01, NFR-03, NFR-06).
  Future<UserLocationResult> determinePosition() async {
    try {
      // 1. Periksa apakah layanan GPS diaktifkan di perangkat
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const UserLocationResult(
          position: null,
          status: LocationAccessStatus.serviceDisabled,
          message:
              'Layanan GPS perangkat belum aktif. Silakan aktifkan GPS untuk mendeteksi posisi Anda di kampus.',
        );
      }

      // 2. Periksa izin akses lokasi perangkat
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const UserLocationResult(
            position: null,
            status: LocationAccessStatus.permissionDenied,
            message:
                'Izin akses lokasi ditolak. Anda tetap dapat menjelajahi peta kampus Unand secara manual.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const UserLocationResult(
          position: null,
          status: LocationAccessStatus.permissionDeniedForever,
          message:
              'Izin lokasi ditolak secara permanen di pengaturan perangkat. Buka pengaturan aplikasi untuk mengizinkan.',
        );
      }

      // 3. Ambil posisi GPS dengan timeout dan akurasi tinggi
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return UserLocationResult(
        position: LatLng(position.latitude, position.longitude),
        status: LocationAccessStatus.ready,
        message: 'Lokasi GPS berhasil ditemukan.',
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return UserLocationResult(
        position: null,
        status: LocationAccessStatus.error,
        message: 'Gagal memperoleh koordinat GPS: $e',
      );
    }
  }

  /// Menghitung jarak antar dua titik koordinat dalam meter (FR-L06).
  double distanceBetween(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Format jarak yang mudah dibaca pengguna (misal: "85 m", "1.2 km").
  String formatDistance(double meters) {
    if (meters < 10) return '< 10 m';
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Mencari laporan barang yang berada di dalam radius tertentu dari pengguna (FR-L06).
  List<Item> getItemsInRadius({
    required LatLng userPosition,
    required List<Item> items,
    double radiusMeters = 500.0,
  }) {
    return items.where((item) {
      final itemPos = LatLng(
        item.latitude ?? CampusLocations.getCoordinates(item.location, fallbackSeed: item.id).latitude,
        item.longitude ?? CampusLocations.getCoordinates(item.location, fallbackSeed: item.id).longitude,
      );
      final dist = distanceBetween(userPosition, itemPos);
      return dist <= radiusMeters;
    }).toList();
  }
}

