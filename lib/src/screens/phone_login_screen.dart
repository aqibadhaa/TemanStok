import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../providers/session_provider.dart';
import '../../utils/phone_utils.dart';
import '../services/auth_service.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _otpSent = false;
  String _otpCode = '';

  Timer? _timer;
  int _secondsRemaining = 59;

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _onMasuk() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final storeId = sanitizePhone(_phoneController.text);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          _showSnackBar('Nomor belum terdaftar. Silakan daftar dulu.',
              isError: false, isWarning: true);
        }
        return;
      }

      await _authService.requestOtp(storeId);

      setState(() {
        _otpSent = true;
        _otpCode = '';
      });
      _startTimer();

      if (mounted) {
        _showSnackBar('Kode OTP telah dikirim ke WhatsApp Anda', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      _showSnackBar('Mohon masukkan 6 digit kode OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final storeId = sanitizePhone(_phoneController.text);

    try {
      // Verifikasi ke server. Kalau valid, AuthService juga langsung
      // signInWithCustomToken di baliknya.
      final isValid = await _authService.verifyOtp(storeId, _otpCode);

      if (!isValid) {
        if (mounted) {
          _showSnackBar('Kode OTP salah!', isError: true);
          setState(() => _otpCode = '');
        }
        return;
      }

      await ref.read(sessionProvider.notifier).saveSession(storeId);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onKeyPress(String key) {
    if (_isLoading) return;
    if (key == 'backspace') {
      if (_otpCode.isNotEmpty) {
        setState(() => _otpCode = _otpCode.substring(0, _otpCode.length - 1));
      }
    } else {
      if (_otpCode.length < 6) {
        setState(() => _otpCode += key);
        if (_otpCode.length == 6) {
          _verifyOtp();
        }
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red
            : (isWarning ? Colors.orange.shade700 : Colors.green.shade600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () {
            if (_otpSent) {
              setState(() {
                _otpSent = false;
                _otpCode = '';
              });
              _timer?.cancel();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: _buildStepIndicator(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: _otpSent ? _buildOtpBody() : _buildPhoneInputBody(),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i == 0;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 10 : 8,
          height: isActive ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }

  Widget _buildPhoneInputBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Center(child: _buildHeaderIcon()),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Masuk ke Akun',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Masukkan nomor HP terdaftar untuk mengelola stok warungmu',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Nomor Handphone',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildPhoneInput(),
            const SizedBox(height: 24),
            _buildMasukButton(),
            const SizedBox(height: 28),
            _buildFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBody() {
    final displayPhone = formatDisplayPhone(_phoneController.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Center(child: _buildCheckmarkIcon()),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Verifikasi Masuk',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
              children: [
                const TextSpan(text: 'Kode dikirim ke WA '),
                TextSpan(
                  text: displayPhone,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => _buildOtpBox(index)),
          ),
        ),
        const SizedBox(height: 36),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time_rounded, color: AppTheme.gold, size: 18),
              const SizedBox(width: 6),
              Text(
                'Kirim ulang dalam 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _secondsRemaining == 0 ? _onMasuk : null,
            child: Text(
              'Kirim Ulang Kode',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _secondsRemaining == 0 ? AppTheme.primary : Colors.grey.shade400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildCustomKeypad(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCheckmarkIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFE2F3F4),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary, width: 2.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.check, size: 48, color: AppTheme.primary),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    String char = '';
    if (_otpCode.length > index) char = _otpCode[index];
    final isActive = _otpCode.length == index;

    return Container(
      width: 48,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppTheme.primary : Colors.grey.shade200,
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        char.isNotEmpty ? char : (isActive ? '|' : ''),
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isActive ? AppTheme.primary : AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCustomKeypad() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [_buildKeypadButton('1'), _buildKeypadButton('2'), _buildKeypadButton('3')],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [_buildKeypadButton('4'), _buildKeypadButton('5'), _buildKeypadButton('6')],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [_buildKeypadButton('7'), _buildKeypadButton('8'), _buildKeypadButton('9')],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const SizedBox(width: 80, height: 50),
              _buildKeypadButton('0'),
              _buildKeypadButton('backspace', isIcon: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String value, {bool isIcon = false}) {
    return SizedBox(
      width: 80,
      height: 50,
      child: InkWell(
        onTap: () => _onKeyPress(value),
        borderRadius: BorderRadius.circular(25),
        child: Center(
          child: isIcon
              ? Icon(Icons.backspace_outlined, color: Colors.grey.shade600, size: 22)
              : Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.storefront_rounded, size: 50, color: AppTheme.primary),
          Positioned(
            top: 18,
            right: 18,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇮🇩', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('+62', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
            ],
          ),
        ),
        hintText: '8xx-xxxx-xxxx',
        hintStyle: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Nomor HP tidak boleh kosong';
        if (value.trim().length < 10) return 'Nomor HP minimal 10 digit';
        return null;
      },
    );
  }

  Widget _buildMasukButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onMasuk,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
          elevation: 4,
          shadowColor: AppTheme.primary.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Masuk', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
        children: [
          const TextSpan(text: 'Dengan melanjutkan, kamu menyetujui '),
          TextSpan(text: 'Ketentuan Layanan', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
          const TextSpan(text: ' & '),
          TextSpan(text: 'Kebijakan Privasi', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
          const TextSpan(text: ' kami.'),
        ],
      ),
    );
  }
}
