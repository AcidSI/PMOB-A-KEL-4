import 'package:flutter/material.dart';

import '../data/item_repository.dart';
import '../models/item.dart';
import '../routes/app_routes.dart';
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
  final _searchController = TextEditingController();
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
      _repository.items.insert(0, item);
      _items.insert(0, item);
      _selectedFilter = 'Semua';
      _searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laporan baru ditambahkan ke daftar.')),
    );
  }

  Future<void> _openItem(Item item) async {
    final deletedId = await Navigator.pushNamed<String>(
      context,
      AppRoutes.detail,
      arguments: item,
    );
    if (!mounted || deletedId == null) return;
    setState(() {
      _repository.items.removeWhere((entry) => entry.id == deletedId);
      _items.removeWhere((entry) => entry.id == deletedId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Buat laporan',
        onPressed: _openAddReport,
        child: const Icon(Icons.camera_alt),
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: scheme.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selamat Datang',
                        style: TextStyle(color: scheme.secondary, fontSize: 12)),
                    Text(
                      'Mari Temukan Barangmu!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Pencarian berbobot',
                onPressed: () =>
                    Navigator.pushNamed<void>(context, AppRoutes.advancedSearch),
                color: Colors.white,
                icon: const Icon(Icons.manage_search),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari Barang',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 36, 22, 100),
      children: [
        Align(alignment: Alignment.centerLeft, child: _buildReportCallout()),
        const SizedBox(height: 26),
        _buildFilters(),
        const SizedBox(height: 30),
        const Text(
          'LAPORAN TERBARU',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
  // --- Kartu laporan barang ---
  Widget _buildReportCallout() {
    return Material(
      color: const Color(0xFFFEDADA),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('home-create-report'),
        onTap: () => _createReport(false),
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 165,
          height: 132,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search,
                color: Color(0xFFC20E18),
                size: 56,
              ),
              const SizedBox(height: 2),
              const Text(
                'Laporkan',
                style: TextStyle(
                  color: Color(0xFFC20E18),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Text(
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
                color: selected ? Colors.white : const Color(0xFF595858),
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF045436),
              side: BorderSide(
                color: selected ? const Color(0xFF045436) : Colors.black12,
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
        ? const Color(0xFF045436)
        : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x33999999)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openItem(item),
          child: SizedBox(
            height: 101,
            child: Row(
              children: [
                const SizedBox(width: 13),
                ItemArtwork(item: item, size: 74),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.nameItem,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            StatusPill(
                              label: item.isFound ? 'Ditemukan' : 'Kehilangan',
                              color: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF595858),
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  item.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF045436),
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.eventDateLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Color(0x99595858),
                                  fontSize: 9,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x40888888)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home, color: scheme.primary, size: 29),
            Icon(Icons.map_outlined, color: scheme.primary, size: 27),
            const SizedBox(width: 42),
            Icon(Icons.notifications_none, color: scheme.primary, size: 28),
            Icon(Icons.account_circle_outlined, color: scheme.primary, size: 29),
          ],
        ),
      ),
    );
  }
}
