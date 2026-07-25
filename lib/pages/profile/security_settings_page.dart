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
  // --- SISTEM & LOGIC (TIDAK DIGANGGU GUGAT) ---
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

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

  // --- DESAIN UI (DIPERBARUI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background lebih bersih
      appBar: AppBar(
        title: const Text(
          'Keamanan Akun',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF00838F), // Cyan Gelap
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF00838F)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(), // Efek scroll modern
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER IKON ---
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_rounded, // Sedikit diubah agar lebih modern
                  size: 70,
                  color: Color(0xFF00897B),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- TEKS INSTRUKSI ---
            const Text(
              'Perbarui Password Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00838F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan password Anda menggunakan kombinasi huruf dan angka agar akun tetap aman.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // --- WADAH FORM INPUT ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Field Password Saat Ini
                  CustomTextField(
                    controller: _currentPasswordController,
                    labelText: 'Password Saat Ini',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscureCurrent,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Garis Pemisah Lembut
                  Divider(
                    color: Colors.grey.shade200,
                    thickness: 1.5,
                    height: 32,
                  ),

                  // Field Password Baru
                  CustomTextField(
                    controller: _newPasswordController,
                    labelText: 'Password Baru',
                    prefixIcon: Icons.lock_rounded,
                    obscureText: _obscureNew,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Field Konfirmasi Password Baru
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Konfirmasi Password Baru',
                    prefixIcon: Icons.lock_reset_rounded,
                    obscureText: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- TOMBOL SIMPAN GRADASI 3D ---
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
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
                  backgroundColor:
                      Colors.transparent, // Transparan agar gradient terlihat
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                        'Simpan Password Baru',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20), // Tambahan ruang kosong di bawah
          ],
        ),
      ),
    );
  }
}
