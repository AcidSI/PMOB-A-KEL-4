# Project Requirements Document (PRD): Find!t

| Project Name | Find!t |
| :--- | :--- |
| Team | Muhammad Arrasyid (2411522027) <br> Akbar Rivan Putra (241152011) <br> Martia Perdana Putri (2411522019) |
| Course | Mobile Programming |
| Version | 1.0 |
| Date | 13 September 2026 |

---

## 1. Problem & Users

### 1.1 Problem Statement
Proses pelaporan dan pencarian barang hilang di lingkungan kampus Universitas Andalas saat ini masih terfragmentasi karena mengandalkan media sosial dan pos keamanan secara manual. Kondisi ini menyulitkan pemilik barang untuk menemukan kembali miliknya, memperlambat proses verifikasi kepemilikan, dan membuka celah terjadinya klaim palsu atau penipuan (*scam*) karena tidak ada mekanisme verifikasi identitas pelapor.

### 1.2 Target Users
Mahasiswa, dosen, dan staf Universitas Andalas yang aktif beraktivitas di lingkungan kampus serta berpotensi kehilangan barang pribadi atau menemukan barang milik civitas akademika lain.

### 1.3 User Needs / Pain Points
* Sulit menyebarkan dan menemukan informasi barang hilang/ditemukan secara cepat dan terpusat dalam lingkup kampus.
* Belum ada sistem pencocokan (*matching*) otomatis antara laporan barang hilang dan barang temuan berdasarkan kategori maupun lokasi kejadian.
* Proses verifikasi kepemilikan barang tidak transparan, tidak terstruktur, dan rawan disalahgunakan oleh pihak yang bukan pemilik sah.
* Sulit memastikan keaslian identitas pelapor karena tidak ada validasi berbasis identitas sivitas akademika (KTM).

### 1.4 Project Goal
Membangun aplikasi mobile **Find!t** sebagai platform terpusat bagi civitas akademika Universitas Andalas untuk melaporkan dan mencari barang hilang maupun ditemukan, unggah bukti foto barang dengan dukungan kamera perangkat, penandaan lokasi berbasis GPS, serta sistem pencocokan dan notifikasi otomatis untuk mempercepat proses pengembalian barang kepada pemilik sah.

---

## 2. Product Requirements

### 2.1 Functional Requirements

#### A. Shared Functionality (Authentication & User Account)
*Fungsionalitas pendukung yang digunakan oleh seluruh modul:*
* **FR-S01:** Pengguna dapat melakukan registrasi akun menggunakan identitas sivitas akademika.
* **FR-S02:** Pengguna dapat melakukan login menggunakan akun yang telah terdaftar.
* **FR-S03:** Pengguna dapat melihat dan memperbarui informasi profil pribadi.
* **FR-S04:** Pengguna dapat mengubah kata sandi dan melakukan logout dari aplikasi.

#### B. Functional Module 1: Reporting & Item Management
*Modul ini menangani proses pembuatan dan pengelolaan laporan barang hilang atau ditemukan.*
* **FR-R01:** Pengguna dapat membuat laporan baru dengan memilih jenis laporan *Lost* atau *Found* serta mengisi nama barang, kategori, deskripsi, dan waktu kejadian/penemuan.
* **FR-R02 (Fitur Perangkat Kamera):** Sistem dapat mengakses kamera perangkat (untuk pengambil foto *real-time* pada laporan *Found*) serta galeri/penyimpanan media perangkat (untuk unggah foto arsip pada laporan *Lost*).
* **FR-R03:** Pengguna dapat melihat detail laporan barang yang telah dibuat atau dipublikasikan.
* **FR-R04:** Pengguna dapat memperbarui informasi laporan barang yang dibuatnya sendiri.
* **FR-R05:** Pengguna dapat menghapus laporan barang yang dibuatnya sendiri.
* **FR-R06 (Notifikasi Modul 1):** Sistem dapat mengirimkan notifikasi lokal (*local notification*) ke perangkat pengguna saat laporan barang miliknya berhasil dipublikasikan, diperbarui, atau dihapus.

> **Integrasi Modul 1:** 
> Buat Laporan $\rightarrow$ Ambil Foto (Kamera/Galeri) $\rightarrow$ Publikasikan $\rightarrow$ Notifikasi Status $\rightarrow$ Lihat Detail / Edit / Hapus

