import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/custom_alert.dart';
import '../../components/custom_text_field.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      showCustomAlert(
        context: context,
        title: 'Data Kosong',
        message: 'Silakan isi kedua kolom password.',
        isError: true,
      );
      return;
    }

    if (password != confirmPassword) {
      showCustomAlert(
        context: context,
        title: 'Tidak Cocok',
        message: 'Kombinasi password dan konfirmasi password tidak sama.',
        isError: true,
      );
      return;
    }

    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      showCustomAlert(
        context: context,
        title: 'Password Lemah',
        message:
            'Minimal 8 karakter dan mengandung kombinasi huruf serta angka.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fungsi Supabase untuk memperbarui password user yang sedang memiliki token pemulihan
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Berhasil!',
          message:
              'Password Anda telah berhasil diubah. Silakan masuk (login) dengan password baru.',
          isError: false,
        );
        Future.delayed(const Duration(seconds: 3), () {
          // Hapus semua tumpukan layar dan paksa kembali ke layar Login
          if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Gagal',
          message: e.message,
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Error',
          message: 'Koneksi bermasalah.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Buat Password Baru',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading:
            false, // Menghilangkan tombol back agar tidak error navigasi
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- LOGO / IKON APLIKASI KECIL ---
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
                    // Fallback jika gambar gagal dimuat
                    return Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 50,
                        color: Color(0xFF00838F),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- TEKS HEADER ---
            const Text(
              'Amankan Akun Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00838F), // Cyan gelap yang elegan
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Silakan buat password baru yang kuat dan mudah Anda ingat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // --- FORM INPUT ---
            CustomTextField(
              controller: _passwordController,
              labelText: 'Password Baru',
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
            const SizedBox(height: 16),

            CustomTextField(
              controller: _confirmPasswordController,
              labelText: 'Konfirmasi Password Baru',
              prefixIcon: Icons.lock_reset,
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 40),

            // --- TOMBOL SIMPAN PASSWORD ---
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
                onPressed: _isLoading ? null : _updatePassword,
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
                        'Simpan Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
