import 'package:find_it/domain/report_rules.dart';

class Validators {
  Validators._(); // Private constructor to prevent instantiation

  static String? requiredField(
    String? value, {
    String fieldName = 'Field ini',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredField(value, fieldName: 'Email');
    if (requiredError != null) return requiredError;
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\\w-]+)+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Format email tidak valid';
    }
    return null;
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
    if (value != originalPassword) {
      return 'Kata sandi tidak cocok';
    }
    return null;
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
      ReportRules.validateName(value);

  static String? reportWhatsapp(String? value) =>
      ReportRules.validateWhatsapp(value);

  static String? reportSecretDetail(String? value) {
    if ((value?.trim().length ?? 0) > ReportRules.maxSecretDetailLength) {
      return 'Detail pembeda maksimal '
          '${ReportRules.maxSecretDetailLength} karakter';
    }
    return null;
  }

  static String? reportCategory(String? value) =>
      requiredField(value, fieldName: 'Kategori');

  static String? reportDescription(String? value) {
    final requiredError = requiredField(value, fieldName: 'Deskripsi');
    if (requiredError != null) return requiredError;
    return maxLength(
      value,
      ReportRules.maxDescriptionLength,
      fieldName: 'Deskripsi',
    );
  }

  static String? reportLocation(String? value) =>
      requiredField(value, fieldName: 'Lokasi');
}
