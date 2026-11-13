import 'package:flutter_test/flutter_test.dart';

import 'package:find_it/core/utils/validators.dart';
import 'package:find_it/features/report/data/item_repository.dart';
import 'package:find_it/features/report/domain/report_rules.dart';
import 'package:find_it/features/report/models/report.dart';
import 'package:find_it/features/report/models/report_category.dart';

// Ganti `findit` dengan nama paket pada pubspec.yaml proyek Anda.

Item _item({
  ReportStatus status = ReportStatus.active,
  bool isOwner = true,
  DateTime? expiresAt,
  String category = 'Elektronik',
}) => Item(
  id: 'x',
  nameItem: 'Laptop',
  subtitle: 's',
  description: 'd',
  location: 'l',
  isFound: false,
  category: category,
  isOwner: isOwner,
  status: status,
  expiresAt: expiresAt,
);

void main() {
  final now = DateTime(2026, 11, 1, 12);

  group('haversine', () {
    test('titik sama = 0 m', () {
      expect(ReportRules.haversineMeters(-0.91, 100.46, -0.91, 100.46), 0);
    });
    test('0.001 derajat lintang ≈ 111 m', () {
      final d = ReportRules.haversineMeters(-0.910, 100.46, -0.909, 100.46);
      expect(d, closeTo(111.2, 1));
    });
  });

  group('validateFoundPhoto (FR-R11)', () {
    test('tanpa waktu foto ditolak', () {
      expect(
        ReportRules.validateFoundPhoto(takenAt: null, now: now),
        isNotNull,
      );
    });
    test('29 menit lolos, 31 menit ditolak', () {
      expect(
        ReportRules.validateFoundPhoto(
          takenAt: now.subtract(const Duration(minutes: 29)),
          now: now,
        ),
        isNull,
      );
      expect(
        ReportRules.validateFoundPhoto(
          takenAt: now.subtract(const Duration(minutes: 31)),
          now: now,
        ),
        isNotNull,
      );
    });
    test('jarak > 500 m ditolak, ≤ 500 m lolos', () {
      final taken = now.subtract(const Duration(minutes: 1));
      expect(
        ReportRules.validateFoundPhoto(
          takenAt: taken,
          now: now,
          photoLat: -0.910,
          photoLng: 100.46,
          reportLat: -0.9055, // ±500 m lebih
          reportLng: 100.46,
        ),
        isNotNull,
      );
      expect(
        ReportRules.validateFoundPhoto(
          takenAt: taken,
          now: now,
          photoLat: -0.910,
          photoLng: 100.46,
          reportLat: -0.9075, // ±278 m
          reportLng: 100.46,
        ),
        isNull,
      );
    });
    test('tanpa koordinat, jarak tidak diperiksa', () {
      expect(
        ReportRules.validateFoundPhoto(
          takenAt: now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        isNull,
      );
    });
  });

  group('hak akses status (FR-R09)', () {
    test('Active: bisa edit inti, hapus, perpanjang', () {
      final item = _item();
      expect(ReportRules.canEditCoreFields(item), isTrue);
      expect(ReportRules.canEdit(item), isTrue);
      expect(ReportRules.canDelete(item), isTrue);
    });
    test('InVerification: edit sebagian, tidak bisa hapus', () {
      final item = _item(status: ReportStatus.inVerification);
      expect(ReportRules.canEditCoreFields(item), isFalse);
      expect(ReportRules.canEdit(item), isTrue);
      expect(ReportRules.canDelete(item), isFalse);
      expect(ReportRules.canExtend(item), isFalse);
    });
    test('bukan pemilik tidak bisa apa-apa', () {
      final item = _item(isOwner: false);
      expect(ReportRules.canEdit(item), isFalse);
      expect(ReportRules.canDelete(item), isFalse);
    });
  });

  group('kedaluwarsa (FR-R10)', () {
    test('melewati expiresAt = expired', () {
      expect(
        ReportRules.isPastExpiry(
          _item(expiresAt: now.subtract(const Duration(days: 1))),
          now,
        ),
        isTrue,
      );
    });
    test('pengingat tepat 7 hari, tidak pada 8 hari', () {
      expect(
        ReportRules.needsExpiryReminder(
          _item(expiresAt: now.add(const Duration(days: 7))),
          now,
        ),
        isTrue,
      );
      expect(
        ReportRules.needsExpiryReminder(
          _item(expiresAt: now.add(const Duration(days: 8))),
          now,
        ),
        isFalse,
      );
    });
    test('expiryFrom = +90 hari', () {
      expect(ReportRules.expiryFrom(now), now.add(const Duration(days: 90)));
    });
  });

  group('input', () {
    test('judul kategori sensitif tak boleh berisi nomor panjang', () {
      expect(
        ReportRules.validateSensitiveTitle('Dompet & Kartu', 'KTM 2111522001'),
        isNotNull,
      );
      expect(
        ReportRules.validateSensitiveTitle('Dompet & Kartu', 'Dompet hitam'),
        isNull,
      );
      expect(
        ReportRules.validateSensitiveTitle('Elektronik', 'HP 08123456789'),
        isNull,
      );
    });
    test('waktu kejadian tidak boleh di masa depan', () {
      expect(
        ReportRules.validateEventTime(now.add(const Duration(minutes: 5)), now),
        isNotNull,
      );
      expect(ReportRules.validateEventTime(now, now), isNull);
    });
    test('deskripsi maksimal 300 karakter', () {
      expect(Validators.reportDescription('a' * 300), isNull);
      expect(Validators.reportDescription('a' * 301), isNotNull);
    });
  });

  group('kategori', () {
    test('ada 10 kategori baku', () {
      expect(ReportCategories.all.length, 10);
    });
    test('hanya Dompet & Dokumen yang sensitif', () {
      final sensitive = ReportCategories.all
          .where((c) => c.isSensitive)
          .map((c) => c.name)
          .toList();
      expect(sensitive, [
        'Dompet & Kartu',
        'Dokumen & Perlengkapan Kuliah',
      ]);
    });
  });

  group('ItemRepository', () {
    test('add → Active, berlaku 90 hari; softDelete menyembunyikan', () {
      final repo = ItemRepository(items: [], clock: () => now);
      final stored = repo.add(_item(isOwner: true));
      expect(stored.status, ReportStatus.active);
      expect(stored.expiresAt, now.add(const Duration(days: 90)));
      expect(repo.visibleItems.length, 1);
      repo.softDelete('x');
      expect(repo.visibleItems, isEmpty);
    });
    test('hapus laporan InVerification ditolak', () {
      final repo = ItemRepository(
        items: [_item(status: ReportStatus.inVerification)],
        clock: () => now,
      );
      expect(() => repo.softDelete('x'), throwsStateError);
    });
    test('refreshExpiry lalu extend mengaktifkan kembali', () {
      final repo = ItemRepository(
        items: [_item(expiresAt: now.subtract(const Duration(days: 1)))],
        clock: () => now,
      );
      repo.refreshExpiry();
      expect(repo.items.first.status, ReportStatus.expired);
      final extended = repo.extend('x');
      expect(extended.status, ReportStatus.active);
      expect(extended.expiresAt, now.add(const Duration(days: 90)));
    });
    test('laporan expired milik orang lain disembunyikan', () {
      final repo = ItemRepository(
        items: [
          _item(
            isOwner: false,
            status: ReportStatus.expired,
          ),
        ],
        clock: () => now,
      );
      expect(repo.visibleItems, isEmpty);
    });
  });
}
