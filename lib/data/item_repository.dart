import 'lost_item_database.dart';
import '../models/item.dart';

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
        ownerId: 'reporter:${lostItem.id}',
        eventDate: _dateFor(lostItem.tanggalHilang),
        color: lostItem.warna,
        brand: lostItem.merek,
        reporter: lostItem.pelapor,
        iconCategory: lostItem.iconCategory,
        assetPath: lostItem.iconCategory == 'wallet'
            ? 'assets/images/dompet.jpg'
            : null,
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
      ownerId: 'reporter:sample-tumbler',
      assetPath: 'assets/images/tumbler.jpg',
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
      'wallet' => 'Dompet & Kartu',
      'book' => 'Dokumen & Perlengkapan Kuliah',
      'bag' => 'Tas & Ransel',
      'key' || 'bicycle' => 'Kunci & Kendaraan',
      'bottle' => 'Botol & Perlengkapan Makan',
      'jacket' || 'glasses' || 'watch' => 'Pakaian & Aksesori',
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

  Future<List<Item>> fetchItems({bool simulateError = false}) async {
    await Future.delayed(fetchDelay);
    if (simulateError) {
      throw Exception('Gagal memuat data. Periksa koneksi internet.');
    }
    return items;
  }
}
