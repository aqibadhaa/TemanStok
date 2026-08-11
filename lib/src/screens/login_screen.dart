import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/onboarding_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _sanitizePhone(String phone) {
    phone = phone.trim()
        .replaceAll('+', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62')) {
      phone = '62$phone';
    }
    return phone;
  }

  Future<void> _onMasuk() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final storeId = _sanitizePhone(_phoneController.text);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      if (doc.exists) {
        // Nomor terdaftar → simpan session → home
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('store_id', storeId);
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        // Nomor belum terdaftar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nomor belum terdaftar. Silakan daftar dulu.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onDaftarBaru() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final storeId = _sanitizePhone(_phoneController.text);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      if (doc.exists) {
        // Nomor sudah terdaftar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nomor sudah terdaftar. Silakan masuk.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Nomor baru → lanjut onboarding
        ref.read(onboardingProvider.notifier)
            .updatePhoneNumber(_phoneController.text.trim());
        if (mounted) {
          Navigator.pushNamed(context, '/setup_profil');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE2EFF9), // light icy blue
            Color(0xFF86A8C9), // soft medium blue
            Color(0xFF1E3A64), // deep blue
            Color(0xFF0D1E36), // darker deep blue
          ],
          stops: [0.0, 0.45, 0.85, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon Logo Container
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B305B),
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.home_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    
                    // Title "TemanStok"
                    Text(
                      'TemanStok',
                      style: GoogleFonts.prata(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    const Text(
                      'Teman pintar kelola stok warungmu.\nCukup bicara, beres.',
                      style: TextStyle(
                        fontSize: 16, 
                        color: Color(0xFFE2EFF9),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    
                    // TextFormField with Glassmorphism Look
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.12),
                        labelText: 'Nomor HP',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        hintText: 'Contoh: 08123456789',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.phone, color: Colors.white70),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        errorStyle: const TextStyle(color: Color(0xFFFF9E9E)),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Color(0xFFFF9E9E)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Color(0xFFFF9E9E), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nomor HP tidak boleh kosong';
                        }
                        if (value.trim().length < 10) {
                          return 'Nomor HP minimal 10 digit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Tombol Masuk (Primary)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _onMasuk,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1B305B),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    
                    // Tombol Daftar Baru (Secondary)
                    OutlinedButton(
                      onPressed: _isLoading ? null : _onDaftarBaru,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Daftar Baru',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}