#### C. Functional Module 2: Location & Discovery
*Modul ini menangani proses penentuan lokasi serta pencarian dan eksplorasi laporan.*
* **FR-L01 (Fitur Perangkat GPS):** Sistem dapat membaca koordinat lokasi perangkat menggunakan GPS untuk menentukan lokasi laporan dan mendukung fitur berbasis lokasi.
* **FR-L02:** Sistem dapat menampilkan lokasi laporan dalam bentuk penanda (*marker*) pada peta kampus berdasarkan koordinat yang tersimpan.
* **FR-L03:** Pengguna dapat melihat daftar laporan barang yang tersedia di dalam aplikasi.
* **FR-L04:** Pengguna dapat mencari laporan berdasarkan nama atau informasi barang.
* **FR-L05:** Pengguna dapat memfilter laporan berdasarkan jenis laporan, kategori, dan status.
* **FR-L06 (Notifikasi Modul 2):** Sistem dapat mengirimkan notifikasi lokal kepada pengguna jika terdapat laporan baru yang diterbitkan di sekitar radius area lokasi pengguna.

> **Integrasi Modul 2:** 
> GPS Lokasi Laporan $\rightarrow$ Peta/Marker $\rightarrow$ Search / Filter $\rightarrow$ Eksplorasi Laporan $\rightarrow$ Area Radius Notification

#### D. Functional Module 3: Matching, Claim & Resolution
*Modul ini menangani proses inti untuk mempertemukan barang hilang dengan barang yang ditemukan hingga proses pengembalian.*
* **FR-M01:** Sistem dapat melakukan pencocokan antara laporan *Lost* dan *Found* berdasarkan kriteria yang telah ditentukan, seperti kategori barang, karakteristik barang, dan kedekatan lokasi.
* **FR-M02 (Notifikasi Modul 3):** Sistem dapat mengirimkan *push notification* kepada pengguna ketika ditemukan potensi kecocokan antara laporan *Lost* dan *Found*.
* **FR-M03:** Pengguna dapat melakukan klaim terhadap laporan barang yang dianggap sesuai dan memberikan informasi untuk memverifikasi kepemilikan.
* **FR-M04:** Pengguna dapat mengirim dan menerima pesan/komentar untuk melakukan verifikasi serta menyepakati proses pengembalian barang.
* **FR-M05:** Pengguna dapat mengubah status laporan menjadi Selesai/Dikembalikan (*Resolved*) setelah proses pengembalian barang berhasil.

> **Integrasi Modul 3:** 
> Matching $\rightarrow$ Match Notification $\rightarrow$ Claim $\rightarrow$ Verification/Communication $\rightarrow$ Return Resolved

---

### 2.2 Non-functional Requirements

* **NFR-01 (Performance):** Aplikasi dapat menampilkan halaman utama dalam waktu $\le 3$ detik pada kondisi jaringan normal.
* **NFR-02 (Usability):** Antarmuka aplikasi harus sederhana, konsisten, dan mudah dipahami oleh pengguna tanpa memerlukan panduan khusus untuk menjalankan fungsi utama.
* **NFR-03 (Permission & Privacy Control):** Sistem harus meminta persetujuan pengguna sebelum mengakses kamera dan lokasi perangkat, serta memberikan informasi yang jelas mengenai penggunaannya.
* **NFR-04 (Privacy & Security):** Data pribadi pengguna, informasi kontak, foto KTM, serta data laporan hanya dapat diakses sesuai dengan hak akses dan kebutuhan fungsional pengguna.
* **NFR-05 (Media Efficiency):** Sistem membatasi ukuran dan format foto yang dapat diunggah agar penggunaan penyimpanan dan *bandwidth* tetap efisien.
* **NFR-06 (Reliability & Error Handling):** Sistem harus menampilkan pesan yang jelas dan informatif apabila terjadi kegagalan koneksi internet, kegagalan memperoleh lokasi GPS, atau kegagalan proses unggah data.
* **NFR-07 (Compatibility):** Aplikasi harus dapat berjalan pada perangkat Android yang mendukung kebutuhan minimum kamera, GPS, dan koneksi internet.

---

### 2.3 Core Features

