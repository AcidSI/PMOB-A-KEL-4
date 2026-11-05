# Find!t

Aplikasi Flutter untuk melihat, mencari, dan melaporkan barang hilang atau
ditemukan di Universitas Andalas.

## Menjalankan aplikasi

```sh
flutter pub get
flutter run
```

Untuk menjalankan pemeriksaan otomatis:

```sh
flutter analyze
flutter test
```

## Fitur

- Form masuk memvalidasi email institusi/NIP dan kata sandi sebelum membuka
  daftar laporan.
- Beranda menggabungkan daftar barang awal dari pencarian lama dengan data
  contoh dan laporan baru.
- Pencarian biasa dan pencarian berbobot (nama, warna, merek, dan lokasi)
  tersedia dari beranda.
- Pengguna dapat membuat laporan kehilangan atau penemuan, melihat detail, dan
  membuka halaman chat pelapor.
- Matching lost/found memakai skor teks (40%), lokasi (35%), waktu (25%), dan
  pengali kategori; hasil ≥60% tampil sebagai kandidat, dengan maksimal lima
  kandidat per laporan.
- Alur klaim menyediakan jawaban detail pembeda rahasia, alasan/bukti,
  komentar verifikasi yang tidak dapat diubah, keputusan pemilik, persetujuan
  berbagi kontak, dan konfirmasi serah terima oleh kedua pihak.
- Halaman Matching memuat kandidat, klaim masuk, dan notifikasi dalam aplikasi;
  pengguna dapat mengabaikan kandidat yang tidak relevan.
- Foto barang dapat dipilih dari galeri pada platform yang didukung oleh
  `image_picker`.

**Batas prototipe:** data, klaim, komentar, notifikasi, dan pembatasan anti-scam
masih disimpan dalam memori aplikasi dan hilang saat aplikasi dimulai ulang.
Validasi email kampus saat ini hanya simulasi lokal; belum ada OTP, backend,
penyimpanan terenkripsi, notifikasi sistem, sinkronisasi antarperangkat, atau
penegakan batas klaim di server. Implementasi ini bukan pengganti kontrol
keamanan sisi server yang dijelaskan PRD.
