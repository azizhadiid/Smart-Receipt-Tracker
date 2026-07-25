import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Dibutuhkan untuk TextInputFormatter
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/custom_alert.dart';

class BudgetSettingsPage extends StatefulWidget {
  const BudgetSettingsPage({super.key});

  @override
  State<BudgetSettingsPage> createState() => _BudgetSettingsPageState();
}

class _BudgetSettingsPageState extends State<BudgetSettingsPage> {
  final _budgetController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentBudget();
  }

  // --- 1. MENGAMBIL BUDGET SAAT INI (LOGIKA TETAP) ---
  Future<void> _loadCurrentBudget() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('profiles')
          .select('budget_limit')
          .eq('id', user.id)
          .single();

      // Format angka mentah dari database ke dalam format titik Rupiah
      final rawBudget = data['budget_limit'].toString();
      _budgetController.text = _formatRupiah(rawBudget);
    } catch (e) {
      debugPrint('Gagal memuat budget: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. MENYIMPAN BUDGET BARU (LOGIKA TETAP) ---
  Future<void> _saveBudget() async {
    // Hilangkan semua titik sebelum disimpan ke database
    final rawValue = _budgetController.text.replaceAll('.', '');

    if (rawValue.isEmpty) {
      showCustomAlert(
        context: context,
        title: 'Data Kosong',
        message: 'Nominal budget tidak boleh kosong.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final newBudget = double.parse(rawValue);

      await Supabase.instance.client
          .from('profiles')
          .update({'budget_limit': newBudget})
          .eq('id', user!.id);

      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Berhasil!',
          message: 'Batas pengeluaran bulanan Anda telah diperbarui.',
          isError: false,
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true); // Kembali ke profil
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomAlert(
          context: context,
          title: 'Gagal Menyimpan',
          message: e.toString(),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Fungsi manual untuk memformat string angka menjadi format Rupiah
  String _formatRupiah(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) return '';
    String formatted = '';
    int count = 0;
    for (int i = value.length - 1; i >= 0; i--) {
      count++;
      formatted = value[i] + formatted;
      if (count % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }
    return formatted;
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Batas Budget',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
            )
          : SingleChildScrollView(
              // Diganti menjadi SingleChildScrollView agar aman dari keyboard overlap
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        Icons.account_balance_wallet_rounded,
                        size: 70,
                        color: Color(0xFF00897B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- TEXT KETERANGAN ---
                  const Text(
                    'Atur Batas Pengeluaran Bulanan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00838F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kami akan memberikan notifikasi jika pengeluaranmu sudah mendekati batas nominal ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- 3. INPUT FIELD DENGAN FORMATTER (UPDATE DESAIN) ---
                  Container(
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
                    child: TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00838F), // Cyan Gelap
                        letterSpacing: 1,
                      ),
                      // Aturan ketat agar hanya bisa mengetik angka, lalu diolah menjadi format titik
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        RupiahInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nominal Budget',
                        labelStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixText: 'Rp ', // Teks statis di depan input
                        prefixStyle: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00838F),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- 4. TOMBOL SIMPAN 3D ---
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00BCD4),
                          Color(0xFF00897B),
                        ], // Cyan ke Teal
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00BCD4).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .transparent, // Transparan agar gradient terlihat
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// --- KELAS FORMATTER RUPIAH CUSTOM (TIDAK DIUBAH) ---
// Kelas ini bertugas mencegat ketikan pengguna di layar dan menyisipkan titik setiap 3 digit
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Bersihkan karakter non-angka
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) return newValue.copyWith(text: '');

    // Proses penyisipan titik dari belakang
    String formatted = '';
    int count = 0;
    for (int i = newText.length - 1; i >= 0; i--) {
      count++;
      formatted = newText[i] + formatted;
      if (count % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }

    return TextEditingValue(
      text: formatted,
      // Posisikan kursor selalu di paling kanan setelah mengetik
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
