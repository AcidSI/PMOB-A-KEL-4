import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../data/item_repository.dart';
import '../models/item.dart';
import '../routes/app_routes.dart';
import '../services/location_service.dart';
import '../utils/campus_locations.dart';
import '../widgets/item_visuals.dart';
import '../widgets/state_views.dart';

/// Screen Peta Interaktif & Eksplorasi Laporan Kampus Unand (Modul 2: Location & Discovery)
/// Mengimplementasikan PRD v1.1:
/// - FR-L01: Pembacaan sensor GPS perangkat pengguna & fallback titik gedung
/// - FR-L02: Visualisasi peta kampus Universitas Andalas (flutter_map + OpenStreetMap)
///           dengan marker penanda Lost (Merah) dan Found (Hijau)
/// - FR-L03: Daftar laporan barang yang terintegrasi di peta (terbaru lebih dulu)
/// - FR-L04: Pencarian kata kunci akurat (word-boundary matching bebas salah sub-string)
/// - FR-L05: Filter laporan berdasarkan jenis (Lost vs Found) dan 10 Kategori Baku
/// - FR-L06: Notifikasi banner deteksi barang dalam radius lokasi pengguna
/// - FR-L07: Pilihan radius notifikasi (200 m / 500 m / 1.000 m)
/// - FR-L08: Opsi moderasi komunitas / laporkan konten mencurigakan
class MapDiscoveryScreen extends StatefulWidget {
  final ItemRepository? repository;
  final Item? initialSelectedItem;

  const MapDiscoveryScreen({
    super.key,
    this.repository,
    this.initialSelectedItem,
  });

  @override
  State<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends State<MapDiscoveryScreen>
    with TickerProviderStateMixin {
  // ─── Theme Colors ────────────────────────────────────────────────────────
  static const Color _primaryGreen = Color(0xFF045436);
  static const Color _lostRed = Color(0xFFEF4444);
  static const Color _foundGreen = Color(0xFF045436);

  // 10 Kategori Baku PRD v1.1
  static const List<String> _bakuCategories = [
    'Semua',
    'Dompet & Kartu',
    'Tas & Ransel',
    'Elektronik',
    'Kunci & Kendaraan',
    'Dokumen & Perlengkapan Kuliah',
    'Pakaian & Aksesori',
    'Botol & Perlengkapan Makan',
    'Perlengkapan Ibadah',
    'Perlengkapan Olahraga',
    'Lainnya',
  ];

  // ─── Controllers & Services ──────────────────────────────────────────────
  late final ItemRepository _repository;
  final LocationService _locationService = const LocationService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // ─── State Variables ─────────────────────────────────────────────────────
  bool _isLoading = true;
  List<Item> _allItems = [];

  // Filter State (FR-L04, FR-L05, FR-L07)
  String _searchQuery = '';
  String _selectedTypeFilter = 'Semua'; // 'Semua', 'Kehilangan', 'Ditemukan'
  String _selectedCategoryFilter = 'Semua';
  bool _onlyNearbyFilter = false;
  double _selectedRadiusMeters = 500.0; // FR-L07: 200m, 500m (default), 1000m

  // Selected Item for Preview Popup
  Item? _selectedItem;

  // GPS User Location State (FR-L01, FR-L06)
  LatLng? _userLocation;
  bool _isLocatingUser = false;
  List<Item> _nearbyItems = [];
  bool _hasPromptedNearbyAlert = false;
  bool _showNearbyBanner = false;
  Timer? _nearbyBannerTimer;

  // Sheet Height Tracker for Full-Screen Search View (Poin 3)
  double _currentSheetSize = 0.32;

  // ─── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ItemRepository();
    _selectedItem = widget.initialSelectedItem;

    _sheetController.addListener(() {
      if (_sheetController.isAttached) {
        final newSize = _sheetController.size;
        if ((newSize - _currentSheetSize).abs() > 0.05) {
          setState(() {
            _currentSheetSize = newSize;
          });
        }
      }
    });

    _initDataAndLocation();
  }

