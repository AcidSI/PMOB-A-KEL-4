import 'package:flutter_test/flutter_test.dart';

import 'package:find_it/data/item_repository.dart';
import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/services/report_notification_service.dart';

Item _newReport(String id, {String owner = 'user:me', bool isFound = false}) {
  return Item(
    id: id,
    nameItem: 'Tumbler hijau $id',
    subtitle: '',
    description: 'Tumbler',
    location: 'Perpustakaan',
    isFound: isFound,
    category: 'Botol & Perlengkapan Makan',
    ownerId: owner,
    verificationDetails: const ['stiker kucing di bawah'],
  );
}

void main() {
  late DateTime now;
  late ItemRepository repo;

  setUp(() {
    now = DateTime(2026, 11, 13, 9);
    repo = ItemRepository(
      items: [],
      fetchDelay: Duration.zero,
      submitDelay: Duration.zero,
      clock: () => now,
    );
  });

  test('add: status aktif, berlaku 90 hari', () {
    final stored = repo.add(_newReport('1'));
    expect(stored.status, equals(ReportStatus.active));
    expect(stored.createdAt, equals(now));
    expect(stored.expiresAt, equals(now.add(const Duration(days: 90))));
    expect(repo.items, hasLength(1));
  });

  test('submit gagal tidak menyimpan apa pun', () async {
    repo.simulateSubmitFailure = true;
    Object? caught;
    try {
      await repo.submit(_newReport('1'));
    } catch (error) {
      caught = error;
    }
    expect(caught is ReportSubmitException, isTrue);
    expect(repo.items, isEmpty);
    // Percobaan berikutnya berhasil.
    await repo.submit(_newReport('1'));
    expect(repo.items, hasLength(1));
  });

  test('batas laporan harian ditegakkan di repository', () {
    for (var i = 0; i < ReportRules.maxReportsPerDay; i++) {
      repo.add(_newReport('$i'));
    }
    expect(() => repo.add(_newReport('x')), throwsStateError);
    expect(repo.add(_newReport('y', owner: 'user:other')), isNotNull);
  });

  test('update mencatat riwayat edit', () {
    final stored = repo.add(_newReport('1'));
    now = now.add(const Duration(hours: 1));
    final updated = repo.update(stored.copyWith(description: 'Tumbler 500ml'));
    expect(updated.editHistory, hasLength(1));
    expect(updated.editHistory.first.fields, equals(['deskripsi']));
    expect(updated.updatedAt, equals(now));
  });

  test('field inti terkunci saat verifikasi klaim', () {
    final stored = repo.add(_newReport('1'));
    stored.status = ReportStatus.inVerification; // diubah Modul 3
    expect(
      () => repo.update(stored.copyWith(category: 'Elektronik')),
      throwsStateError,
    );
    // Field non-inti tetap boleh.
    final ok = repo.update(stored.copyWith(description: 'baru'));
    expect(ok.status, equals(ReportStatus.inVerification));
  });

  test('soft delete: disembunyikan, data tetap ada', () {
    repo.add(_newReport('1'));
    repo.softDelete('1', userId: 'user:me');
    expect(repo.items, hasLength(1));
    expect(repo.findById('1')!.status, equals(ReportStatus.removed));
    expect(repo.visibleItemsFor('user:me'), isEmpty);
  });

  test('hapus ditolak untuk bukan pemilik & saat verifikasi', () {
    final stored = repo.add(_newReport('1'));
    expect(() => repo.softDelete('1', userId: 'user:other'), throwsStateError);
    stored.status = ReportStatus.inVerification;
    expect(() => repo.softDelete('1', userId: 'user:me'), throwsStateError);
  });

  test('tutup laporan menyimpan alasan', () {
    repo.add(_newReport('1'));
    final closed = repo.close(
      '1',
      userId: 'user:me',
      reason: 'Barang sudah saya temukan sendiri',
    );
    expect(closed.status, equals(ReportStatus.resolved));
    expect(closed.isClosedByOwner, isTrue);
    expect(closed.statusLabel, equals('Ditutup'));
  });

  test('kedaluwarsa hanya terlihat oleh pemilik, lalu bisa diperpanjang', () {
    repo.add(_newReport('1'));
    now = now.add(const Duration(days: 91));
    expect(repo.visibleItemsFor('user:other'), isEmpty);
    expect(repo.visibleItemsFor('user:me'), hasLength(1));
    expect(repo.findById('1')!.status, equals(ReportStatus.expired));

    final extended = repo.extend('1', userId: 'user:me');
    expect(extended.status, equals(ReportStatus.active));
    expect(repo.visibleItemsFor('user:other'), hasLength(1));
  });

  test('ownedBy hanya laporan milik pengguna, tanpa yang dihapus', () {
    repo.add(_newReport('1'));
    repo.add(_newReport('2', owner: 'user:other'));
    repo.add(_newReport('3'));
    repo.softDelete('3', userId: 'user:me');
    expect(repo.ownedBy('user:me').map((i) => i.id).toList(), equals(['1']));
  });

  group('notifikasi Modul 1', () {
    test('pengingat kedaluwarsa dikirim sekali per masa berlaku', () {
      final notifier = ReportNotificationService(clock: () => now);
      repo.add(_newReport('1'));
      now = now.add(const Duration(days: 85));

      final first = notifier.checkExpiry(repo.ownedBy('user:me'), 'user:me');
      expect(first, hasLength(1));
      expect(first.first.type, equals(ReportNoticeType.expiringSoon));
      expect(
        notifier.checkExpiry(repo.ownedBy('user:me'), 'user:me'),
        isEmpty,
      );

      now = now.add(const Duration(days: 6));
      final expired = notifier.checkExpiry(
        repo.ownedBy('user:me'),
        'user:me',
      );
      expect(expired, hasLength(1));
      expect(expired.first.type, equals(ReportNoticeType.expired));
    });

    test('laporan orang lain tidak memicu pengingat', () {
      final notifier = ReportNotificationService(clock: () => now);
      repo.add(_newReport('1', owner: 'user:other'));
      now = now.add(const Duration(days: 85));
      expect(notifier.checkExpiry(repo.items, 'user:me'), isEmpty);
    });
  });
}
