import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/secrets.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Mengambil API Key dari file terpisah yang di-ignore oleh Git
  final String _waApiKey = AppSecrets.waApiKey; 

  // Simpan status login ke SharedPreferences
  Future<void> _setLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  // Cek apakah user sudah login sebelumnya
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // 0. Cek apakah nomor sudah terdaftar di Firestore
  Future<bool> isPhoneRegistered(String phone) async {
    final query = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userStream => _auth.authStateChanges();

  // 1. Kirim OTP via WhatsApp
  Future<String> sendWhatsAppOtp(String phoneNumber) async {
    // Generate 6 digit random code
    String otpCode = (Random().nextInt(900000) + 100000).toString();

    // Pastikan nomor berformat 62...
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.fonnte.com/send'),
        headers: {'Authorization': _waApiKey},
        body: {
          'target': formattedPhone,
          'message':
              'Kode OTP Registrasi Anda adalah: $otpCode. JANGAN BERIKAN KODE INI KEPADA SIAPAPUN.',
          'countryCode': '62',
        },
      );

      if (response.statusCode == 200) {
        return otpCode; // Kita return kodenya untuk diverifikasi di aplikasi
      } else {
        throw Exception('Gagal mengirim WhatsApp: ${response.body}');
      }
    } catch (e) {
      throw Exception('Kesalahan Koneksi: $e');
    }
  }

  // 2. Selesaikan Registrasi (Setelah OTP WA Benar)
  Future<void> completeRegistration({
    required String name,
    required String phone,
    required String password,
  }) async {
    String email = "${phone.replaceAll(RegExp(r'[^0-9]'), '')}@app.com";

    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Simpan data ke Firestore
    await _db.collection('users').doc(userCredential.user!.uid).set({
      'name': name,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
      'isVerified': true,
    });

    // Simpan status login
    await _setLoginStatus(true);
  }

  // 3. Login dengan Password
  Future<UserCredential> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    String internalEmail = "$cleanPhone@app.com";

    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: internalEmail,
      password: password,
    );

    // Simpan status login
    await _setLoginStatus(true);
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // Hapus status login
    await _setLoginStatus(false);
  }
}
