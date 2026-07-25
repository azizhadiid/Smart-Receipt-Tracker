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
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF00838F), // Cyan Gelap
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF00838F)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        children: [
          // --- HEADER ICON ---
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 70,
                color: Color(0xFF00897B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ada yang bisa kami bantu?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Temukan jawaban dari pertanyaan yang sering diajukan di bawah ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),

          // --- FAQ SECTION ---
          const Text(
            'FAQ (PERTANYAAN UMUM)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          _buildFAQItem(
            context,
            title: 'Bagaimana cara memindai struk?',
            content:
                'Pergi ke menu Scan, arahkan kamera ke struk belanja Anda, pastikan pencahayaan cukup, lalu tekan tombol proses.',
          ),

          _buildFAQItem(
            context,
            title: 'Apakah data saya aman?',
            content:
                'Ya, data Anda disimpan dengan aman menggunakan enkripsi tingkat tinggi di server cloud kami. Hanya Anda yang dapat mengaksesnya.',
          ),
          const SizedBox(height: 32),

          // --- KONTAK CUSTOMER SERVICE ---
          const Text(
            'BUTUH BANTUAN LAIN?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF00897B),
                ),
              ),
              title: const Text(
                'Hubungi Customer Service',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'support@smartreceipt.com',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () {
                // Logika membuka email client (opsional)
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- WIDGET CUSTOM UNTUK FAQ ---
  Widget _buildFAQItem(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        // Menghilangkan garis pembatas (divider) bawaan ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF00897B),
          collapsedIconColor: Colors.grey.shade400,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Text(
                content,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
