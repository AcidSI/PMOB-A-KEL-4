import 'package:flutter_test/flutter_test.dart';

import 'package:find_it/data/item_repository.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/services/matching_service.dart';

/// Memastikan operasi Modul 1 tetap selaras dengan MatchingService (Modul 3)
/// yang berbagi daftar `items` yang sama.
void main() {
  late DateTime now;
  late ItemRepository repo;
  late MatchingService matching;

  Item report(String id, {required bool isFound, required String owner}) {
    return Item(
      id: id,
      nameItem: 'Dompet kulit coklat',
      subtitle: '',
      description: 'Dompet kulit warna coklat merek Fossil',
      location: 'Perpustakaan Pusat',
      isFound: isFound,
      category: 'Dompet & Kartu',
      color: 'Coklat',
      brand: 'Fossil',
      eventDate: now.subtract(Duration(hours: isFound ? 1 : 3)),
      latitude: -0.91462,
      longitude: 100.45981,
      ownerId: owner,
      verificationDetails: const ['Ada foto keluarga di dalam'],
    );
  }

  setUp(() {
    now = DateTime(2026, 11, 13, 12);
    repo = ItemRepository(
      items: [],
      fetchDelay: Duration.zero,
      submitDelay: Duration.zero,
      clock: () => now,
    );
    matching = MatchingService(items: repo.items);
  });

  test('laporan baru dari Modul 1 langsung ikut dicocokkan', () {
    repo.add(report('lost-1', isFound: false, owner: 'user:pemilik'));
    repo.add(report('found-1', isFound: true, owner: 'user:penemu'));
    matching.refreshMatches(now: now);
    expect(matching.matches, hasLength(1));
    expect(matching.matches.first.lostItemId, equals('lost-1'));
  });

  test('laporan yang ditutup atau dihapus keluar dari hasil matching', () {
    repo.add(report('lost-1', isFound: false, owner: 'user:pemilik'));
    repo.add(report('found-1', isFound: true, owner: 'user:penemu'));
    matching.refreshMatches(now: now);
    expect(matching.matches, hasLength(1));

    repo.close('lost-1', userId: 'user:pemilik', reason: 'Ketemu sendiri');
    matching.refreshMatches(now: now);
    expect(matching.matches, isEmpty);

    repo.add(report('lost-2', isFound: false, owner: 'user:pemilik2'));
    matching.refreshMatches(now: now);
    expect(matching.matches, hasLength(1));
    repo.softDelete('found-1', userId: 'user:penemu');
    matching.refreshMatches(now: now);
    expect(matching.matches, isEmpty);
  });

  test('edit laporan tidak memutus referensi Modul 3 (lookup per id)', () {
    repo.add(report('lost-1', isFound: false, owner: 'user:pemilik'));
    final found = repo.add(report('found-1', isFound: true, owner: 'user:p'));
    repo.update(found.copyWith(description: 'Dompet coklat Fossil, resleting'));
    expect(matching.itemById('found-1')!.description, contains('resleting'));
  });
}
