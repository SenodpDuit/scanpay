import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService.init();

  // Cek apakah user sudah login sebelumnya
  final bool alreadyLoggedIn = await AuthService.isLoggedIn();

  runApp(MyApp(startLoggedIn: alreadyLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool startLoggedIn;
  const MyApp({super.key, required this.startLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScanPay',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      // Jika sudah login → langsung ke HomePage (sudah punya nav bar sendiri), jika belum → ke LoginPage
      home: startLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}
