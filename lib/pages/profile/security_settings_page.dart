import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/custom_alert.dart';
import '../../components/custom_text_field.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // --- LOGIKA UPDATE PASSWORD ---
  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 1. Validasi Kolom Kosong
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      showCustomAlert(
        context: context,
        title: 'Data Tidak Lengkap',
        message: 'Harap isi semua kolom password.',
        isError: true,
      );
      return;
    }

    // 2. Validasi Konfirmasi Password
    if (newPassword != confirmPassword) {
      showCustomAlert(
        context: context,
        title: 'Password Tidak Cocok',
        message: 'Password baru dan konfirmasi password tidak sama.',
        isError: true,
      );
      return;
    }

    // 3. Validasi Kekuatan Password Baru
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    if (!passwordRegex.hasMatch(newPassword)) {
      showCustomAlert(
        context: context,
        title: 'Password Lemah',
        message:
            'Password baru minimal 8 karakter dan mengandung kombinasi huruf serta angka.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Ambil data user yang sedang login saat ini
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Sesi pengguna tidak ditemukan. Silakan login ulang.');
      }

      // 4. Verifikasi Password Saat Ini (Re-authentication)
      // Kita mencoba login di latar belakang. Jika error dilempar, berarti password lama salah.
      await Supabase.instance.client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      // 5. Update ke Password Baru
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Update Berhasil!',
          message: 'Password akun Anda telah berhasil diperbarui.',
          isError: false,
        );

        // Bersihkan seluruh kolom form setelah berhasil
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        // Menangkap error jika password lama yang diketikkan ternyata salah
        if (errorMessage.toLowerCase().contains('invalid login credentials')) {
          errorMessage = 'Password saat ini yang Anda masukkan salah.';
        } else if (errorMessage.toLowerCase().contains('same as the old')) {
          errorMessage =
              'Password baru tidak boleh sama dengan password saat ini.';
        }
        showCustomAlert(
          context: context,
          title: 'Gagal Update',
          message: errorMessage,
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Terjadi Kesalahan',
          message: 'Pastikan koneksi internet Anda stabil.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Keamanan Akun',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.shield_outlined, size: 80, color: Colors.teal),
            const SizedBox(height: 16),
            Text(
              'Pastikan password Anda menggunakan kombinasi huruf dan angka agar akun tetap aman.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),

            // Field Password Saat Ini
            CustomTextField(
              controller: _currentPasswordController,
              labelText: 'Password Saat Ini',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureCurrent,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 20),

            // Field Password Baru
            CustomTextField(
              controller: _newPasswordController,
              labelText: 'Password Baru',
              prefixIcon: Icons.lock,
              obscureText: _obscureNew,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: 20),

            // Field Konfirmasi Password Baru
            CustomTextField(
              controller: _confirmPasswordController,
              labelText: 'Konfirmasi Password Baru',
              prefixIcon: Icons.lock_reset,
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            const SizedBox(height: 40),

            // Tombol Simpan
            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.teal.shade200,
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
                      'Simpan Password Baru',
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
