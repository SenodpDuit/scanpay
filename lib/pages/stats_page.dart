import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../models/expense.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — Orange & Light Theme Premium (Disamakan dengan Home)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const bg       = Color(0xFFFFF5F1); // Krem/Peach sangat muda
  static const surface  = Colors.white;      // Kartu & kontainer putih
  static const border   = Color(0xFFF0F0F2); // Batas tipis lembut
  static const accent   = Color(0xFFFF451A); // Oranye terang menyala
  static const success  = Color(0xFF2EC4B6); // Toska teal
  static const text     = Color(0xFF1A1A1C); // Teks utama gelap
  static const textMid  = Color(0xFF7D7E84); // Teks sekunder abu-abu
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => StatsPageState();
}

class StatsPageState extends State<StatsPage> {
  List<FlSpot> spots = [];
  double maxAmount = 0;
  double totalSpent = 0;
  double avgSpent = 0;
  String topCategory = "-";
  int totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    List<Expense> data = await DBService.getExpenses();
    if (!mounted) return;

    if (data.isEmpty) {
      setState(() {
        spots = [];
        maxAmount = 0;
        totalSpent = 0;
        avgSpent = 0;
        topCategory = "-";
        totalTransactions = 0;
      });
      return;
    }

    List<Expense> chronologicalData = data.reversed.toList();
    List<FlSpot> tempSpots = [];
    double tempMax = 0;
    double tempTotal = 0;
    Map<String, double> categoryMap = {};

    for (int i = 0; i < chronologicalData.length; i++) {
      double amount = chronologicalData[i].amount;
      tempSpots.add(FlSpot(i.toDouble(), amount));
      tempTotal += amount;

      if (amount > tempMax) tempMax = amount;

      String cat = chronologicalData[i].category ?? 'Lainnya';
      categoryMap[cat] = (categoryMap[cat] ?? 0) + amount;
    }

    // Cari kategori dengan pengeluaran terbesar
    String highestCat = "-";
    double highestCatAmt = 0;
    categoryMap.forEach((key, value) {
      if (value > highestCatAmt) {
        highestCatAmt = value;
        highestCat = key;
      }
    });

    setState(() {
      spots = tempSpots;
      maxAmount = tempMax;
      totalSpent = tempTotal;
      totalTransactions = data.length;
      avgSpent = tempTotal / data.length;
      topCategory = highestCat;
    });
  }

  String rp(double v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Analitik & Statistik",
          style: TextStyle(color: _T.text, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => load(),
        color: _T.accent,
        child: spots.isEmpty
            ? _buildEmptyState()
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 120), // beri padding bawah agar tidak tertutup navbar melayang
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInsightGrid(),
                    const SizedBox(height: 24),
                    const Text(
                      "TREN FLUKTUASI TRANSAKSI",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _T.textMid, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    _buildChartContainer(),
                    const SizedBox(height: 20),
                    _buildSmartTipCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart_rounded, size: 64, color: _T.textMid),
              SizedBox(height: 14),
              Text(
                "Belum ada data untuk dianalisis",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _T.text),
              ),
              SizedBox(height: 4),
              Text(
                "Silakan tambahkan transaksi baru terlebih dahulu.",
                style: TextStyle(fontSize: 12, color: _T.textMid),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard("TOTAL PENGELUARAN", rp(totalSpent), Icons.wallet_rounded, _T.accent),
        _buildStatCard("RATA-RATA / TX", rp(avgSpent), Icons.pie_chart_rounded, _T.success),
        _buildStatCard("KATEGORI TERTINGGI", topCategory, Icons.moving_rounded, Colors.purple),
        _buildStatCard("TOTAL TRANSAKSI", "$totalTransactions Kali", Icons.receipt_long_rounded, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _T.textMid, letterSpacing: 0.3)),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _T.text), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildChartContainer() {
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(6, 20, 16, 8),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _T.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: _T.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) return const SizedBox();
                  return Text(
                    value >= 1000000 
                        ? "${(value / 1000000).toStringAsFixed(1)}jt" 
                        : value >= 1000 
                            ? "${(value / 1000).toStringAsFixed(0)}k" 
                            : "${value.toInt()}",
                    style: const TextStyle(fontSize: 9, color: _T.textMid, fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxAmount * 1.15,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: _T.accent,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: index == spots.length - 1 ? 5 : 2.5,
                  color: _T.accent,
                  strokeWidth: 2,
                  strokeColor: _T.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [_T.accent.withOpacity(0.15), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.accent.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Text("💡", style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Smart Insights",
                  style: TextStyle(color: _T.text, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  "Grafik menunjukkan pergerakan dinamis dari $totalTransactions transaksi terakhirmu. Jaga kestabilan belanja di kategori $topCategory agar sisa anggaran bulanan tetap aman!",
                  style: const TextStyle(color: _T.textMid, fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}