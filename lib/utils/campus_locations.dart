import 'package:latlong2/latlong.dart';

/// Utilitas koordinat area kampus Universitas Andalas (Limau Manis, Padang).
/// Digunakan untuk Modul 2: Location & Discovery (FR-L01, FR-L02, FR-L05).
class CampusLocations {
  CampusLocations._();

  /// Titik tengah kampus Universitas Andalas (sekitar Gedung Rektorat & Perpustakaan)
  static const LatLng unandCenter = LatLng(-0.91460, 100.45980);

  /// Radius perkiraan kampus Unand (meter)
  static const double unandCampusRadiusMeters = 2500.0;

  /// Daftar titik referensi gedung dan fasilitas utama di Universitas Andalas
  static const Map<String, LatLng> landmarks = {
    'Perpustakaan Pusat': LatLng(-0.91462, 100.45981),
    'Gedung Rektorat': LatLng(-0.91580, 100.45650),
    'Parkiran Rektorat': LatLng(-0.91550, 100.45610),
    'Aula Rektorat': LatLng(-0.91520, 100.45720),
    'Convention Hall': LatLng(-0.91520, 100.45720),
    'Kantin Fakultas Teknik': LatLng(-0.91350, 100.46550),
    'Ruang Kelas GKB 1': LatLng(-0.91520, 100.46210),
    'Ruang Diskusi GKB 2': LatLng(-0.91500, 100.46280),
    'Toilet GKB 3': LatLng(-0.91480, 100.46350),
    'GKB (Gedung Kuliah Bersama)': LatLng(-0.91510, 100.46250),
    'Lapangan Olahraga': LatLng(-0.91250, 100.46100),
    'Masjid Kampus': LatLng(-0.91680, 100.45780),
    'Student Center': LatLng(-0.91380, 100.45890),
    'Ruang Kelas FMIPA': LatLng(-0.91720, 100.46450),
    'Lab Komputer Fasilkom': LatLng(-0.91400, 100.46700),
    'Fakultas Teknologi Informasi': LatLng(-0.91400, 100.46700),
    'Kantin Pusat': LatLng(-0.91500, 100.46050),
    'Parkiran Fakultas Ekonomi': LatLng(-0.91800, 100.45900),
    'Gedung PKM': LatLng(-0.91350, 100.45850),
    'Fakultas Hukum': LatLng(-0.91750, 100.45800),
    'Fakultas Kedokteran': LatLng(-0.91600, 100.46300),
  };

  /// Mendapatkan koordinat dari nama lokasi teks.
  /// Melakukan pencocokan kata kunci toleran terhadap variasi penulisan.
  static LatLng getCoordinates(String? locationName, {String fallbackSeed = ''}) {
    if (locationName == null || locationName.trim().isEmpty) {
      return _generateJitteredCenter(fallbackSeed);
    }

    final query = locationName.toLowerCase().trim();

    // 1. Cek kecocokan langsung pada dictionary
    for (final entry in landmarks.entries) {
      if (entry.key.toLowerCase() == query) {
        return entry.value;
      }
    }

    // 2. Cek kecocokan parsial berdasarkan kata kunci utama di kampus Unand
    if (query.contains('perpustakaan')) {
      return landmarks['Perpustakaan Pusat']!;
    }
    if (query.contains('teknik')) {
      return landmarks['Kantin Fakultas Teknik']!;
    }
    if (query.contains('gkb 1') || query.contains('gkb1')) {
      return landmarks['Ruang Kelas GKB 1']!;
    }
    if (query.contains('gkb 2') || query.contains('gkb2')) {
      return landmarks['Ruang Diskusi GKB 2']!;
    }
    if (query.contains('gkb 3') || query.contains('gkb3')) {
      return landmarks['Toilet GKB 3']!;
    }
    if (query.contains('gkb') || query.contains('kuliah bersama')) {
      return landmarks['GKB (Gedung Kuliah Bersama)']!;
    }
    if (query.contains('lapangan') || query.contains('olahraga')) {
      return landmarks['Lapangan Olahraga']!;
    }
    if (query.contains('masjid') || query.contains('mushalla') || query.contains('nurul ilmi')) {
      return landmarks['Masjid Kampus']!;
    }
    if (query.contains('student center') || query.contains('pkm')) {
      return landmarks['Student Center']!;
    }
    if (query.contains('mipa') || query.contains('fmipa')) {
      return landmarks['Ruang Kelas FMIPA']!;
    }
    if (query.contains('fasilkom') || query.contains('fti') || query.contains('informatika')) {
      return landmarks['Lab Komputer Fasilkom']!;
    }
    if (query.contains('kantin pusat')) {
      return landmarks['Kantin Pusat']!;
    }
    if (query.contains('ekonomi') || query.contains('feb')) {
      return landmarks['Parkiran Fakultas Ekonomi']!;
    }
    if (query.contains('parkiran rektorat') || query.contains('rektorat')) {
      return landmarks['Parkiran Rektorat']!;
    }

    // Fallback dengan jitter kecil agar marker tidak menumpuk di 1 pixel yang sama persis
    return _generateJitteredCenter(locationName + fallbackSeed);
  }

  /// Menghasilkan koordinat Unand center dengan pergeseran deterministik kecil
  static LatLng _generateJitteredCenter(String seed) {
    if (seed.isEmpty) return unandCenter;
    final hash = seed.hashCode;
    final latOffset = ((hash % 100) - 50) * 0.00004;
    final lngOffset = (((hash ~/ 100) % 100) - 50) * 0.00004;
    return LatLng(
      unandCenter.latitude + latOffset,
      unandCenter.longitude + lngOffset,
    );
  }
}

