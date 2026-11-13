import 'dart:async';

import 'package:flutter/material.dart';

import 'package:find_it/data/app_data.dart';
import 'package:find_it/data/item_repository.dart';
import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/models/match.dart';
import 'package:find_it/models/report_category.dart';
import 'package:find_it/routes/app_routes.dart';
import 'package:find_it/services/app_session.dart';
import 'package:find_it/services/matching_service.dart';
import 'package:find_it/widgets/home/home_bottom_nav.dart';
import 'package:find_it/widgets/home/home_header.dart';
import 'package:find_it/widgets/home/home_sections.dart';
import 'package:find_it/widgets/report/report_components.dart';
import 'package:find_it/widgets/report/report_theme.dart';
import 'package:find_it/widgets/state_views.dart';

enum ViewStatus { loading, success, error }

/// Beranda Find!t (desain "A · Aksi cepat").
///
/// Susunan: header (sapaan, notifikasi, pencarian) → aksi cepat
/// Hilang/Ditemukan → banner kecocokan (Modul 3) → Laporan saya →
/// filter kategori & jenis → daftar laporan terbaru → navigasi bawah.
///
/// Widget tampilan ada di `lib/widgets/home/`; layar ini hanya berisi
/// state, pengambilan data, dan navigasi.
class HomeScreen extends StatefulWidget {
  final ItemRepository? repository;
  const HomeScreen({super.key, this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _typeFilters = ['Semua', 'Hilang', 'Ditemukan'];

  late final ItemRepository _repository;
  late final MatchingService _matchingService;
  Timer? _matchingTimer;
  final _searchController = TextEditingController();
  final _reportsSectionKey = GlobalKey();

  ViewStatus _status = ViewStatus.loading;
  List<Item> _items = [];
  String _errorMessage = '';
  String _typeFilter = 'Semua';
  String? _categoryFilter;

  final bool _simulateError = false;

  String? get _userId => AppSession.userId;

  // ------------------------------------------------------------ Lifecycle

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppData.repository;
    _matchingService = identical(_repository, AppData.repository)
        ? AppData.matchingService
        : MatchingService(items: _repository.items);
    _matchingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _matchingService.refreshMatches();
      // Banner kecocokan & badge ikut diperbarui.
      if (mounted) setState(() {});
    });
    _loadItems();
  }

  @override
  void dispose() {
    _matchingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- Data

  Future<void> _loadItems() async {
    setState(() => _status = ViewStatus.loading);
    try {
      final items = await _repository.fetchItems(
        simulateError: _simulateError,
        viewerId: _userId,
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
    }
  }

  void _reloadFromRepository() {
    setState(() => _items = _repository.visibleItemsFor(_userId));
  }

  /// Laporan setelah filter jenis, kategori, dan kata kunci.
  List<Item> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesType = switch (_typeFilter) {
        'Hilang' => !item.isFound,
        'Ditemukan' => item.isFound,
        _ => true,
      };
      final matchesCategory =
          _categoryFilter == null ||
          item.category == _categoryFilter ||
          item.category2 == _categoryFilter;
      final matchesQuery =
          query.isEmpty ||
          item.nameItem.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesType && matchesCategory && matchesQuery;
    }).toList();
  }

  /// Laporan milik pengguna untuk kartu ringkas: yang segera berakhir
  /// atau sedang diverifikasi didahulukan.
  List<Item> get _myHighlightedReports {
    final now = DateTime.now();
    int priority(Item item) {
      if (ReportRules.needsExpiryReminder(item, now)) return 0;
      if (item.status == ReportStatus.inVerification) return 1;
      return 2;
    }

    final mine = _repository
        .ownedBy(_userId)
        .where(
          (item) =>
              item.status == ReportStatus.active ||
              item.status == ReportStatus.inVerification,
        )
        .toList();
    mine.sort((a, b) => priority(a).compareTo(priority(b)));
    return mine;
  }

  /// Kecocokan baru untuk laporan Hilang milik pengguna (Modul 3).
  ({int count, String itemName})? get _matchSummary {
    final userId = _userId;
    if (userId == null) return null;
    final relevant = _matchingService.visibleMatches.where((match) {
      if (match.status == MatchStatus.claimed) return false;
      final lost = _matchingService.itemById(match.lostItemId);
      return lost != null && lost.isOwnedBy(userId);
    }).toList();
    if (relevant.isEmpty) return null;
    final lost = _matchingService.itemById(relevant.first.lostItemId)!;
    return (count: relevant.length, itemName: lost.nameItem);
  }

  int get _unreadNotifications {
    final userId = _userId;
    final matching = userId == null
        ? 0
        : _matchingService
              .notificationsFor(userId)
              .where((notification) => !notification.isRead)
              .length;
    return matching + AppData.reportNotifications.unread.length;
  }

  // ------------------------------------------------------------ Navigasi

  Future<void> _openCreatePicker() async {
    final isFound = await showReportTypePicker(context);
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
      _items = _repository.visibleItemsFor(_userId);
      _typeFilter = 'Semua';
      _categoryFilter = null;
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = _reportsSectionKey.currentContext;
      if (sectionContext != null && sectionContext.mounted) {
        Scrollable.ensureVisible(
          sectionContext,
          duration: const Duration(milliseconds: 250),
          alignment: 0.1,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan berhasil dipublikasikan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openItem(Item item) async {
    // Detail dapat mengubah, menutup, memperpanjang, atau menghapus (soft
    // delete) laporan lewat repository, jadi daftar dimuat ulang.
    await Navigator.pushNamed<String>(
      context,
      AppRoutes.detail,
      arguments: item,
    );
    if (mounted) _reloadFromRepository();
  }

  Future<void> _openMatching() async {
    await Navigator.pushNamed<void>(
      context,
      AppRoutes.matches,
      arguments: _matchingService,
    );
    if (mounted) _reloadFromRepository();
  }

  Future<void> _openMyReports() async {
    await Navigator.pushNamed<void>(context, AppRoutes.myReports);
    if (mounted) _reloadFromRepository();
  }

  void _onTabSelected(HomeTab tab) {
    switch (tab) {
      case HomeTab.home:
        break;
      case HomeTab.map:
        Navigator.pushNamed<void>(context, AppRoutes.mapDiscovery);
      case HomeTab.matching:
        _openMatching();
      case HomeTab.account:
        _openAccountSheet();
    }
  }

  /// FR-R06/FR-R10: pengingat laporan milik pengguna yang hampir/sudah
  /// kedaluwarsa, sekali per laporan.
  void _checkReportReminders() {
    final fresh = AppData.reportNotifications.checkExpiry(
      _repository.ownedBy(_userId),
      _userId,
    );
    if (fresh.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          fresh.length == 1
              ? fresh.first.body
              : '${fresh.length} laporan Anda perlu diperhatikan.',
        ),
        action: SnackBarAction(label: 'Lihat', onPressed: _openMyReports),
      ),
    );
  }

  Future<void> _openAccountSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: ReportColors.surface,
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
              leading: const Icon(Icons.logout, color: ReportColors.lost),
              title: const Text(
                'Keluar',
                style: TextStyle(color: ReportColors.lost),
              ),
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

  // ---------------------------------------------------------------- Teks

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi,';
    if (hour < 15) return 'Selamat siang,';
    if (hour < 18) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  /// Nama tampilan dari bagian depan email kampus.
  String get _displayName {
    final email = AppSession.email;
    if (email == null || !email.contains('@')) return 'Sivitas Unand';
    final local = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    final words = local.split(' ').where((word) => word.isNotEmpty);
    if (words.isEmpty) return 'Sivitas Unand';
    return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String get _initials {
    final words = _displayName.split(' ');
    final letters = words.take(2).map((w) => w.isEmpty ? '' : w[0]);
    return letters.join().toUpperCase();
  }

  static String _relativeTime(Item item) {
    final time = item.createdAt ?? item.eventDate;
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return Item.formatDateTime(time).split(' ').first;
  }

  // --------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReportColors.background,
      body: switch (_status) {
        ViewStatus.loading => const LoadingView(),
        ViewStatus.error => ErrorView(
          message: _errorMessage,
          onRetry: _loadItems,
        ),
        ViewStatus.success => _buildContent(),
      },
      bottomNavigationBar: HomeBottomNav(
        current: HomeTab.home,
        onTabSelected: _onTabSelected,
        onCreate: _openCreatePicker,
        matchingBadge: _matchSummary?.count ?? 0,
      ),
    );
  }

  Widget _buildContent() {
    final items = _filteredItems;
    final match = _matchSummary;
    final myReports = _myHighlightedReports;

    return RefreshIndicator(
      color: ReportColors.green,
      onRefresh: _loadItems,
      // Satu daftar gulir: header ikut bergulir bersama isi halaman.
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          HomeHeader(
            greeting: _greeting,
            displayName: _displayName,
            initials: _initials,
            unreadCount: _unreadNotifications,
            searchController: _searchController,
            onSearchChanged: (_) => setState(() {}),
            onNotificationsTap: _openMatching,
            onAdvancedSearchTap: () =>
                Navigator.pushNamed<void>(context, AppRoutes.advancedSearch),
          ),
          // Kartu aksi cepat menumpang di lengkungan bawah header.
          HomeHeaderOverlap(child: _buildQuickActions()),
          const SizedBox(height: 20),
          if (match != null) ...[
            _padded(
              HomeMatchBanner(
                count: match.count,
                itemName: match.itemName,
                onTap: _openMatching,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (myReports.isNotEmpty) ...[
            _padded(
              HomeSectionTitle(
                title: 'Laporan saya',
                actionLabel: 'Kelola',
                onAction: _openMyReports,
              ),
            ),
            const SizedBox(height: 6),
            _padded(HomeMyReportsStrip(reports: myReports, onOpen: _openItem)),
            const SizedBox(height: 20),
          ],
          KeyedSubtree(
            key: _reportsSectionKey,
            child: _padded(const HomeSectionTitle(title: 'Laporan terbaru')),
          ),
          const SizedBox(height: 10),
          // Kategori selebar layar; padding ada di dalam daftar gulirnya.
          HomeCategoryBar(
            categories: [
              for (final category in ReportCategories.all) category.name,
            ],
            selected: _categoryFilter,
            onSelected: (value) => setState(() => _categoryFilter = value),
          ),
          const SizedBox(height: 10),
          _padded(
            HomeTypeSegment(
              options: _typeFilters,
              selected: _typeFilter,
              onChanged: (value) => setState(() => _typeFilter = value),
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const SizedBox(
              height: 180,
              child: EmptyView(message: 'Tidak ada laporan yang cocok.'),
            )
          else
            for (final item in items) ...[
              _padded(
                HomeReportCard(
                  item: item,
                  timeLabel: _relativeTime(item),
                  onTap: () => _openItem(item),
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: child,
  );

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _elevated(
            ReportTypeOption(
              key: const Key('home-create-lost'),
              isFound: false,
              onTap: () => _createReport(false),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _elevated(
            ReportTypeOption(
              key: const Key('home-create-found'),
              isFound: true,
              onTap: () => _createReport(true),
            ),
          ),
        ),
      ],
    );
  }

  /// Bayangan lembut agar kartu terlihat "melayang" di atas header.
  Widget _elevated(Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ReportRadius.card),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A14282C),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
