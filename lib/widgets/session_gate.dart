import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';

/// Guard untuk rute yang butuh sesi warung aktif: /main, /home, /mic.
/// Kalau session kosong, redirect ke /phone_login alih-alih membiarkan
/// screen di baliknya nampilin data kosong atau melempar
/// SessionExpiredException tanpa penjelasan.
///
/// JANGAN pakai widget ini buat wrap alur onboarding (/register_otp,
/// /setup_profil, /input_barang) — session belum sengaja disimpan sampai
/// OnboardingNotifier.submit() selesai di ujung alur itu, jadi guard ini
/// bakal salah nendang user yang baru selesai verifikasi OTP balik ke
/// login sebelum sempat isi profil toko.
///
/// CATATAN: guard ini murni UX (mencegah screen kosong/crash), BUKAN
/// kontrol keamanan — itu tetap tanggung jawab Firestore rules (lihat
/// firestore.rules) begitu Track A (mint custom token di n8n) live.
class SessionGate extends ConsumerStatefulWidget {
  final Widget child;
  const SessionGate({super.key, required this.child});

  @override
  ConsumerState<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<SessionGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await ref.read(sessionProvider.notifier).loadSession();
    final storeId = ref.read(sessionProvider);

    final hasSession = storeId != null && storeId.isNotEmpty;

    if (!mounted) return;

    if (!hasSession) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/phone_login', (route) => false);
      return;
    }

    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}
