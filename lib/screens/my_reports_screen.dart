import 'package:flutter/material.dart';

import 'package:find_it/data/app_data.dart';
import 'package:find_it/data/item_repository.dart';
import 'package:find_it/data/report_draft_store.dart';
import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/routes/app_routes.dart';
import 'package:find_it/services/app_session.dart';
import 'package:find_it/services/report_notification_service.dart';
import 'package:find_it/widgets/report/report_actions.dart';
import 'package:find_it/widgets/report/report_components.dart';
import 'package:find_it/widgets/report/report_theme.dart';

/// "Laporan Saya": semua laporan milik pengguna, dikelompokkan per status,
/// beserta pengingat masa berlaku dan draf (FR-R03, FR-R06, FR-R10).
class MyReportsScreen extends StatefulWidget {
  final ItemRepository? repository;
  const MyReportsScreen({super.key, this.repository});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

enum _Tab {
  active('Aktif'),
  verifying('Diverifikasi'),
  expired('Kedaluwarsa'),
  done('Selesai');

  const _Tab(this.label);
  final String label;

  bool accepts(Item item) => switch (this) {
    _Tab.active => item.status == ReportStatus.active,
    _Tab.verifying => item.status == ReportStatus.inVerification,
    _Tab.expired => item.status == ReportStatus.expired,
    _Tab.done => item.status == ReportStatus.resolved,
  };
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late final ItemRepository _repository;
  late final ReportActions _actions;
  List<Item> _items = const [];
  List<ReportNotice> _notices = const [];
  List<ReportDraft> _drafts = const [];
  _Tab _tab = _Tab.active;

  String? get _userId => AppSession.userId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppData.repository;
    _actions = ReportActions(repository: _repository);
    _reload();
  }

  void _reload() {
    final items = _repository.ownedBy(_userId);
    AppData.reportNotifications.checkExpiry(items, _userId);
    setState(() {
      _items = items;
      _notices = AppData.reportNotifications.unread;
      _drafts = [
        for (final isFound in const [false, true])
          if (AppData.reportDrafts.read(isFound: isFound) case final draft?)
            draft,
      ];
    });
  }

  // ------------------------------------------------------------ Navigasi

  Future<void> _open(Item item) async {
    await Navigator.pushNamed<String>(
      context,
      AppRoutes.detail,
      arguments: item,
    );
    if (mounted) _reload();
  }

  Future<void> _edit(Item item) async {
    final updated = await Navigator.pushNamed<Item>(
      context,
      AppRoutes.editReport,
      arguments: item,
    );
    if (!mounted) return;
    _reload();
    if (updated != null) _snack('Laporan berhasil diperbarui.');
  }

  Future<void> _create(bool isFound) async {
    final created = await Navigator.pushNamed<Item>(
      context,
      AppRoutes.addReport,
      arguments: isFound,
    );
    if (!mounted) return;
    _reload();
    if (created != null) _snack('Laporan berhasil dipublikasikan.');
  }

  void _openMatching() => Navigator.pushNamed<void>(
    context,
    AppRoutes.matches,
    arguments: AppData.matchingService,
  );

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _afterAction(ReportActionResult? result) {
    if (result != null && mounted) _reload();
  }

  void _dismissNotices() {
    AppData.reportNotifications.markAllRead();
    setState(() => _notices = const []);
  }

