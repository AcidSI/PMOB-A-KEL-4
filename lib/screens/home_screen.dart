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
  // State async memisahkan loading, daftar kosong, hasil, dan error.
  late final ItemRepository _repository;
  final _searchController = TextEditingController();
  ViewStatus _status = ViewStatus.loading;
  List<Item> _items = [];
  String _errorMessage = '';
  String _selectedFilter = 'Semua';
  // Toggle ini sengaja mutable agar error state dapat diuji sesuai praktikum.
  // ignore: prefer_final_fields
  bool _simulateError = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? const ItemRepository();
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
        _items = items;
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
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
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
            //TextButton(
              // onPressed: () => Navigator.pushNamed(context, '/route-tidak-ada'),
              // child: const Text('Tes 404'),),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Buat laporan',
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form laporan belum tersedia.')),
        ),
        child: const Icon(Icons.camera_alt),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF045436),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF045436), size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selamat Datang,',
                        style: TextStyle(color: Color(0xFF5CC9B1))),
                    Text(
                      'Martia Perdana Putri',
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
                tooltip: 'Notifikasi',
                onPressed: () {},
                color: Colors.white,
                icon: const Icon(Icons.notifications),
              ),
              IconButton(
                tooltip: 'Tampilan',
                onPressed: () {},
                color: Colors.white,
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari nama barang',
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

  Widget _buildReportList() {
    final items = _visibleItems;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 100),
      children: [
        const Text(
          'PETA KAMPUS UNAND',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const _CampusMap(),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 36),
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
              selectedColor: const Color(0xFF059669),
              side: BorderSide(
                color: selected ? const Color(0xFF059669) : Colors.black12,
              ),
              shape: const StadiumBorder(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemCard(Item item) {
    final statusColor = item.isFound
        ? const Color(0xFF059669)
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
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.detail,
            arguments: item,
          ),
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
                                item.title,
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
                          item.subtitle,
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
                                item.timeAgo,
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

  Widget _buildBottomBar() {
    const green = Color(0xFF045436);
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x40888888)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home, color: green, size: 29),
            Icon(Icons.map_outlined, color: green, size: 27),
            Icon(Icons.add_circle, color: green, size: 36),
            Icon(Icons.notifications_none, color: green, size: 28),
            Icon(Icons.account_circle_outlined, color: green, size: 29),
          ],
        ),
      ),
    );
  }
}

class _CampusMap extends StatelessWidget {
  const _CampusMap();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 142,
        child: CustomPaint(
          painter: _CampusMapPainter(),
          child: const Stack(
            children: [
              Positioned(left: 42, top: 26, child: _MapPin()),
              Positioned(left: 186, top: 53, child: _MapPin()),
              Positioned(right: 53, top: 37, child: _MapPin()),
              Positioned(
                left: 12,
                bottom: 10,
                child: Text(
                  'UNIVERSITAS ANDALAS',
                  style: TextStyle(
                    color: Color(0xFF486454),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.location_on, size: 17, color: Color(0xFF059669));
  }
}

class _CampusMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFF7F7F3);
    canvas.drawRect(Offset.zero & size, background);
    final green = Paint()..color = const Color(0xFFD7F0E4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-20, 12, 90, 46),
        const Radius.circular(24),
      ),
      green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 75, 74, 100, 60),
        const Radius.circular(24),
      ),
      green,
    );
    final road = Paint()
      ..color = const Color(0xFFCAD4D8)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final roadCenter = Path()
      ..moveTo(-10, size.height * .77)
      ..cubicTo(size.width * .24, size.height * .25, size.width * .41,
          size.height * .92, size.width * .68, size.height * .31)
      ..cubicTo(size.width * .82, size.height * .02, size.width * .91,
          size.height * .82, size.width + 10, size.height * .45);
    canvas.drawPath(roadCenter, road);
    final minorRoad = Paint()
      ..color = const Color(0xFFDCE2E3)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var index = 0; index < 4; index++) {
      final path = Path()
        ..moveTo(size.width * (index * .24), 0)
        ..lineTo(size.width * (index * .24 + .13), size.height);
      canvas.drawPath(path, minorRoad);
    }
    final block = Paint()..color = const Color(0xFFEAE9E2);
    for (var index = 0; index < 5; index++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(18 + index * 68, 24 + (index % 2) * 58, 36, 22),
          const Radius.circular(4),
        ),
        block,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CampusMapPainter oldDelegate) => false;
}

