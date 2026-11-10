import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../utils/campus_locations.dart';

/// Hasil pemilihan lokasi kampus dari Peta Interaktif
class CampusLocationResult {
  final String locationName;
  final double latitude;
  final double longitude;
  final String buildingName;

  const CampusLocationResult({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.buildingName,
  });
}

/// Layar Pemilih Lokasi Interaktif Kampus Unand ala Google Maps (FR-L01)
/// Fitur:
/// - Peta kampus interaktif dengan pin mengambang di tengah (Center Pin)
/// - Deteksi otomatis gedung/area kampus terdekat secara live saat peta digeser
/// - Pencarian cepat nama gedung/fakultas untuk langsung mengarahkan kamera
/// - Tombol GPS "Lokasi Saya" untuk langsung menyorot posisi pengguna di kampus
/// - Konfirmasi titik lokasi akurat ke formulir pelaporan
class CampusLocationPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;
  final String? initialLocationName;

  const CampusLocationPickerScreen({
    super.key,
    this.initialCenter,
    this.initialLocationName,
  });

  @override
  State<CampusLocationPickerScreen> createState() =>
      _CampusLocationPickerScreenState();
}

class _CampusLocationPickerScreenState extends State<CampusLocationPickerScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF045436);
  static const Color _accentGreen = Color(0xFF73C47A);

  final MapController _mapController = MapController();
  final LocationService _locationService = const LocationService();
  final TextEditingController _searchController = TextEditingController();

  late LatLng _currentCenter;
  String _detectedBuilding = 'Mendeteksi gedung...';
  double _distanceToBuilding = 0.0;
  bool _isMapMoving = false;
  bool _isLocatingUser = false;
  List<String> _filteredLandmarks = [];
  bool _showSearchOverlay = false;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialCenter ??
        (widget.initialLocationName != null &&
                widget.initialLocationName!.trim().isNotEmpty
            ? CampusLocations.getCoordinates(widget.initialLocationName)
            : CampusLocations.unandCenter);

    _updateDetectedLocation(_currentCenter);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _updateDetectedLocation(LatLng center) {
    final details = CampusLocations.getNearestLandmarkDetails(center);
    setState(() {
      _currentCenter = center;
      _detectedBuilding = details.name;
      _distanceToBuilding = details.distanceMeters;
    });
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!_isMapMoving) {
      setState(() => _isMapMoving = true);
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _isMapMoving = false);
        _updateDetectedLocation(camera.center);
      }
    });
  }

  void _moveToLocation(LatLng target, {String? landmarkName}) {
    _mapController.move(target, 17.5);
    setState(() {
      _currentCenter = target;
      if (landmarkName != null) {
        _detectedBuilding = landmarkName;
        _distanceToBuilding = 0.0;
      }
      _showSearchOverlay = false;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _detectCurrentGpsLocation() async {
    if (_isLocatingUser) return;
    setState(() => _isLocatingUser = true);

    final res = await _locationService.determinePosition();
    if (!mounted) return;
    setState(() => _isLocatingUser = false);

    if (res.isSuccess && res.position != null) {
      _moveToLocation(res.position!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GPS terdeteksi di sekitar $_detectedBuilding',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message, style: GoogleFonts.poppins(fontSize: 12)),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _filterLandmarks(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filteredLandmarks = [];
        _showSearchOverlay = false;
      });
      return;
    }

    final matches = CampusLocations.landmarkNames.where((name) {
      return name.toLowerCase().contains(q);
    }).toList();

    setState(() {
      _filteredLandmarks = matches;
      _showSearchOverlay = true;
    });
  }

  void _confirmSelectedLocation() {
    final result = CampusLocationResult(
      locationName: _detectedBuilding,
      latitude: _currentCenter.latitude,
      longitude: _currentCenter.longitude,
      buildingName: _detectedBuilding,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Interactive Campus Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 17.0,
              minZoom: 13.5,
              maxZoom: 19.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'id.ac.unand.find_it',
                maxZoom: 19,
              ),

              // Landmark Labels on Map
              MarkerLayer(
                markers: CampusLocations.landmarks.entries.map((entry) {
                  return Marker(
                    point: entry.value,
                    width: 100,
                    height: 28,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Google Maps-style Center Pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 38), // Pin tip alignment
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                offset: _isMapMoving ? const Offset(0, -0.25) : Offset.zero,
                curve: Curves.easeOutCubic,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: Text(
                        _isMapMoving ? 'Lepas untuk memilih...' : 'Titik Lokasi',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFC62828),
                      size: 44,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pin Ground Target Dot
          Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Floating Search Bar (Gedung/Fakultas)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white,
                        elevation: 4,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: _primaryGreen),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterLandmarks,
                            decoration: InputDecoration(
                              hintText: 'Cari nama gedung atau fakultas...',
                              hintStyle: GoogleFonts.poppins(fontSize: 12),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: _primaryGreen,
                                size: 20,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterLandmarks('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Search Suggestions Overlay List
                  if (_showSearchOverlay && _filteredLandmarks.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8, left: 48),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _filteredLandmarks.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, idx) {
                          final name = _filteredLandmarks[idx];
                          final coords = CampusLocations.landmarks[name]!;
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.apartment_rounded,
                              color: _primaryGreen,
                              size: 20,
                            ),
                            title: Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () =>
                                _moveToLocation(coords, landmarkName: name),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 4. Floating Action Buttons (GPS & Center Campus)
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'picker-gps-btn',
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryGreen,
                  tooltip: 'Lokasi Saya (GPS)',
                  onPressed: _detectCurrentGpsLocation,
                  child: _isLocatingUser
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'picker-center-campus',
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryGreen,
                  tooltip: 'Pusat Kampus Unand',
                  onPressed: () {
                    _moveToLocation(
                      CampusLocations.unandCenter,
                      landmarkName: 'Pusat Kampus Unand',
                    );
                  },
                  child: const Icon(Icons.school_outlined),
                ),
              ],
            ),
          ),

          // 5. Bottom Location Confirmation Sheet (Google Maps Style)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: _primaryGreen,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gedung / Area Terdeteksi',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _detectedBuilding,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Status Jarak & Koordinat GPS
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _distanceToBuilding <= 100
                                ? '✓ Tepat di kawasan gedung'
                                : '±${_distanceToBuilding.round()}m dari gedung',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _distanceToBuilding <= 100
                                  ? _primaryGreen
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Primary Confirmation Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _confirmSelectedLocation,
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          'Gunakan Lokasi Ini',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}
