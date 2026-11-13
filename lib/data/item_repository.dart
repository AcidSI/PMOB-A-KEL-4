import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/utils/campus_locations.dart';
import 'package:find_it/data/lost_item_database.dart';
import 'package:find_it/models/item.dart';

/// Gagal mengirim data ke server (dipakai untuk simulasi & penanganan error).
class ReportSubmitException implements Exception {
  final String message;
  const ReportSubmitException(this.message);
  @override
  String toString() => message;
}

/// Sumber data laporan bersama untuk Modul 1, 2, dan 3. Saat ini berupa data
/// di memori; nanti isi method di bawah diganti panggilan REST API tanpa
/// mengubah layar. Daftar [items] sengaja dibagi (shared) dengan
/// `MatchingService` agar Modul 3 selalu melihat data terbaru.
class ItemRepository {
  ItemRepository({
    List<Item>? items,
    this.fetchDelay = const Duration(seconds: 2),
    this.submitDelay = const Duration(milliseconds: 650),
    DateTime Function()? clock,
  }) : items = items ?? _defaultItems,
       _clock = clock ?? DateTime.now;

  static final List<Item> _defaultItems = [
    for (final lostItem in LostItemDatabase.items)
      Item(
        id: lostItem.id,
        nameItem: lostItem.namaBarang,
        subtitle: 'Hilang di ${lostItem.lokasi}',
        description: lostItem.deskripsi,
        location: lostItem.lokasi,
        isFound: false,
        category: _categoryFor(lostItem.iconCategory),
        ownerId: 'reporter:${lostItem.id}',
        eventDate: _dateFor(lostItem.tanggalHilang),
        color: lostItem.warna,
        brand: lostItem.merek,
        reporter: lostItem.pelapor,
        iconCategory: lostItem.iconCategory,
        assetPath: lostItem.iconCategory == 'wallet'
            ? 'assets/images/dompet.jpg'
            : null,
        latitude: CampusLocations.getCoordinates(
          lostItem.lokasi,
          fallbackSeed: lostItem.id,
        ).latitude,
        longitude: CampusLocations.getCoordinates(
          lostItem.lokasi,
          fallbackSeed: lostItem.id,
        ).longitude,
      ),
    // Sample Found items
    Item(
      id: 'found-earphone-demo',
      nameItem: 'Earphone Bluetooth',
      subtitle: 'Ditemukan di dekat Masjid Unand',
      description:
          'Earphone Bluetooth dalam casing biru muda ditemukan di area '
          'Masjid Ilmi Universitas Andalas.',
      location: 'Masjid Ilmi Unand',
      isFound: true,
      category: 'Elektronik',
      eventDate: DateTime(2026, 10, 9, 10),
      reporter: 'Pemilik laporan',
      ownerId: 'user:founder@student.unand.ac.id',
      latitude: -0.9142,
      longitude: 100.4598,
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
      ownerId: 'reporter:sample-tumbler',
      assetPath: 'assets/images/tumbler.jpg',
      latitude: -0.9148,
      longitude: 100.4596,
    ),
    Item(
      id: 'found-laptop-demo',
      nameItem: 'Laptop ASUS',
      subtitle: 'Ditemukan di Perpustakaan Pusat',
      description: 'Laptop warna silver ditemukan di area baca perpustakaan.',
      location: 'Perpustakaan Pusat',
      isFound: true,
      category: 'Elektronik',
      eventDate: DateTime(2026, 10, 10, 14),
      color: 'Silver',
      brand: 'ASUS',
      reporter: 'Pemilik laporan',
      ownerId: 'user:founder@student.unand.ac.id',
      verificationDetails: const ['Ada stiker kecil di dekat engsel kiri.'],
      latitude: -0.9148,
      longitude: 100.4596,
    ),
    Item(
      id: 'found-wallet-demo',
      nameItem: 'Dompet kulit',
      subtitle: 'Ditemukan di Kantin Fakultas Teknik',
      description: 'Dompet kulit coklat ditemukan di meja kantin.',
      location: 'Kantin Fakultas Teknik',
      isFound: true,
      category: 'Dompet & Kartu',
      eventDate: DateTime(2026, 10, 11, 12),
      color: 'Coklat',
      brand: 'Fossil',
      reporter: 'Pemilik laporan',
      ownerId: 'user:founder@student.unand.ac.id',
      verificationDetails: const [
        'Di dalamnya ada gantungan kunci berbentuk daun.',
      ],
      assetPath: 'assets/images/dompet.jpg',
      latitude: -0.9165,
      longitude: 100.4575,
    ),
    Item(
      id: 'found-001',
      nameItem: 'KTM Mahasiswa Unand',
      subtitle: 'Ditemukan di Perpustakaan Pusat',
      description:
          'Ditemukan Kartu Tanda Mahasiswa atas nama Rian Pratama jurusan Sistem Informasi di meja baca lantai 2.',
      location: 'Perpustakaan Pusat',
      isFound: true,
      category: 'Dompet & Kartu',
      eventDate: DateTime(2026, 10, 14, 11, 30),
      reporter: 'Petugas Perpus',
      ownerId: 'user:petugas@unand.ac.id',
      iconCategory: 'book',
      latitude: -0.91462,
      longitude: 100.45981,
    ),
    Item(
      id: 'found-002',
      nameItem: 'Kunci Motor Honda',
      subtitle: 'Ditemukan di Parkiran Fakultas Ekonomi',
      description:
          'Kunci motor Honda dengan gantungan tali hitam ditemukan di dekat pos satpam parkiran FE.',
      location: 'Parkiran Fakultas Ekonomi',
      isFound: true,
      category: 'Kunci & Kendaraan',
      eventDate: DateTime(2026, 10, 15, 14, 15),
      reporter: 'Satpam FE',
      ownerId: 'user:satpam@unand.ac.id',
      iconCategory: 'key',
      latitude: -0.91800,
      longitude: 100.45900,
    ),
    Item(
      id: 'found-003',
      nameItem: 'Botol Minum Tupperware',
      subtitle: 'Ditemukan di Ruang Kelas GKB 1',
      description:
          'Botol minum Tupperware warna biru toska tertinggal di bawah kursi baris depan.',
      location: 'Ruang Kelas GKB 1',
      isFound: true,
      category: 'Botol & Perlengkapan Makan',
      eventDate: DateTime(2026, 10, 16, 10, 00),
      reporter: 'Cleaning Service',
      ownerId: 'user:cleaning@unand.ac.id',
      iconCategory: 'tumbler',
      latitude: -0.91520,
      longitude: 100.46210,
    ),
  ];

