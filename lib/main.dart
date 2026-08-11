import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/mic_screen.dart';
import 'src/screens/landing_screen.dart';
import 'src/screens/phone_login_screen.dart';
import 'src/screens/register_otp_screen.dart';
import 'src/screens/setup_profil_screen.dart';
import 'src/screens/input_barang_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Cek session
  final prefs = await SharedPreferences.getInstance();
  final storeId = prefs.getString('store_id');
  print('🔍 Session store_id: $storeId');
  runApp(ProviderScope(child: MyApp(storeId: storeId)));
}

class MyApp extends StatelessWidget {
  final String? storeId;
  const MyApp({super.key, this.storeId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TemanStok',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      // Kalau sudah ada session → langsung main dashboard, belum → login
      home: storeId != null ? const MainScreen() : const LandingScreen(),
      routes: {
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LandingScreen(),
        '/phone_login': (context) => const PhoneLoginScreen(),
        '/register_otp': (context) => const RegisterOtpScreen(),
        '/setup_profil': (context) => const SetupProfilScreen(),
        '/input_barang': (context) => const InputBarangScreen(),
        '/main': (context) => const MainScreen(),
        '/mic': (context) => const MicScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}