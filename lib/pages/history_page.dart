import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: const Center(
        child: Text('Daftar Struk Bahan Baku', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
