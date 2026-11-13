import 'package:flutter_test/flutter_test.dart';

import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';

Item _item({
  String id = 'a',
  String name = 'Dompet kulit coklat',
  bool isFound = false,
  String category = 'Dompet & Kartu',
  ReportStatus status = ReportStatus.active,
  String? ownerId = 'user:me',
  DateTime? createdAt,
  DateTime? expiresAt,
}) {
  return Item(
    id: id,
    nameItem: name,
    subtitle: '',
    description: 'desc',
    location: 'Perpustakaan',
    isFound: isFound,
    category: category,
    status: status,
    ownerId: ownerId,
    createdAt: createdAt,
    expiresAt: expiresAt,
  );
}

void main() {
  final now = DateTime(2026, 11, 13, 12);

  group('validasi input', () {
    test('nama barang 3–60 karakter', () {
      expect(ReportRules.validateName(''), isNotNull);
      expect(ReportRules.validateName('HP'), isNotNull);
      expect(ReportRules.validateName('Tas'), isNull);
      expect(ReportRules.validateName('x' * 61), isNotNull);
    });

    test('waktu kejadian tidak boleh di masa depan', () {
      expect(
        ReportRules.validateEventTime(now.add(const Duration(minutes: 1)), now),
        isNotNull,
      );
      expect(ReportRules.validateEventTime(now, now), isNull);
    });

    test('rentang waktu: akhir harus setelah awal', () {
      final start = now.subtract(const Duration(hours: 3));
      expect(
        ReportRules.validateEventTime(
          start,
          now,
          end: start.subtract(const Duration(minutes: 1)),
        ),
        isNotNull,
      );
      expect(
        ReportRules.validateEventTime(
          start,
          now,
          end: start.add(const Duration(hours: 1)),
        ),
        isNull,
      );
    });

    test('judul kategori sensitif tidak boleh memuat nomor kartu', () {
      expect(
        ReportRules.validateSensitiveTitle('Dompet & Kartu', 'KTM 2411522019'),
        isNotNull,
      );
      expect(
        ReportRules.validateSensitiveTitle('Dompet & Kartu', 'KTM biru'),
        isNull,
      );
      expect(
        ReportRules.validateSensitiveTitle('Elektronik', 'HP 2411522019'),
        isNull,
      );
    });

    test('format WhatsApp', () {
      expect(ReportRules.validateWhatsapp(''), isNull);
      expect(ReportRules.validateWhatsapp('081234567890'), isNull);
      expect(ReportRules.validateWhatsapp('+62 812-3456-7890'), isNull);
      expect(ReportRules.validateWhatsapp('12345'), isNotNull);
    });
  });

  group('foto Found (FR-R11)', () {
    test('harus dari kamera dan ≤ 30 menit', () {
      expect(
        ReportRules.validateFoundPhoto(takenAt: null, now: now),
        isNotNull,
      );
      expect(
        ReportRules.validateFoundPhoto(
          takenAt: now.subtract(const Duration(minutes: 31)),
          now: now,
        ),
        isNotNull,
      );
      expect(
        ReportRules.validateFoundPhoto(
          takenAt: now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        isNull,
      );
    });

    test('lokasi foto ≤ 500 m dari titik laporan', () {
      // ±0,01° lintang ≈ 1,1 km.
      expect(
        ReportRules.validateFoundPhoto(
          takenAt: now,
          now: now,
          photoLat: -0.914,
          photoLng: 100.459,
          reportLat: -0.904,
          reportLng: 100.459,
        ),
        isNotNull,
      );
      expect(
        ReportRules.validateFoundPhoto(
          takenAt: now,
          now: now,
          photoLat: -0.914,
          photoLng: 100.459,
          reportLat: -0.9145,
          reportLng: 100.459,
        ),
        isNull,
      );
    });
  });

  group('hak akses status', () {
    test('pemilik ditentukan oleh ownerId', () {
      final item = _item();
      expect(ReportRules.canEdit(item, 'user:me'), isTrue);
      expect(ReportRules.canEdit(item, 'user:other'), isFalse);
      expect(ReportRules.canDelete(item, null), isFalse);
    });

    test('verifikasi klaim: boleh edit sebagian, tidak boleh hapus/tutup', () {
      final item = _item(status: ReportStatus.inVerification);
      expect(ReportRules.canEdit(item, 'user:me'), isTrue);
      expect(ReportRules.canEditCoreFields(item), isFalse);
      expect(ReportRules.canDelete(item, 'user:me'), isFalse);
      expect(ReportRules.canClose(item, 'user:me'), isFalse);
    });

    test('kedaluwarsa: boleh diperpanjang', () {
      final item = _item(status: ReportStatus.expired);
      expect(ReportRules.canExtend(item, 'user:me'), isTrue);
      expect(ReportRules.canEdit(item, 'user:me'), isFalse);
    });
  });

  group('kedaluwarsa', () {
    test('pengingat muncul 7 hari sebelum berakhir', () {
      expect(
        ReportRules.needsExpiryReminder(
          _item(expiresAt: now.add(const Duration(days: 6))),
          now,
        ),
        isTrue,
      );
      expect(
        ReportRules.needsExpiryReminder(
          _item(expiresAt: now.add(const Duration(days: 30))),
          now,
        ),
        isFalse,
      );
    });

    test('lewat expiresAt dianggap kedaluwarsa', () {
      expect(
        ReportRules.isPastExpiry(
          _item(expiresAt: now.subtract(const Duration(minutes: 1))),
          now,
        ),
        isTrue,
      );
    });
  });

  group('anti-spam & duplikat', () {
    test('maksimal 5 laporan per 24 jam', () {
      final items = [
        for (var i = 0; i < ReportRules.maxReportsPerDay; i++)
          _item(id: '$i', createdAt: now.subtract(Duration(hours: i))),
      ];
      expect(ReportRules.checkRateLimit(items, 'user:me', now), isNotNull);
      expect(ReportRules.checkRateLimit(items, 'user:other', now), isNull);
    });

    test('nama mirip + kategori sama dalam 24 jam = kemungkinan duplikat', () {
      final items = [
        _item(createdAt: now.subtract(const Duration(hours: 2))),
      ];
      final duplicate = ReportRules.findPossibleDuplicate(
        items,
        userId: 'user:me',
        isFound: false,
        category: 'Dompet & Kartu',
        name: 'dompet coklat kulit',
        now: now,
      );
      expect(duplicate, isNotNull);

      final differentCategory = ReportRules.findPossibleDuplicate(
        items,
        userId: 'user:me',
        isFound: false,
        category: 'Elektronik',
        name: 'dompet coklat kulit',
        now: now,
      );
      expect(differentCategory, isNull);
    });
  });

  test('changedFields mencatat nama field yang berubah', () {
    final before = _item();
    final after = before.copyWith(
      description: 'baru',
      category: 'Tas & Ransel',
    );
    expect(
      ReportRules.changedFields(before, after),
      equals(['deskripsi', 'kategori']),
    );
    expect(ReportRules.changedFields(before, before.copyWith()), isEmpty);
  });
}
