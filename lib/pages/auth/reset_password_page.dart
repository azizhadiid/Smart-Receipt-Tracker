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
      if (mounted)
        showCustomAlert(
          context: context,
          title: 'Gagal',
          message: e.message,
          isError: true,
        );
    } catch (e) {
      if (mounted)
        showCustomAlert(
          context: context,
          title: 'Error',
          message: 'Koneksi bermasalah.',
          isError: true,
        );
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading:
            false, // Menghilangkan tombol back agar tidak error navigasi
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.teal),
            const SizedBox(height: 30),

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
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
