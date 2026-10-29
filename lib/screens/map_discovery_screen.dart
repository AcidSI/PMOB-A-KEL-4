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
/// Mengimplementasikan:
/// - FR-L01: Pembacaan sensor GPS perangkat pengguna
/// - FR-L02: Visualisasi peta kampus Universitas Andalas dan marker laporan Lost & Found
/// - FR-L03: Daftar laporan barang yang terintegrasi di peta
/// - FR-L04: Pencarian laporan berdasarkan kata kunci/nama barang/lokasi
/// - FR-L05: Filter laporan berdasarkan jenis (Lost vs Found) dan kategori
/// - FR-L06: Notifikasi/indikator deteksi barang dalam radius lokasi pengguna
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
  static const Color _accentGreen = Color(0xFF73C47A);
  static const Color _lostRed = Color(0xFFEF4444);
  static const Color _foundGreen = Color(0xFF045436);

  // ─── Controllers & Services ──────────────────────────────────────────────
  late final ItemRepository _repository;
  final LocationService _locationService = const LocationService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // ─── State Variables ─────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _errorMessage;
  List<Item> _allItems = [];

  // Filter State (FR-L04, FR-L05)
  String _searchQuery = '';
  String _selectedTypeFilter = 'Semua'; // 'Semua', 'Kehilangan', 'Ditemukan'
  String _selectedCategoryFilter = 'Semua';
  bool _onlyNearbyFilter = false;

  // Selected Item for Preview Popup
  Item? _selectedItem;

  // GPS User Location State (FR-L01, FR-L06)
  LatLng? _userLocation;
  bool _isLocatingUser = false;
  String? _gpsStatusMessage;
  List<Item> _nearbyItems = [];
  bool _hasPromptedNearbyAlert = false;

  // ─── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ItemRepository();
    _selectedItem = widget.initialSelectedItem;
    _initDataAndLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _initDataAndLocation() async {
    await _loadItems();
    // Auto-detect user GPS on screen launch (FR-L01)
    await _detectUserLocation(showSnackBarOnError: false);
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.fetchItems();
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _isLoading = false;
      });

      // Update nearby items if GPS is already ready
      if (_userLocation != null) {
        _updateNearbyItems(_userLocation!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ─── GPS & Location Logic (FR-L01, FR-L06) ──────────────────────────────
  Future<void> _detectUserLocation({bool showSnackBarOnError = true}) async {
    if (_isLocatingUser) return;
    setState(() {
      _isLocatingUser = true;
    });

    final result = await _locationService.determinePosition();

    if (!mounted) return;

    setState(() {
      _isLocatingUser = false;
      _gpsStatusMessage = result.message;
    });

    if (result.isSuccess && result.position != null) {
      final pos = result.position!;
      setState(() {
        _userLocation = pos;
      });

      _updateNearbyItems(pos);

      // Animate map camera to user position
      _animatedMapMove(pos, 17.0);

      // FR-L06: Radius notification banner trigger
      if (_nearbyItems.isNotEmpty && !_hasPromptedNearbyAlert) {
        _hasPromptedNearbyAlert = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '📍 Ditemukan ${_nearbyItems.length} laporan dalam radius 500m dari lokasimu!',
                    style: GoogleFonts.poppins(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Filter',
              textColor: _accentGreen,
              onPressed: () {
                setState(() => _onlyNearbyFilter = true);
              },
            ),
          ),
        );
      }
    } else if (showSnackBarOnError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, style: GoogleFonts.poppins(fontSize: 12)),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _updateNearbyItems(LatLng pos) {
    final nearby = _locationService.getItemsInRadius(
      userPosition: pos,
      items: _allItems,
      radiusMeters: 500.0,
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

  // ─── Filter & Search Engine (FR-L04, FR-L05) ────────────────────────────
  List<Item> get _filteredItems {
    final query = _searchQuery.trim().toLowerCase();

    return _allItems.where((item) {
      // 1. Type Filter (Lost vs Found)
      if (_selectedTypeFilter == 'Kehilangan' && item.isFound) return false;
      if (_selectedTypeFilter == 'Ditemukan' && !item.isFound) return false;

      // 2. Category Filter
      if (_selectedCategoryFilter != 'Semua' &&
          item.category != _selectedCategoryFilter) {
        return false;
      }

      // 3. Radius Filter (≤ 500m from user GPS)
      if (_onlyNearbyFilter && _userLocation != null) {
        final itemPos = _getItemLatLng(item);
        final dist = _locationService.distanceBetween(_userLocation!, itemPos);
        if (dist > 500.0) return false;
      }

      // 4. Keyword Query Search
      if (query.isNotEmpty) {
        final matchesName = item.nameItem.toLowerCase().contains(query);
        final matchesLocation = item.location.toLowerCase().contains(query);
        final matchesDescription = item.description.toLowerCase().contains(query);
        final matchesBrand = (item.brand ?? '').toLowerCase().contains(query);
        final matchesColor = (item.color ?? '').toLowerCase().contains(query);
        final matchesReporter = (item.reporter ?? '').toLowerCase().contains(query);

        if (!matchesName &&
            !matchesLocation &&
            !matchesDescription &&
            !matchesBrand &&
            !matchesColor &&
            !matchesReporter) {
          return false;
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

  // ─── Build UI ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. Interactive Map Layer (FR-L02)
          _buildMap(),

          // 2. Top Header Bar & GPS Status Badge
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopHeader(),
          ),

          // 3. Floating Map Controls (GPS Button, Center Campus, Zoom)
          Positioned(
            right: 16,
            bottom: 300,
            child: _buildMapControls(),
          ),

          // 4. Selected Marker Popup Card Preview
          if (_selectedItem != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 270,
              child: _buildSelectedItemPreviewCard(_selectedItem!),
            ),

          // 5. Draggable Scrollable Bottom Sheet (FR-L03, FR-L04, FR-L05)
          _buildDraggableBottomSheet(),

          // 6. Loading Indicator
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

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: CampusLocations.unandCenter,
        initialZoom: 16.5,
        minZoom: 13.0,
        maxZoom: 18.5,
        onTap: (_, __) {
          // Tap on empty space deselects selected marker
          if (_selectedItem != null) {
            setState(() => _selectedItem = null);
          }
        },
      ),
      children: [
        // OpenStreetMap Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.ac.unand.find_it',
          maxZoom: 19,
        ),

        // Campus Landmarks Reference Markers (Translucent pins for context)
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
                    color: Colors.white.withValues(alpha: 0.85),
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

        // User GPS Position Marker (FR-L01)
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

        // Items Marker Layer (FR-L02)
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
        // Pin pointer needle
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

  // ─── Widget: User GPS Location Pulse Marker ──────────────────────────────
  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.25),
          ),
        ),
        // Inner blue dot
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

  // ─── Widget: Top Header Bar ──────────────────────────────────────────────
  Widget _buildTopHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Back Button
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
            // Title & GPS Status Pill
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
        // My Location GPS Button
        FloatingActionButton.small(
          heroTag: 'btn-my-location',
          backgroundColor: Colors.white,
          foregroundColor: _userLocation != null ? _primaryGreen : Colors.grey,
          tooltip: 'Lokasi Saya (GPS)',
          onPressed: () => _detectUserLocation(showSnackBarOnError: true),
          child: _isLocatingUser
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),
        // Campus Center Reset Button
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
        // Zoom In
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
        // Zoom Out
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
            ItemArtwork(item: item, size: 68),
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

  // ─── Widget: Draggable Bottom Sheet (FR-L03, FR-L04, FR-L05) ─────────────
  Widget _buildDraggableBottomSheet() {
    final filteredItems = _filteredItems;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.32,
      minChildSize: 0.12,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.12, 0.32, 0.65, 0.88],
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
              // Grab Handle & Search / Filter Header
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grab handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // Search Bar (FR-L04)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari laporan di kampus Unand...',
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

                    const SizedBox(height: 10),

                    // Filter Types: Semua, Kehilangan, Ditemukan (FR-L05)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildTypeFilterRow(),
                    ),

                    const SizedBox(height: 8),

                    // Category Filters (FR-L05)
                    _buildCategoryFilterList(),

                    const SizedBox(height: 8),

                    // Summary & Nearby Switch Banner (FR-L06)
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
                          // Radius Filter Toggle (FR-L06)
                          if (_userLocation != null)
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  _onlyNearbyFilter = !_onlyNearbyFilter;
                                });
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
                                      'Radius ≤ 500m',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: _onlyNearbyFilter
                                          ? Colors.white
                                          : _primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                            ? 'Tidak ada laporan yang sesuai filter pencarian.'
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

  // ─── Widget: Filter Kategori Horizontal ──────────────────────────────────
  Widget _buildCategoryFilterList() {
    const categories = [
      'Semua',
      'Elektronik',
      'Aksesori',
      'Dokumen',
      'Lainnya',
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
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
            // Optionally collapse sheet slightly so user can view marker on map
            if (_sheetController.size > 0.45) {
              _sheetController.animateTo(
                0.32,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ItemArtwork(item: item, size: 70),
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

