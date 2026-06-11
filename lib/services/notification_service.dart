import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

/// Service untuk menampilkan notifikasi lokal ke perangkat,
/// terutama saat sebuah transaksi melebihi 50% dari sisa anggaran.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Harus dipanggil sekali saat aplikasi start (mis. di main()).
  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings);

    // Minta izin notifikasi (Android 13+ & iOS)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static String _rp(double v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(v);

  /// Cek apakah [transactionAmount] melebihi 50% dari [totalBudget].
  /// Jika ya, tampilkan notifikasi peringatan ke perangkat.
  ///
  /// [totalBudget] adalah dana/anggaran yang dimiliki (mis. budgetTarget
  /// atau sisa anggaran saat ini).
  static Future<void> checkAndNotifyLargeTransaction({
    required double transactionAmount,
    required double totalBudget,
    String? storeName,
  }) async {
    if (totalBudget <= 0) return;

    final ratio = transactionAmount / totalBudget;
    if (ratio < 0.5) return;

    await init();

    final percent = (ratio * 100).toStringAsFixed(0);
    final title = '⚠️ Transaksi Besar Terdeteksi';
    final body = storeName != null && storeName.trim().isNotEmpty
        ? 'Transaksi di $storeName sebesar ${_rp(transactionAmount)} '
            'telah menggunakan $percent% dari dana yang kamu miliki.'
        : 'Transaksi sebesar ${_rp(transactionAmount)} '
            'telah menggunakan $percent% dari dana yang kamu miliki.';

    const androidDetails = AndroidNotificationDetails(
      'large_transaction_channel',
      'Peringatan Transaksi Besar',
      channelDescription:
          'Notifikasi saat transaksi melebihi 50% dari dana yang dimiliki',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notifDetails,
    );
  }
}
