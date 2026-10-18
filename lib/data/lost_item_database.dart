import '../models/lost_item.dart';

class LostItemDatabase {
  static const List<LostItem> items = [
    LostItem(
      id: '001',
      namaBarang: 'Laptop',
      warna: 'Silver',
      merek: 'ASUS',
      lokasi: 'Perpustakaan Pusat',
      deskripsi:
          'Laptop ASUS ROG warna silver dengan stiker logo Unand di bagian belakang. Hilang saat meninggalkan area baca.',
      tanggalHilang: '10 Oktober 2026',
      pelapor: 'Ahmad Fauzi',
      iconCategory: 'laptop',
    ),
    LostItem(
      id: '002',
      namaBarang: 'Dompet',
      warna: 'Coklat',
      merek: 'Fossil',
      lokasi: 'Kantin Fakultas Teknik',
      deskripsi:
          'Dompet kulit berwarna coklat merk Fossil. Berisi KTM, SIM, dan beberapa kartu ATM.',
      tanggalHilang: '11 Oktober 2026',
      pelapor: 'Sari Dewi',
      iconCategory: 'wallet',
    ),
    LostItem(
      id: '003',
      namaBarang: 'Handphone',
      warna: 'Hitam',
      merek: 'Samsung',
      lokasi: 'Ruang Kelas GKB 1',
      deskripsi:
          'Samsung Galaxy A54 warna hitam dengan casing transparan. Hilang di ruang kelas lantai 3.',
      tanggalHilang: '9 Oktober 2026',
      pelapor: 'Budi Santoso',
      iconCategory: 'phone',
    ),
    LostItem(
      id: '004',
      namaBarang: 'Kacamata',
      warna: 'Hitam',
      merek: 'Oakley',
      lokasi: 'Lapangan Olahraga',
      deskripsi:
          'Kacamata minus frame hitam merek Oakley. Hilang saat kegiatan olahraga di lapangan.',
      tanggalHilang: '8 Oktober 2026',
      pelapor: 'Rizki Pratama',
      iconCategory: 'glasses',
    ),
    LostItem(
      id: '005',
      namaBarang: 'Tas Ransel',
      warna: 'Biru Navy',
      merek: 'Eiger',
      lokasi: 'Masjid Kampus',
      deskripsi:
          'Tas ransel Eiger warna biru navy dengan tanda pengenal nama di tali tas. Berisi buku dan alat tulis.',
      tanggalHilang: '12 Oktober 2026',
      pelapor: 'Fatimah Zahra',
      iconCategory: 'bag',
    ),
    LostItem(
      id: '006',
      namaBarang: 'Powerbank',
      warna: 'Putih',
      merek: 'Anker',
      lokasi: 'Student Center',
      deskripsi:
          'Powerbank Anker 20000mAh warna putih. Hilang di area duduk student center.',
      tanggalHilang: '13 Oktober 2026',
      pelapor: 'Deni Kurniawan',
      iconCategory: 'battery',
    ),
    LostItem(
      id: '007',
      namaBarang: 'Earphone',
      warna: 'Putih',
      merek: 'Apple',
      lokasi: 'Perpustakaan Pusat',
      deskripsi:
          'AirPods Pro generasi 2 warna putih beserta casing-nya. Hilang di area baca perpustakaan.',
      tanggalHilang: '7 Oktober 2026',
      pelapor: 'Nadia Putri',
      iconCategory: 'earphone',
    ),
    LostItem(
      id: '008',
      namaBarang: 'Jaket',
      warna: 'Merah',
      merek: 'The North Face',
      lokasi: 'Ruang Kelas FMIPA',
      deskripsi:
          'Jaket windbreaker merah merek The North Face ukuran M. Hilang setelah kelas praktikum.',
      tanggalHilang: '6 Oktober 2026',
      pelapor: 'Hendra Wijaya',
      iconCategory: 'jacket',
    ),
    LostItem(
      id: '009',
      namaBarang: 'Flash Disk',
      warna: 'Merah',
      merek: 'SanDisk',
      lokasi: 'Lab Komputer Fasilkom',
      deskripsi:
          'Flash disk SanDisk 64GB warna merah. Berisi data skripsi yang sangat penting.',
      tanggalHilang: '5 Oktober 2026',
      pelapor: 'Agus Salim',
      iconCategory: 'storage',
    ),
    LostItem(
      id: '010',
      namaBarang: 'Buku Catatan',
      warna: 'Hijau',
      merek: 'Moleskine',
      lokasi: 'Kantin Pusat',
      deskripsi:
          'Buku catatan hardcover Moleskine warna hijau berisi catatan kuliah Kalkulus dan Fisika.',
      tanggalHilang: '4 Oktober 2026',
      pelapor: 'Cindy Maharani',
      iconCategory: 'book',
    ),
    LostItem(
      id: '011',
      namaBarang: 'Charger Laptop',
      warna: 'Putih',
      merek: 'Apple',
      lokasi: 'Ruang Diskusi GKB 2',
      deskripsi:
          'Charger MagSafe Apple 67W warna putih. Tertinggal di colokan ruang diskusi.',
      tanggalHilang: '3 Oktober 2026',
      pelapor: 'Maya Sari',
      iconCategory: 'charger',
    ),
    LostItem(
      id: '012',
      namaBarang: 'Sepeda',
      warna: 'Hijau',
      merek: 'Polygon',
      lokasi: 'Parkiran Rektorat',
      deskripsi:
          'Sepeda gunung Polygon warna hijau dengan keranjang depan. Rantai agak berkarat.',
      tanggalHilang: '2 Oktober 2026',
      pelapor: 'Eko Prasetyo',
      iconCategory: 'bicycle',
    ),
    LostItem(
      id: '013',
      namaBarang: 'Kunci Motor',
      warna: 'Hitam',
      merek: 'Honda',
      lokasi: 'Parkiran Fakultas Ekonomi',
      deskripsi:
          'Kunci motor Honda dengan gantungan kunci katak berwarna hijau.',
      tanggalHilang: '1 Oktober 2026',
      pelapor: 'Rini Susanti',
      iconCategory: 'key',
    ),
    LostItem(
      id: '014',
      namaBarang: 'Tablet',
      warna: 'Abu-abu',
      merek: 'Xiaomi',
      lokasi: 'Aula Rektorat',
      deskripsi:
          'Xiaomi Pad 6 warna abu-abu dengan cover keyboard berwarna hitam.',
      tanggalHilang: '30 September 2026',
      pelapor: 'Fandi Ahmad',
      iconCategory: 'tablet',
    ),
    LostItem(
      id: '015',
      namaBarang: 'Jam Tangan',
      warna: 'Silver',
      merek: 'Casio',
      lokasi: 'Toilet GKB 3',
      deskripsi:
          'Jam tangan Casio G-Shock warna silver. Tertinggal di wastafel toilet.',
      tanggalHilang: '29 September 2026',
      pelapor: 'Wahyu Setiawan',
      iconCategory: 'watch',
    ),
  ];

