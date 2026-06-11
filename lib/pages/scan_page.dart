import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/db_service.dart';

// ─── DESIGN TOKENS (Tema Orange & Light) ─────────────────────────────────────
const _bgLight    = Color(0xFFFFF5F1); 
const _bgCard     = Colors.white;      
const _borderCol  = Color(0xFFF0F0F2); 
const _accent     = Color(0xFFFF451A); 
const _textPri    = Color(0xFF1A1A1C); 
const _textSec    = Color(0xFF7D7E84); 
const _textMuted  = Color(0xFFC1C2C7); 

class ReceiptItem {
  String name;
  double price;
  ReceiptItem(this.name, this.price);
}

class ScanResult {
  final String storeName;
  final double totalAmount;
  final List<ReceiptItem> items;
  final double confidence;
  ScanResult({required this.storeName, required this.totalAmount, required this.items, required this.confidence});
}

// ─── MAIN SCAN PAGE WIDGET ───────────────────────────────────────────────────
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  File? _imageFile;

  // Controller Utama untuk Form
  final _storeController = TextEditingController();
  String _selectedCategory = 'Makanan';
  DateTime _selectedDate = DateTime.now();

  // List Dinamis Penampung Item Barang & Harga
  List<ReceiptItem> _dynamicItems = [];

  final List<String> _categories = ['Makanan', 'Transport', 'Belanja', 'Kesehatan', 'Lainnya'];

  @override
  void dispose() {
    _storeController.dispose();
    super.dispose();
  }

  // Fungsi Hitung Otomatis Total Harga dari Semua Item
  double _calculateTotalAmount() {
    return _dynamicItems.fold(0, (sum, item) => sum + item.price);
  }

  // Fungsi Tampilkan Kalender
  Future<void> _pickDate(BuildContext context, StateSetter modalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accent,
              onPrimary: Colors.white,
              onSurface: _textPri,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      modalState(() {
        _selectedDate = picked;
      });
    }
  }

  // Proses Pindai Gambar Menggunakan AI ML Kit
  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 85);
      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _imageFile = File(pickedFile.path);
      });

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final parsedResult = ReceiptParser.parse(recognizedText.text);

      setState(() {
        _storeController.text = parsedResult.storeName;
        _dynamicItems = parsedResult.items.isNotEmpty 
            ? parsedResult.items 
            : [ReceiptItem("Total Scan Otomatis", parsedResult.totalAmount)];
        _selectedDate = DateTime.now();
        _isLoading = false;
      });

      if (mounted) _showSaveBottomSheet();

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses struk: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // Buka Form Kosongan untuk Input Manual
  void _openManualInput() {
    setState(() {
      _imageFile = null;
      _storeController.clear();
      _selectedCategory = 'Makanan';
      _selectedDate = DateTime.now();
      // Berikan 1 baris input barang kosong di awal agar tidak bingung
      _dynamicItems = [ReceiptItem("", 0)]; 
    });
    _showSaveBottomSheet();
  }

  // Tampilan Utama Form Modal BottomSheet
  void _showSaveBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final double currentTotal = _calculateTotalAmount();

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85, // Batasi tinggi max 85% layar
                ),
                decoration: const BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: _borderCol, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _imageFile == null ? 'Input Pengeluaran Manual' : 'Konfirmasi Hasil Scan',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: _textPri),
                        ),
                        // Indikator Total Real-time melayang di atas kanan form
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            "Total: Rp ${NumberFormat('#,###', 'id_ID').format(currentTotal)}",
                            style: const TextStyle(color: _accent, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Input Toko
                    _buildTextField(controller: _storeController, label: 'Nama Toko / Tempat', icon: Icons.storefront_outlined),
                    const SizedBox(height: 12),
                    
                    // Input Tanggal
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: _textSec),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMMM yyyy').format(_selectedDate),
                                style: const TextStyle(color: _textPri, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => _pickDate(context, setModalState),
                            child: const Text('Ubah Tanggal', style: TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // AREA DINAMIS INPUT BARANG & HARGA (Bisa di-scroll kalau banyak)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daftar Barang & Harga', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _textPri)),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              _dynamicItems.add(ReceiptItem("", 0));
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: _accent),
                          label: const Text('Tambah Barang', style: TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 12)),
                        )
                      ],
                    ),
                    
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _dynamicItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return Row(
                            children: [
                              // Input Nama Barang
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: _dynamicItems[index].name,
                                  style: const TextStyle(color: _textPri, fontSize: 12, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText: 'Nama Barang (Contoh: Seblak)',
                                    hintStyle: const TextStyle(color: _textMuted, fontSize: 11),
                                    filled: true,
                                    fillColor: _bgLight,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                  onChanged: (val) => _dynamicItems[index].name = val,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Input Harga Barang
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: _dynamicItems[index].price == 0 ? "" : _dynamicItems[index].price.toStringAsFixed(0),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: _textPri, fontSize: 12, fontWeight: FontWeight.w700),
                                  decoration: InputDecoration(
                                    hintText: 'Harga (Rp)',
                                    hintStyle: const TextStyle(color: _textMuted, fontSize: 11),
                                    filled: true,
                                    fillColor: _bgLight,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                  onChanged: (val) {
                                    setModalState(() {
                                      _dynamicItems[index].price = double.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              // Tombol Hapus Baris Barang
                              if (_dynamicItems.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  onPressed: () {
                                    setModalState(() {
                                      _dynamicItems.removeAt(index);
                                    });
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kategori Dropdown
                    const Text('Kategori', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textSec)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: _bgCard,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bgLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 13),
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => _selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tombol Simpan Final
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_storeController.text.trim().isEmpty || currentTotal <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nama toko dan rincian harga barang harus valid!'), backgroundColor: Colors.orange),
                            );
                            return;
                          }

                          // Susun teks rincian barang terformat untuk disimpan ke field 'items' di DB
                          final String formattedItems = _dynamicItems
                              .where((item) => item.name.trim().isNotEmpty)
                              .map((item) => "${item.name}\nRp ${NumberFormat('#,###', 'id_ID').format(item.price)}")
                              .join("\n\n");

                          final data = Expense(
                            store: _storeController.text.trim(),
                            amount: currentTotal,
                            date: _selectedDate.toIso8601String(),
                            category: _selectedCategory,
                            items: formattedItems.isEmpty ? "Rincian manual tanpa nama" : formattedItems,
                          );

                          await DBService.insertExpense(data);
                          HapticFeedback.heavyImpact();

                          if (context.mounted) {
                            Navigator.pop(context); // Tutup BottomSheet
                            Navigator.pop(context); // Kembali ke Dashboard
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Simpan Pengeluaran', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSec, fontSize: 12, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _textSec, size: 16),
        filled: true,
        fillColor: _bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPri, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pindai / Catat Struk', style: TextStyle(color: _textPri, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.document_scanner_outlined, size: 64, color: _accent),
                  const SizedBox(height: 12),
                  const Text('Pilih Metode Input', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _textPri)),
                  const SizedBox(height: 6),
                  const Text('Kamu bisa scan struk belanjaan otomatis menggunakan AI atau input mandiri secara manual.',
                      textAlign: TextAlign.center, style: TextStyle(color: _textSec, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 32),
                  
                  _SourceButton(icon: Icons.camera_alt_outlined, label: 'Ambil Foto Struk', onTap: () => _processImage(ImageSource.camera)),
                  const SizedBox(height: 10),
                  _SourceButton(icon: Icons.photo_library_outlined, label: 'Pilih dari Galeri', onTap: () => _processImage(ImageSource.gallery)),
                  
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Container(height: 1, color: _borderCol)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('atau', style: TextStyle(color: _textMuted, fontSize: 12))),
                    Expanded(child: Container(height: 1, color: _borderCol)),
                  ]),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ).childHandler(
                      onPressed: _openManualInput,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Input Manual Sendiri', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── SOURCE SELECTION BUTTON WIDGET ──────────────────────────────────────────
class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bgCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: _borderCol)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _accent, size: 18),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: _textPri, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

extension on ButtonStyle {
  Widget childHandler({required VoidCallback onPressed, required Widget child}) {
    return OutlinedButton(style: this, onPressed: onPressed, child: child);
  }
}

// ─── AI RECEIPT PARSER ENGINE (RegEx) ────────────────────────────────────────
class ReceiptParser {
  static ScanResult parse(String rawText) {
    final lines = rawText.split('\n');
    String storeName = "Outlet / Toko";
    if (lines.isNotEmpty && lines.first.trim().length > 2) {
      storeName = lines.first.trim();
    }

    double totalAmount = 0;
    List<ReceiptItem> parsedItems = [];

    final RegExp priceRegex = RegExp(r'(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+)', caseSensitive: false);
    final RegExp totalKeywords = RegExp(r'(total|grand\s*total|jumlah|netto|amount|payable)', caseSensitive: false);

    for (var line in lines) {
      if (totalKeywords.hasMatch(line)) {
        final matches = priceRegex.allMatches(line);
        if (matches.isNotEmpty) {
          final cleanPrice = matches.last.group(1)!.replaceAll('.', '').replaceAll(',', '');
          final val = double.tryParse(cleanPrice) ?? 0;
          if (val > totalAmount) totalAmount = val;
        }
      }
    }

    if (totalAmount == 0) {
      double maxPrice = 0;
      for (var line in lines) {
        final matches = priceRegex.allMatches(line);
        if (matches.isNotEmpty) {
          final cleanPrice = matches.first.group(1)!.replaceAll('.', '').replaceAll(',', '');
          final val = double.tryParse(cleanPrice) ?? 0;
          if (val > maxPrice) maxPrice = val;
        }
      }
      totalAmount = maxPrice;
    }

    return ScanResult(
      storeName: storeName,
      totalAmount: totalAmount,
      items: parsedItems,
      confidence: totalAmount > 0 ? 0.85 : 0.40,
    );
  }
}