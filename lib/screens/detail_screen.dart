import 'package:flutter/material.dart';

import 'package:find_it/data/app_data.dart';
import 'package:find_it/data/item_repository.dart';
import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/routes/app_routes.dart';
import 'package:find_it/services/app_session.dart';
import 'package:find_it/widgets/item_visuals.dart';

/// Detail laporan (FR-R03) beserta aksi pemilik: ubah (FR-R04), hapus
/// (FR-R05), perpanjang & tutup laporan (FR-R10).
///
/// Mengembalikan id laporan lewat `pop` bila laporan dihapus. Pemanggil
/// sebaiknya tetap memuat ulang daftar karena laporan bisa berubah.
class DetailScreen extends StatefulWidget {
  final Item item;
  final ItemRepository? repository;
  const DetailScreen({super.key, required this.item, this.repository});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  static const _green = Color(0xFF0A5934);
  static const _muted = Color(0xFF595858);

  late final ItemRepository _repository;
  late Item _item;
  int _photoIndex = 0;

  String? get _userId => AppSession.userId;
  bool get _isOwner => _item.isOwnedBy(_userId);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppData.repository;
    // Ambil versi terbaru dari repository (bisa saja sudah diubah).
    _item = _repository.findById(widget.item.id) ?? widget.item;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _afterChange(Item updated, String message) {
    AppData.matchingService.refreshMatches();
    setState(() {
      _item = updated;
      _photoIndex = 0;
    });
    _showMessage(message);
  }

  Future<void> _editReport() async {
    final updated = await Navigator.pushNamed<Item>(
      context,
      AppRoutes.editReport,
      arguments: _item,
    );
    if (!mounted || updated == null) return;
    // Form sudah menyimpan ke repository.
    _afterChange(updated, 'Laporan berhasil diperbarui.');
  }

