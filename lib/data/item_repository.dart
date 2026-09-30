import '../models/item.dart';

// Dataset tetap mengikuti tiga laporan yang tampil pada desain terlampir.
class ItemRepository {
  const ItemRepository({
    this.items = _items,
    this.fetchDelay = const Duration(seconds: 2),
  });

  static const List<Item> _items = [
    Item(
      id: '1',
      title: 'Earphone Bluetooth',
      subtitle: 'Ditemukan di dekat Masjid Unand',
      description:
          'Earphone Bluetooth dalam casing biru muda ditemukan di area '
          'Masjid Ilmi Universitas Andalas.',
      location: 'Masjid Ilmi Unand',
      timeAgo: '2 jam yang lalu',
      isFound: true,
    ),
    Item(
      id: '2',
      title: 'Tumbler Hijau',
      subtitle: 'Hilang di sekitar perpustakaan',
      description:
          'Tumbler berwarna hijau tertinggal di sekitar Perpustakaan '
          'Universitas Andalas.',
      location: 'Perpustakaan',
      timeAgo: '10 menit yang lalu',
      isFound: false,
    ),
    Item(
      id: '3',
      title: 'Dompet Kulit Coklat',
      subtitle: 'Ditemukan di dekat Pusat Bahasa Unand',
      description:
          'Dompet kulit berwarna coklat ditemukan di sekitar Pusat Bahasa '
          'Universitas Andalas.',
      location: 'Pusat Bahasa',
      timeAgo: '1 jam yang lalu',
      isFound: true,
    ),
  ];

  final List<Item> items;
  final Duration fetchDelay;

  Future<List<Item>> fetchItems({bool simulateError = false}) async {
    await Future.delayed(fetchDelay);
    if (simulateError) {
      throw Exception('Gagal memuat data. Periksa koneksi internet.');
    }
    return items;
  }
}