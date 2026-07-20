import 'package:flutter/foundation.dart' show Uint8List;
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

  // --- FUNGSI UTAMA UNDUH LAPORAN ---
  Future<void> _downloadReport(String format) async {
    setState(() => _isDownloading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Sesi pengguna tidak valid.');

      // 1. Menentukan rentang tanggal berdasarkan bulan & tahun yang dipilih
      // Tanggal awal: Hari ke-1 bulan tersebut
      final startDate = DateTime(_selectedYear, _selectedMonth, 1);
      // Tanggal akhir: Hari ke-0 bulan depannya (sama dengan hari terakhir bulan ini)
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
        return; // Hentikan proses jika data kosong
      }

      // 4. Hitung Analisis Singkat
      double totalAmount = 0;
      for (var item in data) {
        totalAmount += (item['amount'] as num).toDouble();
      }
      int totalTransactions = data.length;

      // 5. Eksekusi pembuatan file sesuai format
      final fileName =
          'Laporan_Pengeluaran_${_monthNames[_selectedMonth - 1]}_$_selectedYear';

      if (format == 'pdf') {
        await _generateAndSavePDF(
          data,
          totalAmount,
          totalTransactions,
          fileName,
        );
      } else if (format == 'excel') {
        await _generateAndSaveExcel(
          data,
          totalAmount,
          totalTransactions,
          fileName,
        );
      }

      // 6. Tampilkan Notifikasi Sukses
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Berhasil Mengunduh!',
          message:
              'Laporan $format untuk bulan ${_monthNames[_selectedMonth - 1]} telah disimpan.',
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

  // --- LOGIKA PEMBUATAN PDF ---
  Future<void> _generateAndSavePDF(
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

              // Bagian Analisis
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

              // Tabel Transaksi
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
    await FileSaver.instance.saveFile(
      name: '$fileName.pdf',
      bytes: pdfBytes,
      mimeType: MimeType.pdf,
    );
  }

  // --- LOGIKA PEMBUATAN EXCEL ---
  Future<void> _generateAndSaveExcel(
    List<dynamic> data,
    double totalAmount,
    int totalTransactions,
    String fileName,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Laporan Bulanan'];
    excel.setDefaultSheet('Laporan Bulanan');

    // Header Analisis
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
    sheetObject.appendRow([TextCellValue('')]); // Baris Kosong

    // Header Tabel
    sheetObject.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Deskripsi Transaksi'),
      TextCellValue('Nominal (Rp)'),
    ]);

    // Isi Data
    for (var item in data) {
      sheetObject.appendRow([
        TextCellValue(item['transaction_date'].toString()),
        TextCellValue(item['title'].toString()),
        DoubleCellValue((item['amount'] as num).toDouble()),
      ]);
    }

    final List<int>? excelBytes = excel.save();
    if (excelBytes == null) throw Exception('Gagal merender file Excel.');

    await FileSaver.instance.saveFile(
      name: '$fileName.xlsx',
      bytes: Uint8List.fromList(excelBytes),
      mimeType: MimeType.microsoftExcel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Unduh Laporan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.analytics_outlined, size: 80, color: Colors.teal),
            const SizedBox(height: 16),
            Text(
              'Unduh rekapitulasi pengeluaran Anda dalam format PDF atau Excel. Pilih bulan dan tahun laporan di bawah ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),

            // --- FILTER PERIODE ---
            const Text(
              'Pilih Periode',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Dropdown Bulan
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
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

                // Dropdown Tahun
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _selectedYear,
                        items: List.generate(5, (index) {
                          // Menampilkan tahun ini sampai 4 tahun ke belakang
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
            const SizedBox(height: 40),

            // --- TOMBOL UNDUH ---
            const Text(
              'Pilih Format Dokumen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_isDownloading)
              const Center(child: CircularProgressIndicator(color: Colors.teal))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadReport('pdf'),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      label: const Text('Unduh PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadReport('excel'),
                      icon: const Icon(Icons.table_chart, color: Colors.green),
                      label: const Text('Unduh Excel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
