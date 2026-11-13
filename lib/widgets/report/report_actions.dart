import 'package:flutter/material.dart';

import 'package:find_it/data/app_data.dart';
import 'package:find_it/data/item_repository.dart';
import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/services/app_session.dart';
import 'package:find_it/widgets/report/report_theme.dart';

/// Hasil aksi pemilik atas laporan.
sealed class ReportActionResult {
  const ReportActionResult();
}

/// Laporan berubah (diperpanjang/ditutup).
class ReportUpdated extends ReportActionResult {
  final Item item;
  const ReportUpdated(this.item);
}

/// Laporan dihapus (soft delete).
class ReportDeleted extends ReportActionResult {
  const ReportDeleted();
}

/// Aksi pemilik (perpanjang, tutup, hapus) beserta dialog konfirmasinya.
/// Dipakai oleh layar Detail dan Laporan Saya agar perilakunya sama.
/// Setiap aksi yang berhasil memicu ulang matching Modul 3.
class ReportActions {
  ReportActions({ItemRepository? repository})
    : _repository = repository ?? AppData.repository;

  final ItemRepository _repository;

  String? get _userId => AppSession.userId;

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  ReportActionResult? _run(
    BuildContext context,
    ReportActionResult Function() action,
    String successMessage,
  ) {
    try {
      final result = action();
      AppData.matchingService.refreshMatches();
      _snack(context, successMessage);
      return result;
    } on StateError catch (error) {
      _snack(context, error.message);
      return null;
    }
  }

  /// FR-R10: perpanjang 90 hari.
  ReportActionResult? extend(BuildContext context, Item item) {
    return _run(
      context,
      () => ReportUpdated(_repository.extend(item.id, userId: _userId)),
      'Masa berlaku diperpanjang ${ReportRules.expiryDays} hari.',
    );
  }

  /// Tutup laporan dengan alasan (barang ketemu sendiri, dll.).
  Future<ReportActionResult?> close(BuildContext context, Item item) async {
    final reasons = item.isFound
        ? const [
            'Barang sudah dikembalikan langsung ke pemiliknya',
            'Barang diserahkan ke pihak kampus (satpam/TU)',
            'Lainnya',
          ]
        : const [
            'Barang sudah saya temukan sendiri',
            'Tidak lagi mencari barang ini',
            'Lainnya',
          ];
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: ReportColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tutup laporan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Laporan ditandai selesai dan tidak tampil di pencarian '
                'maupun pencocokan. Pilih alasannya:',
                style: TextStyle(fontSize: 13, color: ReportColors.muted),
              ),
              const SizedBox(height: 12),
              for (final option in reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, option),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: ReportColors.ink,
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: ReportColors.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(option),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (reason == null || !context.mounted) return null;
    return _run(
      context,
      () => ReportUpdated(
        _repository.close(item.id, userId: _userId, reason: reason),
      ),
      'Laporan ditutup.',
    );
  }

  /// FR-R05: hapus (soft delete) setelah konfirmasi.
  Future<ReportActionResult?> delete(BuildContext context, Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus laporan?'),
        content: const Text(
          'Laporan disembunyikan dari semua pengguna dan tidak ikut '
          'pencocokan lagi. Jika barang sudah ketemu, sebaiknya pilih '
          '"Tutup laporan" agar riwayatnya tetap ada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ReportColors.lost),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return null;
    return _run(context, () {
      _repository.softDelete(item.id, userId: _userId);
      return const ReportDeleted();
    }, 'Laporan dihapus.');
  }
}
