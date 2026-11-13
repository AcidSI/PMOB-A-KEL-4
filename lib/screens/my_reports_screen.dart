import 'package:flutter/material.dart';

import 'package:find_it/data/app_data.dart';
import 'package:find_it/data/item_repository.dart';
import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/routes/app_routes.dart';
import 'package:find_it/services/app_session.dart';
import 'package:find_it/services/report_notification_service.dart';
import 'package:find_it/widgets/item_visuals.dart';

/// "Laporan Saya": semua laporan milik pengguna, dikelompokkan per status,
/// beserta pengingat masa berlaku (FR-R03, FR-R06, FR-R10).
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
  static const _green = Color(0xFF0A5934);
  static const _muted = Color(0xFF63777B);

  late final ItemRepository _repository;
  List<Item> _items = const [];
  List<ReportNotice> _notices = const [];
  _Tab _tab = _Tab.active;

  String? get _userId => AppSession.userId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppData.repository;
    _reload();
  }

  void _reload() {
    final items = _repository.ownedBy(_userId);
    AppData.reportNotifications.checkExpiry(items, _userId);
    setState(() {
      _items = items;
      _notices = AppData.reportNotifications.unread;
    });
  }

  Future<void> _open(Item item) async {
    await Navigator.pushNamed<String>(
      context,
      AppRoutes.detail,
      arguments: item,
    );
    if (mounted) _reload();
  }

  Future<void> _create(bool isFound) async {
    final created = await Navigator.pushNamed<Item>(
      context,
      AppRoutes.addReport,
      arguments: isFound,
    );
    if (!mounted) return;
    _reload();
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dipublikasikan.')),
      );
    }
  }

  void _dismissNotices() {
    AppData.reportNotifications.markAllRead();
    setState(() => _notices = const []);
  }

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final tab in _Tab.values) tab: _items.where(tab.accepts).length,
    };
    final visible = _items.where(_tab.accepts).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F7),
      appBar: AppBar(title: const Text('Laporan Saya')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('my-reports-create'),
        onPressed: () => _showCreateSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Buat laporan'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            if (_notices.isNotEmpty) ...[
              _buildNotices(),
              const SizedBox(height: 12),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in _Tab.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: Key('my-reports-tab-${tab.name}'),
                        label: Text('${tab.label} (${counts[tab]})'),
                        selected: _tab == tab,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _tab = tab),
                        selectedColor: _green,
                        labelStyle: TextStyle(
                          color: _tab == tab ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, size: 48, color: _muted),
                    const SizedBox(height: 8),
                    Text(
                      _items.isEmpty
                          ? 'Anda belum membuat laporan.'
                          : 'Tidak ada laporan berstatus ${_tab.label}.',
                      style: const TextStyle(color: _muted),
                    ),
                  ],
                ),
              )
            else
              ...visible.map(_buildCard),
          ],
        ),
      ),
    );
  }

  Widget _buildNotices() {
    return Container(
      key: const Key('my-reports-notices'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: Color(0xFF8A4B08),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Pemberitahuan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _dismissNotices,
                child: const Text('Tandai dibaca'),
              ),
            ],
          ),
          for (final notice in _notices.take(5))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '• ${notice.title}: ${notice.body}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5C3A06)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Item item) {
    final now = DateTime.now();
    final days = ReportRules.daysUntilExpiry(item, now);
    final reminder = ReportRules.needsExpiryReminder(item, now);
    final subtitle = switch (item.status) {
      ReportStatus.active when days != null => 'Berlaku $days hari lagi',
      ReportStatus.active => 'Aktif',
      ReportStatus.inVerification => 'Ada klaim yang sedang diverifikasi',
      ReportStatus.expired => 'Tidak tampil ke publik · perpanjang di detail',
      ReportStatus.resolved => item.closedReason ?? 'Barang telah dikembalikan',
      ReportStatus.removed => 'Dihapus',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: Key('my-report-${item.id}'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(item),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                LegacyItemArtwork(item: item, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusPill(
                            label: item.isFound ? 'Ditemukan' : 'Kehilangan',
                            color: item.isFound
                                ? const Color(0xFF045436)
                                : const Color(0xFFEF4444),
                          ),
                          if (reminder) ...[
                            const SizedBox(width: 6),
                            const StatusPill(
                              label: 'Segera berakhir',
                              color: Color(0xFFB45309),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.nameItem,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: reminder ? const Color(0xFFB45309) : _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateSheet() async {
    final isFound = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Barang Hilang'),
              onTap: () => Navigator.pop(sheetContext, false),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Barang Ditemukan'),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
          ],
        ),
      ),
    );
    if (!mounted || isFound == null) return;
    await _create(isFound);
  }
}
