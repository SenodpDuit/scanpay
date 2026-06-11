import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — Orange & Light Theme Premium (Disamakan dengan Home & Stats)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const bg       = Color(0xFFFFF5F1); // Krem/Peach sangat muda
  static const surface  = Colors.white;      // Kartu & kontainer putih
  static const border   = Color(0xFFF0F0F2); // Batas tipis lembut
  static const accent   = Color(0xFFFF451A); // Oranye terang menyala
  static const text     = Color(0xFF1A1A1C); // Teks utama gelap
  static const textMid  = Color(0xFF7D7E84); // Teks sekunder abu-abu
}

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data tips keuangan lengkap dengan Ikon, Warna Tema, Deskripsi, dan Gambar Ilustrasi Unsplash
    final List<Map<String, dynamic>> tips = [
      {
        "title": "Metode Alokasi 50/30/20",
        "desc": "Sediakan 50% untuk kebutuhan pokok, 30% untuk keinginan pribadi, dan sisihkan 20% khusus tabungan atau investasi masa depan.",
        "icon": Icons.pie_chart_rounded,
        "color": Colors.blue,
        "image": "https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500&auto=format&fit=crop&q=60",
      },
      {
        "title": "Evaluasi Jajan Impulsif",
        "desc": "Cek berkala riwayat transaksi harianmu. Kurangi kebiasaan jajan kecil yang jika diakumulasikan ternyata menguras dompet.",
        "icon": Icons.fastfood_rounded,
        "color": Colors.orange,
        "image": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500&auto=format&fit=crop&q=60",
      },
      {
        "title": "Catat Pengeluaran Real-Time",
        "desc": "Biasakan langsung memindai struk belanjaan sesaat setelah transaksi agar catatan keuanganmu selalu akurat tanpa ada yang terlewat.",
        "icon": Icons.qr_code_scanner_rounded,
        "color": Colors.green,
        "image": "https://images.unsplash.com/photo-1556742044-3c52d6e88c62?w=500&auto=format&fit=crop&q=60",
      },
      {
        "title": "Mulai Membawa Bekal",
        "desc": "Memasak sendiri di rumah dan membawa bekal ke kampus atau kantor terbukti ampuh menghemat pengeluaran makan hingga 40% sebulan.",
        "icon": Icons.restaurant_rounded,
        "color": Colors.redAccent,
        "image": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=60",
      },
      {
        "title": "Bangun Pondasi Dana Darurat",
        "desc": "Sisihkan sebagian kecil uang secara konsisten setiap minggu. Dana ini sangat vital untuk mengamankan kebutuhan tak terduga.",
        "icon": Icons.savings_rounded,
        "color": Colors.purple,
        "image": "https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=500&auto=format&fit=crop&q=60",
      },
    ];

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Tips & Edukasi Keuangan",
          style: TextStyle(color: _T.text, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120), // Padding bawah longgar agar tidak tertumpuk navbar melayang
        itemCount: tips.length,
        itemBuilder: (context, i) {
          final item = tips[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _T.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias, // Memotong gambar sesuai lengkungan border container
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Gambar Ilustrasi Utama dari Network URL dengan Progress Loader
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.network(
                    item['image'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: _T.bg,
                        child: const Center(
                          child: SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(_T.accent),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Jika koneksi internet mati/gambar gagal dimuat, pasang container minimalis sebagai fallback
                      return Container(
                        color: _T.bg,
                        child: const Icon(Icons.broken_image_outlined, color: _T.textMid),
                      );
                    },
                  ),
                ),
                
                // 2. Area Detail Konten (Judul, Ikon, Deskripsi)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lingkaran Ikon Mini Pembuat Kontras Visual
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item['color'].withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'], color: item['color'], size: 20),
                      ),
                      const SizedBox(width: 12),
                      
                      // Blok Teks Informasi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: _T.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['desc'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: _T.textMid,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}