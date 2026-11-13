import 'package:flutter/material.dart';

import 'package:find_it/core/routes/app_routes.dart';
import 'package:find_it/core/widgets/item_visuals.dart';
import 'package:find_it/core/widgets/status_pill.dart';
import 'package:find_it/features/report/data/item_repository.dart';
import 'package:find_it/features/report/domain/report_rules.dart';
import 'package:find_it/features/report/models/report.dart';

class DetailScreen extends StatefulWidget {
  final Item item;
  final ItemRepository? repository;
  const DetailScreen({super.key, required this.item, this.repository});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final ItemRepository _repository;
  late Item _item;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ItemRepository();
    _item = widget.item;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editReport() async {
    final updated = await Navigator.pushNamed<Item>(
      context,
      AppRoutes.editReport,
      arguments: _item,
    );
    if (!mounted || updated == null) return;
    try {
      final stored = _repository.update(updated);
      setState(() {
        _item = stored;
        _photoIndex = 0;
      });
      // Pengganti sementara notifikasi lokal "laporan diperbarui" (FR-R06).
      _showMessage('Laporan berhasil diperbarui.');
    } catch (error) {
      _showMessage('Laporan gagal diperbarui: $error');
    }
  }

  Future<void> _deleteReport() async {
    try {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Hapus laporan?'),
          content: const Text('Laporan ini akan dihapus dari daftar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );
      if (!mounted || shouldDelete != true) return;
      _repository.softDelete(_item.id);
      Navigator.pop<String>(context, _item.id);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Laporan gagal dihapus: $error');
    }
  }

  void _extendReport() {
    try {
      final extended = _repository.extend(_item.id);
      setState(() => _item = extended);
      _showMessage('Masa berlaku diperpanjang ${ReportRules.expiryDays} hari.');
    } catch (error) {
      _showMessage('Gagal memperpanjang: $error');
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final now = DateTime.now();
    final typeColor = item.isFound
        ? const Color(0xFF0A5934)
        : const Color(0xFFEF4444);
    final needsReminder = ReportRules.needsExpiryReminder(item, now);
    final isExpired = item.status == ReportStatus.expired;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Detail Item',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Center(child: _buildPhotos(item)),
          const SizedBox(height: 28),
          Text(
            item.nameItem,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text(
            item.subtitle,
            style: const TextStyle(color: Color(0xFF595858), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _pill(item.category, const Color(0xFFF1F5F9)),
              if (item.category2 != null)
                _pill(item.category2!, const Color(0xFFF1F5F9)),
              _pill(item.location, const Color(0xFFECFDF5)),
              StatusPill(
                label: item.isFound ? 'Ditemukan' : 'Kehilangan',
                color: typeColor,
              ),
              if (item.status != ReportStatus.active)
                StatusPill(
                  label: item.status.label,
                  color: reportStatusColor(item.status),
                ),
            ],
          ),
          if (item.color != null || item.brand != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (item.color case final color?)
                  _ItemDetailTag(icon: Icons.palette_outlined, label: color),
                if (item.brand case final brand?)
                  _ItemDetailTag(
                    icon: Icons.branding_watermark_outlined,
                    label: brand,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text(
            item.description,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
          if (item.keeping case final keeping?) ...[
            const SizedBox(height: 12),
            _ItemDetailTag(
              icon: Icons.inventory_2_outlined,
              label: 'Barang: ${keeping.label}',
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Waktu kejadian: ${item.eventDateLabel}',
            style: const TextStyle(
              color: Color(0x99595858),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (item.expiresAt case final expiresAt?) ...[
            const SizedBox(height: 4),
            Text(
              isExpired
                  ? 'Kedaluwarsa sejak ${_formatDate(expiresAt)}'
                  : 'Berlaku hingga ${_formatDate(expiresAt)}',
              style: const TextStyle(color: Color(0xFF595858), fontSize: 12),
            ),
          ],
          if (item.reporter case final reporter?) ...[
            const SizedBox(height: 8),
            Text(
              'Pelapor: $reporter',
              style: const TextStyle(fontSize: 12, color: Color(0xFF595858)),
            ),
          ],
          // FR-R08: detail pembeda hanya terlihat oleh pemilik laporan.
          if (item.isOwner && item.secretDetail != null) ...[
            const SizedBox(height: 16),
            Container(
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
                      Text(
                        'Detail pembeda (hanya Anda yang melihat)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.secretDetail!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          if (item.isOwner && (needsReminder || isExpired)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isExpired
                    ? 'Laporan ini sudah kedaluwarsa dan tidak tampil ke '
                          'pengguna lain. Perpanjang agar aktif kembali.'
                    : 'Laporan akan kedaluwarsa dalam '
                          '${ReportRules.daysUntilExpiry(item, now)} hari.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5C3A06)),
              ),
            ),
          ],
          const Divider(height: 32),
          if (!item.isOwner)
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed<void>(
                context,
                AppRoutes.chat,
                arguments: item,
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat Pelapor'),
            ),
          if (item.isOwner) ..._ownerActions(item, needsReminder || isExpired),
        ],
      ),
    );
  }

  List<Widget> _ownerActions(Item item, bool showExtend) {
    final canEdit = ReportRules.canEdit(item);
    final canDelete = ReportRules.canDelete(item);
    final verifying = item.status == ReportStatus.inVerification;
    return [
      if (ReportRules.canExtend(item) && showExtend) ...[
        FilledButton.icon(
          key: const Key('extend-report'),
          onPressed: _extendReport,
          icon: const Icon(Icons.update),
          label: Text('Perpanjang ${ReportRules.expiryDays} hari'),
        ),
        const SizedBox(height: 12),
      ],
      OutlinedButton.icon(
        key: const Key('edit-report'),
        onPressed: canEdit ? _editReport : null,
        icon: const Icon(Icons.edit_outlined),
        label: Text(verifying ? 'Ubah Laporan (sebagian)' : 'Ubah Laporan'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const Key('delete-report'),
        onPressed: canDelete ? _deleteReport : null,
        icon: const Icon(Icons.delete_outline),
        label: const Text('Hapus Laporan'),
      ),
      if (verifying) ...[
        const SizedBox(height: 8),
        const Text(
          'Laporan tidak dapat dihapus selama klaim sedang diverifikasi.',
          style: TextStyle(fontSize: 12, color: Color(0xFF595858)),
        ),
      ],
    ];
  }

  Widget _buildPhotos(Item item) {
    if (item.photos.length <= 1) {
      return ItemArtwork(item: item, size: 277);
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
                  color: i == _photoIndex
                      ? const Color(0xFF0A5934)
                      : const Color(0xFFD5E2E0),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pill(String text, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF0A5934), fontSize: 12),
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
