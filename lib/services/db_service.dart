import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class DBService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scanpay_database.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tabel Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Tabel profil tambahan per user (nama lengkap, telepon, dsb)
    await db.execute('''
      CREATE TABLE user_profiles (
        user_id INTEGER PRIMARY KEY,
        display_name TEXT,
        phone TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Tabel Expenses dengan user_id agar data tiap akun terpisah
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 0,
        store TEXT,
        amount REAL,
        date TEXT,
        category TEXT,
        items TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE expenses ADD COLUMN user_id INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      // Buat tabel profil jika belum ada
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profiles (
          user_id INTEGER PRIMARY KEY,
          display_name TEXT,
          phone TEXT
        )
      ''');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUTENTIKASI
  // ─────────────────────────────────────────────────────────────────────────

  static Future<int> registerUser(String username, String password) async {
    final db = await database;
    try {
      final id = await db.insert('users', {
        'username': username,
        'password': password,
      });
      // Buat profil default otomatis saat register
      if (id != -1) {
        await db.insert('user_profiles', {
          'user_id': id,
          'display_name': username,
          'phone': '',
        });
      }
      return id;
    } catch (e) {
      return -1;
    }
  }

  static Future<bool> loginUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return res.isNotEmpty;
  }

  /// Ambil user_id berdasarkan username
  static Future<int?> getUserId(String username) async {
    final db = await database;
    final res = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (res.isEmpty) return null;
    return res.first['id'] as int?;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROFIL USER
  // ─────────────────────────────────────────────────────────────────────────

  /// Ambil profil user yang sedang login
  static Future<Map<String, String>> getCurrentUserProfile() async {
    final username = await AuthService.getLoggedInUsername();
    if (username == null) return {'display_name': '', 'phone': '', 'username': ''};

    final userId = await getUserId(username);
    if (userId == null) return {'display_name': username, 'phone': '', 'username': username};

    final db = await database;
    final res = await db.query('user_profiles', where: 'user_id = ?', whereArgs: [userId]);

    if (res.isEmpty) {
      // Buat profil default jika belum ada (misal: akun lama)
      await db.insert('user_profiles', {'user_id': userId, 'display_name': username, 'phone': ''});
      return {'display_name': username, 'phone': '', 'username': username};
    }

    return {
      'display_name': (res.first['display_name'] as String?) ?? username,
      'phone': (res.first['phone'] as String?) ?? '',
      'username': username,
    };
  }

  /// Update profil user yang sedang login
  static Future<void> updateUserProfile({required String displayName, required String phone}) async {
    final username = await AuthService.getLoggedInUsername();
    if (username == null) return;
    final userId = await getUserId(username);
    if (userId == null) return;

    final db = await database;
    await db.update(
      'user_profiles',
      {'display_name': displayName, 'phone': phone},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXPENSES — Semua operasi otomatis pakai user_id dari session aktif
  // ─────────────────────────────────────────────────────────────────────────

  static Future<int> _currentUserId() async {
    final username = await AuthService.getLoggedInUsername();
    if (username == null) return 0;
    return (await getUserId(username)) ?? 0;
  }

  static Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final userId = await _currentUserId();
    final map = expense.toMap();
    map['user_id'] = userId;
    final result = await db.insert('expenses', map, conflictAlgorithm: ConflictAlgorithm.replace);

    // Cek apakah transaksi ini melebihi 50% dari dana yang dimiliki
    await _checkBudgetNotification(expense.amount, expense.store);

    return result;
  }

  /// Bandingkan nominal transaksi dengan budget yang tersimpan,
  /// kirim notifikasi jika sudah >= 50% dari dana yang dimiliki.
  static Future<void> _checkBudgetNotification(double amount, String? store) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetTarget = prefs.getDouble('budget_target');
      if (budgetTarget == null || budgetTarget <= 0) return;

      await NotificationService.checkAndNotifyLargeTransaction(
        transactionAmount: amount,
        totalBudget: budgetTarget,
        storeName: store,
      );
    } catch (_) {
      // Abaikan error notifikasi agar tidak mengganggu proses simpan data
    }
  }

  static Future<List<Expense>> getExpenses() async {
    final db = await database;
    final userId = await _currentUserId();
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  static Future<int> updateExpense(Expense expense) async {
    final db = await database;
    final result = await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
    await _checkBudgetNotification(expense.amount, expense.store);
    return result;
  }

  static Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteAll() async {
    final db = await database;
    final userId = await _currentUserId();
    return await db.delete('expenses', where: 'user_id = ?', whereArgs: [userId]);
  }
}
