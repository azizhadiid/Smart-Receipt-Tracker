import 'package:flutter/material.dart';

class TransactionDetailPage extends StatelessWidget {
  // Deklarasi variabel untuk menampung data yang dikirim dari HistoryPage
  final Map<String, dynamic> transactionData;

  const TransactionDetailPage({super.key, required this.transactionData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF00838F), // Cyan Gelap Modern
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF00838F)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50, // Latar merah lembut
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Hapus Transaksi',
              onPressed: () {
                // Nanti untuk logika hapus data di database
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. PLACEHOLDER / FOTO STRUK ---
            Container(
              height:
                  380, // Dibuat sedikit lebih panjang agar proporsional untuk foto struk
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
                // Nanti ini diganti dengan CachedNetworkImage dari URL Supabase
                // Sementara menggunakan efek border putus-putus manual untuk placeholder
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withOpacity(0.03),
                    border: Border.all(
                      color: const Color(0xFF00BCD4).withOpacity(0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          size: 50,
                          color: Color(0xFF00897B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Foto Struk',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- 2. KARTU INFORMASI DETAIL ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ikon melingkar sesuai tema
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          transactionData['icon'] as IconData,
                          color: const Color(0xFF00897B),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Judul & Tanggal
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transactionData['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              transactionData['date'],
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Garis Pemisah (Divider)
                  Row(
                    children: List.generate(
                      40,
                      (index) => Expanded(
                        child: Container(
                          color: index % 2 == 0
                              ? Colors.transparent
                              : Colors.grey.shade300,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bagian Total Harga
                  const Text(
                    'TOTAL PENGELUARAN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transactionData['amount'],
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.redAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