  final List<Item> items;
  final Duration fetchDelay;
  final Duration submitDelay;
  final DateTime Function() _clock;

  /// Untuk pengujian: paksa pengiriman berikutnya gagal (simulasi jaringan).
  bool simulateSubmitFailure = false;

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
      'jacket' || 'glasses' || 'watch' => 'Pakaian & Aksesori',
      'bottle' || 'tumbler' => 'Botol & Perlengkapan Makan',
      _ => 'Lainnya',
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

  /// Daftar laporan untuk ditampilkan. Laporan yang dihapus (soft delete)
  /// disembunyikan; yang kedaluwarsa hanya terlihat oleh pemiliknya.
  Future<List<Item>> fetchItems({
    bool simulateError = false,
    String? viewerId,
  }) async {
    await Future.delayed(fetchDelay);
    if (simulateError) {
      throw Exception('Gagal memuat data. Periksa koneksi internet.');
    }
    return visibleItemsFor(viewerId);
  }

  List<Item> visibleItemsFor(String? viewerId) {
    refreshExpiry();
    return items
        .where(
          (item) =>
              item.status != ReportStatus.removed &&
              (item.status != ReportStatus.expired ||
                  item.isOwnedBy(viewerId)),
        )
        .toList();
  }

  /// Laporan milik [userId] (termasuk kedaluwarsa & selesai, tanpa yang
  /// dihapus), terbaru di atas. Dipakai layar "Laporan Saya".
  List<Item> ownedBy(String? userId) {
    refreshExpiry();
    final owned = items
        .where(
          (item) =>
              item.isOwnedBy(userId) && item.status != ReportStatus.removed,
        )
        .toList();
    owned.sort((a, b) {
      final ta = a.createdAt ?? a.eventDate ?? DateTime(2000);
      final tb = b.createdAt ?? b.eventDate ?? DateTime(2000);
      return tb.compareTo(ta);
    });
    return owned;
  }

  Item? findById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  int _indexOf(String id) {
    final index = items.indexWhere((entry) => entry.id == id);
    if (index == -1) throw StateError('Laporan tidak ditemukan.');
    return index;
  }

