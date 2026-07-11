import 'package:flutter/material.dart';
import 'package:smart_receipt/pages/history/transaction_detail_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data untuk mensimulasikan daftar riwayat struk
    final List<Map<String, dynamic>> dummyTransactions = [
      {
        'title': 'Susu Kental Manis Kaleng',
        'date': '7 Juli 2026',
        'amount': 'Rp 85.000',
        'icon': Icons.inventory_2,
      },
      {
        'title': 'Sirup Frambozen & Fanta',
        'date': '6 Juli 2026',
        'amount': 'Rp 125.000',
        'icon': Icons.local_drink,
      },
      {
        'title': 'Es Batu Kristal (10 Karung)',
        'date': '5 Juli 2026',
        'amount': 'Rp 50.000',
        'icon': Icons.ac_unit,
      },
      {
        'title': 'Gelas Cup Plastik 16oz',
        'date': '3 Juli 2026',
        'amount': 'Rp 45.000',
        'icon': Icons.shopping_bag,
      },
      {
        'title': 'Kantong Plastik Takeaway',
        'date': '1 Juli 2026',
        'amount': 'Rp 15.000',
        'icon': Icons.shopping_basket,
      },
      {
        'title': 'Susu Kental Manis Kaleng',
        'date': '28 Juni 2026',
        'amount': 'Rp 85.000',
        'icon': Icons.inventory_2,
      },
      {
        'title': 'Sirup Frambozen',
        'date': '25 Juni 2026',
        'amount': 'Rp 60.000',
        'icon': Icons.local_drink,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Data',
            onPressed: () {
              // Nanti untuk fitur filter bulan/minggu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Kolom Pencarian (Search Bar)
          // 1. Kolom Pencarian (Search Bar)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              // Membungkus TextField dengan Container untuk memberikan bayangan
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari nama bahan baku atau toko...',
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide:
                        BorderSide.none, // Menghilangkan garis tepi bawaan
                  ),
                ),
              ),
            ),
          ),

          // 2. Daftar Riwayat menggunakan ListView.builder
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: dummyTransactions.length,
              itemBuilder: (context, index) {
                final trx =
                    dummyTransactions[index]; // Mengambil data per baris

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(trx['icon'] as IconData, color: Colors.teal),
                    ),
                    title: Text(
                      trx['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      trx['date'] as String,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '- ${trx['amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionDetailPage(transactionData: trx),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
