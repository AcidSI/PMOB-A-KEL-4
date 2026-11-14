import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../routes/app_routes.dart';
import '../utils/validators.dart';
import '../widgets/brand/findit_brand.dart';

/// Halaman pendaftaran akun Find!t.
///
/// Gaya visual mengikuti Login (logo, palet hijau-kuning, dekorasi).
/// Saat berhasil, halaman ditutup dengan mengembalikan email kampus
/// agar Login bisa langsung mengisinya.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscurePassword = true;
  bool _isObscureConfirm = true;
  bool _agreedToPrivacy = false;
  bool _submittedOnce = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ Aksi

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    setState(() => _submittedOnce = true);

    final formValid = _formKey.currentState!.validate();
    if (!formValid || !_agreedToPrivacy) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulasi pendaftaran ke server.
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context, _emailController.text.trim());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Gagal melakukan registrasi. Silakan periksa koneksi Anda.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onBackTapped() {
    if (_isLoading) return;
    Navigator.maybePop(context);
  }

  void _onLoginTapped() {
    if (_isLoading) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  // ------------------------------------------------------------ Validasi

  static String? _validateNimNip(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'NIM / NIP wajib diisi';
    if (!RegExp(r'^\d{8,20}$').hasMatch(text)) {
      return 'NIM / NIP hanya berisi angka (8–20 digit)';
    }
    return null;
  }

  static String? _validateCampusEmail(String? value) {
    final text = value?.trim().toLowerCase() ?? '';
    if (text.isEmpty) return 'Email kampus wajib diisi';
    if (!RegExp(r'^[\w.+-]+@([\w-]+\.)*unand\.ac\.id$').hasMatch(text)) {
      return 'Gunakan email kampus (@student.unand.ac.id / @unand.ac.id)';
    }
    return null;
  }

  String? _validateConfirm(String? value) =>
      Validators.confirmPassword(value, _passwordController.text);

  // ------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const Positioned(
              right: -80,
              top: -110,
              child: BrandBlob(size: 240, color: BrandColors.mint),
            ),
            const Positioned(
              right: 30,
              top: 84,
              child: BrandRing(size: 34, stroke: 7),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submittedOnce
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(onBack: _onBackTapped),
                      const SizedBox(height: 28),
                      const _Heading(),
                      const SizedBox(height: 28),
                      ..._buildFields(),
                      const SizedBox(height: 4),
                      _PrivacyConsent(
                        value: _agreedToPrivacy,
                        showError: _submittedOnce && !_agreedToPrivacy,
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _agreedToPrivacy = v),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(
                          message: _errorMessage!,
                          onRetry: _isLoading ? null : _handleRegister,
                        ),
                      ],
                      const SizedBox(height: 24),
                      BrandPrimaryButton(
                        label: 'Daftar & kirim verifikasi',
                        trailingIcon: Icons.arrow_forward_rounded,
                        busy: _isLoading,
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: 12),
                      _LoginPrompt(onLogin: _onLoginTapped),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    return [
      _LabeledField(
        label: 'Nama lengkap',
        child: TextFormField(
          controller: _nameController,
          enabled: !_isLoading,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: Validators.registerName,
          decoration: brandInputDecoration(
            hint: 'Sesuai KTM / kartu pegawai',
            icon: Icons.person_outline_rounded,
          ),
        ),
      ),
      _LabeledField(
        label: 'NIM / NIP',
        child: TextFormField(
          controller: _idController,
          enabled: !_isLoading,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: _validateNimNip,
          decoration: brandInputDecoration(
            hint: 'mis. 2411522019',
            icon: Icons.badge_outlined,
          ),
        ),
      ),
      _LabeledField(
        label: 'Email kampus',
        helper: 'Tautan verifikasi dikirim ke email ini.',
        child: TextFormField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: _validateCampusEmail,
          decoration: brandInputDecoration(
            hint: 'nama@student.unand.ac.id',
            icon: Icons.mail_outline_rounded,
          ),
        ),
      ),
      _LabeledField(
        label: 'Nomor WhatsApp (opsional)',
        helper: 'Hanya dibagikan setelah klaim disetujui kedua pihak.',
        child: TextFormField(
          controller: _phoneController,
          enabled: !_isLoading,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          validator: Validators.reportWhatsapp,
          decoration: brandInputDecoration(
            hint: '08xxxxxxxxxx',
            icon: Icons.phone_outlined,
          ),
        ),
      ),
      _LabeledField(
        label: 'Kata sandi',
        child: TextFormField(
          controller: _passwordController,
          enabled: !_isLoading,
          obscureText: _isObscurePassword,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          validator: Validators.password,
          decoration: brandInputDecoration(
            hint: 'Minimal 8 karakter',
            icon: Icons.lock_outline_rounded,
            suffix: _VisibilityToggle(
              obscured: _isObscurePassword,
              onPressed: () =>
                  setState(() => _isObscurePassword = !_isObscurePassword),
            ),
          ),
        ),
      ),
      _LabeledField(
        label: 'Ulangi kata sandi',
        child: TextFormField(
          controller: _confirmPasswordController,
          enabled: !_isLoading,
          obscureText: _isObscureConfirm,
          textInputAction: TextInputAction.done,
          validator: _validateConfirm,
          onFieldSubmitted: (_) => _handleRegister(),
          decoration: brandInputDecoration(
            hint: 'Ketik ulang kata sandi',
            icon: Icons.lock_outline_rounded,
            suffix: _VisibilityToggle(
              obscured: _isObscureConfirm,
              onPressed: () =>
                  setState(() => _isObscureConfirm = !_isObscureConfirm),
            ),
          ),
        ),
      ),
    ];
  }
}

