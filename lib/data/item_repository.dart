import 'lost_item_database.dart';
import '../models/item.dart';
import '../utils/campus_locations.dart';

class ItemRepository {
  ItemRepository({
    List<Item>? items,
    this.fetchDelay = const Duration(seconds: 2),
  }) : items = items ?? _defaultItems;

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
    Item(
      id: 'sample-tumbler',
      nameItem: 'Tumbler Hijau',
      subtitle: 'Hilang di sekitar perpustakaan',
      description:
          'Tumbler berwarna hijau tertinggal di sekitar Perpustakaan '
          'Universitas Andalas.',
      location: 'Perpustakaan',
      isFound: false,
      category: 'Lainnya',
      color: 'Hijau',
      brand: 'smätt',
      reporter: 'Pelapor',
      assetPath: 'assets/images/tumbler.jpg',
      latitude: -0.91462,
      longitude: 100.45981,
    ),
    Item(
      id: 'found-001',
      nameItem: 'KTM Mahasiswa Unand',
      subtitle: 'Ditemukan di Perpustakaan Pusat',
      description:
          'Ditemukan Kartu Tanda Mahasiswa atas nama Rian Pratama jurusan Sistem Informasi di meja baca lantai 2.',
      location: 'Perpustakaan Pusat',
      isFound: true,
      category: 'Dokumen',
      eventDate: DateTime(2026, 10, 14, 11, 30),
      reporter: 'Petugas Perpus',
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
      category: 'Aksesori',
      eventDate: DateTime(2026, 10, 15, 14, 15),
      reporter: 'Satpam FE',
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
      category: 'Lainnya',
      eventDate: DateTime(2026, 10, 16, 10, 00),
      reporter: 'Cleaning Service',
      iconCategory: 'tumbler',
      latitude: -0.91520,
      longitude: 100.46210,
    ),
    
  ];

  final List<Item> items;
  final Duration fetchDelay;

  static String _categoryFor(String iconCategory) {
    return switch (iconCategory) {
      'laptop' ||
      'phone' ||
      'battery' ||
      'earphone' ||
      'storage' ||
      'charger' ||
      'tablet' => 'Elektronik',
      'book' => 'Dokumen',
      _ => 'Aksesori',
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

  Future<List<Item>> fetchItems({bool simulateError = false}) async {
    await Future.delayed(fetchDelay);
    if (simulateError) {
      throw Exception('Gagal memuat data. Periksa koneksi internet.');
    }
    return items;
  }
}