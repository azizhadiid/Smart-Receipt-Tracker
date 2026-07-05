import 'package:flutter/material.dart';
import 'layouts/main_layout.dart'; // Memanggil komponen layout utama

void main() {
  runApp(const SmartReceiptApp());
}

class SmartReceiptApp extends StatelessWidget {
  const SmartReceiptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Receipt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true, // Menggunakan desain UI modern
      ),
      // Memanggil MainLayout layaknya master.blade.php
      home: const MainLayout(),
    );
  }
}