| No. | Core Feature | Purpose / Value |
| :---: | :--- | :--- |
| **1** | Pelaporan Barang Lost & Found | Memungkinkan pengguna membuat dan mengelola laporan barang hilang atau ditemukan dengan informasi detail dan bukti foto barang sehingga informasi terverifikasi dengan jelas. |
| **2** | Pemetaan & Eksplorasi Laporan | Membantu pengguna menemukan laporan yang relevan melalui penanda lokasi GPS pada peta kampus, daftar laporan, pencarian, dan *filtering*. |
| **3** | Matching & Automatic Notification | Mempercepat proses menemukan barang dengan mencocokkan laporan *Lost* dan *Found* secara otomatis berdasarkan karakteristik dan lokasi serta memberikan *notification* saat ada potensi kecocokan. |
| **4** | Claim & Verification | Memungkinkan pengguna melakukan klaim dan berkomunikasi via komentar/pesan interaktif untuk proses verifikasi kepemilikan barang sebelum pengembalian. |
| **5** | Return & Resolution | Mendukung penyelesaian proses pengembalian barang dengan mengubah status laporan menjadi Selesai/Dikembalikan (*Resolved*) setelah barang berhasil diserahkan. |

---

### 2.4 User Flow (Ringkasan Alur)
1. **Shared Module (Autentikasi & Profil):** Pengecekan sesi login $\rightarrow$ Pilihan Registrasi (Input NIM/NIP, Email Kampus, Sandi) atau Login Kredensial $\rightarrow$ Validasi via REST API $\rightarrow$ Masuk ke Dashboard Utama.
2. **Modul 1 (Pelaporan):** Buka Menu Pelaporan $\rightarrow$ Pilih Jenis (Lost/Found) $\rightarrow$ Isi Data Detail $\rightarrow$ Unggah Foto (Galeri untuk Lost, Kamera *real-time* untuk Found) $\rightarrow$ Submit via REST API $\rightarrow$ Notifikasi Lokal Berhasil.
3. **Modul 2 (Peta & Discovery):** Buka Menu Peta $\rightarrow$ Baca Sensor GPS $\rightarrow$ Render Peta & Marker $\rightarrow$ Opsional Search/Filter $\rightarrow$ Pilih Marker/Item $\rightarrow$ Lihat Detail Foto & Koordinat GPS.
4. **Modul 3 (Matching & Klaim):** *Background Engine* mencocokkan kategori & radius GPS $\rightarrow$ *Push Notification* Potensi Kecocokan $\rightarrow$ Buka Detail $\rightarrow$ Kirim Pesan/Komentar Verifikasi $\rightarrow$ Sepakati Titik Temu $\rightarrow$ Ubah Status menjadi *Resolved*.

---

### 2.5 Data Requirements

| Data / Entity | Key Information | Purpose |
| :--- | :--- | :--- |
| **User** | User ID, Nama, NIM/Nomor Identitas, Email Kampus, Nomor Telepon/WhatsApp | Mengidentifikasi pemilik laporan atau penemu barang agar dapat dihubungi dengan aman. |
| **Lost & Found Report** | Report ID, User ID, Tipe Laporan (Lost/Found), Nama Barang, Kategori, Deskripsi/Karakteristik, Foto Barang, Tanggal & Waktu Kejadian/Penemuan, Status Laporan (Active/Resolved), Location ID | Menyimpan informasi utama mengenai barang yang hilang atau ditemukan, termasuk informasi yang digunakan dalam proses pencarian dan *matching*. |
| **Match** | Match ID, Lost Report ID, Found Report ID, Tingkat/Score Kecocokan, Kriteria Kecocokan, Status Match, Waktu Pencocokan | Mencatat hubungan antara laporan *Lost* dan *Found* yang memiliki potensi kecocokan berdasarkan kategori, karakteristik, dan kedekatan lokasi. |
| **Notification** | Notification ID, User ID, Match ID, Jenis Notifikasi, Pesan, Status Dibaca, Waktu | Menyimpan informasi notifikasi ketika sistem menemukan potensi kecocokan laporan. |
| **Location** | Location ID, Latitude, Longitude, Gedung/Area Kampus, Nama/Keterangan Tambahan | Menyimpan lokasi kejadian atau penemuan barang berdasarkan koordinat GPS dan informasi area kampus untuk mendukung pemetaan serta *matching* berbasis lokasi. |
| **Claim** | Claim ID, Report ID, Claimant User ID, Alasan/Bukti Kepemilikan, Status Klaim, Waktu Klaim | Mencatat proses klaim dan verifikasi kepemilikan. |
| **Comment** | Comment ID, Report ID/Match ID, Sender ID, Isi Pesan, Waktu, Status | Menyimpan komunikasi antara pengguna dalam proses verifikasi kepemilikan dan koordinasi pengembalian barang. |

---

### 2.6 Constraints & Assumptions

