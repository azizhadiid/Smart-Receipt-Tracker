import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Tambahkan package intl di pubspec.yaml jika belum ada
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
  final bool _isProcessing = false;

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

  // --- POPUP FORM MANUAL SEBELUM UPLOAD ---
  void _showManualInputForm() {
    if (_selectedFile == null) {
      showCustomAlert(
        context: context,
        title: 'File Kosong',
        message: 'Silakan pilih struk (Foto/PDF/Excel) terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Detail Transaksi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00838F),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Masukkan detail secara manual karena sistem ML Kit belum diaktifkan.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Nama Transaksi / Toko',
                        prefixIcon: const Icon(Icons.store),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Harga (Rp)',
                        prefixIcon: const Icon(Icons.monetization_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && picked != selectedDate) {
                          setStateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        DateFormat('dd MMMM yyyy').format(selectedDate),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isUploading)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (titleController.text.isEmpty ||
                              amountController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Harap isi semua kolom'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => isUploading = true);

                          await _uploadToSupabase(
                            title: titleController.text,
                            amount: double.parse(amountController.text),
                            date: selectedDate,
                          );

                          if (context.mounted) {
                            Navigator.pop(
                              context,
                            ); // Tutup dialog setelah selesai
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Data',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- LOGIKA UPLOAD KE SUPABASE & SIMPAN KE DATABASE ---
  Future<void> _uploadToSupabase({
    required String title,
    required double amount,
    required DateTime date,
  }) async {
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

      // 4. Simpan ke Database Tabel 'transactions' menggunakan data inputan
      await Supabase.instance.client.from('transactions').insert({
        'user_id': user.id,
        'title': title,
        'amount': amount,
        'transaction_date': date.toIso8601String(),
        'receipt_image_url':
            publicUrl, // Nama kolom disesuaikan dengan skema Anda
      });

      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Berhasil',
          message: 'Struk berhasil disimpan ke riwayat Anda!',
          isError: false,
        );

        // Reset state utama setelah berhasil
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

    // Jika file adalah gambar, tampilkan preview gambar
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

    // Jika file adalah PDF atau Excel, tampilkan Ikon
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Area Preview Gambar / File
            Expanded(
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
            const SizedBox(height: 32),

            // 2. Tombol Pilihan (Kamera / Galeri)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showCustomAlert(
                        context: context,
                        title: 'Info',
                        message:
                            'Fitur kamera akan diaktifkan nanti saat pengujian di perangkat asli.',
                        isError: false,
                      );
                    },
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: const Text(
                      'Kamera',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00897B),
                      backgroundColor: const Color(
                        0xFF00BCD4,
                      ).withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Color(0xFF00BCD4),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickFile,
                    icon: const Icon(Icons.folder, size: 20),
                    label: const Text(
                      'Pilih File',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00897B),
                      backgroundColor: const Color(
                        0xFF00BCD4,
                      ).withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Color(0xFF00BCD4),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Tombol Proses & Upload (Memicu Pop-Up Form)
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
                onPressed: _isProcessing ? null : _showManualInputForm,
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
                        'Unggah & Proses Struk',
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
      ),
    );
  }
}
