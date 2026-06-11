import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — Orange & Light Theme Premium (Disamakan dengan Beranda)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const bg       = Color(0xFFFFF5F1); // Krem/Peach sangat muda
  static const surface  = Colors.white;      // Kartu & kontainer putih
  static const border   = Color(0xFFF0F0F2); // Batas tipis lembut
  static const accent   = Color(0xFFFF451A); // Oranye terang menyala
  static const text     = Color(0xFF1A1A1C); // Teks utama gelap
  static const textMid  = Color(0xFF7D7E84); // Teks sekunder abu-abu
  static const textDim  = Color(0xFFC1C2C7); // Teks pudar
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State lokal untuk menyimpan data Profil (Bisa langsung diubah lewat aplikasi)
  String name = "Mohamad Rafi Ardiansyah";
  String phone = "+628123456756";

  // State lokal untuk menu Settings
  String _currentLanguage = 'English';
  bool _isNotificationEnabled = true;

  // Fungsi untuk menampilkan Dialog Pop-up Edit Profile (LANGSUNG AKTIF)
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profil Kamu', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _T.text),
              ),
              const SizedBox(height: 16),
              
              // Input Nama
              _buildDialogField(controller: nameController, label: 'Nama Lengkap', icon: Icons.person_outline),
              const SizedBox(height: 12),
              
              // Input Nomor HP
              _buildDialogField(controller: phoneController, label: 'Nomor HP', icon: Icons.phone_outlined, isNumber: true),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          setState(() {
                            name = nameController.text.trim();
                            phone = phoneController.text.trim();
                          });
                          Navigator.pop(context);
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
                          );
                        }
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
              )
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi untuk menampilkan BottomSheet Pilihan Bahasa (LANGSUNG AKTIF)
  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _T.surface, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
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
            const Text('Pilih Bahasa / Language', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: _T.text)),
            const SizedBox(height: 12),
            _buildLanguageOption('English'),
            Divider(color: _T.border, height: 1),
            _buildLanguageOption('Bahasa Indonesia'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String lang) {
    final isSelected = _currentLanguage == lang;
    return ListTile(
      dense: true,
      title: Text(lang, style: TextStyle(color: _T.text, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: _T.accent, size: 20) : null,
      onTap: () {
        setState(() => _currentLanguage = lang);
        Navigator.pop(context);
        HapticFeedback.lightImpact();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(color: _T.text, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: _T.accent), 
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // Avatar Header (Menampilkan Nama & No HP secara Dinamis)
            Center(
              child: Column(
                children: [
                  Container(
                    width: 84, height: 84,
                    decoration: const BoxDecoration(color: Color(0xFF1A1A1C), shape: BoxShape.circle),
                    child: const Center(child: Text('⚡', style: TextStyle(fontSize: 38))),
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: const TextStyle(color: _T.text, fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(phone, style: const TextStyle(color: _T.textMid, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Subscription Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _T.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _T.border)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subscription', style: TextStyle(color: _T.text, fontWeight: FontWeight.w900, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _T.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Free', style: TextStyle(color: _T.accent, fontSize: 10, fontWeight: FontWeight.w800)),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Align(alignment: Alignment.centerLeft, child: Text('Upgrade to unlock unlimited features', style: TextStyle(color: _T.textMid, fontSize: 12, fontWeight: FontWeight.w500))),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: _T.accent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Upgrade Plan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('ACCOUNT', style: TextStyle(color: _T.textMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 8),

            // Grid Menu (Tombol Edit Profile di sini)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                _buildGridMenuItem(Icons.edit_outlined, 'Edit Profile', onTap: _showEditProfileDialog), // ⚡ TOMBOL INI AKTIF SEKARANG!
                _buildGridMenuItem(Icons.credit_card_rounded, 'Payment Methods', onTap: () {}),
                _buildGridMenuItem(Icons.history_rounded, 'History', onTap: () {}),
                _buildGridMenuItem(Icons.phone_android_rounded, 'Register Phone Number', onTap: () {}),
              ],
            ),
            const SizedBox(height: 20),

            const Text('SETTINGS', style: TextStyle(color: _T.textMid, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(color: _T.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _T.border)),
              child: Column(
                children: [
                  _buildListTileMenu(Icons.language_rounded, 'Language', trailingText: _currentLanguage, onTap: _showLanguageBottomSheet), // ⚡ AKTIF
                  
                  // Perbaikan permanen: Keyword const dilepas agar bebas dari evaluation error
                  Divider(color: _T.border, height: 1, thickness: 1),
                  
                  // Mengubah Notification menjadi Toggle Switch Interaktif (LANGSUNG AKTIF)
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.notifications_none_rounded, color: _T.text, size: 20),
                    title: const Text('Notifications', style: TextStyle(color: _T.text, fontWeight: FontWeight.w700, fontSize: 13)),
                    activeColor: _T.accent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    value: _isNotificationEnabled,
                    onChanged: (bool value) {
                      setState(() => _isNotificationEnabled = value);
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

  // ─── SUB-COMPONENTS WIDGET HELPER ──────────────────────────────────────────
  Widget _buildGridMenuItem(IconData icon, String label, {required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: _T.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _T.border)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () { 
            HapticFeedback.selectionClick(); 
            onTap(); 
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _T.bg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: _T.accent, size: 18),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(label, style: const TextStyle(color: _T.text, fontWeight: FontWeight.w800, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.chevron_right_rounded, color: _T.textMid, size: 16),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTileMenu(IconData icon, String label, {String? trailingText, required VoidCallback onTap}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: _T.text, size: 20),
      title: Text(label, style: const TextStyle(color: _T.text, fontWeight: FontWeight.w700, fontSize: 13)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) Text(trailingText, style: const TextStyle(color: _T.accent, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: _T.textDim, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDialogField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: _T.text, fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _T.textMid, fontSize: 12, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _T.textMid, size: 16),
        filled: true,
        fillColor: _T.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _T.accent, width: 1.5)),
      ),
    );
  }
}