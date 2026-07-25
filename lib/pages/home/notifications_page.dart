import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Latar belakang bersih
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF00838F), // Cyan gelap elegan
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true, // Judul diletakkan di tengah
        iconTheme: const IconThemeData(color: Color(0xFF00838F)),
      ),
      body: ListView(
        physics:
            const BouncingScrollPhysics(), // Efek scroll memantul yang modern
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            color: const Color(0xFF00897B), // Menggunakan Teal dari tema utama
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

  // --- WIDGET CUSTOM NOTIFIKASI (UPDATE DESAIN) ---
  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle, // Latar ikon melingkar
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
