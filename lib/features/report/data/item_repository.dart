import 'package:find_it/features/report/data/lost_item_database.dart';
import 'package:find_it/features/report/domain/report_rules.dart';
import 'package:find_it/features/report/models/report.dart';
import 'package:find_it/features/report/models/report_category.dart';

/// Repository laporan. Saat ini berupa data tiruan di memori; nanti diganti
/// implementasi yang memanggil REST API tanpa mengubah layar.
class ItemRepository {
  ItemRepository({
    List<Item>? items,
    this.fetchDelay = const Duration(seconds: 2),
    DateTime Function()? clock,
  })  : items = items ?? _defaultItems,
        _clock = clock ?? DateTime.now;

  static final List<Item> _defaultItems = _buildDefaultItems();

  static List<Item> _buildDefaultItems() {
    final now = DateTime.now();
    return [
      for (final lostItem in LostItemDatabase.items)
        Item(
          id: lostItem.id,
          nameItem: lostItem.namaBarang,
          subtitle: 'Hilang di ${lostItem.lokasi}',
          description: lostItem.deskripsi,
          location: lostItem.lokasi,
          isFound: false,
          category: _categoryFor(lostItem.iconCategory),
          eventDate: _dateFor(lostItem.tanggalHilang),
          color: lostItem.warna,
          brand: lostItem.merek,
          reporter: lostItem.pelapor,
          iconCategory: lostItem.iconCategory,
          assetPath: lostItem.iconCategory == 'wallet'
              ? 'assets/images/dompet.jpg'
              : null,
          createdAt: now,
          updatedAt: now,
          expiresAt: ReportRules.expiryFrom(now),
        ),
      Item(
        id: 'sample-tumbler',
        nameItem: 'Tumbler Hijau',
        subtitle: 'Hilang di sekitar perpustakaan',
        description:
            'Tumbler berwarna hijau tertinggal di sekitar Perpustakaan '
            'Universitas Andalas.',
        location: 'Perpustakaan',
        isFound: false,
        category: 'Botol & Perlengkapan Makan',
        color: 'Hijau',
        brand: 'smätt',
        reporter: 'Pelapor',
        assetPath: 'assets/images/tumbler.jpg',
        createdAt: now,
        updatedAt: now,
        expiresAt: ReportRules.expiryFrom(now),
      ),
    ];
  }

  final List<Item> items;
  final Duration fetchDelay;
  final DateTime Function() _clock;

  /// Memetakan ikon data lama ke 10 kategori baku (PRD 2.2).
  static String _categoryFor(String iconCategory) {
    return switch (iconCategory) {
      'laptop' ||
      'phone' ||
      'battery' ||
      'earphone' ||
      'storage' ||
      'charger' ||
      'tablet' =>
        'Elektronik',
      'wallet' => 'Dompet & Kartu',
      'bag' => 'Tas & Ransel',
      'key' || 'bicycle' => 'Kunci & Kendaraan',
      'book' => 'Dokumen & Perlengkapan Kuliah',
      'glasses' || 'jacket' || 'watch' => 'Pakaian & Aksesori',
      _ => ReportCategories.lainnya,
    };
  }

  static DateTime? _dateFor(String label) {
    final parts = label.split(' ');
    if (parts.length != 3) return null;
    const months = {
      'Januari': 1,
      'Februari': 2,
      'Maret': 3,
      'April': 4,
      'Mei': 5,
      'Juni': 6,
      'Juli': 7,
      'Agustus': 8,
      'September': 9,
      'Oktober': 10,
      'November': 11,
      'Desember': 12,
    };
    final day = int.tryParse(parts[0]);
    final month = months[parts[1]];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  /// Laporan yang boleh tampil di daftar: yang dihapus disembunyikan, dan
  /// yang kedaluwarsa hanya terlihat oleh pemiliknya (agar dapat diperpanjang).
  List<Item> get visibleItems {
    refreshExpiry();
    return items
        .where(
          (item) =>
              item.status != ReportStatus.removed &&
              (item.status != ReportStatus.expired || item.isOwner),
        )
        .toList();
  }

  Future<List<Item>> fetchItems({bool simulateError = false}) async {
    await Future.delayed(fetchDelay);
    if (simulateError) {
      throw Exception('Gagal memuat data. Periksa koneksi internet.');
    }
    return visibleItems;
  }

  Item? findById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// FR-R01: menerbitkan laporan baru (status Active, berlaku 90 hari).
  Item add(Item item) {
    final now = _clock();
    final stored = item.copyWith(
      status: ReportStatus.active,
      createdAt: now,
      updatedAt: now,
      expiresAt: ReportRules.expiryFrom(now),
    );
    items.insert(0, stored);
    return stored;
  }

  /// FR-R04: menyimpan hasil edit.
  Item update(Item item) {
    final index = items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) throw StateError('Laporan tidak ditemukan.');
    final stored = item.copyWith(updatedAt: _clock());
    items[index] = stored;
    return stored;
  }

  /// FR-R05: soft delete. Ditolak jika ada klaim Pending (FR-R09).
  void softDelete(String id) {
    final index = items.indexWhere((entry) => entry.id == id);
    if (index == -1) throw StateError('Laporan tidak ditemukan.');
    final current = items[index];
    if (!ReportRules.canDelete(current)) {
      throw StateError(
        'Laporan tidak dapat dihapus karena sedang dalam verifikasi klaim.',
      );
    }
    items[index] = current.copyWith(
      status: ReportStatus.removed,
      updatedAt: _clock(),
    );
  }

  /// FR-R10: memperpanjang masa berlaku 90 hari dan mengaktifkan kembali.
  Item extend(String id) {
    final index = items.indexWhere((entry) => entry.id == id);
    if (index == -1) throw StateError('Laporan tidak ditemukan.');
    final current = items[index];
    if (!ReportRules.canExtend(current)) {
      throw StateError('Laporan ini tidak dapat diperpanjang.');
    }
    final now = _clock();
    final extended = current.copyWith(
      status: ReportStatus.active,
      expiresAt: ReportRules.expiryFrom(now),
      updatedAt: now,
    );
    items[index] = extended;
    return extended;
  }

  /// FR-R10: laporan Active yang lewat masa berlaku menjadi Expired.
  /// Dipanggil setiap daftar dimuat; nanti dikerjakan job terjadwal di server.
  void refreshExpiry() {
    final now = _clock();
    for (var i = 0; i < items.length; i++) {
      if (ReportRules.isPastExpiry(items[i], now)) {
        items[i] = items[i].copyWith(status: ReportStatus.expired);
      }
    }
  }
}
