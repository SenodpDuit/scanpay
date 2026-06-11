class AnalysisService {
  static String warning(List<double> data) {
    // Jika tidak ada data sama sekali
    if (data.isEmpty) return "Mulai catat transaksi hari ini!";

    // Jika baru ada 1 data
    if (data.length < 2) return "Data pertama tercatat. Terus pantau!";

    // Ambil transaksi paling baru
    double lastTransaction = data.last;

    // Hitung rata-rata dari semua transaksi sebelumnya (kecuali yang terakhir)
    List<double> previousData = data.sublist(0, data.length - 1);
    double sum = previousData.fold(0, (a, b) => a + b);
    double average = sum / previousData.length;

    // Tentukan batas toleransi (misal 20% di atas rata-rata dianggap boros)
    double threshold = average * 1.2;

    if (lastTransaction > threshold) {
      return "⚠️ Transaksi ini jauh di atas rata-rata!";
    } else if (lastTransaction > average) {
      return "📈 Sedikit di atas tren biasanya.";
    } else if (lastTransaction < average * 0.8) {
      return "🎉 Bagus! Transaksi ini lebih hemat.";
    } else {
      return "✅ Pengeluaran masih sesuai batas wajar.";
    }
  }
}