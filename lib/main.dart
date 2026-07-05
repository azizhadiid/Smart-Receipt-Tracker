import 'package:flutter/material.dart';
import 'pages/auth/login_page.dart'; // Panggil file login

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
        useMaterial3: true,
      ),
      // Awal aplikasi diarahkan ke Halaman Login
      home: const LoginPage(),
    );
  }
}
