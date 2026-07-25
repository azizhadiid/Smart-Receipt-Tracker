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
  // --- SISTEM & LOGIC (TIDAK DIGANGGU GUGAT) ---
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _roleController = TextEditingController();
  bool _isLoading = false;
  String? _currentAvatarUrl;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  // 1. MENGAMBIL DATA SAAT INI (TERMASUK FOTO)
  Future<void> _loadCurrentData() async {
    try {
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
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
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
    // Menentukan ImageProvider secara dinamis
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentAvatarUrl!);
    }

    return Scaffold(
      backgroundColor: Colors
          .grey[50], // Diubah ke abu-abu sangat muda agar card input menonjol
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true, // Modern look
        backgroundColor: Colors.white,
        elevation: 0.5, // Sedikit bayangan untuk memisahkan appbar dan body
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(), // Efek scroll halus
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- BAGIAN FOTO PROFIL (UPDATE DESAIN) ---
            Center(
              child: GestureDetector(
                onTap: _pickImage, // Klik untuk buka galeri
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Bingkai dan Bayangan Foto
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 60, // Sedikit lebih besar
                        backgroundColor: Colors.teal.shade50,
                        backgroundImage: imageProvider,
                        // Ikon Default muncul jika tidak ada foto
                        child: imageProvider == null
                            ? const Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.teal,
                              )
                            : null,
                      ),
                    ),
                    // Ikon Kamera/Edit di pojok
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
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
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.teal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- HEADER FORM ---
            Row(
              children: [
                const Icon(Icons.badge_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Informasi Dasar",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- FORM INPUT (UPDATE DESAIN LEBIH RAPI) ---
            // Dibungkus Container/Card putih agar lebih menonjol di atas background abu-abu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20), // Jarak lebih besar antar input

                  CustomTextField(
                    controller: _institutionController,
                    labelText: 'Asal Instansi',
                    // hintText: 'Contoh: Universitas Jambi',
                    prefixIcon: Icons.account_balance_outlined,
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: _roleController,
                    labelText: 'Peran / Pekerjaan',
                    // hintText: 'Contoh: Web Developer',
                    prefixIcon: Icons.work_outline_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48), // Jarak besar sebelum tombol
            // --- TOMBOL SIMPAN (UPDATE DESAIN PREMIUM) ---
            SizedBox(
              width: double.infinity,
              height: 55, // Tombol lebih tinggi dan nyaman ditekan
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: Colors.teal.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Rounded modern
                  ),
                  disabledBackgroundColor: Colors.teal.shade200,
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
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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