  Future<void> _deleteReport() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus laporan?'),
        content: const Text(
          'Laporan akan disembunyikan dari semua pengguna dan tidak ikut '
          'pencocokan lagi. Jika barang sudah ketemu, sebaiknya pilih '
          '"Tutup laporan" agar riwayatnya tetap ada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (!mounted || shouldDelete != true) return;
    try {
      _repository.softDelete(_item.id, userId: _userId);
      AppData.matchingService.refreshMatches();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan dihapus.')),
      );
      Navigator.pop<String>(context, _item.id);
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _closeReport() async {
    final reasons = _item.isFound
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
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Tutup laporan'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Laporan ditandai selesai dan tidak tampil di pencarian maupun '
              'pencocokan. Pilih alasannya:',
              style: TextStyle(fontSize: 13),
            ),
          ),
          for (final option in reasons)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, option),
              child: Text(option),
            ),
        ],
      ),
    );
    if (!mounted || reason == null) return;
    try {
      final closed = _repository.close(
        _item.id,
        userId: _userId,
        reason: reason,
      );
      _afterChange(closed, 'Laporan ditutup.');
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  void _extendReport() {
    try {
      final extended = _repository.extend(_item.id, userId: _userId);
      _afterChange(
        extended,
        'Masa berlaku diperpanjang ${ReportRules.expiryDays} hari.',
      );
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final now = DateTime.now();
    final isOwner = _isOwner;
    final needsReminder = ReportRules.needsExpiryReminder(item, now);
    final isExpired = item.status == ReportStatus.expired;
    final typeColor = item.isFound
        ? const Color(0xFF045436)
        : const Color(0xFFEF4444);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Detail Laporan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Center(child: _buildPhotos(item)),
          if (item.isFound && item.hasUnverifiedPhoto) ...[
            const SizedBox(height: 10),
            _notice(
              key: const Key('detail-unverified-photo'),
              icon: Icons.info_outline,
              text:
                  'Sebagian foto tidak diambil langsung dengan kamera saat '
                  'barang ditemukan.',
            ),
          ],
          const SizedBox(height: 22),
          Text(
            item.nameItem,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(item.subtitle, style: const TextStyle(color: _muted)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: item.isFound ? 'Ditemukan' : 'Kehilangan',
                color: typeColor,
              ),
              if (item.status != ReportStatus.active)
                StatusPill(
                  label: item.statusLabel,
                  color: legacyReportStatusColor(item.status),
                ),
              _pill(item.category),
              if (item.category2 case final category2?) _pill(category2),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ItemDetailTag(
                icon: Icons.location_on_outlined,
                label: item.isLocationApproximate
                    ? '${item.location} (perkiraan)'
                    : item.location,
              ),
              _ItemDetailTag(
                icon: Icons.schedule,
                label: item.eventDateLabel,
              ),
              if (item.color case final color?)
                _ItemDetailTag(icon: Icons.palette_outlined, label: color),
              if (item.brand case final brand?)
                _ItemDetailTag(
                  icon: Icons.branding_watermark_outlined,
                  label: brand,
                ),
              if (item.keeping case final keeping?)
                _ItemDetailTag(
                  icon: Icons.inventory_2_outlined,
                  label: item.keepingNote == null
                      ? keeping.label
                      : '${keeping.label}: ${item.keepingNote}',
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            item.description,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 14),
          _buildMetaInfo(item, isOwner, isExpired),
          if (item.closedReason case final reason?) ...[
            const SizedBox(height: 12),
            _notice(
              icon: Icons.task_alt,
              text: 'Ditutup oleh pelapor: $reason',
            ),
          ],
          // FR-R08: detail pembeda hanya terlihat oleh pemilik laporan.
          if (isOwner && item.secretDetail != null) ...[
            const SizedBox(height: 16),
            _buildSecretCard(item),
          ],
          if (isOwner && (needsReminder || isExpired)) ...[
            const SizedBox(height: 16),
            _notice(
              key: const Key('detail-expiry-banner'),
              icon: Icons.timer_outlined,
              text: isExpired
                  ? 'Laporan ini sudah kedaluwarsa dan tidak tampil ke '
                        'pengguna lain. Perpanjang agar aktif kembali.'
                  : 'Laporan akan kedaluwarsa dalam '
                        '${ReportRules.daysUntilExpiry(item, now)} hari.',
            ),
          ],
          const Divider(height: 32),
          if (item.hasCoordinates)
            OutlinedButton.icon(
              key: const Key('detail-open-map'),
              onPressed: () => Navigator.pushNamed<void>(
                context,
                AppRoutes.mapDiscovery,
                arguments: item,
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Lihat Lokasi di Peta Kampus'),
            ),
          if (!isOwner &&
              (item.status == ReportStatus.active ||
                  item.status == ReportStatus.inVerification)) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('detail-chat'),
              onPressed: () => Navigator.pushNamed<void>(
                context,
                AppRoutes.chat,
                arguments: item,
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat Pelapor'),
            ),
          ],
          if (isOwner) ...[
            const SizedBox(height: 10),
            ..._ownerActions(item, needsReminder || isExpired),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaInfo(Item item, bool isOwner, bool isExpired) {
    final lines = <String>[
      if (item.reporter case final reporter?) 'Pelapor: $reporter',
      if (item.createdAt case final created?)
        'Dilaporkan: ${Item.formatDateTime(created)}',
      // Riwayat edit publik (anti "umpan lalu ganti"): hanya nama field.
      if (item.editHistory.isNotEmpty)
        'Diubah ${item.editHistory.length}× · terakhir '
            '${Item.formatDateTime(item.editHistory.last.at)} '
            '(${item.editHistory.last.fields.join(', ')})',
      if (isOwner && item.expiresAt != null)
        isExpired
            ? 'Kedaluwarsa sejak ${_formatDate(item.expiresAt!)}'
            : 'Berlaku hingga ${_formatDate(item.expiresAt!)}',
    ];
    return Column(
      key: const Key('detail-meta'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ),
      ],
    );
  }

  Widget _buildSecretCard(Item item) {
    return Container(
      key: const Key('secret-detail-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Detail pembeda (hanya Anda yang melihat)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.secretDetail!, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  List<Widget> _ownerActions(Item item, bool showExtend) {
    final userId = _userId;
    final canEdit = ReportRules.canEdit(item, userId);
    final canDelete = ReportRules.canDelete(item, userId);
    final canClose = ReportRules.canClose(item, userId);
    final verifying = item.status == ReportStatus.inVerification;
    return [
      if (ReportRules.canExtend(item, userId) && showExtend) ...[
        FilledButton.icon(
          key: const Key('extend-report'),
          onPressed: _extendReport,
          icon: const Icon(Icons.update),
          label: const Text('Perpanjang ${ReportRules.expiryDays} hari'),
        ),
        const SizedBox(height: 10),
      ],
      if (canEdit) ...[
        OutlinedButton.icon(
          key: const Key('edit-report'),
          onPressed: _editReport,
          icon: const Icon(Icons.edit_outlined),
          label: Text(verifying ? 'Ubah Laporan (sebagian)' : 'Ubah Laporan'),
        ),
        const SizedBox(height: 10),
      ],
      if (canClose) ...[
        OutlinedButton.icon(
          key: const Key('close-report'),
          onPressed: _closeReport,
          icon: const Icon(Icons.task_alt),
          label: Text(
            item.isFound ? 'Tutup laporan' : 'Barang sudah ketemu / tutup',
          ),
        ),
        const SizedBox(height: 10),
      ],
      OutlinedButton.icon(
        key: const Key('delete-report'),
        onPressed: canDelete ? _deleteReport : null,
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Hapus Laporan'),
      ),
      if (verifying) ...[
        const SizedBox(height: 8),
        const Text(
          'Laporan tidak dapat dihapus atau ditutup selama klaim sedang '
          'diverifikasi. Selesaikan lewat menu Matching & Klaim.',
          style: TextStyle(fontSize: 12, color: _muted),
        ),
      ],
    ];
  }

  Widget _buildPhotos(Item item) {
    if (item.photos.length <= 1) {
      return LegacyItemArtwork(item: item, size: 277);
    }
    return Column(
      children: [
        SizedBox(
          width: 277,
          height: 277,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: PageView.builder(
              key: const Key('detail-photos'),
              itemCount: item.photos.length,
              onPageChanged: (index) => setState(() => _photoIndex = index),
              itemBuilder: (_, index) =>
                  Image.memory(item.photos[index], fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < item.photos.length; i++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _photoIndex ? _green : const Color(0xFFD5E2E0),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: _green, fontSize: 11)),
    );
  }

  Widget _notice({Key? key, required IconData icon, required String text}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8A4B08)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF5C3A06)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDetailTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ItemDetailTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
