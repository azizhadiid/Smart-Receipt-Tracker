import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/login_page.dart';

// Import sub-halaman
import 'profile/budget_settings_page.dart';
import 'profile/export_data_page.dart';
import 'profile/security_settings_page.dart';
import 'profile/help_support_page.dart';
import 'profile/edit_profile_page.dart'; // Import halaman edit yang baru dibuat

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _fullName = 'Memuat...';
  String _institution = 'Memuat...';
  String _role = 'Memuat...';
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Fungsi untuk membaca data dari Supabase
  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _fullName = data['full_name'] ?? 'Pengguna Tanpa Nama';
          _institution = data['institution'] ?? 'Belum diatur';
          _role = data['role'] ?? 'Pengguna';
          _avatarUrl = data['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // 1. Bagian Foto Profil dan Data Diri
                  Center(
                    child: Column(
                      children: [
                        // Logika menampilkan foto asli atau ikon default
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.teal.shade100,
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: _avatarUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.teal,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _institution,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _role,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tombol Edit Profil
                        OutlinedButton.icon(
                          onPressed: () async {
                            // Menunggu hasil dari halaman Edit Profile
                            final bool? isUpdated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                            // Jika user klik simpan, refresh data di halaman ini
                            if (isUpdated == true) {
                              _fetchProfileData();
                            }
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Data Diri'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: const BorderSide(color: Colors.teal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 2. Menu Pengaturan Aplikasi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengaturan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _buildProfileMenu(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Batas Budget Bulanan',
                          subtitle: 'Atur batas pengeluaran maksimum',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BudgetSettingsPage(),
                            ),
                          ),
                        ),

                        _buildProfileMenu(
                          icon: Icons.download_outlined,
                          title: 'Download Laporan (Excel/PDF)',
                          subtitle: 'Unduh laporan keuangan',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExportDataPage(),
                            ),
                          ),
                        ),

                        _buildProfileMenu(
                          icon: Icons.security_outlined,
                          title: 'Keamanan Akun',
                          subtitle: 'Ubah password atau PIN',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SecuritySettingsPage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Lainnya',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _buildProfileMenu(
                          icon: Icons.help_outline,
                          title: 'Bantuan & Dukungan',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportPage(),
                            ),
                          ),
                        ),

                        // Tombol Logout
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout, color: Colors.red),
                          ),
                          title: const Text(
                            'Keluar (Logout)',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () async {
                            // Pastikan keluar dari sesi Supabase juga
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileMenu({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
