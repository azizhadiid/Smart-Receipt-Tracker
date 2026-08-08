import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:excel/excel.dart' hide Border;
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
      
      // Langsung jalankan proses setelah foto diambil
      await _uploadToSupabase();
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
        
        // Langsung jalankan proses setelah file dipilih
        await _uploadToSupabase();
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

  // --- LOGIKA EKSTRAKSI TEKS & VALIDASI (OCR / READERS) ---
  Future<String> _extractTextFromFile() async {
    if (_selectedFile == null || _fileExtension == null) return '';
    String extractedText = '';

    try {
      if (['jpg', 'jpeg', 'png'].contains(_fileExtension)) {
        final inputImage = InputImage.fromFile(_selectedFile!);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        try {
          final recognizedText = await textRecognizer.processImage(inputImage);
          extractedText = recognizedText.text;
        } finally {
          await textRecognizer.close();
        }
      } else if (_fileExtension == 'pdf') {
        try {
          extractedText = await ReadPdfText.getPDFtext(_selectedFile!.path);
        } catch (_) {
          extractedText = '';
        }
      } else if (['xls', 'xlsx'].contains(_fileExtension)) {
        try {
          final bytes = _selectedFile!.readAsBytesSync();
          final excel = Excel.decodeBytes(bytes);
          for (var table in excel.tables.keys) {
            final sheet = excel.tables[table];
            if (sheet != null) {
              for (var row in sheet.rows) {
                for (var cell in row) {
                  if (cell != null && cell.value != null) {
                    extractedText += '${cell.value} ';
                  }
                }
                extractedText += '\n';
              }
            }
          }
        } catch (_) {
          extractedText = '';
        }
      }
    } catch (e) {
      debugPrint('Error extracting text: $e');
    }
    return extractedText;
  }

  double _extractAmount(String text) {
    final lines = text.split('\n');
    double maxAmount = 0;
    double keywordAmount = 0;
    
    // Kata kunci umum pada struk untuk menandai total belanja
    final keywords = ['grand total', 'total', 'bayar', 'jumlah', 'tagihan', 'netto', 'amount', 'total bayar'];

    for (var line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Deteksi angka nominal (misal: 45.000, 150,000, Rp 25.000, 50000)
      final matches = RegExp(r'(?:[Rr][Pp]\.?\s*)?([0-9]+(?:[\.\,][0-9]{2,3})*(?:[\.\,][0-9]{1,2})?)').allMatches(line);
      
      for (var match in matches) {
        String numStr = match.group(1) ?? '';
        // Hapus akhir desimal .00 atau ,00
        numStr = numStr.replaceAll(RegExp(r'[\.\,](00)$'), '');
        // Hapus semua titik, koma, dan simbol selain angka murni
        numStr = numStr.replaceAll(RegExp(r'[^0-9]'), '');
        
        if (numStr.isNotEmpty) {
          final val = double.tryParse(numStr) ?? 0;
          // Abaikan nominal terlalu kecil (< 100) atau tidak masuk akal (> 500 juta)
          if (val >= 100 && val <= 500000000) {
            if (val > maxAmount) maxAmount = val;
            if (keywords.any((k) => lowerLine.contains(k))) {
              if (val > keywordAmount) keywordAmount = val;
            }
          }
        }
      }
    }

    // Prioritaskan angka di dekat kata kunci total jika ada
    return keywordAmount > 0 ? keywordAmount : maxAmount;
  }

  String _extractTitle(String text) {
    final lines = text.split('\n');
    for (var line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.length < 3) continue;
      // Abaikan jika hanya angka atau simbol
      if (RegExp(r'^[0-9\W]+$').hasMatch(cleanLine)) continue;
      
      final lower = cleanLine.toLowerCase();
      // Abaikan informasi umum di kop surat/struk
      if (lower.startsWith('jl') || lower.startsWith('jln') || lower.startsWith('telp') || 
          lower.startsWith('npwp') || lower.contains('kasir') || lower.contains('tanggal') ||
          lower.startsWith('no.') || lower.contains('struk') || lower.startsWith('www.')) {
        continue;
      }
      // Ambil baris teks pertama yang valid sebagai nama toko/judul transaksi
      return cleanLine.length > 45 ? cleanLine.substring(0, 45) : cleanLine;
    }
    return 'Struk Belanja (${_fileExtension?.toUpperCase() ?? "DOC"})';
  }

  String _extractDate(String text) {
    // Cari pola tanggal DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY atau YYYY-MM-DD
    final dateRegex = RegExp(r'(\d{1,4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,4})');
    final match = dateRegex.firstMatch(text);
    if (match != null) {
      try {
        int part1 = int.parse(match.group(1)!);
        int part2 = int.parse(match.group(2)!);
        int part3 = int.parse(match.group(3)!);
        
        int day = part1;
        int month = part2;
        int year = part3;

        // Jika format YYYY-MM-DD
        if (part1 > 1000) {
          year = part1;
          month = part2;
          day = part3;
        } else if (part3 < 100) {
          year = 2000 + part3;
        }

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          final date = DateTime(year, month, day);
          return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        }
      } catch (_) {
        // Fallback jika gagal parse
      }
    }
    // Default menggunakan tanggal hari ini dalam format YYYY-MM-DD
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // --- LOGIKA UPLOAD KE SUPABASE & SIMPAN KE DATABASE ---
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
      if (user == null) throw Exception('Sesi pengguna tidak valid. Silakan login terlebih dahulu.');

      // 1. Ekstraksi teks dari file (OCR untuk gambar, ReadPdf untuk PDF, Excel decoder)
      final extractedText = await _extractTextFromFile();
      final numberRegex = RegExp(r'\d+');

      // 2. VALIDASI TEKS / REJECT FILE: Jika bukan struk dan tidak ada angka
      if (extractedText.trim().isEmpty || !numberRegex.hasMatch(extractedText)) {
        if (mounted) {
          showCustomAlert(
            context: context,
            title: 'File Ditolak',
            message: 'Dokumen tidak valid! Tidak terdeteksi angka atau teks nominal pada file ini. Pastikan file yang dipilih adalah bukti struk yang dapat terbaca dengan jelas.',
            isError: true,
          );
          setState(() => _selectedFile = null);
        }
        return;
      }

      // 3. Parse Data Struk (Amount, Title, Date)
      final amount = _extractAmount(extractedText);
      if (amount <= 0) {
        if (mounted) {
          showCustomAlert(
            context: context,
            title: 'File Ditolak',
            message: 'Tidak ditemukan nominal angka belanja yang valid (Total/Tagihan) pada dokumen ini.',
            isError: true,
          );
          setState(() => _selectedFile = null);
        }
        return;
      }

      final title = _extractTitle(extractedText);
      final transactionDate = _extractDate(extractedText);

      // 4. Membuat nama file yang unik
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${user.id}_$timestamp.$_fileExtension';

      // 5. Upload fisik file ke bucket 'receipts' di Supabase Storage
      await Supabase.instance.client.storage
          .from('receipts')
          .upload(uniqueFileName, _selectedFile!);

      // 6. Mengambil URL publik gambar/dokumen
      final publicUrl = Supabase.instance.client.storage
          .from('receipts')
          .getPublicUrl(uniqueFileName);

      // 7. Simpan hasil ekstraksi OCR ke Tabel 'transactions' di Database Supabase
      await Supabase.instance.client.from('transactions').insert({
        'user_id': user.id,
        'title': title,
        'amount': amount,
        'transaction_date': transactionDate,
        'receipt_image_url': publicUrl,
      });

      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Berhasil',
          message: 'Struk terverifikasi!\nToko: $title\nTotal: Rp ${amount.toStringAsFixed(0)}\nTanggal: $transactionDate',
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
          message: 'Pesan dari server storage: ${e.message}\nPastikan bucket "receipts" telah dibuat di Supabase.',
          isError: true,
        );
        setState(() => _selectedFile = null);
      }
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Terjadi Kesalahan',
          message: e.toString(),
          isError: true,
        );
        setState(() => _selectedFile = null);
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

                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF00838F),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Mendeteksi dan Menyimpan...',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
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
