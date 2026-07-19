import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_alert.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _roleController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  // Mengambil data saat ini untuk diisi ke dalam TextField
  Future<void> _loadCurrentData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    setState(() {
      _nameController.text = data['full_name'] ?? '';
      _institutionController.text = data['institution'] == 'Belum diatur'
          ? ''
          : data['institution'];
      _roleController.text = data['role'] == 'Pengguna' ? '' : data['role'];
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': _nameController.text.trim(),
            'institution': _institutionController.text.trim().isEmpty
                ? 'Belum diatur'
                : _institutionController.text.trim(),
            'role': _roleController.text.trim().isEmpty
                ? 'Pengguna'
                : _roleController.text.trim(),
          })
          .eq('id', user!.id);

      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Berhasil',
          message: 'Profil Anda telah diperbarui.',
          isError: false,
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted)
            Navigator.pop(
              context,
              true,
            ); // Kembali dan bawa status 'true' agar halaman sebelumnya me-refresh data
        });
      }
    } catch (e) {
      if (mounted)
        showCustomAlert(
          context: context,
          title: 'Gagal',
          message: 'Gagal memperbarui profil.',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
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
            // Placeholder untuk edit foto nanti
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal.shade50,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.teal,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            CustomTextField(
              controller: _nameController,
              labelText: 'Nama Lengkap',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _institutionController,
              labelText: 'Asal Instansi (Contoh: Universitas Jambi)',
              prefixIcon: Icons.business_outlined,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _roleController,
              labelText: 'Peran / Pekerjaan (Contoh: Web Developer)',
              prefixIcon: Icons.work_outline,
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
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
                      'Simpan Perubahan',
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
