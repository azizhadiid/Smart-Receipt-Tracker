import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: const Center(
        child: Text(
          'Pengaturan dan Ekspor Data',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
