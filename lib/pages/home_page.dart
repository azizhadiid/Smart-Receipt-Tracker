import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Keuangan')),
      body: const Center(
        child: Text(
          'Ringkasan Pengeluaran Bulan Ini',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
