import 'package:flutter/material.dart';

import 'package:find_it/data/app_data.dart';
import 'package:find_it/data/item_repository.dart';
import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/routes/app_routes.dart';
import 'package:find_it/services/app_session.dart';
import 'package:find_it/widgets/report/report_actions.dart';
import 'package:find_it/widgets/report/report_components.dart';
import 'package:find_it/widgets/report/report_theme.dart';

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
  static const _heroHeight = 320.0;

  late final ItemRepository _repository;
  late final ReportActions _actions;
  late Item _item;
  int _photoIndex = 0;

  bool get _isOwner => _item.isOwnedBy(AppSession.userId);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppData.repository;
    _actions = ReportActions(repository: _repository);
    // Ambil versi terbaru dari repository (bisa saja sudah diubah).
    _item = _repository.findById(widget.item.id) ?? widget.item;
  }

  // ------------------------------------------------------------- Aksi

  void _apply(ReportActionResult? result) {
    if (!mounted || result == null) return;
    switch (result) {
      case ReportUpdated(:final item):
        setState(() {
          _item = item;
          _photoIndex = 0;
        });
      case ReportDeleted():
        Navigator.pop<String>(context, _item.id);
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.pushNamed<Item>(
      context,
      AppRoutes.editReport,
      arguments: _item,
    );
    if (!mounted || updated == null) return;
    // Form sudah menyimpan ke repository dan memicu matching.
    setState(() {
      _item = updated;
      _photoIndex = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan berhasil diperbarui.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openMap() => Navigator.pushNamed<void>(
    context,
    AppRoutes.mapDiscovery,
    arguments: _item,
  );

  void _openChat() =>
      Navigator.pushNamed<void>(context, AppRoutes.chat, arguments: _item);

  // ------------------------------------------------------------ Build

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final isOwner = _isOwner;
    final canChat =
        !isOwner &&
        (item.status == ReportStatus.active ||
            item.status == ReportStatus.inVerification);

    return Scaffold(
      backgroundColor: ReportColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(item)),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: const BoxDecoration(
                  color: ReportColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildBody(item, isOwner),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: canChat
          ? ReportBottomBar(
              buttonKey: const Key('detail-chat'),
              label: 'Chat pelapor',
              onPressed: _openChat,
            )
          : null,
    );
  }

  Widget _buildHero(Item item) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: _heroHeight + topInset,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPhotos(item),
          Positioned(
            left: 16,
            top: topInset + 12,
            child: ReportIconButton(
              icon: Icons.arrow_back,
              tooltip: 'Kembali',
              filled: true,
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          if (item.hasCoordinates)
            Positioned(
              right: 16,
              top: topInset + 12,
              child: ReportIconButton(
                key: const Key('detail-open-map'),
                icon: Icons.map_outlined,
                tooltip: 'Lihat di peta kampus',
                filled: true,
                onPressed: _openMap,
              ),
            ),
          if (item.photos.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < item.photos.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _photoIndex ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _photoIndex
                            ? ReportColors.green
                            : Colors.white70,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotos(Item item) {
    if (item.photos.isNotEmpty) {
      return PageView.builder(
        key: const Key('detail-photos'),
        itemCount: item.photos.length,
        onPageChanged: (index) => setState(() => _photoIndex = index),
        itemBuilder: (_, index) =>
            Image.memory(item.photos[index], fit: BoxFit.cover),
      );
    }
    if (item.assetPath case final asset?) {
      return Image.asset(asset, fit: BoxFit.cover);
    }
    return Container(
      color: ReportColors.typeTint(item.isFound),
      alignment: Alignment.center,
      child: Icon(
        ReportArtwork.iconFor(item.category),
        size: 110,
        color: ReportColors.typeColor(item.isFound),
      ),
    );
  }

  List<Widget> _buildBody(Item item, bool isOwner) {
    final now = DateTime.now();
    final needsReminder = ReportRules.needsExpiryReminder(item, now);
    final isExpired = item.status == ReportStatus.expired;
    return [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ReportTag.type(item.isFound),
          if (item.status != ReportStatus.active)
            ReportTag(
              item.statusLabel,
              foreground: ReportColors.warn,
              background: ReportColors.warnTint,
            ),
          ReportTag(
            item.category,
            foreground: ReportColors.green,
            background: const Color(0xFFE1F3E5),
          ),
          if (item.category2 case final category2?)
            ReportTag(
              category2,
              foreground: ReportColors.green,
              background: const Color(0xFFE1F3E5),
            ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        item.nameItem,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: ReportColors.ink,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        item.description,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: ReportColors.body,
        ),
      ),
      if (item.isFound && item.hasUnverifiedPhoto) ...[
        const SizedBox(height: 12),
        const ReportBanner(
          key: Key('detail-unverified-photo'),
          icon: Icons.photo_outlined,
          text:
              'Sebagian foto tidak diambil langsung dengan kamera saat '
              'barang ditemukan.',
        ),
      ],
      const SizedBox(height: 18),
      _buildInfoGrid(item),
      if (item.closedReason case final reason?) ...[
        const SizedBox(height: 14),
        ReportBanner(
          tone: ReportBannerTone.success,
          icon: Icons.task_alt,
          text: 'Ditutup oleh pelapor: $reason',
        ),
      ],
      const SizedBox(height: 14),
      _buildReporterCard(item),
      if (!isOwner && item.isFound && item.secretDetail != null) ...[
        const SizedBox(height: 14),
        const ReportBanner(
          tone: ReportBannerTone.info,
          icon: Icons.lock_outline,
          text:
              'Penemu menyimpan ciri rahasia barang ini. Saat mengajukan '
              'klaim lewat menu Matching, Anda akan diminta menyebutkannya.',
        ),
      ],
      if (isOwner) ...[
        if (item.secretDetail != null) ...[
          const SizedBox(height: 14),
          _buildSecretCard(item),
        ],
        if (needsReminder || isExpired) ...[
          const SizedBox(height: 14),
          ReportBanner(
            key: const Key('detail-expiry-banner'),
            icon: Icons.timer_outlined,
            text: isExpired
                ? 'Laporan ini sudah kedaluwarsa dan tidak tampil ke '
                      'pengguna lain. Perpanjang agar aktif kembali.'
                : 'Laporan akan kedaluwarsa dalam '
                      '${ReportRules.daysUntilExpiry(item, now)} hari.',
          ),
        ],
        const SizedBox(height: 20),
        ..._buildOwnerActions(item, needsReminder || isExpired),
      ],
      const SizedBox(height: 24),
    ];
  }

  Widget _buildInfoGrid(Item item) {
    final colorBrand = [item.color, item.brand].whereType<String>().join(' · ');
    final tiles = <Widget>[
      ReportInfoTile(
        label: 'Lokasi',
        value: item.isLocationApproximate
            ? '${item.location} (perkiraan)'
            : item.location,
      ),
      ReportInfoTile(
        label: item.isFound ? 'Ditemukan' : 'Waktu hilang',
        value: item.eventDateLabel,
      ),
      if (colorBrand.isNotEmpty)
        ReportInfoTile(label: 'Warna · Merek', value: colorBrand),
      if (item.keeping case final keeping?)
        ReportInfoTile(
          label: 'Barang sekarang',
          value: item.keepingNote ?? keeping.label,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }

  Widget _buildReporterCard(Item item) {
    final lines = <String>[
      if (item.createdAt case final created?)
        'Dilaporkan ${Item.formatDateTime(created)}',
      // Riwayat edit publik (anti "umpan lalu ganti"): hanya nama field.
      if (item.editHistory.isNotEmpty)
        'Diubah ${item.editHistory.length}× · terakhir '
            '${Item.formatDateTime(item.editHistory.last.at)} '
            '(${item.editHistory.last.fields.join(', ')})',
      if (_isOwner && item.expiresAt != null)
        item.status == ReportStatus.expired
            ? 'Kedaluwarsa sejak ${_formatDate(item.expiresAt!)}'
            : 'Berlaku hingga ${_formatDate(item.expiresAt!)}',
    ];
    return Container(
      key: const Key('detail-meta'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE1F3E5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_outline, color: ReportColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOwner ? 'Laporan Anda' : (item.reporter ?? 'Pelapor'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ReportColors.ink,
                  ),
                ),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ReportColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecretCard(Item item) {
    return Container(
      key: const Key('secret-detail-card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ReportColors.greenDeep,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: ReportColors.limeText),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Detail pembeda (hanya Anda yang melihat)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ReportColors.onDeepMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.secretDetail!,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOwnerActions(Item item, bool showExtend) {
    final userId = AppSession.userId;
    final verifying = item.status == ReportStatus.inVerification;
    final buttons = <Widget>[
      if (ReportRules.canExtend(item, userId) && showExtend)
        _ActionButton.filled(
          key: const Key('extend-report'),
          icon: Icons.update,
          label: 'Perpanjang ${ReportRules.expiryDays} hari',
          onPressed: () => _apply(_actions.extend(context, item)),
        ),
      if (ReportRules.canEdit(item, userId))
        _ActionButton.outlined(
          key: const Key('edit-report'),
          icon: Icons.edit_outlined,
          label: verifying ? 'Ubah laporan (sebagian)' : 'Ubah laporan',
          onPressed: _edit,
        ),
      if (ReportRules.canClose(item, userId))
        _ActionButton.outlined(
          key: const Key('close-report'),
          icon: Icons.task_alt,
          label: item.isFound ? 'Tutup laporan' : 'Barang sudah ketemu',
          onPressed: () async => _apply(await _actions.close(context, item)),
        ),
      _ActionButton.outlined(
        key: const Key('delete-report'),
        icon: Icons.delete_outline,
        label: 'Hapus laporan',
        danger: true,
        onPressed: ReportRules.canDelete(item, userId)
            ? () async => _apply(await _actions.delete(context, item))
            : null,
      ),
    ];
    return [
      const Text(
        'Kelola laporan',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: ReportColors.ink,
        ),
      ),
      const SizedBox(height: 10),
      for (final button in buttons) ...[button, const SizedBox(height: 10)],
      if (verifying)
        const Text(
          'Laporan tidak dapat dihapus atau ditutup selama klaim sedang '
          'diverifikasi. Selesaikan lewat menu Matching & Klaim.',
          style: TextStyle(fontSize: 12, color: ReportColors.muted),
        ),
    ];
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Tombol aksi pemilik dengan tinggi seragam.
class _ActionButton extends StatelessWidget {
  const _ActionButton._({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.filled,
    this.danger = false,
  });

  const _ActionButton.filled({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) : this._(
         key: key,
         icon: icon,
         label: label,
         onPressed: onPressed,
         filled: true,
       );

  const _ActionButton.outlined({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool danger = false,
  }) : this._(
         key: key,
         icon: icon,
         label: label,
         onPressed: onPressed,
         filled: false,
         danger: danger,
       );

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: ReportColors.green,
          minimumSize: const Size.fromHeight(50),
          shape: shape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }
    final color = danger ? ReportColors.lost : ReportColors.ink;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(
          color: danger
              ? ReportColors.lost.withValues(alpha: 0.5)
              : ReportColors.outline,
          width: 1.5,
        ),
        shape: shape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
