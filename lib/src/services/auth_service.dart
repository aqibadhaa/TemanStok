import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userStream => _auth.authStateChanges();

  /// Minta OTP dikirim ke nomor WhatsApp [phone] (format tersanitasi, 62...).
  /// Kode OTP digenerate dan disimpan sepenuhnya di server (n8n +
  /// koleksi Firestore otp_verifications) — method ini tidak pernah
  /// menerima nilai OTP itu sendiri.
  Future<void> requestOtp(String phone) async {
    http.Response response;
    try {
      response = await http.post(
        Uri.parse(ApiConfig.otpRequestUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({'phone': phone}),
      );
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }

    if (response.statusCode != 200) {
      throw Exception('Gagal mengirim OTP (${response.statusCode})');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Respons server tidak valid');
    }

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal mengirim OTP');
    }
  }

  /// Verifikasi [otp] untuk [phone] lewat server. Mengembalikan true hanya
  /// jika n8n mengonfirmasi kode valid. Kalau valid, method ini juga
  /// langsung menukar custom token dari n8n jadi sesi Firebase Auth
  /// (signInWithCustomToken) — uid hasilnya sama dengan [phone] tersanitasi,
  /// karena itu yang dipakai n8n saat mint token. Client tidak pernah
  /// menyimpan atau membandingkan kode OTP asli secara lokal.
  Future<bool> verifyOtp(String phone, String otp) async {
    http.Response response;
    try {
      response = await http.post(
        Uri.parse(ApiConfig.otpVerifyUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }

    if (response.statusCode != 200) {
      throw Exception('Gagal verifikasi OTP (${response.statusCode})');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Respons server tidak valid');
    }

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Verifikasi gagal');
    }

    if (data['valid'] != true) {
      return false;
    }

    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      // Server bilang valid tapi gak ngasih token — jangan lanjut buat
      // sesi. Kondisi ini seharusnya gak pernah kejadian kalau n8n sesuai
      // kontrak (lihat catatan Track A: otp/verify wajib sertakan token
      // begitu valid:true).
      throw Exception('Verifikasi tidak lengkap, coba lagi');
    }

    try {
      await _auth.signInWithCustomToken(token);
    } on FirebaseAuthException catch (e) {
      throw Exception('Gagal membuat sesi: ${e.message}');
    }

    return true;
  }
}
