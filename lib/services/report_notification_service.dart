import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';

/// Jenis notifikasi Modul 1 (FR-R06, revisi).
///
/// Notifikasi "laporan berhasil dipublikasikan/diubah/dihapus" diganti
/// snackbar di layar, karena pengguna sedang melihat layar tersebut.
/// Notifikasi lokal dipakai untuk hal yang terjadi saat pengguna TIDAK
/// melihat layarnya: masa berlaku hampir habis, laporan kedaluwarsa, dan
/// pengiriman yang gagal (tersimpan sebagai draf).
enum ReportNoticeType { expiringSoon, expired, submitFailed }

class ReportNotice {
  final String id;
  final String? itemId;
  final ReportNoticeType type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool read;

  ReportNotice({
    required this.id,
    required this.itemId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });
}

/// Jembatan ke notifikasi sistem Android. Implementasi bawaan hanya
/// mencatat; ganti dengan implementasi berbasis plugin
/// `flutter_local_notifications` (lihat CATATAN_MODUL_1.md) tanpa mengubah
/// kode lain.
abstract class LocalNotificationGateway {
  Future<void> show(ReportNotice notice);
}

class InAppOnlyNotificationGateway implements LocalNotificationGateway {
  const InAppOnlyNotificationGateway();
  @override
  Future<void> show(ReportNotice notice) async {}
}

class ReportNotificationService {
  ReportNotificationService({
    this.gateway = const InAppOnlyNotificationGateway(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  LocalNotificationGateway gateway;
  final DateTime Function() _clock;
  final List<ReportNotice> notices = [];

  /// Kunci dedup agar pengingat yang sama tidak dikirim berulang.
  final Set<String> _sentKeys = {};

  List<ReportNotice> get unread =>
      notices.where((notice) => !notice.read).toList();

  void markAllRead() {
    for (final notice in notices) {
      notice.read = true;
    }
  }

  /// Memeriksa laporan milik [userId] dan memunculkan pengingat yang baru.
  /// Mengembalikan notifikasi yang baru dibuat pada pemanggilan ini.
  List<ReportNotice> checkExpiry(Iterable<Item> items, String? userId) {
    final now = _clock();
    final created = <ReportNotice>[];
    for (final item in items) {
      if (!item.isOwnedBy(userId)) continue;
      final expiresAt = item.expiresAt;
      if (expiresAt == null) continue;
      // Kunci memuat expiresAt agar perpanjangan memicu pengingat baru.
      final stamp = expiresAt.millisecondsSinceEpoch;
      if (item.status == ReportStatus.expired) {
        final key = 'expired:${item.id}:$stamp';
        if (_sentKeys.add(key)) {
          created.add(
            _push(
              key,
              item.id,
              ReportNoticeType.expired,
              'Laporan kedaluwarsa',
              '"${item.nameItem}" tidak lagi tampil ke pengguna lain. '
                  'Buka Laporan Saya untuk memperpanjang.',
              now,
            ),
          );
        }
      } else if (ReportRules.needsExpiryReminder(item, now)) {
        final key = 'expiring:${item.id}:$stamp';
        if (_sentKeys.add(key)) {
          final days = ReportRules.daysUntilExpiry(item, now);
          created.add(
            _push(
              key,
              item.id,
              ReportNoticeType.expiringSoon,
              'Laporan segera kedaluwarsa',
              '"${item.nameItem}" berakhir dalam $days hari. '
                  'Masih relevan? Perpanjang atau tutup laporannya.',
              now,
            ),
          );
        }
      }
    }
    return created;
  }

  ReportNotice notifySubmitFailed(String itemName) {
    final now = _clock();
    return _push(
      'failed:${now.microsecondsSinceEpoch}',
      null,
      ReportNoticeType.submitFailed,
      'Laporan belum terkirim',
      '"$itemName" disimpan sebagai draf. Buka form laporan untuk mengirim '
          'ulang.',
      now,
    );
  }

  ReportNotice _push(
    String id,
    String? itemId,
    ReportNoticeType type,
    String title,
    String body,
    DateTime now,
  ) {
    final notice = ReportNotice(
      id: id,
      itemId: itemId,
      type: type,
      title: title,
      body: body,
      createdAt: now,
    );
    notices.insert(0, notice);
    gateway.show(notice);
    return notice;
  }
}
