import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../utils/validators.dart'; // Pastikan file ini memiliki fungsi validasi yang sesuai

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscurePassword = true;
  bool _isObscureConfirm = true;
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulasi proses asinkron pendaftaran ke server
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulasi kemungkinan error acak (opsional, hapus di produksi)
      // if (DateTime.now().second % 2 == 0) throw Exception("Koneksi terputus");

      if (!mounted) return;
      
      // Berhasil mendaftar, kembali ke halaman sebelumnya dengan data hasil (opsional)
      Navigator.pop(context, _emailController.text);
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Gagal melakukan registrasi. Silakan periksa koneksi Anda.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onLoginTapped() {
    if (_isLoading) return;
    // Menggunakan named routes sesuai konstanta
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Tangani aksi jika back ditekan namun dihalangi (misal saat loading)
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Latar belakang sesuai spesifikasi
        appBar: AppBar(
          backgroundColor: const Color(0xFFF1F5F9),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () {
              if (!_isLoading) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Registrasi Akun',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF045436)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gunakan identitas sivitas akademik Unand',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Color(0xFF595858),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildInputField(
                          label: 'Nama Lengkap',
                          hint: 'Nama sesuai KTM',
                          controller: _nameController,
                          validator: Validators.registerName, // Sesuaikan dengan class di validators.dart
                        ),
                        _buildInputField(
                          label: 'NIM/NIP',
                          hint: 'Contoh: 2411522019',
                          controller: _idController,
                          keyboardType: TextInputType.number,
                          validator: Validators.institutionalEmailOrNip,
                        ),
                        _buildInputField(
                          label: 'Email kampus',
                          hint: 'nama@student.unand.ac.id',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.institutionalEmailOrNip,
                        ),
                        _buildInputField(
                          label: 'Nomor WhatsApp',
                          hint: '08xxxxxxxxxx',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: Validators.noWhatsAppp, // Sesuaikan dengan class di validators.dart
                        ),
                        _buildInputField(
                          label: 'Kata Sandi',
                          hint: 'Minimal 8 karakter',
                          controller: _passwordController,
                          obscureText: _isObscurePassword,
                          validator: Validators.password, // Sesuaikan dengan class di validators.dart
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _isObscurePassword = !_isObscurePassword),
                          ),
                        ),
                        _buildInputField(
                          label: 'Konfirmasi Kata Sandi',
                          hint: 'Masukkan kata sandi',
                          controller: _confirmPasswordController,
                          obscureText: _isObscureConfirm,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Kata sandi tidak cocok';
                            }
                            return Validators.confirmPassword(value, _passwordController.text);
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscureConfirm ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                          ),
                        ),
                        
                        // Menampilkan Error State dengan Tombol Muat Ulang
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _handleRegister,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Coba Lagi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade100,
                                    foregroundColor: Colors.red.shade800,
                                    elevation: 0,
                                  ),
                                )
                              ],
                            ),
                          ),

                        const SizedBox(height: 10),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF045436),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                fontFamily: 'Calibri',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFFFAFFF4),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Center(
                          child: GestureDetector(
                            onTap: _onLoginTapped,
                            child: RichText(
                              text: const TextSpan(
                                text: 'Sudah punya akun sivitas? ',
                                style: TextStyle(
                                  fontFamily: 'Calibri',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Color(0xFF595858),
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Masuk',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF045436),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF595858),
              ),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0x40000000), width: 1), // rgba(0,0,0,0.25)
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0x40000000), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF045436), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}