class Validators {
  Validators._(); // Private constructor to prevent instantiation 

  static String? requiredField(
    String? value, { // Menerima nilai yang akan diperiksa
    String fieldName = 'Field ini',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null; // Jika nilai berisi teks, menandakan tidak ada error.
  }

  static String? email(String? value) { // Nilai email boleh null, agar fungsi dapat memeriksa masukan nullable.
    final requiredError = requiredField(value, fieldName: 'Email'); // Memakai validator wajib isi terlebih dahulu dan menyimpan hasilnya.
    if (requiredError != null) return requiredError; //Jika kosong, langsung mengembalikan pesan wajib isi dan tidak melanjutkan pemeriksaan format.
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Format email tidak valid';
    }
    return null; // Email cocok dengan pemeriksaan format, sehingga tidak ada error.
  }

  static String? institutionalEmailOrNip(String? value) {
  final requiredError = requiredField(
    value,
    fieldName: 'Email Institusi / NIP',
  );
  if (requiredError != null) return requiredError;
  
  final input = value!.trim(); 
  final isNip = RegExp(r'^\d{5,20}$').hasMatch(input);
  
  if (!isNip) {
    // Jika bukan NIP, langsung periksa apakah diakhiri dengan domain kampus
    if (!input.endsWith('@student.unand.ac.id')) {
      return 'Masukkan NIP atau email @student.unand.ac.id yang valid';
    }
  }
  return null;
}

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi';
    }
    
    // Validasi konsistensi: memastikan string yang dimasukkan persis sama dengan kata sandi utama[cite: 4, 7].
    if (value != originalPassword) {
      return 'Kata sandi tidak cocok'; // Pesan error jika input berbeda[cite: 4, 7].
    }
    return null; // Valid
  }

  static String? minLength(
    String? value,
    int min, {
    String fieldName = 'Field ini',
  }) {
    final requiredError = requiredField(value, fieldName: fieldName);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < min) {
      return '$fieldName minimal $min karakter';
    }
    return null;
  }

  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'Field ini',
  }) {
    final requiredError = requiredField(value, fieldName: fieldName);
    if (requiredError != null) return requiredError;
    if (value!.trim().length > max) {
      return '$fieldName maksimal $max karakter';
    }
    return null;
  }
  
  static String? registerName(String? value) =>
      requiredField(value, fieldName: 'Nama Lengkap');

  static String? noWhatsAppp(String? value) =>
      requiredField(value, fieldName: 'Nomor WhatsApp');

  static String? reportName(String? value) =>
      requiredField(value, fieldName: 'Nama barang');

  static String? reportCategory(String? value) =>
      requiredField(value, fieldName: 'Kategori');

  static String? reportDescription(String? value) {
    final requiredError = requiredField(value, fieldName: 'Deskripsi');
    if (requiredError != null) return requiredError;
    return maxLength(value, 50, fieldName: 'Deskripsi');
  }

  static String? reportLocation(String? value) =>
      requiredField(value, fieldName: 'Lokasi');
}
