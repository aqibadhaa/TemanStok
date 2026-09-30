import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _n8nBase =
      'https://n8n-mbpw.srv1978072.hstgr.cloud/webhook/warungai';

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String sanitizePhone(String phone) {
    phone = phone.trim().replaceAll('+', '').replaceAll('-', '').replaceAll(' ', '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62')) {
      phone = '62$phone';
    }
    return phone;
  }

  Future<void> _saveSession(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_id', storeId);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('store_id');
  }

  Future<String?> getSessionStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('store_id');
  }

  // ─── Cek nomor sudah terdaftar ──────────────────────────────────────────────

  Future<bool> isPhoneRegistered(String phone) async {
    final storeId = sanitizePhone(phone);
    final doc = await _db.collection('stores').doc(storeId).get();
    return doc.exists;
  }

  // ─── Kirim OTP via n8n → Fonnte → WhatsApp ──────────────────────────────────
  // mode: 'register' | 'login'

  Future<void> sendOtp(String phone, {String mode = 'register'}) async {
    final storeId = sanitizePhone(phone);

    final response = await http.post(
      Uri.parse('$_n8nBase/otp-send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': storeId,
        'mode': mode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengirim OTP: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal mengirim OTP');
    }
  }

  // ─── Verifikasi OTP via n8n ──────────────────────────────────────────────────

  Future<bool> verifyOtp(String phone, String otpCode) async {
    final storeId = sanitizePhone(phone);

    final response = await http.post(
      Uri.parse('$_n8nBase/otp-verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': storeId,
        'otp': otpCode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal verifikasi OTP: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  // ─── Selesaikan login — simpan session ──────────────────────────────────────

  Future<void> completeLogin(String phone) async {
    final storeId = sanitizePhone(phone);
    await _saveSession(storeId);
  }

  // ─── Logout ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await clearSession();
  }
}