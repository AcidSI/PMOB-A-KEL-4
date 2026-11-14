import 'package:flutter/material.dart';

import 'package:find_it/routes/app_routes.dart';
import 'package:find_it/services/app_session.dart';
import 'package:find_it/utils/validators.dart';
import 'package:find_it/widgets/brand/findit_brand.dart';

/// Halaman Masuk dengan identitas logo Find!t.
///
/// Logika tetap seperti sebelumnya: validasi email @student.unand.ac.id /
/// NIP dan kata sandi, `AppSession.signIn`, lalu ke Beranda.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _hasAttemptedSubmit = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    AppSession.signIn(_identityController.text);
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  Future<void> _openRegister() async {
    final email = await Navigator.pushNamed<String>(
      context,
      AppRoutes.register,
    );
    // Halaman Daftar dapat mengembalikan email yang baru didaftarkan.
    if (!mounted || email == null || email.isEmpty) return;
    setState(() => _identityController.text = email);
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Fitur atur ulang kata sandi belum tersedia. Hubungi admin Find!t.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ---- Hiasan latar (dari unsur logo)
          const Positioned(
            left: -70,
            top: -120,
            child: BrandBlob(size: 260, color: BrandColors.mint),
          ),
          const Positioned(right: 34, top: 46, child: BrandRing()),
          const Positioned(left: 40, top: 156, child: BrandLeaf(width: 30)),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: FinditLogo(width: 150)),
                        const SizedBox(height: 26),
                        const _Heading(),
                        const SizedBox(height: 22),
                        _buildForm(),
                        const SizedBox(height: 16),
                        const _CampusOnlyNotice(),
                        const Spacer(),
                        const SizedBox(height: 24),
                        _RegisterPrompt(onRegister: _openRegister),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _hasAttemptedSubmit
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('Email kampus atau NIP'),
          TextFormField(
            key: const Key('login-identity'),
            controller: _identityController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: Validators.institutionalEmailOrNip,
            decoration: brandInputDecoration(
              hint: 'nama@student.unand.ac.id',
              icon: Icons.mail_outline,
            ),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Kata sandi'),
          TextFormField(
            key: const Key('login-password'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            validator: Validators.password,
            onFieldSubmitted: (_) => _submit(),
            decoration: brandInputDecoration(
              hint: 'Minimal 8 karakter',
              icon: Icons.lock_outline,
              suffix: IconButton(
                tooltip: _obscurePassword
                    ? 'Tampilkan kata sandi'
                    : 'Sembunyikan kata sandi',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: BrandColors.green,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Lupa kata sandi?'),
            ),
          ),
          const SizedBox(height: 4),
          BrandPrimaryButton(
            key: const Key('login-submit'),
            label: 'Masuk',
            trailingIcon: Icons.arrow_forward,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ======================================================= Widget privat

class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masuk ke akunmu',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: BrandColors.greenDeep,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Gunakan email kampus atau NIP Universitas Andalas.',
          style: TextStyle(fontSize: 14, color: BrandColors.body),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: BrandColors.ink,
        ),
      ),
    );
  }
}

class _CampusOnlyNotice extends StatelessWidget {
  const _CampusOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BrandColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFBE3A0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: Color(0xFF8A6300),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hanya sivitas Unand yang dapat masuk, supaya setiap laporan '
              'bisa dipercaya.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF5C4300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  const _RegisterPrompt({required this.onRegister});
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Belum punya akun?',
          style: TextStyle(fontSize: 14, color: BrandColors.body),
        ),
        TextButton(
          key: const Key('login-register'),
          onPressed: onRegister,
          style: TextButton.styleFrom(
            foregroundColor: BrandColors.green,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Daftar sekarang'),
        ),
      ],
    );
  }
}