// ======================================================= Widget privat

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 44,
          child: IconButton(
            tooltip: 'Kembali ke Masuk',
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: BrandColors.greenDeep,
              side: const BorderSide(color: BrandColors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        const FinditLogo(variant: FinditLogoVariant.wordmark, height: 24),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buat akun Find!t',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: BrandColors.greenDeep,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Hanya untuk sivitas Universitas Andalas. Datamu dipakai untuk '
          'memastikan setiap laporan bisa dipercaya.',
          style: TextStyle(fontSize: 14, height: 1.5, color: BrandColors.body),
        ),
      ],
    );
  }
}

/// Label di atas field + teks bantuan opsional di bawahnya.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.helper});

  final String label;
  final String? helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: BrandColors.ink,
              ),
            ),
          ),
          child,
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                helper!,
                style: const TextStyle(fontSize: 12, color: BrandColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscured, required this.onPressed});
  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
      onPressed: onPressed,
      color: BrandColors.muted,
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
      ),
    );
  }
}

class _PrivacyConsent extends StatelessWidget {
  const _PrivacyConsent({
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  final bool value;
  final bool showError;
  final ValueChanged<bool>? onChanged;

  static const _errorColor = Color(0xFFB42318);

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onChanged == null ? null : () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: Checkbox(
                    value: value,
                    onChanged: onChanged == null
                        ? null
                        : (v) => onChanged(v ?? false),
                    activeColor: BrandColors.green,
                    side: BorderSide(
                      color: showError ? _errorColor : BrandColors.outline,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Saya setuju data saya diproses sesuai ',
                      children: [
                        TextSpan(
                          text: 'Kebijakan Privasi Find!t',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: BrandColors.green,
                          ),
                        ),
                        TextSpan(text: ' untuk keperluan pelaporan barang.'),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: BrandColors.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 36, top: 2),
            child: Text(
              'Centang persetujuan ini untuk melanjutkan.',
              style: TextStyle(fontSize: 12, color: _errorColor),
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDCA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFB42318),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF912018),
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB42318),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Sudah punya akun?',
          style: TextStyle(fontSize: 14, color: BrandColors.body),
        ),
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(
            foregroundColor: BrandColors.green,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Masuk'),
        ),
      ],
    );
  }
}