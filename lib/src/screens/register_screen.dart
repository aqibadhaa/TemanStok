import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _otpSent = false;
  String? _generatedOtp;

  // Step 1: Kirim OTP via WhatsApp
  Future<void> _sendWhatsApp() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar('Mohon isi semua data');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Cek dulu apakah nomor sudah terdaftar
      bool isRegistered = await _authService.isPhoneRegistered(
        _phoneController.text,
      );
      if (isRegistered) {
        _showSnackBar('Nomor ini sudah terdaftar. Silakan login.');
        setState(() => _isLoading = false);
        return;
      }

      // 2. Jika belum, baru kirim OTP
      String code = await _authService.sendWhatsAppOtp(_phoneController.text);
      setState(() {
        _generatedOtp = code;
        _otpSent = true;
      });
      _showSnackBar('Kode OTP telah dikirim ke WhatsApp Anda', isError: false);
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Step 2: Verifikasi Kode & Simpan ke Firebase
  Future<void> _verifyAndRegister() async {
    if (_otpController.text != _generatedOtp) {
      _showSnackBar('Kode OTP salah!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.completeRegistration(
        name: _nameController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/setup_profil');
      }
    } catch (e) {
      _showSnackBar('Gagal Registrasi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi via WhatsApp')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              if (!_otpSent) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp (08xxx)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Buat Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ] else ...[
                const Text(
                  'Masukkan 6 digit kode yang dikirim ke WhatsApp Anda',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Kode OTP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _otpSent ? _verifyAndRegister : _sendWhatsApp,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        _otpSent
                            ? 'Verifikasi & Daftar'
                            : 'Kirim Kode via WhatsApp',
                      ),
                    ),
              if (_otpSent)
                TextButton(
                  onPressed: () => setState(() => _otpSent = false),
                  child: const Text('Ganti Nomor/Data'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
