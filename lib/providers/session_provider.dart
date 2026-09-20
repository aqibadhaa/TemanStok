// lib/providers/session_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionNotifier extends StateNotifier<String?> {
  SessionNotifier() : super(null);

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('store_id');
  }

  Future<void> saveSession(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_id', storeId);
    state = storeId;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('store_id');
    // Cabut juga sesi Firebase Auth (dibuat lewat signInWithCustomToken
    // pasca-OTP) — tanpa ini, token yang mengikat identitas tetap hidup
    // di device meski SharedPreferences sudah dibersihkan.
    await FirebaseAuth.instance.signOut();
    state = null;
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, String?>((ref) {
  return SessionNotifier();
});
