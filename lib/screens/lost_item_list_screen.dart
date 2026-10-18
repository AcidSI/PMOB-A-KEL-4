import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/item_repository.dart';
import '../models/item.dart';
import '../models/lost_item.dart';
import '../data/lost_item_database.dart';
import 'item_detail_screen.dart';

class LostItemListScreen extends StatefulWidget {
  const LostItemListScreen({super.key});

  @override
  State<LostItemListScreen> createState() => _LostItemListScreenState();
}

class _LostItemListScreenState extends State<LostItemListScreen>
    with SingleTickerProviderStateMixin {
  late final List<LostItem> _items;

  // ─── State ───────────────────────────────────────────────────────────────
  bool _isSearchExpanded = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _searchResults = [];

  final _namaController = TextEditingController();
  final _warnaController = TextEditingController();
  final _merekController = TextEditingController();
  final _lokasiController = TextEditingController();
  String? _namaError;

  late final AnimationController _searchPanelCtrl;
  late final Animation<double> _searchPanelAnim;

  // ─── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _items = ItemRepository().items
        .where((item) => !item.isFound)
        .map(_toLostItem)
        .toList();
    _searchPanelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _searchPanelAnim = CurvedAnimation(
      parent: _searchPanelCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchPanelCtrl.dispose();
    _namaController.dispose();
    _warnaController.dispose();
    _merekController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  // ─── Logic ───────────────────────────────────────────────────────────────
  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _searchPanelCtrl.forward();
      } else {
        _searchPanelCtrl.reverse();
        _hasSearched = false;
        _searchResults = [];
        _namaController.clear();
        _warnaController.clear();
        _merekController.clear();
        _lokasiController.clear();
        _namaError = null;
      }
    });
  }

  void _doSearch() {
    final nama = _namaController.text.trim();
    if (nama.isEmpty) {
      setState(() => _namaError = 'Wajib diisi');
      return;
    }

    // Tutup panel pencarian otomatis setelah menekan Cari
    _searchPanelCtrl.reverse();
    setState(() {
      _namaError = null;
      _hasSearched = true;
      _isSearchExpanded = false;
      _searchResults = LostItemDatabase.search(
        namaBarang: nama,
        warna: _warnaController.text.trim(),
        merek: _merekController.text.trim(),
        lokasi: _lokasiController.text.trim(),
        sourceItems: _items,
      );
    });
  }

  void _resetSearch() {
    setState(() {
      _hasSearched = false;
      _searchResults = [];
      _namaController.clear();
      _warnaController.clear();
      _merekController.clear();
      _lokasiController.clear();
      _namaError = null;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final displayItems = _hasSearched
        ? _searchResults
        : _items.map((e) => {'item': e, 'score': null}).toList();

    // Scaffold: kerangka halaman dan latar belakang.
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      // CustomScrollView: menggabungkan AppBar dan konten dalam satu guliran.
      body: CustomScrollView(
        slivers: [
          // SliverAppBar: header halaman yang dapat menyusut saat digulir.
          _buildAppBar(),
          // SliverToBoxAdapter: membungkus tombol pencarian sebagai sliver.
          SliverToBoxAdapter(child: _buildSearchButton()),
          // SliverToBoxAdapter + SizeTransition: panel pencarian yang beranimasi.
          SliverToBoxAdapter(
            child: SizeTransition(
              sizeFactor: _searchPanelAnim,
              alignment: Alignment.topCenter,
              child: _buildSearchPanel(),
            ),
          ),
          // Header jumlah hasil hanya ditampilkan setelah pencarian.
          if (_hasSearched)
            SliverToBoxAdapter(child: _buildSearchResultHeader()),
          // SliverFillRemaining: menempatkan ilustrasi saat hasil kosong.
          if (displayItems.isEmpty && _hasSearched)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          // SliverList: menampilkan daftar kartu barang.
          else
            _buildItemList(displayItems),
        ],
      ),
    );
  }

  LostItem _toLostItem(Item item) {
    return LostItem(
      id: item.id,
      namaBarang: item.nameItem,
      warna: item.color ?? 'Belum diketahui',
      merek: item.brand ?? 'Belum diketahui',
      lokasi: item.location,
      deskripsi: item.description,
      tanggalHilang: item.eventDateLabel,
      pelapor: item.reporter ?? (item.isOwner ? 'Anda' : 'Pelapor'),
      iconCategory: item.iconCategory ?? 'other',
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    // SliverAppBar: AppBar pinned dengan latar FlexibleSpaceBar.
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      // stretch dinonaktifkan agar gambar no-result tidak terzoom saat pull-down
      stretch: false,
      backgroundColor: const Color(0xFF045436),
      // Judul collapsed (hanya muncul saat AppBar menyusut penuh)
      title: Text(
        'Find!t',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      // FlexibleSpaceBar: area latar dan identitas halaman saat AppBar terbuka.
      flexibleSpace: FlexibleSpaceBar(
        // collapseMode.pin agar background tidak ikut naik
        collapseMode: CollapseMode.pin,
        // TIDAK ada title di sini agar tidak menimpa konten background
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF045436), Color(0xFF0B6670)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          // SafeArea: menjaga konten header dari area status bar.
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              // Column: menumpuk identitas aplikasi dan deskripsi secara vertikal.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Row: ikon, nama aplikasi, dan label kampus dalam satu baris.
                  Row(
                    children: [
                      // Container: bidang dekoratif di belakang ikon pencarian.
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Icon: ikon pencarian pada header.
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text: nama aplikasi pada header.
                      Text(
                        'Find!t',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      // Container: label kampus UNAND.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6F00),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        // Text: teks label kampus.
                        child: Text(
                          'UNAND',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Text: keterangan singkat halaman.
                  Text(
                    'Daftar Barang Hilang',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Search toggle button ─────────────────────────────────────────────────
  Widget _buildSearchButton() {
    // Padding + Row: memberi jarak luar dan menyediakan tombol selebar area.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Expanded: tombol mengisi lebar yang tersedia.
          Expanded(
            // AnimatedContainer: tombol dengan warna transisi saat panel dibuka.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 46,
              decoration: BoxDecoration(
                gradient: _isSearchExpanded
                    ? const LinearGradient(
                        colors: [Color(0xFF0B6670), Color(0xFF73C47A)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF045436), Color(0xFF0B6670)],
                      ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B6670).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              // Material + InkWell: area tombol dengan efek sentuh.
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _toggleSearch,
                  // Row: ikon dan label tombol pencarian.
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // AnimatedRotation: memutar ikon saat status tombol berubah.
                      AnimatedRotation(
                        turns: _isSearchExpanded ? 0.125 : 0,
                        duration: const Duration(milliseconds: 300),
                        // Icon: ikon pencarian pada tombol.
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Text: label berubah mengikuti status panel.
                      Text(
                        _isSearchExpanded
                            ? 'Tutup Pencarian'
                            : 'Cari Barang Hilang',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search panel ─────────────────────────────────────────────────────────
  Widget _buildSearchPanel() {
    // Container: panel putih yang membungkus judul, field, dan tombol pencarian.
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Column: menyusun isi panel pencarian secara vertikal.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text: judul panel.
          Text(
            'Filter Pencarian',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: const Color(0xFF045436),
            ),
          ),
          const SizedBox(height: 4),
          // Text: keterangan bobot dan syarat pencarian.
          Text(
            'Nama barang wajib diisi. Bobot: Nama 40% · Warna 20% · Merek 20% · Lokasi 20%',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 14),
          // Search field: nama barang, satu-satunya field wajib.
          _buildSearchField(
            controller: _namaController,
            label: 'Nama Barang *',
            hint: 'mis. Laptop, Dompet, Kacamata...',
            icon: Icons.inventory_2_outlined,
            errorText: _namaError,
            onChanged: (_) {
              if (_namaError != null) setState(() => _namaError = null);
            },
          ),
          const SizedBox(height: 10),
          // Search field: filter warna barang.
          _buildSearchField(
            controller: _warnaController,
            label: 'Warna Barang',
            hint: 'mis. Hitam, Merah, Silver...',
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 10),
          // Search field: filter merek barang.
          _buildSearchField(
            controller: _merekController,
            label: 'Merek',
            hint: 'mis. Samsung, Apple, ASUS...',
            icon: Icons.branding_watermark_outlined,
          ),
          const SizedBox(height: 10),
          // Search field: filter lokasi terakhir barang.
          _buildSearchField(
            controller: _lokasiController,
            label: 'Lokasi Terakhir',
            hint: 'mis. Perpustakaan, Kantin...',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          // Row: tombol reset (opsional) dan tombol cari.
          Row(
            children: [
              if (_hasSearched)
                Expanded(
                  // OutlinedButton.icon: mengosongkan filter dan hasil pencarian.
                  child: OutlinedButton.icon(
                    onPressed: _resetSearch,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      'Reset',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B6670),
                      side: const BorderSide(color: Color(0xFF0B6670)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (_hasSearched) const SizedBox(width: 10),
              // Expanded: tombol Cari mendapat ruang lebih besar dari tombol Reset.
              Expanded(
                flex: 2,
                // Container: latar gradasi tombol Cari.
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF045436), Color(0xFF0B6670)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B6670).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  // Material + InkWell: tombol Cari dengan efek sentuh.
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _doSearch,
                      // Padding: tinggi tombol dan area sentuh.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        // Row: ikon dan teks tombol Cari.
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon: ikon pencarian tombol.
                            const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            // Text: label tombol.
                            Text(
                              'Cari',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    // Column: label, TextField, dan pesan error untuk satu filter.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text: label field.
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF045436),
          ),
        ),
        const SizedBox(height: 4),
        // TextField: input nilai filter.
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF73C47A), size: 20),
            errorText: errorText,
            errorStyle: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFF4F6FC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E4F0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0B6670),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ],
    );
  }

  // ─── Search result header ─────────────────────────────────────────────────
  Widget _buildSearchResultHeader() {
    // Padding + Row: membungkus status hasil dalam satu baris.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      // Row: menempatkan chip status hasil.
      child: Row(
        children: [
          // Container: chip dengan warna berbeda untuk hasil kosong dan ditemukan.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
            decoration: BoxDecoration(
              color: _searchResults.isEmpty
                  ? Colors.orange[50]
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _searchResults.isEmpty
                    ? Colors.orange[200]!
                    : const Color(0xFF73C47A),
              ),
            ),
            // Text: jumlah hasil atau status tidak ditemukan.
            child: Text(
              _searchResults.isEmpty
                  ? 'Tidak ada hasil'
                  : '${_searchResults.length} barang ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: _searchResults.isEmpty
                    ? Colors.orange[800]
                    : const Color(0xFF045436),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Item list ────────────────────────────────────────────────────────────
  Widget _buildItemList(List<Map<String, dynamic>> items) {
    // SliverPadding + SliverList: daftar kartu barang dengan jarak tepi.
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        // SliverChildBuilderDelegate: membuat kartu hanya saat diperlukan.
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final item = items[i]['item'] as LostItem;
          // _ItemCard: widget kartu untuk satu barang.
          return _ItemCard(item: item);
        }, childCount: items.length),
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    // Center + Image: menampilkan ilustrasi ketika pencarian tidak menemukan barang.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Image.asset(
          'assets/images/no_results.png',
          // scaleDown memastikan gambar tidak membesar melebihi ukuran aslinya
          fit: BoxFit.scaleDown,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Item Card Widget
// ═══════════════════════════════════════════════════════════════════════════
class _ItemCard extends StatefulWidget {
  final LostItem item;

  const _ItemCard({required this.item});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _isPressed = false;

  IconData _getIcon(String category) {
    switch (category) {
      case 'laptop':
        return Icons.laptop_rounded;
      case 'phone':
        return Icons.smartphone_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'glasses':
        return Icons.visibility_rounded;
      case 'bag':
        return Icons.backpack_rounded;
      case 'battery':
        return Icons.battery_charging_full_rounded;
      case 'earphone':
        return Icons.headphones_rounded;
      case 'jacket':
        return Icons.dry_cleaning_rounded;
      case 'storage':
        return Icons.usb_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'charger':
        return Icons.cable_rounded;
      case 'bicycle':
        return Icons.directions_bike_rounded;
      case 'key':
        return Icons.key_rounded;
      case 'tablet':
        return Icons.tablet_rounded;
      case 'watch':
        return Icons.watch_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'laptop':
        return const Color(0xFF0B6670);
      case 'phone':
        return const Color(0xFF00897B);
      case 'wallet':
        return const Color(0xFF6D4C41);
      case 'glasses':
        return const Color(0xFF546E7A);
      case 'bag':
        return const Color(0xFF1565C0);
      case 'battery':
        return const Color(0xFF2E7D32);
      case 'earphone':
        return const Color(0xFF6A1B9A);
      case 'jacket':
        return const Color(0xFFC62828);
      case 'storage':
        return const Color(0xFFE65100);
      case 'book':
        return const Color(0xFF558B2F);
      case 'charger':
        return const Color(0xFF37474F);
      case 'bicycle':
        return const Color(0xFF00838F);
      case 'key':
        return const Color(0xFFF57F17);
      case 'tablet':
        return const Color(0xFF4527A0);
      case 'watch':
        return const Color(0xFF880E4F);
      default:
        return const Color(0xFF0B6670);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(widget.item.iconCategory);

    // GestureDetector: menangani tap dan status tekan pada kartu.
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(item: widget.item),
          ),
        );
      },
      // AnimatedScale: mengecilkan kartu sebentar saat ditekan.
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        // Container: permukaan kartu barang.
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          // Padding: jarak isi kartu dari tepi.
          child: Padding(
            padding: const EdgeInsets.all(14),
            // Row: ikon kategori di samping detail barang.
            child: Row(
              children: [
                // Icon container
                // Container: bidang berwarna untuk ikon kategori.
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  // Icon: ikon sesuai kategori barang.
                  child: Icon(
                    _getIcon(widget.item.iconCategory),
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                // Expanded: detail mengisi sisa lebar kartu.
                Expanded(
                  // Column: nama, informasi, tanggal, dan tautan detail.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text: nama barang.
                      Text(
                        widget.item.namaBarang,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF045436),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // _InfoRow: baris informasi warna.
                      _InfoRow(
                        icon: Icons.palette_outlined,
                        text: widget.item.warna,
                        color: color,
                      ),
                      const SizedBox(height: 2),
                      // _InfoRow: baris informasi merek.
                      _InfoRow(
                        icon: Icons.branding_watermark_outlined,
                        text: widget.item.merek,
                        color: color,
                      ),
                      const SizedBox(height: 2),
                      // _InfoRow: baris informasi lokasi.
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: widget.item.lokasi,
                        color: color,
                      ),
                      const SizedBox(height: 6),
                      // Row: tanggal kehilangan dan petunjuk membuka detail.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Text: tanggal barang hilang.
                          Text(
                            widget.item.tanggalHilang,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          // Row: teks Detail dan ikon arah.
                          Row(
                            children: [
                              // Text: label navigasi detail.
                              Text(
                                'Detail',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Icon: penunjuk arah ke halaman detail.
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 11,
                                color: color,
                              ),
                            ],
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    // Row: ikon metadata dan teks yang dapat terpotong jika terlalu panjang.
    return Row(
      children: [
        // Icon: penanda jenis metadata.
        Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        // Expanded: membatasi teks ke ruang yang tersedia.
        Expanded(
          // Text: nilai metadata barang.
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
