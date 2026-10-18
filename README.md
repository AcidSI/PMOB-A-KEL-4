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
- Foto barang dapat dipilih dari galeri pada platform yang didukung oleh
  `image_picker`.

Data contoh dan laporan yang dibuat hanya disimpan selama aplikasi berjalan.
Form masuk saat ini hanya melakukan validasi di sisi aplikasi; belum terhubung
ke layanan autentikasi atau penyimpanan backend.
