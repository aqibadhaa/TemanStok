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
import 'widgets/session_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final storeId = prefs.getString('store_id');
  final hasSession = storeId != null && storeId.isNotEmpty;

  runApp(ProviderScope(child: MyApp(hasSession: hasSession)));
}

class MyApp extends StatelessWidget {
  final bool hasSession;
  const MyApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TemanStok',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      // Keputusan Landing vs MainScreen dicek sekali di main() lewat baca
      // SharedPreferences langsung (murni buat nentuin fork awal). Tapi itu
      // TIDAK mengisi state sessionProvider (Riverpod) — cuma SessionGate
      // yang manggil loadSession(). Tanpa SessionGate di sini, cold start
      // dengan session valid bakal render MainScreen dengan sessionProvider
      // masih null, dan konsumen yang baca ref.read(sessionProvider) tanpa
      // fallback (stok_screen.dart) bakal salah kira sesi kosong lalu
      // nendang user yang sebenarnya sudah login. SessionGate di sini
      // menutup celah itu dengan cost minimal (satu baca SharedPreferences
      // async, biasanya sub-frame, sebelum MainScreen tampil).
      home: hasSession
          ? const SessionGate(child: MainScreen())
          : const LandingScreen(),
      routes: {
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LandingScreen(),
        '/phone_login': (context) => const PhoneLoginScreen(),
        '/register_otp': (context) => const RegisterOtpScreen(),
        '/setup_profil': (context) => const SetupProfilScreen(),
        // Bagian onboarding — session belum ada sampai submit() di layar
        // ini selesai. TIDAK boleh digate, sama seperti /setup_profil.
        '/input_barang': (context) => const InputBarangScreen(),
        '/main': (context) => const SessionGate(child: MainScreen()),
        '/mic': (context) => const SessionGate(child: MicScreen()),
        '/home': (context) => const SessionGate(child: MainScreen()),
      },
    );
  }
}
