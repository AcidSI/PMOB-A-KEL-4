/// Kategori baku laporan (PRD 2.2). Nantinya dimuat dari database sehingga
/// dapat diubah tanpa merilis ulang aplikasi (FR-R12); untuk sementara disimpan
/// sebagai seed lokal dengan bentuk yang sama.
class ReportCategory {
  final String id;
  final String name;
  final String examples;

  /// Kategori yang rawan memuat nama/nomor pada foto atau judul (FR-R07).
  final bool isSensitive;

  const ReportCategory({
    required this.id,
    required this.name,
    required this.examples,
    this.isSensitive = false,
  });
}

/// Pasangan kategori yang saling terkait beserta pengali skor matching
/// (PRD 2.2). Titik awal saja; pemegang Modul 3 yang mengkalibrasi.
class CategoryRelation {
  final String categoryA;
  final String categoryB;
  final double multiplier;
  const CategoryRelation(this.categoryA, this.categoryB, this.multiplier);
}

class ReportCategories {
  ReportCategories._();

  static const String lainnya = 'Lainnya';

  static const List<ReportCategory> all = [
    ReportCategory(
      id: 'dompet-kartu',
      name: 'Dompet & Kartu',
      examples: 'dompet, KTM, ATM, SIM',
      isSensitive: true,
    ),
    ReportCategory(
      id: 'tas-ransel',
      name: 'Tas & Ransel',
      examples: 'tas, ransel, totebag',
    ),
    ReportCategory(
      id: 'elektronik',
      name: 'Elektronik',
      examples: 'HP, laptop, earphone, charger, powerbank',
    ),
    ReportCategory(
      id: 'kunci-kendaraan',
      name: 'Kunci & Kendaraan',
      examples: 'kunci motor/mobil, helm, STNK',
    ),
    ReportCategory(
      id: 'dokumen-kuliah',
      name: 'Dokumen & Perlengkapan Kuliah',
      examples: 'buku, jas lab, map, alat tulis, kalkulator',
      isSensitive: true,
    ),
    ReportCategory(
      id: 'pakaian-aksesori',
      name: 'Pakaian & Aksesori',
      examples: 'jaket, topi, jam, kacamata, perhiasan',
    ),
    ReportCategory(
      id: 'botol-makan',
      name: 'Botol & Perlengkapan Makan',
      examples: 'botol minum, kotak makan',
    ),
    ReportCategory(
      id: 'ibadah',
      name: 'Perlengkapan Ibadah',
      examples: "mukena, sajadah, Al-Qur'an",
    ),
    ReportCategory(
      id: 'olahraga',
      name: 'Perlengkapan Olahraga',
      examples: 'sepatu, raket, bola',
    ),
    ReportCategory(
      id: 'lainnya',
      name: lainnya,
      examples: 'di luar kategori di atas',
    ),
  ];

  /// Relasi awal dari contoh di PRD 2.2 (pengali ×0,8).
  static const List<CategoryRelation> relations = [
    CategoryRelation('Dompet & Kartu', 'Tas & Ransel', 0.8),
    CategoryRelation('Elektronik', 'Tas & Ransel', 0.8),
    CategoryRelation('Dompet & Kartu', 'Dokumen & Perlengkapan Kuliah', 0.8),
  ];

  static ReportCategory? byName(String? name) {
    if (name == null) return null;
    for (final category in all) {
      if (category.name == name) return category;
    }
    return null;
  }

  static bool isSensitiveName(String? name) => byName(name)?.isSensitive ?? false;

  /// Memetakan kategori lama (4 pilihan) ke kategori baku agar data lama tidak
  /// rusak.
  static String fromLegacy(String legacy) {
    return switch (legacy) {
      'Elektronik' => 'Elektronik',
      'Dokumen' => 'Dokumen & Perlengkapan Kuliah',
      'Aksesori' => 'Pakaian & Aksesori',
      _ => byName(legacy)?.name ?? lainnya,
    };
  }
}
