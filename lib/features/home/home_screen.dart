import 'package:flutter/material.dart';

import 'package:find_it/core/routes/app_routes.dart';
import 'package:find_it/core/widgets/item_visuals.dart';
import 'package:find_it/core/widgets/state_views.dart';
import 'package:find_it/core/widgets/status_pill.dart';
import 'package:find_it/features/report/data/item_repository.dart';
import 'package:find_it/features/report/models/report.dart';

enum ViewStatus { loading, success, error }

class HomeScreen extends StatefulWidget {
  final ItemRepository? repository;
  const HomeScreen({super.key, this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ItemRepository _repository;
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
    _repository = widget.repository ?? ItemRepository();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _status = ViewStatus.loading);
    try {
      final items = await _repository.fetchItems(simulateError: _simulateError);
      if (!mounted) return;
      setState(() {
        _items = [...items];
        _status = ViewStatus.success;
        _errorMessage = '';
      });
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
    setState(() {
      _repository.add(item);
      _items = _repository.visibleItems;
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
      const SnackBar(content: Text('Laporan baru ditambahkan ke daftar.')),
    );
  }

  Future<void> _openItem(Item item) async {
    // Detail dapat mengubah, memperpanjang, atau menghapus (soft delete)
    // laporan lewat repository, jadi daftar dimuat ulang setelah kembali.
    await Navigator.pushNamed<String>(
      context,
      AppRoutes.detail,
      arguments: item,
    );
    if (!mounted) return;
    setState(() => _items = _repository.visibleItems);
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
    return SizedBox(
      height: 236,
      child: Stack(
        clipBehavior: Clip.none,
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 29,
                          backgroundColor: Colors.white,
                          child: const Text(
                            'F',
                            style: TextStyle(
                              color: Color(0xFF0A5934),
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat datang',
                                style: TextStyle(
                                  color: Color(0xFFD8F1EE),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Temukan barangmu',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 29,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFD8F1EE),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Universitas Andalas · Kampus Limau Manis',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFE7F5F3),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Saya kehilangan',
                  subtitle: 'Laporkan barang hilang',
                  icon: Icons.search_rounded,
                  background: const Color(0xFFF8A10A),
                  foreground: const Color(0xFF14282C),
                  onTap: () => _createReport(false),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildActionCard(
                  title: 'Saya menemukan',
                  subtitle: 'Laporkan barang temuan',
                  icon: Icons.camera_alt_outlined,
                  background: const Color(0xFF0A5934),
                  foreground: Colors.white,
                  onTap: _openAddReport,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildDiscoveryCard(),
          const SizedBox(height: 24),
          _buildSectionHeading('Kategori', action: 'Lihat semua'),
          const SizedBox(height: 12),
          _buildCategories(),
          const SizedBox(height: 24),
          KeyedSubtree(
            key: _reportsSectionKey,
            child: _buildSectionHeading(
              'LAPORAN TERBARU',
              action: 'Lihat semua',
            ),
          ),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const SizedBox(
              height: 180,
              child: EmptyView(message: 'Tidak ada laporan yang cocok.'),
            )
          else
            ...items.map(_buildItemCard),
        ],
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

  Widget _buildDiscoveryCard() {
    return Material(
      color: const Color(0xFFDDF2EF),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF0A5934),
              child: Text(
                '${_items.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan di kampus',
                    style: TextStyle(
                      color: Color(0xFF0D5F59),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Temukan barang lebih cepat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF14282C),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_items.length} laporan tersedia',
                    style: const TextStyle(
                      color: Color(0xFF63777B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () =>
                  Navigator.pushNamed<void>(context, AppRoutes.advancedSearch),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0A5934),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Cari'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeading(String title, {String? action}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF14282C),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null)
          Text(
            action,
            style: const TextStyle(
              color: Color(0xFF0A5934),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildCategories() {
    const categories = [
      (Icons.account_balance_wallet_outlined, 'Dompet'),
      (Icons.backpack_outlined, 'Tas'),
      (Icons.devices_other_outlined, 'Elektronik'),
      (Icons.key_outlined, 'Kunci'),
      (Icons.description_outlined, 'Dokumen'),
    ];
    return Row(
      children: [
        for (var index = 0; index < categories.length; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == categories.length - 1 ? 0 : 4,
              ),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDF2EF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      categories[index].$1,
                      color: const Color(0xFF0A5934),
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    categories[index].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF263B3F),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

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
    final statusColor = item.isFound
        ? const Color(0xFFDDF2EF)
        : const Color(0xFFFFE9C8);
    final statusForeground = item.isFound
        ? const Color(0xFF0D5F59)
        : const Color(0xFF8A4B08);
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
                ItemArtwork(item: item, size: 94),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              item.isFound ? 'Ditemukan' : 'Hilang',
                              style: TextStyle(
                                color: statusForeground,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (item.status != ReportStatus.active) ...[
                            const SizedBox(width: 6),
                            StatusPill(
                              label: item.status.label,
                              color: reportStatusColor(item.status),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDCE6E4))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Beranda', selected: true),
              _buildNavItem(Icons.map_outlined, 'Peta'),
              const SizedBox(width: 56),
              _buildNavItem(Icons.notifications_none, 'Notifikasi'),
              _buildNavItem(Icons.person_outline, 'Profil'),
            ],
          ),
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
