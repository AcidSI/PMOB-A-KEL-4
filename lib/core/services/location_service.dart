import 'package:geolocator/geolocator.dart';

typedef GeoPoint = ({double latitude, double longitude});

/// Membaca posisi GPS sekali (bukan pelacakan terus-menerus, sesuai PRD).
/// Mengembalikan null bila layanan lokasi mati, izin ditolak, atau gagal,
/// sehingga pengguna tetap dapat mengisi lokasi secara manual (NFR-03).
class LocationService {
  const LocationService();

  Future<GeoPoint?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }
}
