import 'package:flutter/material.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Nota')),
      body: const Center(
        child: Text(
          'Kamera dan ML Kit akan ada di sini',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
