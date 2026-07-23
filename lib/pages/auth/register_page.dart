import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/custom_alert.dart'; // Import Custom Alert
import '../../components/custom_text_field.dart'; // Import Custom Text Field

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 1. Validasi Kolom Kosong
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showCustomAlert(
        context: context,
        title: 'Data Tidak Lengkap',
        message: 'Pastikan semua kolom telah diisi sebelum mendaftar.',
        isError: true,
      );
      return;
    }

    // 2. Validasi Nama dan Email tidak boleh sama
    if (name.toLowerCase() == email.toLowerCase()) {
      showCustomAlert(
        context: context,
        title: 'Keamanan Akun',
        message: 'Nama lengkap tidak boleh sama dengan alamat email Anda.',
        isError: true,
      );
      return;
    }

    // 3. Validasi Format Email
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailRegex.hasMatch(email)) {
      showCustomAlert(
        context: context,
        title: 'Format Email Salah',
        message: 'Masukkan alamat email yang valid (contoh: budi@gmail.com).',
        isError: true,
      );
      return;
    }

    // 4. Validasi Password
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      showCustomAlert(
        context: context,
        title: 'Password Lemah',
        message:
            'Password minimal 8 karakter dan harus mengandung kombinasi huruf dan angka.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simpan balasan dari Supabase ke dalam variabel 'response'
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
        emailRedirectTo: 'smartreceipt://login-callback',
      );

      if (mounted) {
        // Cek apakah email sudah pernah didaftarkan (identities kosong)
        if (response.user != null &&
            response.user!.identities != null &&
            response.user!.identities!.isEmpty) {
          showCustomAlert(
            context: context,
            title: 'Email Sudah Digunakan',
            message:
                'Email ini telah terdaftar. Silakan gunakan email lain atau masuk (login).',
            isError: true,
          );
          return; // Hentikan proses
        }

        // --- LOGIKA BARU VERIFIKASI EMAIL ---
        // Jika session null, berarti Supabase sedang menunggu user klik link di email
        if (response.session == null) {
          showCustomAlert(
            context: context,
            title: 'Cek Inbox Email Anda!',
            message:
                'Tautan verifikasi telah dikirim ke $email. Silakan klik tautan tersebut untuk mengaktifkan akun sebelum Anda bisa Login.',
            isError: false,
          );
        } else {
          // Jaga-jaga jika sewaktu-waktu kamu mematikan fitur verifikasi email di dashboard
          showCustomAlert(
            context: context,
            title: 'Registrasi Berhasil!',
            message: 'Akun Anda telah dibuat. Silakan masuk (login).',
            isError: false,
          );
        }

        // Kembali ke halaman Login setelah 4 detik agar user sempat membaca pesan
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        if (errorMessage.toLowerCase().contains('user already registered')) {
          errorMessage =
              'Email ini sudah terdaftar. Silakan gunakan email lain atau coba masuk (login).';
        }
        showCustomAlert(
          context: context,
          title: 'Gagal Mendaftar',
          message: errorMessage,
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Terjadi Kesalahan',
          message: 'Pastikan koneksi internet stabil dan coba lagi.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Buat Akun',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- LOGO APLIKASI KECIL ---
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 90,
                  height: 90,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- TEKS HEADER ---
            const Text(
              'Mulai Kelola Strukmu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00838F), // Cyan gelap yang elegan
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daftar sekarang untuk memantau pengeluaran dengan lebih cerdas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // --- FORM INPUT ---
            CustomTextField(
              controller: _nameController,
              labelText: 'Nama Lengkap',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _emailController,
              labelText: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _passwordController,
              labelText: 'Password',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 32),

            // --- TOMBOL DAFTAR ---
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00BCD4),
                    Color(0xFF00897B),
                  ], // Cyan ke Teal
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BCD4).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      Colors.transparent, // Transparan agar gradient terlihat
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Daftar Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // --- LINK KE LOGIN ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sudah punya akun? ',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Masuk',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00ACC1),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