  /// Weighted Scoring Search:
  /// namaBarang: 40%, warna: 20%, merek: 20%, lokasi: 20%
  /// Minimum score to show: 35%
  static List<Map<String, dynamic>> search({
    required String namaBarang,
    String? warna,
    String? merek,
    String? lokasi,
    List<LostItem>? sourceItems,
  }) {
    const double weightNama = 0.40;
    const double weightWarna = 0.20;
    const double weightMerek = 0.20;
    const double weightLokasi = 0.20;
    const double minScore = 0.35;

    List<Map<String, dynamic>> results = [];

    for (final item in sourceItems ?? items) {
      double scoreNama = 0.0;
      double scoreWarna = 0.0;
      double scoreMerek = 0.0;
      double scoreLokasi = 0.0;

      // Score nama (mandatory - jika kosong diberi 0, tidak ada default)
      if (namaBarang.isNotEmpty) {
        scoreNama = _stringSimilarity(
          namaBarang.toLowerCase(),
          item.namaBarang.toLowerCase(),
        );
      }

      // Score warna (optional - jika kosong diberi 0)
      if (warna != null && warna.isNotEmpty) {
        scoreWarna = _stringSimilarity(
          warna.toLowerCase(),
          item.warna.toLowerCase(),
        );
      }

      // Score merek (optional - jika kosong diberi 0)
      if (merek != null && merek.isNotEmpty) {
        scoreMerek = _stringSimilarity(
          merek.toLowerCase(),
          item.merek.toLowerCase(),
        );
      }

      // Score lokasi (optional - jika kosong diberi 0)
      if (lokasi != null && lokasi.isNotEmpty) {
        scoreLokasi = _stringSimilarity(
          lokasi.toLowerCase(),
          item.lokasi.toLowerCase(),
        );
      }

      final double totalScore = (scoreNama * weightNama) +
          (scoreWarna * weightWarna) +
          (scoreMerek * weightMerek) +
          (scoreLokasi * weightLokasi);

      if (totalScore >= minScore) {
        results.add({'item': item, 'score': totalScore});
      }
    }

    // Sort by score descending
    results.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    return results;
  }

  /// Simple string similarity: checks for substring containment + partial match
  static double _stringSimilarity(String query, String target) {
    if (query.isEmpty || target.isEmpty) return 0.0;

    // Exact match
    if (query == target) return 1.0;

    // Contains check (query in target or target in query)
    if (target.contains(query)) return 0.9;
    if (query.contains(target)) return 0.85;

    // Word-level matching
    final queryWords = query.split(RegExp(r'\s+'));
    final targetWords = target.split(RegExp(r'\s+'));
    int matchedWords = 0;

    for (final qw in queryWords) {
      if (qw.length < 2) continue;
      for (final tw in targetWords) {
        if (tw.contains(qw) || qw.contains(tw)) {
          matchedWords++;
          break;
        }
      }
    }

    if (queryWords.isNotEmpty) {
      final wordScore = matchedWords / queryWords.length;
      if (wordScore > 0) return wordScore * 0.8;
    }

    // Character-level: how many chars of query are in target
    int charMatch = 0;
    for (final ch in query.runes) {
      if (target.contains(String.fromCharCode(ch))) charMatch++;
    }
    final charScore = charMatch / query.length;
    return charScore * 0.5;
  }
}
