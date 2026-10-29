import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/services/location_service.dart';
import 'package:find_it/utils/campus_locations.dart';

void main() {
  group('CampusLocations & Coordinates Tests (Modul 2)', () {
    test('CampusLocations resolves known Unand places accurately', () {
      final perpusCoord = CampusLocations.getCoordinates('Perpustakaan Pusat');
      expect(perpusCoord.latitude, closeTo(-0.91462, 0.001));
      expect(perpusCoord.longitude, closeTo(100.45981, 0.001));

      final teknikCoord = CampusLocations.getCoordinates('Kantin Fakultas Teknik');
      expect(teknikCoord.latitude, closeTo(-0.91350, 0.001));

      final gkbCoord = CampusLocations.getCoordinates('Ruang Kelas GKB 1');
      expect(gkbCoord.latitude, closeTo(-0.91520, 0.001));
    });

    test('CampusLocations fallback produces coordinates near Unand center', () {
      final fallbackCoord = CampusLocations.getCoordinates(
        'Lokasi Antah Berantah',
        fallbackSeed: 'test-seed',
      );
      expect(fallbackCoord.latitude, closeTo(CampusLocations.unandCenter.latitude, 0.01));
      expect(fallbackCoord.longitude, closeTo(CampusLocations.unandCenter.longitude, 0.01));
    });
  });

  group('LocationService Tests (Modul 2 - FR-L01 & FR-L06)', () {
    const service = LocationService();

    test('formatDistance formats meters and kilometers properly', () {
      expect(service.formatDistance(5), '< 10 m');
      expect(service.formatDistance(150), '150 m');
      expect(service.formatDistance(1250), '1.3 km');
    });

    test('getItemsInRadius filters items correctly within given radius (FR-L06)', () {
      final center = CampusLocations.unandCenter;

      final itemNear = Item(
        id: 'item-near',
        nameItem: 'Buku',
        subtitle: 'Dekat Rektorat',
        description: 'Buku tertinggal',
        location: 'Perpustakaan Pusat',
        isFound: false,
        category: 'Dokumen',
        latitude: center.latitude + 0.0002,
        longitude: center.longitude + 0.0002,
      );

      final itemFar = Item(
        id: 'item-far',
        nameItem: 'Helm',
        subtitle: 'Jauh di Pasar Baru',
        description: 'Helm tertinggal',
        location: 'Pasar Baru',
        isFound: false,
        category: 'Aksesori',
        latitude: -0.92500, // ~1.5 km away
        longitude: 100.43000,
      );

      final filtered = service.getItemsInRadius(
        userPosition: center,
        items: [itemNear, itemFar],
        radiusMeters: 500.0,
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, 'item-near');
    });
  });

  group('Item model coordinates test', () {
    test('Item hasCoordinates reflects latitude and longitude presence', () {
      const itemWithCoords = Item(
        id: '1',
        nameItem: 'Laptop',
        subtitle: 'Hilang',
        description: 'Deskripsi',
        location: 'Perpus',
        isFound: false,
        category: 'Elektronik',
        latitude: -0.9146,
        longitude: 100.4598,
      );
      expect(itemWithCoords.hasCoordinates, isTrue);

      const itemWithoutCoords = Item(
        id: '2',
        nameItem: 'Laptop',
        subtitle: 'Hilang',
        description: 'Deskripsi',
        location: 'Perpus',
        isFound: false,
        category: 'Elektronik',
      );
      expect(itemWithoutCoords.hasCoordinates, isFalse);
    });
  });
}

