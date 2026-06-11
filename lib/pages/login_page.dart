import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isRegistering = false; // Flag untuk tukar mode Login / Register
  bool _showIntro = true;      // Flag untuk menampilkan halaman Intro sebelum Login

  // ─────────────────────────────────────────────────────────────────────────────
  // DESIGN TOKENS — Diselaraskan dengan Tema Light Premium Beranda
  // ─────────────────────────────────────────────────────────────────────────────
  final Color _bg       = const Color(0xFFFFF5F1); // Krem/Peach sangat muda
  final Color _surface  = Colors.white;      // Putih bersih untuk card input
  final Color _border   = const Color(0xFFF0F0F2); // Batas tipis abu-abu lembut
  final Color _accent   = const Color(0xFFFF451A); // Oranye terang menyala khas referensi
  final Color _textPri  = const Color(0xFF1A1A1C); // Teks utama gelap/hitam
  final Color _textSec  = const Color(0xFF7D7E84); // Teks sekunder abu-abu

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Username dan password tidak boleh kosong!');
      return;
    }

    if (_isRegistering) {
      // PROSES REGISTER
      int result = await DBService.registerUser(username, password);
      if (result != -1) {
        HapticFeedback.vibrate(); 
        _showSnackBar('Akun berhasil dibuat! Silakan login.');
        setState(() {
          _isRegistering = false;
        });
        _passwordController.clear();
      } else {
        _showSnackBar('Username sudah digunakan, cari nama lain!');
      }
    } else {
      // PROSES LOGIN
      bool isSuccess = await DBService.loginUser(username, password);
      if (isSuccess) {
        HapticFeedback.mediumImpact();
        // Simpan session agar tidak perlu login ulang
        await AuthService.saveSession(username);
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        _showSnackBar('Username atau password salah!');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
        backgroundColor: _textPri, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, 
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.03),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                child: child,
              ),
            );
          },
          child: _showIntro ? _buildIntroScreen() : _buildLoginScreen(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. WIDGET TAMPILAN INTRO / ONBOARDING
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildIntroScreen() {
    return Padding(
      key: const ValueKey('IntroScreen'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 95, height: 95,
              decoration: BoxDecoration(
                color: _textPri,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ]
              ),
              child: const Center(
                child: Text('📊', style: TextStyle(fontSize: 44)),
              ),
            ),
          ),
          const SizedBox(height: 36),
          
          Text(
            'Atur Keuanganmu\nLebih Mudah & Stabil',
            textAlign: TextAlign.center, 
            style: TextStyle(
              color: _textPri,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          
          Text(
            'Pindai struk belanjaanmu secara instan, lacak pengeluaran real-time, dan bangun kondisi finansial yang jauh lebih sehat bersama ScanPay.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSec,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const Spacer(),

          _buildFeatureRow('⚡', 'Pindai Struk Instan Tanpa Ketik Manual'),
          const SizedBox(height: 12),
          _buildFeatureRow('📈', 'Grafik Analisis Tren yang Presisi & Stabil'),
          
          const Spacer(),

          Container(
            height: 52,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() => _showIntro = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'MULAI SEKARANG',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: _textPri, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. WIDGET PANEL FORM LOGIN / REGISTER
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLoginScreen() {
    return Center(
      key: const ValueKey('LoginScreen'),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: _textPri,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Center(
              child: Text(
                _isRegistering ? 'Buat Akun Baru' : 'Masuk Ke ScanPay',
                style: TextStyle(color: _textPri, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _isRegistering ? 'Daftar untuk mulai mengelola keuangan' : 'Kelola keuangan harianmu dengan cerdas',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSec, fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    isObscure: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              height: 48,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isRegistering ? 'DAFTAR SEKARANG' : 'MASUK SEKARANG',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _isRegistering = !_isRegistering);
                },
                style: TextButton.styleFrom(foregroundColor: _accent, splashFactory: NoSplash.splashFactory),
                child: Text(
                  _isRegistering ? 'Sudah punya akun? Login di sini' : 'Belum punya akun? Daftar di sini',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
            
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showIntro = true),
                icon: Icon(Icons.arrow_back_rounded, size: 14, color: _textSec),
                label: Text('Kembali ke Intro', style: TextStyle(color: _textSec, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      // FIX: Menghapus parameter fabrics: null yang merusak kompilasi
      style: TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textSec, fontSize: 12, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _textSec, size: 18),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}