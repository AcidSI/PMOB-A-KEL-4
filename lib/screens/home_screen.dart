import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../data/item_repository.dart';
import '../models/item.dart';
import '../routes/app_routes.dart';
import '../services/app_session.dart';
import '../services/matching_service.dart';
import '../widgets/item_visuals.dart';
import '../widgets/state_views.dart';

enum ViewStatus { loading, success, error }

class HomeScreen extends StatefulWidget {
  final ItemRepository? repository;
  const HomeScreen({super.key, this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ItemRepository _repository;
  late final MatchingService _matchingService;
  Timer? _matchingTimer;
  final _searchController = TextEditingController();
  final _reportsSectionKey = GlobalKey();
  ViewStatus _status = ViewStatus.loading;
  List<Item> _items = [];
  String _errorMessage = '';
  String _selectedFilter = 'Semua';

  final bool _simulateError = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppData.repository;
    _matchingService = identical(_repository, AppData.repository)
        ? AppData.matchingService
        : MatchingService(items: _repository.items);
    _matchingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _matchingService.refreshMatches();
    });
    _loadItems();
  }

  @override
  void dispose() {
    _matchingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _status = ViewStatus.loading);
    try {
      final items = await _repository.fetchItems(
        simulateError: _simulateError,
        viewerId: AppSession.userId,
      );
      if (!mounted) return;
      _matchingService.refreshMatches();
      setState(() {
        _items = [...items];
        _status = ViewStatus.success;
        _errorMessage = '';
      });
      _checkReportReminders();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _status = ViewStatus.error;
      });
    } finally {
      if (mounted && _status == ViewStatus.loading) {
        setState(() => _status = ViewStatus.success);
      }
    }
  }

  List<Item> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesFilter = switch (_selectedFilter) {
        'Kehilangan' => !item.isFound,
        'Ditemukan' => item.isFound,
        _ => true,
      };
      final matchesQuery =
          query.isEmpty ||
          item.nameItem.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  Future<void> _openAddReport() async {
    final isFound = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Buat laporan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                key: const Key('create-lost-report'),
                leading: const Icon(Icons.search),
                title: const Text('Barang Hilang'),
                subtitle: const Text('Laporkan barang milik Anda yang hilang'),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                key: const Key('create-found-report'),
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Barang Ditemukan'),
                subtitle: const Text('Laporkan barang yang Anda temukan'),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || isFound == null) return;
    await _createReport(isFound);
  }

  Future<void> _createReport(bool isFound) async {
    final item = await Navigator.pushNamed<Item>(
      context,
      AppRoutes.addReport,
      arguments: isFound,
    );
    if (!mounted || item == null) return;
    // Form Modul 1 sudah menyimpan laporan ke repository & memicu matching.
    setState(() {
      _items = _repository.visibleItemsFor(AppSession.userId);
      _selectedFilter = 'Semua';
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = _reportsSectionKey.currentContext;
      if (sectionContext != null) {
        Scrollable.ensureVisible(
          sectionContext,
          duration: const Duration(milliseconds: 250),
          alignment: 0.1,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laporan berhasil dipublikasikan.')),
    );
  }

  Future<void> _openItem(Item item) async {
    // Detail dapat mengubah, menutup, memperpanjang, atau menghapus (soft
    // delete) laporan lewat repository, jadi daftar dimuat ulang setelah
    // kembali. Data tidak dihapus permanen agar riwayat klaim Modul 3 aman.
    await Navigator.pushNamed<String>(
      context,
      AppRoutes.detail,
      arguments: item,
    );
    if (!mounted) return;
    setState(() => _items = _repository.visibleItemsFor(AppSession.userId));
  }

  /// FR-R06/FR-R10: pengingat laporan milik pengguna yang hampir/sudah
  /// kedaluwarsa, sekali per laporan.
  void _checkReportReminders() {
    final fresh = AppData.reportNotifications.checkExpiry(
      _repository.ownedBy(AppSession.userId),
      AppSession.userId,
    );
    if (fresh.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fresh.length == 1
              ? fresh.first.body
              : '${fresh.length} laporan Anda perlu diperhatikan.',
        ),
        action: SnackBarAction(label: 'Lihat', onPressed: _openMyReports),
      ),
    );
  }

  Future<void> _openMyReports() async {
    await Navigator.pushNamed<void>(context, AppRoutes.myReports);
    if (!mounted) return;
    setState(() => _items = _repository.visibleItemsFor(AppSession.userId));
  }

  Future<void> _openAccountSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('account-my-reports'),
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Laporan Saya'),
              subtitle: const Text('Kelola, perpanjang, atau tutup laporan'),
              onTap: () => Navigator.pop(sheetContext, 'reports'),
            ),
            ListTile(
              key: const Key('account-logout'),
              leading: const Icon(Icons.logout),
              title: const Text('Keluar'),
              onTap: () => Navigator.pop(sheetContext, 'logout'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'reports':
        await _openMyReports();
      case 'logout':
        AppSession.signOut();
        Navigator.pushNamedAndRemoveUntil<void>(
          context,
          AppRoutes.login,
          (route) => false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Buat laporan',
        onPressed: _openAddReport,
        child: const Icon(Icons.add, size: 34),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            Positioned.fill(
              bottom: 20,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFF0A5934),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(36),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang',
                        style: TextStyle(color: scheme.secondary, fontSize: 12),
                      ),
                      const Text(
                        'Mari Temukan Barangmu!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 0,
              child: Material(
                color: Colors.white,
                elevation: 7,
                shadowColor: const Color(0x22102020),
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 68,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF52676B),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Cari dompet, kunci, botol...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: IconButton.filledTonal(
                          tooltip: 'Pencarian berbobot',
                          onPressed: () => Navigator.pushNamed<void>(
                            context,
                            AppRoutes.advancedSearch,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFDDF2EF),
                            foregroundColor: const Color(0xFF0A5934),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_status == ViewStatus.loading) return const LoadingView();
    if (_status == ViewStatus.error) {
      return ErrorView(message: _errorMessage, onRetry: _loadItems);
    }
    return _buildReportList();
  }

  // --- Daftar laporan barang ---
  Widget _buildReportList() {
    final items = _visibleItems;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 36, 22, 100),
      children: [
        Align(alignment: Alignment.centerLeft, child: _buildReportCallout()),
        const SizedBox(height: 24),
        _buildFilters(),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _reportsSectionKey,
          child: const Text(
            'LAPORAN TERBARU',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const SizedBox(
            height: 180,
            child: EmptyView(message: 'Tidak ada laporan yang cocok.'),
          )
        else
          ...items.map(_buildItemCard),
      ],
    );
  }

  // --- Kartu CTA laporan barang ---
  Widget _buildReportCallout() {
    return Material(
      color: const Color(0xFFFEDADA),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('home-create-report'),
        onTap: () => _createReport(false),
        borderRadius: BorderRadius.circular(20),
        child: const SizedBox(
          width: 165,
          height: 132,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, color: Color(0xFFC20E18), size: 56),
              SizedBox(height: 2),
              Text(
                'Laporkan',
                style: TextStyle(
                  color: Color(0xFFC20E18),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                'Barang Hilang',
                style: TextStyle(
                  color: Color(0xFFC20E18),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 154,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: foreground.withValues(alpha: 0.16),
                  child: Icon(icon, color: foreground, size: 27),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.82),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Filter laporan barang ---
  Widget _buildFilters() {
    const filters = ['Semua', 'Kehilangan', 'Ditemukan'];
    return Row(
      children: filters.map((filter) {
        final selected = filter == _selectedFilter;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(filter, textAlign: TextAlign.center),
              ),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF52676B),
                fontSize: 11,
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF0A5934),
              side: BorderSide(
                color: selected
                    ? const Color(0xFF0A5934)
                    : const Color(0xFFD5E2E0),
              ),
              shape: const StadiumBorder(),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Ringkasan informasi ---
  Widget _buildItemCard(Item item) {
    final reportType = item.isFound ? 'Ditemukan' : 'Kehilangan';
    final statusLabel = switch (item.status) {
      ReportStatus.active => 'Aktif',
      ReportStatus.inVerification => 'Dalam Verifikasi',
      ReportStatus.resolved => 'Selesai',
      ReportStatus.expired => 'Kedaluwarsa',
      ReportStatus.removed => 'Disembunyikan',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 3,
        shadowColor: const Color(0x14102020),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openItem(item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                LegacyItemArtwork(item: item, size: 94),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusPill(
                            label: reportType,
                            color: item.isFound
                                ? const Color(0xFF045436)
                                : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          if (item.status != ReportStatus.active) ...[
                            const SizedBox(width: 6),
                            StatusPill(
                              label: statusLabel,
                              color: legacyReportStatusColor(item.status),
                            ),
                          ],
                          const Spacer(),
                          Flexible(
                            child: Text(
                              item.eventDateLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xFF718488),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.nameItem,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF14282C),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0A5934),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF718488),
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF718488),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Bar navigasi bawah ---
  Widget _buildBottomBar() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDCE6E4))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Beranda',
              onPressed: () {},
              icon: Icon(Icons.home, color: scheme.primary, size: 29),
            ),
            IconButton(
              tooltip: 'Peta Kampus',
              onPressed: () =>
                  Navigator.pushNamed<void>(context, AppRoutes.mapDiscovery),
              icon: Icon(Icons.map_outlined, color: scheme.primary, size: 27),
            ),
            const SizedBox(width: 42),
            IconButton(
              tooltip: 'Matching, klaim & notifikasi',
              onPressed: () => Navigator.pushNamed<void>(
                context,
                AppRoutes.matches,
                arguments: _matchingService,
              ),
              icon: Icon(Icons.notifications_none, color: scheme.primary),
            ),
            IconButton(
              key: const Key('home-account'),
              tooltip: 'Akun & Laporan Saya',
              onPressed: _openAccountSheet,
              icon: Icon(Icons.account_circle_outlined, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool selected = false}) {
    final color = selected ? const Color(0xFF0A5934) : const Color(0xFF607579);
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
