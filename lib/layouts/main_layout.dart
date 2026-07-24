import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/history_page.dart';
import '../pages/scan_page.dart';
import '../pages/profile_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Hapus 'const' di sini agar halaman bisa menerima data dinamis ke depannya
  final List<Widget> _pages = [
    const HomePage(),
    const HistoryPage(),
    const ScanPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // Memungkinkan background body masuk hingga ke bawah lengkungan
      body: _pages[_selectedIndex], // Mengganti halaman di tengah layar
      // --- DESAIN NAVIGASI YANG DIPERBARUI ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5), // Bayangan mengarah ke atas
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 75, // Membuat bar sedikit lebih lega/tinggi
              backgroundColor: Colors.white,
              surfaceTintColor: Colors
                  .transparent, // Menghilangkan efek warna bawaan Material 3
              // Warna blok penanda (pill) saat menu aktif
              indicatorColor: const Color(0xFF00BCD4).withOpacity(0.15),

              // Kustomisasi Teks
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00838F), // Cyan Gelap
                  );
                }
                return TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                );
              }),

              // Kustomisasi Ikon
              iconTheme: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const IconThemeData(
                    color: Color(0xFF00838F),
                    size: 26, // Ikon sedikit membesar saat dipilih
                  );
                }
                return IconThemeData(color: Colors.grey.shade400, size: 24);
              }),
            ),

            // Widget inti Navigation Bar (Logika tetap sama)
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.document_scanner_outlined),
                  selectedIcon: Icon(Icons.document_scanner),
                  label: 'Scan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
