import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Bantuan & Dukungan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ExpansionTile(
            title: Text(
              'Bagaimana cara memindai struk?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Pergi ke menu Scan, arahkan kamera ke struk belanja Anda, pastikan pencahayaan cukup, lalu tekan tombol proses.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              'Apakah data saya aman?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Ya, data Anda disimpan dengan aman menggunakan enkripsi di server cloud kami.',
                ),
              ),
            ],
          ),
          SizedBox(height: 40),
          ListTile(
            leading: Icon(Icons.email, color: Colors.teal),
            title: Text('Hubungi Customer Service'),
            subtitle: Text('support@smartreceipt.com'),
          ),
        ],
      ),
    );
  }
}
