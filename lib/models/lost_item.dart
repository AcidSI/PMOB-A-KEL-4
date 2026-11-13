class LostItem {
  final String id;
  final String namaBarang;
  final String warna;
  final String merek;
  final String lokasi;
  final String deskripsi;
  final String tanggalHilang;
  final String pelapor;
  final String iconCategory;
  final double? latitude;
  final double? longitude;

  const LostItem({
    required this.id,
    required this.namaBarang,
    required this.warna,
    required this.merek,
    required this.lokasi,
    required this.deskripsi,
    required this.tanggalHilang,
    required this.pelapor,
    required this.iconCategory,
    this.latitude,
    this.longitude,
  });
}
