import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Tambahan package
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

  // Variabel untuk menampung URL foto dari database
  String? _currentAvatarUrl;

  // Variabel untuk menampung file foto sementara yang dipilih dari galeri
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  // 1. MENGAMBIL DATA SAAT INI (TERMASUK FOTO)
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
      _currentAvatarUrl = data['avatar_url']; // Ambil URL foto
    });
  }

  // 2. FUNGSI MEMBUKA GALERI HP
  Future<void> _pickImage() async {
    try {
      // Membuka galeri dan mengkompres kualitas gambar agar tidak terlalu besar
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(
            pickedFile.path,
          ); // Simpan file sementara untuk preview
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Gagal',
          message: 'Penyebab: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  // 3. FUNGSI MENYIMPAN DATA & UPLOAD FOTO
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      String? newAvatarUrl = _currentAvatarUrl;

      // Jika user memilih foto baru dari galeri, upload ke Storage dulu
      if (_imageFile != null) {
        // Buat nama file unik berdasarkan ID user dan waktu
        final fileExt = _imageFile!.path.split('.').last;
        final fileName =
            '${user!.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        // Upload ke bucket 'avatars'
        await Supabase.instance.client.storage
            .from('avatars')
            .upload(fileName, _imageFile!);

        // Dapatkan URL publik dari gambar yang baru diupload
        newAvatarUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(fileName);
      }

      // Update tabel profiles dengan data teks dan URL gambar terbaru
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
            'avatar_url': newAvatarUrl, // Update kolom avatar
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
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Gagal',
          message: 'Gagal memperbarui profil: ${e.toString()}',
          isError: true,
        );
      }
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
            // --- BAGIAN FOTO PROFIL ---
            Center(
              child: GestureDetector(
                onTap: _pickImage, // Klik untuk buka galeri
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal.shade50,
                      // Logika prioritas tampilan foto:
                      // 1. Jika ada _imageFile (baru pilih dari galeri), tampilkan itu
                      // 2. Jika tidak ada _imageFile tapi ada _currentAvatarUrl di database, tampilkan dari internet
                      // 3. Jika kosong semua, jangan tampilkan background image
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : (_currentAvatarUrl != null &&
                                _currentAvatarUrl!.isNotEmpty)
                          ? NetworkImage(_currentAvatarUrl!)
                          : null,
                      // Logika tampilan Ikon Default (Hanya muncul jika tidak ada foto sama sekali)
                      child:
                          _imageFile == null &&
                              (_currentAvatarUrl == null ||
                                  _currentAvatarUrl!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.teal,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Ketuk foto untuk mengubah',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 40),

            // --- FORM INPUT ---
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

            // --- TOMBOL SIMPAN ---
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
