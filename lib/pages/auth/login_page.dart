import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_receipt/pages/auth/reset_password_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Tambahan Import

import '../../layouts/main_layout.dart';
import '../../components/custom_alert.dart';
import '../../components/custom_text_field.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    // --- PENDENGAR STATUS AUTENTIKASI ---
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.passwordRecovery) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
        );
      }
      // Logika pengecekan umur akun (Mencegah Auto-Signup via Google)
      else if (event == AuthChangeEvent.signedIn && session != null) {
        final user = session.user;
        final createdAt = DateTime.parse(user.createdAt).toUtc();
        final now = DateTime.now().toUtc();

        if (now.difference(createdAt).inSeconds < 10) {
          // Hapus akun hantu dan sign out
          try {
            await Supabase.instance.client.rpc('delete_ghost_account');
          } catch (e) {
            debugPrint('Gagal menghapus ghost account: $e');
          }
          await Supabase.instance.client.auth.signOut();

          if (mounted) {
            showCustomAlert(
              context: context,
              title: 'Akun Tidak Ditemukan',
              message:
                  'Email Google Anda belum terdaftar. Silakan daftar terlebih dahulu.',
              isError: true,
            );
          }
        } else {
          // Lanjut ke Dashboard jika akun valid
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainLayout()),
            );
          }
        }
      }
    });
  }

  // --- LOGIKA LOGIN EMAIL ---
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showCustomAlert(
        context: context,
        title: 'Data Tidak Lengkap',
        message: 'Masukkan email dan password Anda untuk masuk.',
        isError: true,
      );
      return;
    }

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

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Navigasi dikendalikan oleh _authSubscription di atas
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan saat login.';
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          errorMessage = 'Email atau password yang Anda masukkan salah.';
        }
        showCustomAlert(
          context: context,
          title: 'Gagal Masuk',
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

  // --- LOGIKA LOGIN GOOGLE NATIVE ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      const webClientId =
          '757039015502-p2m5akek1lqduu6t1gr9ssbk7b92nm02.apps.googleusercontent.com';
      const iosClientId =
          '757039015502-m76273m6vi74k6bl9fi5nepvlfbbrqs7.apps.googleusercontent.com';

      // 1. Inisialisasi konfigurasi Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        clientId: iosClientId,
      );

      // 2. Munculkan pop-up akun Google bawaan HP
      final googleUser = await googleSignIn.signIn();

      // Jika user menekan di luar kotak dialog / batal login
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 3. Ekstrak token keamanan dari Google
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Gagal mendapatkan otorisasi dari Google.';
      }

      // 4. Masuk ke Supabase menggunakan ID Token Google
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Catatan: Setelah ini berhasil, _authSubscription di atas akan otomatis berjalan
      // untuk memeriksa apakah akun ini legal (sudah daftar) atau ghost account.
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Gagal Login Google',
          message: e.toString(),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 140,
                      height: 140,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Selamat Datang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00838F),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk melanjutkan ke Smart Receipt',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),

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
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00ACC1),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Lupa Password?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF00897B)],
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
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.transparent,
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
                            'Masuk',
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

                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ATAU',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- TOMBOL LOGIN GOOGLE YANG SUDAH TERHUBUNG ---
                OutlinedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.g_mobiledata,
                              color: Colors.blue,
                              size: 30,
                            ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Masuk dengan Google',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Daftar Sekarang',
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
        ),
      ),
    );
  }
}
