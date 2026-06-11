import 'dart:convert';
import 'dart:ui'; // Diperlukan untuk efek blur (Liquid Glass)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../models/expense.dart';
import 'scan_page.dart';
import 'login_page.dart';
import 'stats_page.dart'; // IMPORT STATS PAGE
import 'tips_page.dart';  // IMPORT TIPS PAGE
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — Orange & Light Theme Premium
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const bg       = Color(0xFFFFF5F1); // Krem/Peach sangat muda
  static const surface  = Colors.white;      // Kartu & kontainer putih
  static const border   = Color(0xFFF0F0F2); // Batas tipis lembut

  static const accent  = Color(0xFFFF451A); // Oranye terang menyala
  static const danger  = Color(0xFFFF6B6B); //
  static const success = Color(0xFF2EC4B6); //

  static const text    = Color(0xFF1A1A1C); // Teks utama gelap
  static const textMid = Color(0xFF7D7E84); // Teks sekunder abu-abu
  static const textDim = Color(0xFFC1C2C7); // Teks pudar

  // Token Khusus Efek Liquid Glass
  static const glassSurface = Colors.white; 
  static const glassBorder  = Color(0x1F7D7E84); 

  static const categories = {
    'Makanan'  : {'icon': '🍜', 'color': Color(0xFFFF8A65)}, //
    'Transport': {'icon': '🚗', 'color': Color(0xFF64B5F6)}, //
    'Belanja'  : {'icon': '🛍', 'color': Color(0xFF81C784)}, //
    'Kesehatan': {'icon': '💊', 'color': Color(0xFFFFD23F)}, //
    'Lainnya'  : {'icon': '📦', 'color': Color(0xFFB39DDB)}, //
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN NAVIGATION HUB (Mengatur Tab Navigasi dengan Gaya Liquid Glass Melayang)
// ─────────────────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final GlobalKey<StatsPageState> _statsKey = GlobalKey<StatsPageState>();

  late final List<Widget> _pages = [
    const _HomeDashboardTab(), // Index 0: Beranda utama
    StatsPage(key: _statsKey), // Index 1: Menghubungkan ke StatsPage kamu
    const TipsPage(),          // Index 2: Menghubungkan ke TipsPage kamu
    const ProfilePage(),       // Index 3: Menghubungkan ke ProfilePage kamu yang sekarang SUDAH AKTIF
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Konten scrolling tembus pandang di belakang glass bar
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          _buildLiquidGlassBottomBar(), // Liquid Glass Bar Melayang
        ],
      ),
    );
  }

  Widget _buildLiquidGlassBottomBar() {
    return Positioned(
      bottom: 24, 
      left: 16, right: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8), //
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), //
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _T.glassSurface.withOpacity(0.7), //
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: _T.glassBorder, width: 1), //
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGlassTabItem(0, Icons.home_filled, 'Home'), //
                    _buildGlassTabItem(1, Icons.bar_chart_rounded, 'Stats'), //
                    _buildGlassTabItem(2, Icons.lightbulb_outline_rounded, 'Tips'), //
                    _buildGlassTabItem(3, Icons.person_outline, 'Profile'), //
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTabItem(int index, IconData icon, String label) {
    final bool active = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick(); //
          setState(() {
            _currentIndex = index; //
          });
          if (index == 1) {
            _statsKey.currentState?.load();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), //
          curve: Curves.easeInOut, //
          padding: const EdgeInsets.symmetric(vertical: 8), //
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? _T.accent : _T.textMid, //
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500, //
                  color: active ? _T.accent : _T.textMid, //
                  letterSpacing: -0.1, //
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD VIEW (Isi Konten Beranda Utama)
// ─────────────────────────────────────────────────────────────────────────────
class _HomeDashboardTab extends StatefulWidget {
  const _HomeDashboardTab();

  @override
  State<_HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<_HomeDashboardTab> with SingleTickerProviderStateMixin {
  List<Expense> allData      = []; //
  List<Expense> filteredData = []; //
  double total               = 0; //
  double budgetTarget        = 4000000;
  String currentFilter       = 'Semua'; //
  String analysisMessage     = 'Mulai scan struk untuk memantau pengeluaranmu.'; //
  bool   analysisPositive    = true; //
  Map<String, double> categoryTotals = {}; //
  String _greetingName       = ''; // Nama untuk sapaan, diambil dari session

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 400), //
  );

  @override
  void initState() {
    super.initState();
    load(); //
    _loadGreetingName();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble('budget_target');
    if (saved != null && mounted) {
      setState(() => budgetTarget = saved);
    }
  }

  Future<void> _saveBudget(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_target', value);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose(); //
    super.dispose();
  }

  Future<void> _loadGreetingName() async {
    final profile = await DBService.getCurrentUserProfile();
    if (!mounted) return;
    final displayName = profile['display_name'] ?? '';
    final uname = profile['username'] ?? '';
    setState(() {
      _greetingName = displayName.isNotEmpty ? displayName : uname;
    });
  }

  Future<void> load() async {
    final data = await DBService.getExpenses(); //
    if (!mounted) return;
    setState(() {
      allData = data; //
      _applyFilter(currentFilter); //
      _updateAnalysis(data); //
      _buildCategoryTotals(); //
    });
    _fadeCtrl.forward(from: 0); //
  }

  void _applyFilter(String filter) {
    currentFilter = filter; //
    final now       = DateTime.now(); //
    final today     = DateFormat('yyyy-MM-dd').format(now); //
    final thisMonth = DateFormat('yyyy-MM').format(now); //
    setState(() {
      filteredData = switch (filter) {
        'Hari Ini'   => allData.where((e) => e.date.startsWith(today)).toList(), //
        'Bulan Ini'  => allData.where((e) => e.date.contains(thisMonth)).toList(), //
        _            => allData, //
      };
      total = filteredData.fold(0, (s, e) => s + e.amount); //
    });
  }

  void _updateAnalysis(List<Expense> data) {
    if (data.length < 2) return; //
    final latest = data[0].amount, previous = data[1].amount; //
    if (latest > previous) {
      analysisMessage  = 'Pengeluaran meningkat dari transaksi terakhir.'; //
      analysisPositive = false; //
    } else if (latest < previous) {
      analysisMessage  = 'Lebih hemat dari transaksi sebelumnya. Bagus!'; //
      analysisPositive = true; //
    } else {
      analysisMessage  = 'Pengeluaran stabil. Pertahankan!'; //
      analysisPositive = true; //
    }
  }

  void _buildCategoryTotals() {
    categoryTotals = {}; //
    for (final e in filteredData) {
      final cat = e.category ?? 'Lainnya'; //
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + e.amount; //
    }
  }

  double get effectiveBudget {
    switch (currentFilter) {
      case 'Hari Ini':
        return budgetTarget;

      case 'Bulan Ini':
      case 'Semua':
      default:
        return budgetTarget;
    }
  }

  double get budgetUsedPct {
    final allExpense = allData.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return (allExpense / budgetTarget).clamp(0.0, 1.0);
  }
  double get todayTotal {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now()); //
    return allData.where((e) => e.date.startsWith(today)).fold(0.0, (s, e) => s + e.amount); //
  }
  double get trendPct {
    if (allData.length < 2) return 0; //
    final a = allData[0].amount, b = allData[1].amount; //
    return b == 0 ? 0 : (a - b) / b * 100; //
  }

  String rp(double v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v); //

  String rpShort(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt'; //
    if (v >= 1000)    return 'Rp ${(v / 1000).toStringAsFixed(0)}k'; //
    return rp(v); //
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('LAPORAN PENGELUARAN SCANPAY',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)), //
          pw.SizedBox(height: 8), //
          pw.Text('Periode: $currentFilter'), //
          pw.Text('Dicetak: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'), //
          pw.Divider(), //
          pw.TableHelper.fromTextArray(
            headers: ['Tanggal', 'Toko', 'Kategori', 'Total'], //
            data: filteredData.map((e) => [
              e.date.split('T')[0], e.store ?? '-', e.category ?? '-', rp(e.amount) //
            ]).toList(),
          ),
          pw.SizedBox(height: 16), //
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('TOTAL: ${rp(total)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)), //
          ),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) => pdf.save()); //
  }

  void _handleLogout() async {
    HapticFeedback.heavyImpact();
    // Hapus session agar saat buka ulang app, user diminta login kembali
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // FITUR BARU: Dialog untuk merubah batas nominal Anggaran
  void _showEditBudgetDialog() {
    final budgetCon = TextEditingController();
    bool tambahAnggaran = true;
    budgetCon.text = '';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kelola Anggaran',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _T.text)), //
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) => Column(
                  children: [
                    Row(
  children: [
    Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setDialogState(() {
            tambahAnggaran = true;
            budgetCon.text = '';
          });
        },
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: tambahAnggaran,
              onChanged: (v) {
                setDialogState(() {
                  tambahAnggaran = true;
                  budgetCon.text = '';
                });
              },
            ),
            const Text('Tambah'),
          ],
        ),
      ),
    ),

    Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setDialogState(() {
            tambahAnggaran = false;
            budgetCon.text =
                budgetTarget.toStringAsFixed(0);
          });
        },
        child: Row(
          children: [
            Radio<bool>(
              value: false,
              groupValue: tambahAnggaran,
              onChanged: (v) {
                setDialogState(() {
                  tambahAnggaran = false;
                  budgetCon.text =
                      budgetTarget.toStringAsFixed(0);
                });
              },
            ),
            const Text('Edit'),
          ],
        ),
                          ),
                        ),
                      ],
                    ),
                    _input(
                controller: budgetCon, 
                label: 'Nominal Anggaran (Rp)', 
                icon: Icons.track_changes_rounded,
                type: TextInputType.number,
              ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _T.textMid,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: _T.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), //
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final value = double.tryParse(budgetCon.text);
                      if (value != null && value > 0) {
                        final newBudget = tambahAnggaran ? (budgetTarget + value) : value;
                        setState(() {
                          budgetTarget = newBudget;
                        });
                        _saveBudget(newBudget);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), //
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    )); //

    return Scaffold(
      backgroundColor: _T.bg, //
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(), //
          slivers: [
            _buildAppBar(), //
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(), //
                  const SizedBox(height: 20), //
                  _buildFilters(), //
                  const SizedBox(height: 20), //
                  _buildBudgetBar(), //
                  const SizedBox(height: 24), //
                  _buildSectionLabel('Kategori', count: categoryTotals.length), //
                  _buildCategoryRow(), //
                  const SizedBox(height: 24), //
                  _buildSectionLabel('Tren Pengeluaran'), //
                  _buildChart(), //
                  const SizedBox(height: 24), //
                  _buildSectionLabel('Riwayat', count: filteredData.length), //
                  const SizedBox(height: 8), //
                ],
              ),
            ),
            _buildTxList(), //
            const SliverToBoxAdapter(child: SizedBox(height: 120)), //
          ],
        ),
      ),
      floatingActionButton: _buildFab(), //
    );
  }

  Widget _buildAppBar() => SliverAppBar(
    floating: true,
    pinned: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    automaticallyImplyLeading: false,
    titleSpacing: 20,
    title: Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1C),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('⚡', style: TextStyle(fontSize: 16)), //
          ),
        ),
        const SizedBox(width: 12), //
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hi, $_greetingName!',
                style: const TextStyle(
                  color: _T.text, //
                  fontWeight: FontWeight.w800, //
                  fontSize: 15,
                  letterSpacing: -0.2, //
                ),
                overflow: TextOverflow.ellipsis, //
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      _iconBtn(
        icon: Icons.picture_as_pdf_outlined,
        onTap: filteredData.isEmpty ? null : _generatePdf, //
      ),
      const SizedBox(width: 8), //
      GestureDetector(
        onTap: _handleLogout, //
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: _T.accent, size: 18), //
            ),
            Positioned(
              top: 10, right: 10,
              child: Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: _T.accent, shape: BoxShape.circle), //
              ),
            )
          ],
        ),
      ),
      const SizedBox(width: 20), //
    ],
  );

  Widget _iconBtn({required IconData icon, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
            size: 18,
            color: onTap == null ? _T.textDim : _T.textMid, //
          ),
        ),
      );

  Widget _buildSummaryCard() {
    final trend    = trendPct; //
    final trendStr = trend == 0
        ? 'Stabil'
        : '${trend < 0 ? '↓' : '↑'} ${trend.abs().toStringAsFixed(0)}%'; //
    final trendPos = trend <= 0; //

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), //
      decoration: BoxDecoration(
        color: _T.surface, //
        borderRadius: BorderRadius.circular(24), //
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF451A).withOpacity(0.04), //
            blurRadius: 20, //
            offset: const Offset(0, 8), //
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), //
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF623E), Color(0xFFFF451A)], //
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)), //
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Periode: ${currentFilter.toUpperCase()}', //
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5), //
                ),
                Text(
                  '${filteredData.length} Transaksi Terlacak', //
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), //
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20), //
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL PENGELUARAN',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, //
                      letterSpacing: 1.0, color: _T.textMid, //
                    )),
                const SizedBox(height: 4), //
                Text(
                  rp(total), //
                  style: const TextStyle(
                    fontWeight: FontWeight.w900, //
                    fontSize: 28, letterSpacing: -1.0, color: _T.text, //
                  ),
                ),
                const SizedBox(height: 16), //
                const Divider(color: _T.border, height: 1), //
                const SizedBox(height: 14), //
                Row(
                  children: [
                    Expanded(child: _statItem('Hari Ini', rpShort(todayTotal))), //
                    Container(width: 1, height: 28, color: _T.border), //
                    Expanded(child: _statItem(
                      'Tren',
                      trendStr, //
                      valueColor: trendPos ? _T.success : _T.danger, //
                    )),
                  ],
                ),
                const SizedBox(height: 14), //
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), //
                  decoration: BoxDecoration(
                    color: _T.bg, //
                    borderRadius: BorderRadius.circular(12), //
                  ),
                  child: Row(children: [
                    Icon(
                      analysisPositive ? Icons.check_circle_rounded : Icons.info_rounded, //
                      size: 16,
                      color: analysisPositive ? _T.success : _T.accent, //
                    ),
                    const SizedBox(width: 10), //
                    Expanded(
                      child: Text(analysisMessage, //
                          style: const TextStyle(
                            fontSize: 12, color: _T.text, height: 1.3, //
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {Color? valueColor}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(),
          style: const TextStyle(fontSize: 9, letterSpacing: 0.8, //
              color: _T.textMid, fontWeight: FontWeight.w700)), //
      const SizedBox(height: 2), //
      Text(value, style: TextStyle(
        fontWeight: FontWeight.w800, fontSize: 15, //
        color: valueColor ?? _T.text, //
      )),
    ],
  );

  Widget _buildFilters() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16), //
    child: Row(
      children: ['Semua', 'Hari Ini', 'Bulan Ini'].map((f) { //
        final sel = currentFilter == f; //
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick(); //
            _applyFilter(f); //
            _buildCategoryTotals(); //
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180), //
            margin: const EdgeInsets.only(right: 8), //
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), //
            decoration: BoxDecoration(
              color: sel ? _T.accent : _T.surface, //
              borderRadius: BorderRadius.circular(99), //
              border: Border.all(color: sel ? _T.accent : _T.border), //
            ),
            child: Text(f,
                style: TextStyle(
                  color: sel ? Colors.white : _T.textMid, //
                  fontWeight: FontWeight.w700, //
                  fontSize: 12,
                )),
          ),
        );
      }).toList(),
    ),
  );

  Widget _buildBudgetBar() {
    final pct        = budgetUsedPct; //
    final allExpense = allData.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final remaining = budgetTarget - allExpense;
    final overBudget = remaining < 0; //

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), //
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showEditBudgetDialog(); //
        },
        child: Container(
          padding: const EdgeInsets.all(18), //
          decoration: BoxDecoration(
            color: _T.surface, //
            borderRadius: BorderRadius.circular(20), //
            border: Border.all(color: _T.border), //
          ),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('SISA ANGGARAN',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, //
                                letterSpacing: 1.0, color: _T.textMid)), //
                        const SizedBox(width: 4),
                        Icon(Icons.edit_rounded, size: 10, color: _T.textMid.withOpacity(0.6)),
                      ],
                    ),
                    const SizedBox(height: 2), //
                    Text(
                      overBudget ? '− ${rp(remaining.abs())}' : rp(remaining), //
                      style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18, //
                        color: overBudget ? _T.danger : _T.text, //
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), //
                  decoration: BoxDecoration(
                    color: (overBudget ? _T.danger : _T.accent).withOpacity(0.1), //
                    borderRadius: BorderRadius.circular(6), //
                  ),
                  child: Text(
                    overBudget ? 'Limit Habis' : '${(pct * 100).toStringAsFixed(0)}%', //
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: overBudget ? _T.danger : _T.accent), //
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), //
            ClipRRect(
              borderRadius: BorderRadius.circular(99), //
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct), //
                duration: const Duration(milliseconds: 700), //
                curve: Curves.easeOutCubic, //
                builder: (_, v, __) => Stack(children: [
                  Container(height: 6, color: _T.border), //
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 6,
                      color: overBudget ? _T.danger : _T.accent, //
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, {int? count}) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 16, 12), //
    child: Row(children: [
      Text(title,
          style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, //
            color: _T.text, //
          )),
      if (count != null) ...[
        const SizedBox(width: 6), //
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), //
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), //
          child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _T.textMid)), //
        ),
      ],
    ]),
  );

  Widget _buildCategoryRow() {
    final cats  = _T.categories.entries.toList(); //
    final maxVal = categoryTotals.values.isEmpty
        ? 1.0
        : categoryTotals.values.reduce((a, b) => a > b ? a : b); //

    return SizedBox(
      height: 90, //
      child: ListView.separated(
        scrollDirection: Axis.horizontal, //
        padding: const EdgeInsets.symmetric(horizontal: 16), //
        itemCount: cats.length, //
        separatorBuilder: (_, __) => const SizedBox(width: 10), //
        itemBuilder: (_, i) {
          final name   = cats[i].key; //
          final cfg    = cats[i].value; //
          final color  = cfg['color'] as Color; //
          final icon   = cfg['icon'] as String; //
          final amount = categoryTotals[name] ?? 0; //
          final pct    = maxVal > 0 ? (amount / maxVal).clamp(0.0, 1.0) : 0.0; //

          return Container(
            width: 95, //
            padding: const EdgeInsets.all(12), //
            decoration: BoxDecoration(
              color: _T.surface, //
              borderRadius: BorderRadius.circular(16), //
              border: Border.all(color: _T.border), //
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, //
              mainAxisAlignment: MainAxisAlignment.spaceBetween, //
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, //
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 16)), //
                    if (amount > 0)
                      Container(
                        width: 5, height: 5, //
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color), //
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, //
                  children: [
                    Text(name,
                        style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: _T.textMid, //
                        )),
                    const SizedBox(height: 4), //
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: pct), //
                      duration: const Duration(milliseconds: 700), //
                      builder: (_, v, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(99), //
                        child: Stack(children: [
                          Container(height: 3, color: _T.border), //
                          FractionallySizedBox(
                            widthFactor: v,
                            child: Container(height: 3, color: color), //
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart() {
    final spots = filteredData.reversed.toList(); //
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), //
      child: Container(
        height: 150, //
        padding: const EdgeInsets.fromLTRB(6, 14, 14, 8), //
        decoration: BoxDecoration(
          color: _T.surface, //
          borderRadius: BorderRadius.circular(20), //
          border: Border.all(color: _T.border), //
        ),
        child: spots.isEmpty
            ? const Center(
                child: Text('Belum ada data grafik',
                    style: TextStyle(color: _T.textDim, fontSize: 12, fontWeight: FontWeight.w500))) //
            : LineChart(_buildLineData(spots)), //
      ),
    );
  }

  LineChartData _buildLineData(List<Expense> items) {
    final chart = items.length > 10 ? items.sublist(items.length - 10) : items; //
    final chartSpots = List.generate(
      chart.length, (i) => FlSpot(i.toDouble(), chart[i].amount), //
    );

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: _T.border, strokeWidth: 1), //
      ),
      borderData: FlBorderData(show: false), //
      titlesData: FlTitlesData(
        rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)), //
        topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)), //
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), //
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, reservedSize: 40, //
            getTitlesWidget: (v, m) {
              if (v == m.max || v == m.min) return const SizedBox(); //
              return Text(
                v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}M' //
                    : v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' //
                    : v.toStringAsFixed(0),
                style: const TextStyle(color: _T.textMid, fontSize: 9, fontWeight: FontWeight.w600), //
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: chartSpots, //
          isCurved: true, //
          curveSmoothness: 0.35, //
          color: _T.accent, //
          barWidth: 2.5, //
          isStrokeCapRound: true, //
          dotData: FlDotData(
            show: true, //
            getDotPainter: (s, p, b, i) => FlDotCirclePainter(
              radius: i == chartSpots.length - 1 ? 4 : 2, //
              color: _T.accent, //
              strokeWidth: 1.5, //
              strokeColor: _T.surface, //
            ),
          ),
          belowBarData: BarAreaData(
            show: true, //
            gradient: LinearGradient(
              colors: [_T.accent.withOpacity(0.1), Colors.transparent], //
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTxList() {
    if (filteredData.isEmpty) { //
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40), //
          child: Column(children: [
            const Icon(Icons.receipt_long_rounded, size: 54, color: _T.textDim), //
            const SizedBox(height: 14), //
            const Text('No bills yet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _T.textMid)), //
            const SizedBox(height: 6), //
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40), //
              child: Text('Mulai dengan memindai struk barumu untuk melacak pengeluaran.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _T.textMid.withOpacity(0.7), fontSize: 12, height: 1.4)), //
            ),
          ]),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16), //
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _TxCard(
            expense: filteredData[i], //
            onTap:       () => _showDetailDialog(filteredData[i]), //
            onLongPress: () => _showActionSheet(filteredData[i]), //
            rp: rp, //
          ),
          childCount: filteredData.length, //
        ),
      ),
    );
  }

  Widget _buildFab() => Container(
    margin: const EdgeInsets.only(bottom: 90), //
    height: 48, //
    decoration: BoxDecoration(
      color: _T.accent, //
      borderRadius: BorderRadius.circular(12), //
      boxShadow: [
        BoxShadow(color: _T.accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)), //
      ],
    ),
    child: Material(
      color: Colors.transparent, //
      child: InkWell(
        borderRadius: BorderRadius.circular(12), //
        onTap: () async {
          HapticFeedback.mediumImpact(); //
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage())); //
          load(); //
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20), //
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Scan Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  )), //
              SizedBox(width: 8), //
              Icon(Icons.crop_free_rounded, color: Colors.white, size: 16), //
            ],
          ),
        ),
      ),
    ),
  );

  void _showDetailDialog(Expense expense) {
    final catCfg = _T.categories[expense.category ?? 'Lainnya'] ?? _T.categories['Lainnya']!; //
    final color  = catCfg['color'] as Color; //
    final icon   = catCfg['icon'] as String; //

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _T.surface, //
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), //
        child: Padding(
          padding: const EdgeInsets.all(22), //
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40, height: 40, //
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12), //
                    borderRadius: BorderRadius.circular(12), //
                  ),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))), //
                ),
                const SizedBox(width: 12), //
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.store ?? 'Outlet', //
                        style: const TextStyle(fontWeight: FontWeight.w800, //
                            fontSize: 16, color: _T.text)), //
                    Text(expense.date.split('T')[0], //
                        style: const TextStyle(fontSize: 11, color: _T.textMid, fontWeight: FontWeight.w500)), //
                  ],
                )),
              ]),
              const SizedBox(height: 18), //
              const Text('RINCIAN STRUK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  letterSpacing: 1.1, color: _T.textMid)), //
              const SizedBox(height: 8), //
              Container(
                width: double.infinity, //
                constraints: const BoxConstraints(maxHeight: 150), //
                padding: const EdgeInsets.all(10), //
                decoration: BoxDecoration(color: _T.bg, borderRadius: BorderRadius.circular(10)), //
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity, //
                    child: Text(
                      (expense.items?.isEmpty ?? true) ? 'Tidak ada rincian.' : expense.items!, //
                      style: const TextStyle(fontSize: 13, height: 1.5, color: _T.text, fontWeight: FontWeight.w500), //
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), //
              Container(
                width: double.infinity, //
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), //
                decoration: BoxDecoration(
                  color: _T.border, //
                  borderRadius: BorderRadius.circular(12), //
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                            letterSpacing: 1.1, color: _T.textMid)), //
                    Text(rp(expense.amount), //
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _T.text)), //
                  ],
                ),
              ),
              const SizedBox(height: 14), //
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup', style: TextStyle(color: _T.textMid, fontWeight: FontWeight.w700)), //
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionSheet(Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _T.surface, //
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)), //
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), //
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: _T.border, //
                    borderRadius: BorderRadius.circular(2))), //
            const SizedBox(height: 20), //
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _T.textMid), //
              title: const Text('Edit Catatan',
                  style: TextStyle(color: _T.text, fontWeight: FontWeight.w700, fontSize: 14)), //
              onTap: () { Navigator.pop(context); _showEditDialog(expense); }, //
            ),
            const Divider(color: _T.border, height: 1), //
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: _T.danger), //
              title: const Text('Hapus Transaksi',
                  style: TextStyle(color: _T.danger, fontWeight: FontWeight.w700, fontSize: 14)), //
              onTap: () async {
                await DBService.deleteExpense(expense.id!); //
                if (mounted) Navigator.pop(context);
                load(); //
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Expense expense) {
    final storeCon  = TextEditingController(text: expense.store); //
    final amountCon = TextEditingController(text: expense.amount.toStringAsFixed(0)); //

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _T.surface, //
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), //
        child: Padding(
          padding: const EdgeInsets.all(22), //
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Transaksi',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _T.text)), //
              const SizedBox(height: 16), //
              _input(controller: storeCon, label: 'Nama Toko', icon: Icons.storefront_outlined), //
              const SizedBox(height: 10), //
              _input(controller: amountCon, label: 'Nominal',
                  icon: Icons.payments_outlined, type: TextInputType.number), //
              const SizedBox(height: 20), //
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _T.textMid, //
                      padding: const EdgeInsets.symmetric(vertical: 12), //
                      side: const BorderSide(color: _T.border), //
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), //
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), //
                  ),
                ),
                const SizedBox(width: 10), //
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = Expense(
                        id: expense.id, store: storeCon.text, //
                        amount: double.tryParse(amountCon.text) ?? expense.amount, //
                        date: expense.date, category: expense.category, //
                        items: expense.items, //
                      );
                      await DBService.updateExpense(updated); //
                      if (mounted) Navigator.pop(context);
                      load(); //
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.accent, //
                      foregroundColor: Colors.white, //
                      padding: const EdgeInsets.symmetric(vertical: 12), //
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), //
                      elevation: 0,
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), //
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) => TextField(
    controller: controller, //
    keyboardType: type, //
    style: const TextStyle(color: _T.text, fontSize: 14, fontWeight: FontWeight.w600), //
    decoration: InputDecoration(
      labelText: label, //
      labelStyle: const TextStyle(color: _T.textMid, fontSize: 12, fontWeight: FontWeight.w500), //
      prefixIcon: Icon(icon, color: _T.textMid, size: 16), //
      filled: true, //
      fillColor: _T.bg, //
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), //
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), //
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), //
          borderSide: const BorderSide(color: _T.accent, width: 1.5)), //
    ),
  );

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _T.surface, //
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), //
        child: Padding(
          padding: const EdgeInsets.all(24), //
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48, height: 48, //
                decoration: BoxDecoration(
                  color: _T.danger.withOpacity(0.1), //
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: _T.danger, size: 22), //
              ),
              const SizedBox(height: 16), //
              const Text('Hapus semua data?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _T.text)), //
              const SizedBox(height: 6), //
              const Text('Semua riwayat pengeluaran akan bersihkan secara permanen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _T.textMid, fontSize: 12, height: 1.4)), //
              const SizedBox(height: 20), //
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _T.textMid, //
                      padding: const EdgeInsets.symmetric(vertical: 12), //
                      side: const BorderSide(color: _T.border), //
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), //
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), //
                  ),
                ),
                const SizedBox(width: 10), //
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await DBService.deleteAll(); //
                      Navigator.pop(context);
                      load(); //
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.danger, //
                      foregroundColor: Colors.white, //
                      padding: const EdgeInsets.symmetric(vertical: 12), //
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), //
                      elevation: 0,
                    ),
                    child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), //
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSAKSI CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _TxCard extends StatelessWidget {
  final Expense expense; //
  final VoidCallback onTap; //
  final VoidCallback onLongPress; //
  final String Function(double) rp; //

  const _TxCard({
    required this.expense, 
    required this.onTap,
    required this.onLongPress, 
    required this.rp,
  });

  @override
  Widget build(BuildContext context) {
    final catCfg  = _T.categories[expense.category ?? 'Lainnya'] ?? _T.categories['Lainnya']!; //
    final icon    = catCfg['icon'] as String; //
    final preview = expense.items?.isEmpty ?? true
        ? 'Tanpa rincian'
        : expense.items!.replaceAll('\n', ', '); //

    return Padding(
      padding: const EdgeInsets.only(bottom: 8), //
      child: Material(
        color: _T.surface, //
        borderRadius: BorderRadius.circular(16), //
        child: InkWell(
          onTap: () { 
            HapticFeedback.selectionClick(); //
            onTap(); 
          },
          onLongPress: () { 
            HapticFeedback.mediumImpact(); //
            onLongPress(); 
          },
          borderRadius: BorderRadius.circular(16), //
          child: Container(
            padding: const EdgeInsets.all(14), //
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16), //
              border: Border.all(color: _T.border), //
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38, //
                decoration: const BoxDecoration(
                  color: _T.bg, //
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))), //
              ),
              const SizedBox(width: 12), //
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, //
                  children: [
                    Text(expense.store ?? 'Outlet', //
                        style: const TextStyle(fontWeight: FontWeight.w700, //
                            fontSize: 13, color: _T.text)), //
                    const SizedBox(height: 2), //
                    Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, //
                        style: const TextStyle(color: _T.textMid, fontSize: 11, fontWeight: FontWeight.w500)), //
                  ],
                ),
              ),
              const SizedBox(width: 10), //
              Column(
                crossAxisAlignment: CrossAxisAlignment.end, //
                children: [
                  Text(rp(expense.amount), //
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13, //
                          color: _T.text, letterSpacing: -0.2)), //
                  const SizedBox(height: 3), //
                  Text(expense.date.split('T').first, //
                      style: const TextStyle(color: _T.textDim, fontSize: 10, fontWeight: FontWeight.w600)), //
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// PROFILE PAGE — Data dinamis dari database, semua fitur aktif
// ─────────────────────────────────────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name     = '';
  String phone    = '';
  String username = '';
  bool _isLoading = true;

  // Settings state — disimpan ke SharedPreferences agar persisten
  String _currentLanguage    = 'Bahasa Indonesia';
  bool _isNotifEnabled       = true;

  void _showActionSheet(Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: _T.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _T.textMid),
              title: const Text('Edit Catatan',
                  style: TextStyle(color: _T.text, fontWeight: FontWeight.w700, fontSize: 14)),
              onTap: () { Navigator.pop(context); _showEditDialog(expense); },
            ),
            const Divider(color: _T.border, height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: _T.danger),
              title: const Text('Hapus Transaksi',
                  style: TextStyle(color: _T.danger, fontWeight: FontWeight.w700, fontSize: 14)),
              onTap: () async {
                await DBService.deleteExpense(expense.id!);
                if (mounted) Navigator.pop(context);
                if (mounted) _showHistorySheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Expense expense) {
    final storeCon  = TextEditingController(text: expense.store);
    final amountCon = TextEditingController(text: expense.amount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Transaksi',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _T.text)),
              const SizedBox(height: 16),
              _input(controller: storeCon, label: 'Nama Toko', icon: Icons.storefront_outlined),
              const SizedBox(height: 10),
              _input(controller: amountCon, label: 'Nominal',
                  icon: Icons.payments_outlined, type: TextInputType.number),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _T.textMid,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: _T.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = Expense(
                        id: expense.id, store: storeCon.text,
                        amount: double.tryParse(amountCon.text) ?? expense.amount,
                        date: expense.date, category: expense.category,
                        items: expense.items,
                      );
                      await DBService.updateExpense(updated);
                      if (mounted) Navigator.pop(context);
                      if (mounted) _showHistorySheet();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) => TextField(
    controller: controller,
    keyboardType: type,
    style: const TextStyle(color: _T.text, fontSize: 14, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _T.textMid, fontSize: 12, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: _T.textMid, size: 16),
      filled: true,
      fillColor: _T.bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _T.accent)),
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final profile = await DBService.getCurrentUserProfile();
    final prefs   = await _getPrefs();
    if (!mounted) return;
    setState(() {
      name             = profile['display_name'] ?? '';
      phone            = profile['phone']        ?? '';
      username         = profile['username']     ?? '';
      _currentLanguage = prefs['language']       ?? 'Bahasa Indonesia';
      _isNotifEnabled  = (prefs['notif'] ?? 'true') == 'true';
      _isLoading       = false;
    });
  }

  Future<Map<String, String>> _getPrefs() async {
    final p = await _ProfilePrefs.load();
    return p;
  }

  // ── EDIT PROFILE DIALOG ────────────────────────────────────────────────────
  void _showEditProfileDialog() {
    final nameCtrl  = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);
    final usernameCtrl = TextEditingController(text: username);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profil',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _T.text)),
              const SizedBox(height: 4),
              const Text('Perubahan nama & nomor HP disimpan permanen.',
                  style: TextStyle(color: _T.textMid, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              _buildDialogField(controller: nameCtrl, label: 'Nama Lengkap', icon: Icons.person_outline),
              const SizedBox(height: 10),
              _buildDialogField(controller: phoneCtrl, label: 'Nomor HP', icon: Icons.phone_outlined, isNumber: true),
              const SizedBox(height: 10),
              // Username — read-only, hanya tampilkan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: _T.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alternate_email_rounded, color: _T.textMid, size: 16),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Username (tidak bisa diubah)',
                            style: TextStyle(color: _T.textMid, fontSize: 10, fontWeight: FontWeight.w500)),
                        Text(username,
                            style: const TextStyle(color: _T.text, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _T.textMid,
                        side: const BorderSide(color: _T.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName  = nameCtrl.text.trim();
                        final newPhone = phoneCtrl.text.trim();
                        if (newName.isEmpty) return;
                        await DBService.updateUserProfile(displayName: newName, phone: newPhone);
                        if (!mounted) return;
                        setState(() { name = newName; phone = newPhone; });
                        Navigator.pop(ctx);
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profil berhasil diperbarui!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _T.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HISTORY BOTTOM SHEET ───────────────────────────────────────────────────

  void _showProfileActionSheet(Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: _T.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _T.textMid),
              title: const Text('Edit Catatan',
                  style: TextStyle(color: _T.text, fontWeight: FontWeight.w700, fontSize: 14)),
              onTap: () { Navigator.pop(context); _showProfileEditDialog(expense); },
            ),
            const Divider(color: _T.border, height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: _T.danger),
              title: const Text('Hapus Transaksi',
                  style: TextStyle(color: _T.danger, fontWeight: FontWeight.w700, fontSize: 14)),
              onTap: () async {
                await DBService.deleteExpense(expense.id!);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileEditDialog(Expense expense) {
    final storeCon  = TextEditingController(text: expense.store);
    final amountCon = TextEditingController(text: expense.amount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Transaksi',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _T.text)),
              const SizedBox(height: 16),
              TextField(
                controller: storeCon,
                decoration: InputDecoration(
                  labelText: 'Nama Toko',
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCon,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _T.textMid,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: _T.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = Expense(
                        id: expense.id, store: storeCon.text,
                        amount: double.tryParse(amountCon.text) ?? expense.amount,
                        date: expense.date, category: expense.category,
                        items: expense.items,
                      );
                      await DBService.updateExpense(updated);
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistorySheet() async {
    final expenses = await DBService.getExpenses();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: _T.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, color: _T.accent, size: 20),
                    const SizedBox(width: 8),
                    const Text('Riwayat Transaksi',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _T.text)),
                    const Spacer(),
                    Text('${expenses.length} transaksi',
                        style: const TextStyle(color: _T.textMid, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: _T.border),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🧾', style: TextStyle(fontSize: 40)),
                            SizedBox(height: 12),
                            Text('Belum ada transaksi',
                                style: TextStyle(color: _T.textMid, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: _T.border),
                        itemBuilder: (_, i) {
                          final e = expenses[i];
                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _showProfileActionSheet(e);
                            },
                            child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: _T.bg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text('🧾', style: TextStyle(fontSize: 18)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.store ?? 'Toko',
                                          style: const TextStyle(
                                              color: _T.text, fontWeight: FontWeight.w700, fontSize: 13)),
                                      Text(e.date.split('T').first,
                                          style: const TextStyle(
                                              color: _T.textMid, fontSize: 11, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Rp ${e.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                  style: const TextStyle(
                                      color: _T.accent, fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                              ],
                            ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── REGISTER PHONE NUMBER DIALOG ───────────────────────────────────────────
  void _showRegisterPhoneDialog() {
    final phoneCtrl = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daftarkan Nomor HP',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _T.text)),
              const SizedBox(height: 4),
              const Text('Nomor HP digunakan untuk verifikasi akun.',
                  style: TextStyle(color: _T.textMid, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              _buildDialogField(
                controller: phoneCtrl,
                label: 'Nomor HP (contoh: 08123456789)',
                icon: Icons.phone_android_rounded,
                isNumber: true,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _T.textMid,
                        side: const BorderSide(color: _T.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newPhone = phoneCtrl.text.trim();
                        if (newPhone.isEmpty) return;
                        await DBService.updateUserProfile(
                            displayName: name.isNotEmpty ? name : username, phone: newPhone);
                        if (!mounted) return;
                        setState(() => phone = newPhone);
                        Navigator.pop(ctx);
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nomor HP berhasil didaftarkan!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _T.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Daftar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── LANGUAGE BOTTOM SHEET ──────────────────────────────────────────────────
  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: _T.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Pilih Bahasa / Language',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: _T.text)),
              const SizedBox(height: 4),
              const Text('Bahasa tampilan aplikasi',
                  style: TextStyle(color: _T.textMid, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              for (final lang in ['Bahasa Indonesia', 'English']) ...[
                _buildLangOption(lang, _currentLanguage, (selected) async {
                  setSheetState(() {});
                  setState(() => _currentLanguage = selected);
                  await _ProfilePrefs.setLanguage(selected);
                  HapticFeedback.lightImpact();
                  if (mounted) Navigator.pop(ctx);
                }),
                if (lang != 'English') const Divider(color: _T.border, height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangOption(String lang, String current, void Function(String) onSelect) {
    final isSelected = current == lang;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Text(lang == 'Bahasa Indonesia' ? '🇮🇩' : '🇬🇧',
          style: const TextStyle(fontSize: 20)),
      title: Text(lang,
          style: TextStyle(
              color: _T.text,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13)),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: _T.accent, size: 20)
          : const Icon(Icons.circle_outlined, color: _T.border, size: 20),
      onTap: () => onSelect(lang),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile',
            style: TextStyle(color: _T.text, fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _T.accent))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Avatar Header ──────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 84, height: 84,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF1A1A1C), shape: BoxShape.circle),
                              child: const Center(child: Text('⚡', style: TextStyle(fontSize: 38))),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: GestureDetector(
                                onTap: _showEditProfileDialog,
                                child: Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: _T.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(name.isNotEmpty ? name : username,
                            style: const TextStyle(
                                color: _T.text, fontWeight: FontWeight.w900, fontSize: 17)),
                        const SizedBox(height: 2),
                        Text('@$username',
                            style: const TextStyle(
                                color: _T.accent, fontWeight: FontWeight.w700, fontSize: 12)),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_rounded, size: 11, color: _T.textMid),
                              const SizedBox(width: 4),
                              Text(phone,
                                  style: const TextStyle(
                                      color: _T.textMid, fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── ACCOUNT Section ────────────────────────────────────────
                  const Text('AKUN',
                      style: TextStyle(
                          color: _T.textMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: [
                      _buildGridItem(Icons.edit_outlined, 'Edit Profile', onTap: _showEditProfileDialog),
                      _buildGridItem(Icons.history_rounded, 'Riwayat', onTap: _showHistorySheet),
                      _buildGridItem(Icons.phone_android_rounded, 'Daftarkan No. HP',
                          onTap: _showRegisterPhoneDialog,
                          badge: phone.isEmpty ? 'Belum' : null),
                      _buildGridItem(Icons.lock_outline_rounded, 'Keamanan', onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur keamanan segera hadir!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── SETTINGS Section ───────────────────────────────────────
                  const Text('PENGATURAN',
                      style: TextStyle(
                          color: _T.textMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: _T.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _T.border),
                    ),
                    child: Column(
                      children: [
                        // Language
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.language_rounded, color: _T.text, size: 20),
                          title: Text(
                            _currentLanguage == 'Bahasa Indonesia' ? 'Bahasa' : 'Language',
                            style: const TextStyle(
                                color: _T.text, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentLanguage == 'Bahasa Indonesia' ? '🇮🇩 Bahasa Indonesia' : '🇬🇧 English',
                                style: const TextStyle(
                                    color: _T.accent, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, color: _T.textDim, size: 18),
                            ],
                          ),
                          onTap: _showLanguageSheet,
                        ),
                        const Divider(color: _T.border, height: 1),
                        // Notifikasi
                        SwitchListTile.adaptive(
                          secondary: const Icon(Icons.notifications_none_rounded,
                              color: _T.text, size: 20),
                          title: Text(
                            _currentLanguage == 'Bahasa Indonesia' ? 'Notifikasi' : 'Notifications',
                            style: const TextStyle(
                                color: _T.text, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          activeColor: _T.accent,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          value: _isNotifEnabled,
                          onChanged: (v) async {
                            setState(() => _isNotifEnabled = v);
                            await _ProfilePrefs.setNotif(v);
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────
  Widget _buildGridItem(IconData icon, String label,
      {required VoidCallback onTap, String? badge}) {
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () { HapticFeedback.selectionClick(); onTap(); },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: _T.bg, borderRadius: BorderRadius.circular(8)),
                      child: Icon(icon, color: _T.accent, size: 18),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge,
                            style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              color: _T.text, fontWeight: FontWeight.w800, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _T.textMid, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(color: _T.text, fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _T.textMid, fontSize: 12, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _T.textMid, size: 16),
        filled: true,
        fillColor: _T.bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _T.accent, width: 1.5)),
      ),
    );
  }
}

// ── Helper class untuk simpan preferensi Settings ──────────────────────────
class _ProfilePrefs {
  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'language': prefs.getString('pref_language') ?? 'Bahasa Indonesia',
      'notif':    prefs.getBool('pref_notif')?.toString() ?? 'true',
    };
  }

  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_language', lang);
  }

  static Future<void> setNotif(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_notif', value);
  }
}