  @override
  void dispose() {
    _nearbyBannerTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _initDataAndLocation() async {
    await _loadItems();

    // Poin 2: Jika dipanggil dari DetailScreen untuk melihat lokasi barang tertentu,
    // utamakan kamera fokus ke barang tersebut dan JANGAN ditimpa oleh GPS pengguna!
    if (_selectedItem != null) {
      final pos = _getItemLatLng(_selectedItem!);
      _animatedMapMove(pos, 17.5);
    }

    // Auto-detect GPS perangkat di latar belakang
    await _detectUserLocation(
      showFeedbackOnError: false,
      shouldMoveCamera: _selectedItem == null, // Jangan geser kamera jika barang sudah dipilih
    );
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _repository.fetchItems();
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _isLoading = false;
      });

      if (_userLocation != null) {
        _updateNearbyItems(_userLocation!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ─── GPS & Location Logic (FR-L01, FR-L06, FR-L07) ───────────────────────
  Future<void> _detectUserLocation({
    bool showFeedbackOnError = true,
    bool shouldMoveCamera = true,
  }) async {
    if (_isLocatingUser) return;
    setState(() {
      _isLocatingUser = true;
    });

    final result = await _locationService.determinePosition();

    if (!mounted) return;

    setState(() {
      _isLocatingUser = false;
    });

    if (result.isSuccess && result.position != null) {
      final pos = result.position!;
      setState(() {
        _userLocation = pos;
      });

      _updateNearbyItems(pos);

      // Poin 2: Hanya geser kamera ke posisi user jika diminta dan tidak sedang menyorot barang
      if (shouldMoveCamera && _selectedItem == null) {
        _animatedMapMove(pos, 17.0);
      }

      // Poin 1 (FR-L06): Tampilkan banner notifikasi radius mandiri tanpa SnackBar yang ngestuck
      if (_nearbyItems.isNotEmpty && !_hasPromptedNearbyAlert) {
        _hasPromptedNearbyAlert = true;
        setState(() {
          _showNearbyBanner = true;
        });

        _nearbyBannerTimer?.cancel();
        _nearbyBannerTimer = Timer(const Duration(seconds: 6), () {
          if (mounted && _showNearbyBanner) {
            setState(() => _showNearbyBanner = false);
          }
        });
      }
    } else if (showFeedbackOnError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, style: GoogleFonts.poppins(fontSize: 12)),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _updateNearbyItems(LatLng pos) {
    final nearby = _locationService.getItemsInRadius(
      userPosition: pos,
      items: _allItems,
      radiusMeters: _selectedRadiusMeters,
    );
    setState(() {
      _nearbyItems = nearby;
    });
  }

  // ─── Smooth Map Camera Animation ─────────────────────────────────────────
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: destZoom,
    );

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.fastOutSlowIn,
    );

    animationController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animationController.dispose();
      }
    });

    animationController.forward();
  }

  // ─── Filter & Search Engine (Poin 4: Word-Boundary Match) ────────────────
  List<Item> get _filteredItems {
    final rawQuery = _searchQuery.trim().toLowerCase();

    return _allItems.where((item) {
      // 1. Type Filter (Lost vs Found)
      if (_selectedTypeFilter == 'Kehilangan' && item.isFound) return false;
      if (_selectedTypeFilter == 'Ditemukan' && !item.isFound) return false;

      // 2. Category Filter (10 Kategori Baku)
      if (_selectedCategoryFilter != 'Semua') {
        final itemCat = item.category.toLowerCase();
        final selCat = _selectedCategoryFilter.toLowerCase();
        // Toleran terhadap mapping kategori pendek/panjang
        if (!itemCat.contains(selCat) && !selCat.contains(itemCat)) {
          return false;
        }
      }

      // 3. Radius Filter (FR-L06 & FR-L07: 200m / 500m / 1000m)
      if (_onlyNearbyFilter && _userLocation != null) {
        final itemPos = _getItemLatLng(item);
        final dist = _locationService.distanceBetween(_userLocation!, itemPos);
        if (dist > _selectedRadiusMeters) return false;
      }

      // 4. Poin 4: Mesin Pencarian Kata Kunci dengan Word-Boundary Regex
      // Menghindari bug sub-string (misal "tas" mencocokkan "universitas" atau "fakultas")
      if (rawQuery.isNotEmpty) {
        final tokens = rawQuery
            .split(RegExp(r'\s+'))
            .where((t) => t.isNotEmpty)
            .toList();

        for (final token in tokens) {
          // Token harus diawali batas kata (word boundary \b)
          final regex = RegExp(r'\b' + RegExp.escape(token), caseSensitive: false);

          final matchesName = regex.hasMatch(item.nameItem);
          final matchesCategory = regex.hasMatch(item.category);
          final matchesBrand = item.brand != null && regex.hasMatch(item.brand!);
          final matchesColor = item.color != null && regex.hasMatch(item.color!);
          final matchesDesc = regex.hasMatch(item.description);
          final matchesLoc = regex.hasMatch(item.location);

          if (!matchesName &&
              !matchesCategory &&
              !matchesBrand &&
              !matchesColor &&
              !matchesDesc &&
              !matchesLoc) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  LatLng _getItemLatLng(Item item) {
    if (item.latitude != null && item.longitude != null) {
      return LatLng(item.latitude!, item.longitude!);
    }
    return CampusLocations.getCoordinates(item.location, fallbackSeed: item.id);
  }

  void _onSelectItem(Item item, {bool focusMap = true}) {
    setState(() {
      _selectedItem = item;
    });

    if (focusMap) {
      final pos = _getItemLatLng(item);
      _animatedMapMove(pos, 17.5);
    }
  }

  void _openItemDetail(Item item) {
    Navigator.pushNamed<dynamic>(
      context,
      AppRoutes.detail,
      arguments: item,
    );
  }

  // ─── Poin 3: Expand / Collapse Bottom Sheet ──────────────────────────────
  void _expandSheetToFull() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _collapseSheetToPeek() {
    _searchFocusNode.unfocus();
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.32,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ─── FR-L08: Dialog Laporkan Konten (Abuse Report) ────────────────────────
  Future<void> _showReportAbuseDialog(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.report_problem_outlined, color: Colors.amber),
            const SizedBox(width: 8),
            Text('Laporkan Laporan?', style: GoogleFonts.poppins(fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin laporan "${item.nameItem}" mencurigakan atau memuat informasi palsu? Sesuai PRD v1.1, laporan dengan ≥3 aduan dari pengguna terverifikasi akan disembunyikan otomatis.',
          style: GoogleFonts.poppins(fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _lostRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Laporkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Laporan telah dikirim untuk ditinjau oleh sistem anti-scam.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ─── Build UI ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. Peta Interaktif (FR-L02)
          _buildMap(),

          // 2. Header Atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopHeader(),
          ),

          // Poin 1 (FR-L06): Banner Notifikasi Radius Mengambang Mandiri (Tidak Ngestuck)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildNearbyBanner(),
          ),

          // 3. Kontrol Peta Mengambang (Hanya tampil jika sheet tidak menutup penuh layar)
          if (_currentSheetSize < 0.75)
            Positioned(
              right: 16,
              bottom: 290,
              child: _buildMapControls(),
            ),

          // 4. Kartu Preview Marker Terpilih
          if (_selectedItem != null && _currentSheetSize < 0.50)
            Positioned(
              left: 16,
              right: 16,
              bottom: 270,
              child: _buildSelectedItemPreviewCard(_selectedItem!),
            ),

          // 5. Draggable Bottom Sheet (Poin 3: Dapat menutupi peta penuh untuk kenyamanan pencarian)
          _buildDraggableBottomSheet(),

          // 6. Loading View
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const LoadingView(message: 'Memuat peta & laporan...'),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Widget: Interactive Map ─────────────────────────────────────────────
  Widget _buildMap() {
    final itemsToRender = _filteredItems;
    final initialCenter = _selectedItem != null
        ? _getItemLatLng(_selectedItem!)
        : CampusLocations.unandCenter;
    final initialZoom = _selectedItem != null ? 17.5 : 16.5;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: 13.0,
        maxZoom: 18.5,
        onTap: (tapPosition, point) {
          if (_selectedItem != null) {
            setState(() => _selectedItem = null);
          }
          if (_currentSheetSize > 0.40) {
            _collapseSheetToPeek();
          }
        },
      ),
      children: [
        // OpenStreetMap Tile Layer (PRD v1.1)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.ac.unand.find_it',
          maxZoom: 19,
        ),

        // Marker Titik Gedung Utama Unand
        MarkerLayer(
          markers: CampusLocations.landmarks.entries.map((entry) {
            return Marker(
              point: entry.value,
              width: 90,
              height: 28,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Marker Posisi GPS Pengguna (FR-L01)
        if (_userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation!,
                width: 50,
                height: 50,
                child: _buildUserLocationMarker(),
              ),
            ],
          ),

        // Marker Laporan Lost & Found (FR-L02)
        MarkerLayer(
          markers: itemsToRender.map((item) {
            final isSelected = _selectedItem?.id == item.id;
            final point = _getItemLatLng(item);
            return Marker(
              point: point,
              width: isSelected ? 56 : 46,
              height: isSelected ? 66 : 54,
              child: GestureDetector(
                onTap: () => _onSelectItem(item, focusMap: true),
                child: _buildItemMapPin(item, isSelected: isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Widget: Custom Item Pin on Map ──────────────────────────────────────
  Widget _buildItemMapPin(Item item, {required bool isSelected}) {
    final pinColor = item.isFound ? _foundGreen : _lostRed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isSelected ? 48 : 38,
          height: isSelected ? 48 : 38,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: pinColor.withValues(alpha: isSelected ? 0.6 : 0.35),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              item.isFound ? Icons.check_circle_outline : Icons.search,
              color: Colors.white,
              size: isSelected ? 24 : 18,
            ),
          ),
        ),
        Container(
          width: 3,
          height: isSelected ? 10 : 8,
          decoration: BoxDecoration(
            color: pinColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // ─── Widget: User Location Marker ────────────────────────────────────────
  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.25),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E88E5),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Poin 1: Banner Notifikasi Radius (Auto-Dismiss, Tidak Ngestuck) ─────
  Widget _buildNearbyBanner() {
    if (!_showNearbyBanner || _nearbyItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          color: _primaryGreen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Laporan di Sekitar Lokasimu',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Ditemukan ${_nearbyItems.length} laporan dalam radius ${_selectedRadiusMeters.round()}m.',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    setState(() {
                      _onlyNearbyFilter = true;
                      _showNearbyBanner = false;
                    });
                    _expandSheetToFull();
                  },
                  child: Text(
                    'Filter',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () {
                    _nearbyBannerTimer?.cancel();
                    setState(() => _showNearbyBanner = false);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Widget: Top Header Bar ──────────────────────────────────────────────
  Widget _buildTopHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Material(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black26,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: _primaryGreen),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, color: _primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Peta Kampus Universitas Andalas',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _primaryGreen,
                            ),
                          ),
                          Text(
                            _userLocation != null
                                ? 'GPS Aktif: Kampus Limau Manis'
                                : 'Eksplorasi Lokasi Laporan',
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widget: Floating Map Controls ───────────────────────────────────────
  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'btn-my-location',
          backgroundColor: Colors.white,
          foregroundColor: _userLocation != null ? _primaryGreen : Colors.grey,
          tooltip: 'Lokasi Saya (GPS)',
          onPressed: () => _detectUserLocation(
            showFeedbackOnError: true,
            shouldMoveCamera: true, // Manual tap: geser kamera ke posisi user
          ),
          child: _isLocatingUser
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'btn-campus-center',
          backgroundColor: Colors.white,
          foregroundColor: _primaryGreen,
          tooltip: 'Pusat Kampus Unand',
          onPressed: () {
            _animatedMapMove(CampusLocations.unandCenter, 16.5);
          },
          child: const Icon(Icons.school_outlined),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'btn-zoom-in',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          tooltip: 'Perbesar',
          onPressed: () {
            _animatedMapMove(
              _mapController.camera.center,
              _mapController.camera.zoom + 0.8,
            );
          },
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'btn-zoom-out',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          tooltip: 'Perkecil',
          onPressed: () {
            _animatedMapMove(
              _mapController.camera.center,
              _mapController.camera.zoom - 0.8,
            );
          },
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }

  // ─── Widget: Selected Marker Quick Preview Card ──────────────────────────
  Widget _buildSelectedItemPreviewCard(Item item) {
    final statusColor = item.isFound ? _foundGreen : _lostRed;
    final itemLatLng = _getItemLatLng(item);
    final distanceLabel = _userLocation != null
        ? _locationService.formatDistance(
            _locationService.distanceBetween(_userLocation!, itemLatLng),
          )
        : null;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            LegacyItemArtwork(item: item, size: 68),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.nameItem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      StatusPill(
                        label: item.isFound ? 'Ditemukan' : 'Kehilangan',
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: _primaryGreen),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (distanceLabel != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '±$distanceLabel',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        item.category,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      // FR-L08: Tombol Laporkan Konten
                      IconButton(
                        tooltip: 'Laporkan Laporan (Anti-scam)',
                        icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.grey),
                        onPressed: () => _showReportAbuseDialog(item),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _openItemDetail(item),
                        child: Text(
                          'Lihat Detail',
                          style: GoogleFonts.poppins(fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _selectedItem = null),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widget: Draggable Bottom Sheet (Poin 3: Fullscreen Search Support) ───
  Widget _buildDraggableBottomSheet() {
    final filteredItems = _filteredItems;
    final isExpandedFull = _currentSheetSize >= 0.85;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.32,
      minChildSize: 0.12,
      maxChildSize: 1.0, // Poin 3: Bisa full 100% menutupi peta agar leluasa
      snap: true,
      snapSizes: const [0.12, 0.32, 0.65, 1.0],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Header Sheet, Search Bar, & Filter
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar & Tombol Toggle View Peta
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // Baris Aksi Pencarian (Search Input & Tombol Fullscreen/Collapse Peta)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onTap: () {
                                // Poin 3: Saat user mengetuk input pencarian, otomatis perluas sheet
                                if (_currentSheetSize < 0.65) {
                                  _expandSheetToFull();
                                }
                              },
                              onChanged: (val) {
                                setState(() => _searchQuery = val);
                              },
                              decoration: InputDecoration(
                                hintText: 'Cari barang, merek, atau deskripsi...',
                                hintStyle: GoogleFonts.poppins(fontSize: 12),
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Poin 3: Tombol Beralih Mode Peta vs Pencarian Penuh
                          Material(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            child: IconButton(
                              tooltip: isExpandedFull ? 'Lihat Peta' : 'Layar Penuh',
                              icon: Icon(
                                isExpandedFull
                                    ? Icons.keyboard_arrow_down
                                    : Icons.fullscreen,
                                color: _primaryGreen,
                              ),
                              onPressed: () {
                                if (isExpandedFull) {
                                  _collapseSheetToPeek();
                                } else {
                                  _expandSheetToFull();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Filter Types: Semua, Kehilangan, Ditemukan (FR-L05)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildTypeFilterRow(),
                    ),

                    const SizedBox(height: 8),

                    // Filter 10 Kategori Baku PRD v1.1
                    _buildCategoryFilterList(),

                    const SizedBox(height: 8),

                    // Baris Informasi Hasil & Pengaturan Radius (FR-L06, FR-L07)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Menampilkan ${filteredItems.length} laporan',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const Spacer(),
                          // Pilihan Radius FR-L07: 200m / 500m / 1000m
                          if (_userLocation != null)
                            PopupMenuButton<double>(
                              tooltip: 'Pilih Radius Notifikasi',
                              initialValue: _selectedRadiusMeters,
                              onSelected: (radius) {
                                setState(() {
                                  _selectedRadiusMeters = radius;
                                  _onlyNearbyFilter = true;
                                });
                                if (_userLocation != null) {
                                  _updateNearbyItems(_userLocation!);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _onlyNearbyFilter
                                      ? _primaryGreen
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.near_me,
                                      size: 13,
                                      color: _onlyNearbyFilter
                                          ? Colors.white
                                          : _primaryGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Radius ≤ ${_selectedRadiusMeters.round()}m',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: _onlyNearbyFilter
                                            ? Colors.white
                                            : _primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 16,
                                      color: _onlyNearbyFilter
                                          ? Colors.white
                                          : _primaryGreen,
                                    ),
                                  ],
                                ),
                              ),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 200.0,
                                  child: Text('Radius 200 m (Sangat Dekat)'),
                                ),
                                const PopupMenuItem(
                                  value: 500.0,
                                  child: Text('Radius 500 m (Default)'),
                                ),
                                const PopupMenuItem(
                                  value: 1000.0,
                                  child: Text('Radius 1.000 m (1 km)'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 16),
                  ],
                ),
              ),

              // Item List or Empty View (FR-L03)
              if (filteredItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyView(
                        message: _searchQuery.isNotEmpty ||
                                _selectedTypeFilter != 'Semua' ||
                                _selectedCategoryFilter != 'Semua'
                            ? 'Tidak ada laporan yang cocok dengan kata kunci "$_searchQuery".'
                            : 'Belum ada laporan di kawasan ini.',
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filteredItems[index];
                        return _buildListItemCard(item);
                      },
                      childCount: filteredItems.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Widget: Filter Jenis (Semua / Kehilangan / Ditemukan) ────────────────
  Widget _buildTypeFilterRow() {
    const types = ['Semua', 'Kehilangan', 'Ditemukan'];

    return Row(
      children: types.map((type) {
        final isSelected = _selectedTypeFilter == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(
                  type,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (_) {
                setState(() => _selectedTypeFilter = type);
              },
              backgroundColor: const Color(0xFFF1F5F9),
              selectedColor: _primaryGreen,
              side: BorderSide(
                color: isSelected ? _primaryGreen : Colors.transparent,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Widget: Filter 10 Kategori Baku Horizontal ──────────────────────────
  Widget _buildCategoryFilterList() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _bakuCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _bakuCategories[index];
          final isSelected = _selectedCategoryFilter == cat;
          return FilterChip(
            label: Text(
              cat,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : _primaryGreen,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) {
              setState(() => _selectedCategoryFilter = cat);
            },
            backgroundColor: const Color(0xFFECFDF5),
            selectedColor: _primaryGreen,
            side: BorderSide(
              color: isSelected ? _primaryGreen : const Color(0x33045436),
            ),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }

  // ─── Widget: List Item Card in Bottom Sheet (FR-L03) ──────────────────────
  Widget _buildListItemCard(Item item) {
    final statusColor = item.isFound ? _foundGreen : _lostRed;
    final itemLatLng = _getItemLatLng(item);
    final distance = _userLocation != null
        ? _locationService.distanceBetween(_userLocation!, itemLatLng)
        : null;
    final isSelected = _selectedItem?.id == item.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? _primaryGreen : const Color(0x22999999),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _onSelectItem(item, focusMap: true);
            // Poin 3: Ketika item ditekan, kecilkan sheet kembali agar peta dan marker terlihat jelas
            _collapseSheetToPeek();
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                LegacyItemArtwork(item: item, size: 70),
                const SizedBox(width: 12),
                Expanded(
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
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          StatusPill(
                            label: item.isFound ? 'Ditemukan' : 'Kehilangan',
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.category,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 11,
                                    color: _primaryGreen,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      item.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 9.5,
                                        color: _primaryGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '±${_locationService.formatDistance(distance)}',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Lihat Detail',
                  icon: const Icon(
                    Icons.chevron_right,
                    color: _primaryGreen,
                  ),
                  onPressed: () => _openItemDetail(item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
