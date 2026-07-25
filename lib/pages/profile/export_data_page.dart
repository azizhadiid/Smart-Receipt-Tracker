import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import '../../components/custom_alert.dart';

class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  bool _isDownloading = false;

  // Variabel untuk filter bulan dan tahun
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  // --- FUNGSI UTAMA UNDUH LAPORAN (LOGIKA TETAP) ---
  Future<void> _downloadReport(String format) async {
    setState(() => _isDownloading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Sesi pengguna tidak valid.');

      // 1. Menentukan rentang tanggal berdasarkan bulan & tahun yang dipilih
      final startDate = DateTime(_selectedYear, _selectedMonth, 1);
      final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);

      // 2. Fetch data dari Supabase dengan filter tanggal
      final List<dynamic> data = await Supabase.instance.client
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .gte('transaction_date', startDate.toIso8601String())
          .lte('transaction_date', endDate.toIso8601String())
          .order('transaction_date', ascending: true);

      // 3. Pengecekan Data Kosong (If-Else)
      if (data.isEmpty) {
        if (mounted) {
          showCustomAlert(
            context: context,
            title: 'Data Tidak Ditemukan',
            message:
                'Belum ada transaksi pada bulan ${_monthNames[_selectedMonth - 1]} $_selectedYear.',
            isError: true,
          );
        }
        return;
      }

      // 4. Hitung Analisis Singkat
      double totalAmount = 0;
      for (var item in data) {
        totalAmount += (item['amount'] as num).toDouble();
      }
      int totalTransactions = data.length;

      final fileName =
          'Laporan_Pengeluaran_${_monthNames[_selectedMonth - 1]}_$_selectedYear';

      // Variabel untuk menangkap lokasi file
      String savedLocation = "";

      // 5. Eksekusi pembuatan file dan tangkap lokasinya
      if (format == 'pdf') {
        savedLocation = await _generateAndSavePDF(
          data,
          totalAmount,
          totalTransactions,
          fileName,
        );
      } else if (format == 'excel') {
        savedLocation = await _generateAndSaveExcel(
          data,
          totalAmount,
          totalTransactions,
          fileName,
        );
      }

      // 6. Tampilkan Notifikasi Sukses beserta Lokasinya
      if (mounted) {
        String pesanSukses = kIsWeb
            ? 'Laporan $format berhasil diunduh ke komputer Anda.'
            : 'Laporan berhasil disimpan di folder Downloads:\n\n$savedLocation';

        showCustomAlert(
          context: context,
          title: 'Berhasil Mengunduh!',
          message: pesanSukses,
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Gagal Mengunduh',
          message: 'Terjadi kesalahan: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // --- LOGIKA PEMBUATAN PDF (TETAP) ---
  Future<String> _generateAndSavePDF(
    List<dynamic> data,
    double totalAmount,
    int totalTransactions,
    String fileName,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan Keuangan Bulanan',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Periode: ${_monthNames[_selectedMonth - 1]} $_selectedYear',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Ringkasan:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Total Transaksi: $totalTransactions aktivitas'),
                    pw.Text(
                      'Total Pengeluaran: Rp ${totalAmount.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                headers: ['Tanggal', 'Deskripsi', 'Nominal (Rp)'],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                },
                data: data.map((item) {
                  return [
                    item['transaction_date'].toString(),
                    item['title'].toString(),
                    item['amount'].toString(),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    final String? savedPath = await FileSaver.instance.saveAs(
      name: '$fileName.pdf',
      bytes: pdfBytes,
      mimeType: MimeType.pdf,
    );

    return savedPath ?? "Penyimpanan dibatalkan";
  }

  // --- LOGIKA PEMBUATAN EXCEL (TETAP) ---
  Future<String> _generateAndSaveExcel(
    List<dynamic> data,
    double totalAmount,
    int totalTransactions,
    String fileName,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Laporan Bulanan'];
    excel.setDefaultSheet('Laporan Bulanan');

    sheetObject.appendRow([
      TextCellValue('Periode:'),
      TextCellValue('${_monthNames[_selectedMonth - 1]} $_selectedYear'),
    ]);
    sheetObject.appendRow([
      TextCellValue('Total Transaksi:'),
      IntCellValue(totalTransactions),
    ]);
    sheetObject.appendRow([
      TextCellValue('Total Pengeluaran:'),
      DoubleCellValue(totalAmount),
    ]);
    sheetObject.appendRow([TextCellValue('')]);

    sheetObject.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Deskripsi Transaksi'),
      TextCellValue('Nominal (Rp)'),
    ]);

    for (var item in data) {
      sheetObject.appendRow([
        TextCellValue(item['transaction_date'].toString()),
        TextCellValue(item['title'].toString()),
        DoubleCellValue((item['amount'] as num).toDouble()),
      ]);
    }

    final List<int>? excelBytes = excel.save();
    if (excelBytes == null) throw Exception('Gagal merender file Excel.');

    final String? savedPath = await FileSaver.instance.saveAs(
      name: '$fileName.xlsx',
      bytes: Uint8List.fromList(excelBytes),
      mimeType: MimeType.microsoftExcel,
    );

    return savedPath ?? "Penyimpanan dibatalkan";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Unduh Laporan',
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER ICON (UPDATE DESAIN) ---
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  size: 70,
                  color: Color(0xFF00897B),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unduh rekapitulasi pengeluaran Anda dalam format PDF atau Excel. Pilih bulan dan tahun laporan di bawah ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // --- FILTER PERIODE (UPDATE DESAIN) ---
            const Text(
              'PILIH PERIODE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade500,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00838F),
                        ),
                        value: _selectedMonth,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(_monthNames[index]),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null)
                            setState(() => _selectedMonth = value);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade500,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00838F),
                        ),
                        value: _selectedYear,
                        items: List.generate(5, (index) {
                          int year = DateTime.now().year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null)
                            setState(() => _selectedYear = value);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // --- TOMBOL UNDUH (UPDATE DESAIN PREMIUM) ---
            const Text(
              'FORMAT DOKUMEN',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            if (_isDownloading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadReport('pdf'),
                      icon: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.red.shade600,
                      ),
                      label: Text(
                        'Unduh PDF',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(
                          color: Colors.red.shade200,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadReport('excel'),
                      icon: Icon(
                        Icons.table_chart_rounded,
                        color: Colors.green.shade600,
                      ),
                      label: Text(
                        'Unduh Excel',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(
                          color: Colors.green.shade200,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