  /// FR-R01: menerbitkan laporan baru (status Active, berlaku 90 hari).
  /// Melempar [ReportSubmitException] bila gagal kirim, atau [StateError]
  /// bila melanggar batas laporan harian.
  Future<Item> submit(Item item) async {
    await Future<void>.delayed(submitDelay);
    if (simulateSubmitFailure) {
      simulateSubmitFailure = false;
      throw const ReportSubmitException(
        'Koneksi terputus saat mengirim laporan. Periksa internet lalu coba '
        'lagi. Isian Anda sudah disimpan sebagai draf.',
      );
    }
    return add(item);
  }

  /// Versi sinkron dari [submit] (tanpa jeda jaringan).
  Item add(Item item) {
    final now = _clock();
    final limit = ReportRules.checkRateLimit(items, item.ownerId, now);
    if (limit != null) throw StateError(limit);
    if (items.any((existing) => existing.id == item.id)) {
      throw StateError('Laporan dengan ID yang sama sudah tersedia.');
    }
    final stored = item.copyWith(
      status: ReportStatus.active,
      createdAt: now,
      updatedAt: now,
      expiresAt: ReportRules.expiryFrom(now),
    );
    items.insert(0, stored);
    return stored;
  }

  /// FR-R04: menyimpan hasil edit dan mencatat field yang berubah.
  Future<Item> saveEdit(Item edited) async {
    await Future<void>.delayed(submitDelay);
    if (simulateSubmitFailure) {
      simulateSubmitFailure = false;
      throw const ReportSubmitException(
        'Koneksi terputus saat menyimpan perubahan. Coba lagi.',
      );
    }
    return update(edited);
  }

  Item update(Item edited) {
    final index = _indexOf(edited.id);
    final current = items[index];
    if (current.status != ReportStatus.active &&
        current.status != ReportStatus.inVerification) {
      throw StateError('Laporan dengan status ini tidak dapat diubah.');
    }
    if (!ReportRules.canEditCoreFields(current) &&
        (current.category != edited.category ||
            current.location != edited.location ||
            current.latitude != edited.latitude ||
            current.verificationDetails.join() !=
                edited.verificationDetails.join())) {
      throw StateError(
        'Kategori, lokasi, dan detail pembeda dikunci selama verifikasi klaim.',
      );
    }
    final now = _clock();
    final changed = ReportRules.changedFields(current, edited);
    final stored = edited.copyWith(
      // Status bisa saja diubah Modul 3 selama form edit terbuka.
      status: current.status,
      updatedAt: now,
      editHistory: changed.isEmpty
          ? current.editHistory
          : [...current.editHistory, ReportEdit(at: now, fields: changed)],
    );
    items[index] = stored;
    return stored;
  }

  /// FR-R05: soft delete (status Removed). Ditolak selama verifikasi klaim.
  void softDelete(String id, {required String? userId}) {
    final index = _indexOf(id);
    final current = items[index];
    if (!current.isOwnedBy(userId)) {
      throw StateError('Hanya pemilik laporan yang dapat menghapus.');
    }
    if (!ReportRules.canDelete(current, userId)) {
      throw StateError(
        'Laporan tidak dapat dihapus karena sedang dalam verifikasi klaim.',
      );
    }
    current.status = ReportStatus.removed;
    items[index] = current.copyWith(updatedAt: _clock());
  }

  /// Pemilik menutup laporan, mis. barang sudah ketemu sendiri.
  Item close(String id, {required String? userId, required String reason}) {
    final index = _indexOf(id);
    final current = items[index];
    if (!ReportRules.canClose(current, userId)) {
      throw StateError('Laporan ini tidak dapat ditutup saat ini.');
    }
    final closed = current.copyWith(
      status: ReportStatus.resolved,
      closedReason: reason,
      updatedAt: _clock(),
    );
    items[index] = closed;
    return closed;
  }

  /// FR-R10: memperpanjang masa berlaku 90 hari dan mengaktifkan kembali.
  Item extend(String id, {required String? userId}) {
    final index = _indexOf(id);
    final current = items[index];
    if (!ReportRules.canExtend(current, userId)) {
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
  /// Dipanggil setiap daftar dimuat; nanti dikerjakan job terjadwal server.
  void refreshExpiry() {
    final now = _clock();
    for (final item in items) {
      if (ReportRules.isPastExpiry(item, now)) {
        item.status = ReportStatus.expired;
      }
    }
  }
}
