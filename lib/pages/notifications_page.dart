import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNotificationItem(
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            title: 'Peringatan Budget',
            message:
                'Pengeluaran bulan ini sudah mencapai 80% dari batas budget harian.',
            time: '2 jam yang lalu',
          ),
          _buildNotificationItem(
            icon: Icons.check_circle_outline,
            color: Colors.teal,
            title: 'Struk Berhasil Diproses',
            message:
                'Struk belanja "Susu Kental Manis" berhasil dipindai dan disimpan.',
            time: '1 hari yang lalu',
          ),
          _buildNotificationItem(
            icon: Icons.campaign_outlined,
            color: Colors.blue,
            title: 'Fitur Baru Tersedia',
            message:
                'Sekarang kamu bisa mengekspor laporan keuanganmu ke format PDF.',
            time: '3 hari yang lalu',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String time,
  }) {
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 8),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
