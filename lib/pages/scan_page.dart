import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/custom_alert.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  File? _selectedFile;
  String? _fileName;
  String? _fileExtension;
  bool _isProcessing = false;

  Future<void> _scanReceiptWithCamera() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      setState(() {
        _selectedFile = File(image.path);
        _fileName = image.name;
        _fileExtension = image.name.split('.').last.toLowerCase();
      });
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Kamera Tidak Dapat Dibuka',
          message: 'Periksa izin kamera perangkat lalu coba lagi.\n$e',
          isError: true,
        );
      }
    }
  }

  // --- LOGIKA MEMILIH FILE DARI GALERI/PENYIMPANAN ---
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'xls', 'xlsx'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _fileExtension = result.files.single.extension?.toLowerCase();
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Gagal Memilih File',
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  // --- LOGIKA UPLOAD KE SUPABASE & SIMPAN KE DATABASE (SEDERHANA) ---
  Future<void> _uploadToSupabase() async {
    if (_selectedFile == null) {
      showCustomAlert(
        context: context,
        title: 'File Kosong',
        message: 'Silakan pilih struk (Foto/PDF/Excel) terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Sesi pengguna tidak valid.');

      // 1. Membuat nama file yang unik
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${user.id}_$timestamp.$_fileExtension';

      // 2. Upload fisik file ke bucket 'receipts'
      await Supabase.instance.client.storage
          .from('receipts')
          .upload(uniqueFileName, _selectedFile!);

      // 3. Mengambil URL publik
      final publicUrl = Supabase.instance.client.storage
          .from('receipts')
          .getPublicUrl(uniqueFileName);

      // 4. Simpan ke Database Tabel 'transactions' menggunakan data DUMMY sementara
      await Supabase.instance.client.from('transactions').insert({
        'user_id': user.id,
        'title': 'Struk Baru ($_fileExtension)', // Judul sementara
        'amount': 0, // Harga 0 sementara
        'transaction_date': DateTime.now()
            .toIso8601String(), // Tanggal hari ini
        'receipt_image_url': publicUrl, // Link gambar dari storage
      });

      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Berhasil',
          message: 'Gambar telah terscan dan tersimpan ke riwayat!',
          isError: false,
        );

        // Reset state setelah upload berhasil
        setState(() {
          _selectedFile = null;
          _fileName = null;
          _fileExtension = null;
        });
      }
    } on StorageException catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Gagal Mengunggah',
          message: 'Pesan dari server: ${e.message}',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Terjadi Kesalahan',
          message: e.toString(),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- HELPER UNTUK TAMPILAN PREVIEW ---
  Widget _buildFilePreview() {
    if (_selectedFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              size: 60,
              color: Color(0xFF00897B),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ambil atau pilih file struk',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mendukung format JPG, PNG, PDF & Excel',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      );
    }

    if (['jpg', 'jpeg', 'png'].contains(_fileExtension)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.file(
          _selectedFile!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    IconData fileIcon = Icons.insert_drive_file;
    Color iconColor = Colors.grey;
    if (_fileExtension == 'pdf') {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.red.shade400;
    } else if (['xls', 'xlsx'].contains(_fileExtension)) {
      fileIcon = Icons.table_chart;
      iconColor = Colors.green.shade400;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(fileIcon, size: 80, color: iconColor),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _fileName ?? 'Dokumen terpilih',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF00838F),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _selectedFile = null),
          icon: const Icon(Icons.close, size: 16, color: Colors.red),
          label: const Text('Batal Pilih', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Scan Struk',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF00838F),
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          final isShort = constraints.maxHeight < 650;
          final pagePadding = isNarrow ? 16.0 : 24.0;
          final previewHeight = (constraints.maxHeight * (isShort ? 0.32 : 0.42))
              .clamp(180.0, 360.0)
              .toDouble();
          final buttonPadding = EdgeInsets.symmetric(
            vertical: isShort ? 13 : 16,
          );

          final scanButton = OutlinedButton.icon(
            onPressed: _isProcessing ? null : _scanReceiptWithCamera,
            icon: const Icon(Icons.document_scanner, size: 20),
            label: const Text('Scan', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00897B),
              backgroundColor: const Color(0xFF00BCD4).withOpacity(0.05),
              padding: buttonPadding,
              side: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
          final fileButton = OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickFile,
            icon: const Icon(Icons.folder, size: 20),
            label: const Text(
              'Pilih File',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00897B),
              backgroundColor: const Color(0xFF00BCD4).withOpacity(0.05),
              padding: buttonPadding,
              side: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pagePadding, pagePadding, pagePadding, 108),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: previewHeight,
                  child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.03),
                      border: Border.all(
                        color: const Color(0xFF00BCD4).withOpacity(0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _buildFilePreview(),
                  ),
                ),
                  ),
                ),
                SizedBox(height: isShort ? 20 : 32),
                if (isNarrow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      scanButton,
                      const SizedBox(height: 12),
                      fileButton,
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: scanButton),
                      const SizedBox(width: 16),
                      Expanded(child: fileButton),
                    ],
                  ),
                SizedBox(height: isShort ? 16 : 24),

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
                // Memanggil _uploadToSupabase secara langsung tanpa pop-up
                onPressed: _isProcessing ? null : _uploadToSupabase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Unggah Gambar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