#### Constraints (Batasan)
* Aplikasi dikembangkan untuk platform **Android** pada tahap awal (tidak mencakup iOS).
* Menggunakan **Flutter/Dart** sebagai teknologi utama sisi mobile.
* Membutuhkan koneksi internet untuk autentikasi, sinkronisasi, pencarian, *matching*, dan komunikasi.
* Menggunakan backend relasional dan **REST API mandiri** (tidak menggunakan Firebase BaaS).
* Fitur kamera dan GPS bergantung pada ketersediaan perangkat dan izin pengguna.
* Akurasi GPS di dalam gedung (*indoor*) dapat dipengaruhi lingkungan.
* Tidak melakukan pelacakan lokasi *real-time* berkelanjutan.
* Cakupan data dibatasi hanya di lingkungan **Universitas Andalas**.
* Ukuran dan format foto dibatasi untuk efisiensi penyimpanan & *bandwidth*.
* Sistem tidak menggunakan AI/Computer Vision otomatis; hasil *matching* berupa potensi kecocokan yang tetap memerlukan verifikasi manual pengguna.

#### Assumptions (Asumsi)
* Pengguna merupakan civitas akademika Universitas Andalas.
* Pengguna memberikan informasi dan foto yang benar, lengkap, dan tidak menyesatkan.
* Pengguna memberikan izin akses kamera dan lokasi.
* Perangkat pengguna memiliki spesifikasi perangkat keras dan internet yang memadai.
* Pengguna memahami bahwa hasil *matching* adalah potensi kecocokan, bukan bukti mutlak barang yang sama tanpa verifikasi manual.

---

### 2.7 Success Criteria
* **Indikator Keberhasilan 1:** Sistem mampu memberikan notifikasi otomatis apabila terdapat kecocokan data antara laporan barang hilang dan barang temuan.
* **Indikator Keberhasilan 2:** Pengguna dapat membuat laporan secara lengkap (termasuk foto dan titik GPS) dalam kurun waktu $< 5$ menit.
* **Indikator Keberhasilan 3:** Sistem berhasil menyelesaikan minimal satu skenario *Lost & Found* dari proses *matching*, klaim, verifikasi, hingga perubahan status menjadi *Resolved*.

---

## 3. Scope

### 3.1 In Scope
* Fitur CRUD laporan barang *Lost/Found* lengkap dengan foto bukti fisik (kamera untuk *Found*, galeri untuk *Lost*).
* Penandaan dan visualisasi lokasi kejadian pada peta interaktif kampus berbasis GPS.
* Pencarian dan penyaringan daftar laporan berdasarkan jenis, kategori, dan waktu.
* Sistem pencocokan otomatis (*matching engine*) antara laporan *Lost* dan *Found*.
* Sistem notifikasi lokal dan *push notification* mandiri.
* Fitur komentar/klaim pada detail barang untuk verifikasi kepemilikan dan kesepakatan titik temu.
* Perubahan status laporan dari "Active" menjadi "Resolved".

### 3.2 Out of Scope
* Integrasi sistem pembayaran digital atau transaksi komersial.
* Pelacakan GPS *real-time* berkelanjutan.
* Dukungan lintas kampus atau skala nasional.
* Dukungan platform selain Android (mis. iOS) pada versi awal.
* Verifikasi kepemilikan otomatis berbasis AI/Computer Vision.
* Penggunaan layanan *Backend-as-as-Service* instan seperti Firebase.

---

## 4. AI Prompt Context
* **Ringkasan Project:** Find!t adalah aplikasi mobile (Android, Flutter/Dart) sebagai platform terpusat civitas akademika Universitas Andalas untuk melaporkan & mencari barang hilang (*Lost*) atau ditemukan (*Found*).
* **Target User:** Mahasiswa, dosen, dan staf kampus.
* **Tujuan:** Mempercepat penemuan & pengembalian barang via verifikasi KTM, bukti foto kamera, GPS, dan pencocokan otomatis.
* **Catatan Teknis untuk AI/Pengembangan:** 
  * Dibangun dengan **Flutter/Dart**.
  * **Tanpa Firebase**, backend relasional & REST API dibangun mandiri.
  * Memperhitungkan kendala GPS *indoor* dan manajemen *permission*.
  * Alur mendukung dua *role* (penemu vs pemilik) dalam satu sistem untuk kebutuhan *matching*.
  * Memerlukan mekanisme anti-kecurangan (*anti-scam*) pada verifikasi klaim manual.