  // --------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final tab in _Tab.values) tab: _items.where(tab.accepts).length,
    };
    final visible = _items.where(_tab.accepts).toList();
    return Scaffold(
      backgroundColor: ReportColors.background,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('my-reports-create'),
        onPressed: _showCreateSheet,
        backgroundColor: ReportColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Buat laporan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          const ReportHeader(title: 'Laporan saya'),
          Container(
            color: ReportColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final tab in _Tab.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ReportChoicePill(
                        key: Key('my-reports-tab-${tab.name}'),
                        label: '${tab.label} · ${counts[tab]}',
                        selected: _tab == tab,
                        onSelected: (_) => setState(() => _tab = tab),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: ReportColors.green,
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                children: [
                  if (_notices.isNotEmpty) ...[
                    _buildNotices(),
                    const SizedBox(height: 12),
                  ],
                  if (visible.isEmpty)
                    _buildEmpty()
                  else
                    for (final item in visible) ...[
                      _ReportCard(
                        item: item,
                        onOpen: () => _open(item),
                        actions: _cardActions(item),
                      ),
                      const SizedBox(height: 12),
                    ],
                  if (_tab == _Tab.active)
                    for (final draft in _drafts) ...[
                      _DraftCard(
                        draft: draft,
                        onContinue: () => _create(draft.isFound),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Aksi cepat sesuai status laporan.
  List<_CardAction> _cardActions(Item item) {
    final now = DateTime.now();
    switch (item.status) {
      case ReportStatus.active:
        if (ReportRules.needsExpiryReminder(item, now)) {
          return [
            _CardAction(
              'Perpanjang ${ReportRules.expiryDays} hari',
              () => _afterAction(_actions.extend(context, item)),
              primary: true,
            ),
            _CardAction(
              item.isFound ? 'Tutup' : 'Sudah ketemu',
              () async => _afterAction(await _actions.close(context, item)),
            ),
          ];
        }
        return [
          _CardAction('Lihat detail', () => _open(item), primary: true),
          _CardAction('Ubah', () => _edit(item)),
        ];
      case ReportStatus.inVerification:
        return [_CardAction('Buka klaim', _openMatching, primary: true)];
      case ReportStatus.expired:
        return [
          _CardAction(
            'Perpanjang ${ReportRules.expiryDays} hari',
            () => _afterAction(_actions.extend(context, item)),
            primary: true,
          ),
          _CardAction(
            'Hapus',
            () async => _afterAction(await _actions.delete(context, item)),
          ),
        ];
      case ReportStatus.resolved:
      case ReportStatus.removed:
        return const [];
    }
  }

  Widget _buildNotices() {
    return ReportBanner(
      key: const Key('my-reports-notices'),
      icon: Icons.notifications_active_outlined,
      text: [
        for (final notice in _notices.take(4))
          '• ${notice.title}: ${notice.body}',
      ].join('\n'),
      action: TextButton(
        onPressed: _dismissNotices,
        style: TextButton.styleFrom(
          foregroundColor: ReportColors.warn,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('Tandai sudah dibaca'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ReportColors.mint,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 34,
              color: ReportColors.green,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _items.isEmpty
                ? 'Anda belum membuat laporan.'
                : 'Tidak ada laporan berstatus ${_tab.label.toLowerCase()}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: ReportColors.muted),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateSheet() async {
    final isFound = await showReportTypePicker(context);
    if (!mounted || isFound == null) return;
    await _create(isFound);
  }
}

// ======================================================= Widget privat

class _CardAction {
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  const _CardAction(this.label, this.onPressed, {this.primary = false});
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.item,
    required this.onOpen,
    required this.actions,
  });

  final Item item;
  final VoidCallback onOpen;
  final List<_CardAction> actions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = ReportRules.daysUntilExpiry(item, now);
    final reminder = ReportRules.needsExpiryReminder(item, now);
    final showProgress =
        days != null &&
        (item.status == ReportStatus.active ||
            item.status == ReportStatus.expired);
    final subtitle = switch (item.status) {
      ReportStatus.active => '${item.location} · berlaku $days hari lagi',
      ReportStatus.inVerification => 'Ada klaim yang sedang diverifikasi',
      ReportStatus.expired => 'Tidak tampil ke publik',
      ReportStatus.resolved => item.closedReason ?? 'Barang telah dikembalikan',
      ReportStatus.removed => 'Dihapus',
    };

    return Material(
      color: ReportColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ReportRadius.card),
        side: BorderSide(
          color: reminder ? ReportColors.warnBorder : ReportColors.line,
          width: reminder ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        key: Key('my-report-${item.id}'),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReportRadius.card),
        ),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  item.imageData != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            item.imageData!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        )
                      : ReportArtwork(
                          isFound: item.isFound,
                          category: item.category,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            ReportTag.type(item.isFound, solid: false),
                            if (reminder)
                              ReportTag(
                                '$days hari lagi',
                                foreground: ReportColors.warn,
                                background: ReportColors.warnTint,
                              ),
                            if (item.isClosedByOwner)
                              const ReportTag(
                                'Ditutup',
                                foreground: ReportColors.neutral,
                                background: Color(0xFFEEF1F0),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.nameItem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ReportColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ReportColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showProgress) ...[
                const SizedBox(height: 12),
                ReportProgressBar(
                  value: days / ReportRules.expiryDays,
                  color: reminder || item.status == ReportStatus.expired
                      ? const Color(0xFFD98A0B)
                      : ReportColors.green,
                  semanticsLabel:
                      'Masa berlaku tersisa $days dari '
                      '${ReportRules.expiryDays} hari',
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: _actionButton(actions[i])),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(_CardAction action) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
    if (action.primary) {
      return FilledButton(
        onPressed: action.onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ReportColors.green,
          minimumSize: const Size.fromHeight(44),
          shape: shape,
          textStyle: textStyle,
        ),
        child: Text(action.label),
      );
    }
    return OutlinedButton(
      onPressed: action.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ReportColors.ink,
        minimumSize: const Size.fromHeight(44),
        side: const BorderSide(color: ReportColors.outline, width: 1.5),
        shape: shape,
        textStyle: textStyle,
      ),
      child: Text(action.label),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft, required this.onContinue});

  final ReportDraft draft;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final name = draft.name.trim().isEmpty ? 'Tanpa nama' : draft.name.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ReportColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF9DBFA8), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: ReportColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Draf: $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ReportColors.ink,
                  ),
                ),
                Text(
                  '${draft.isFound ? 'Ditemukan' : 'Hilang'} · belum '
                  'terkirim · ${Item.formatDateTime(draft.savedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ReportColors.muted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onContinue,
            style: TextButton.styleFrom(
              foregroundColor: ReportColors.green,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }
}
