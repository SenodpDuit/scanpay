import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'logged_in_username';

  /// Simpan session login ke SharedPreferences
  static Future<void> saveSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUsername, username);
  }

  /// Hapus session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyUsername);
  }

  /// Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  /// Ambil username yang sedang login
  static Future<String?> getLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }
}
