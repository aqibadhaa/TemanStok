/// Utility normalisasi nomor telepon Indonesia.
/// Diekstrak dari empat lokasi berbeda (auth_service, register_otp_screen,
/// phone_login_screen, onboarding_provider) yang sebelumnya punya
/// implementasi identik secara terpisah — lihat temuan M-5 pada code review.
library;

String sanitizePhone(String phone) {
  phone = phone.trim().replaceAll('+', '').replaceAll('-', '').replaceAll(' ', '');
  if (phone.startsWith('0')) {
    phone = '62${phone.substring(1)}';
  } else if (!phone.startsWith('62')) {
    phone = '62$phone';
  }
  return phone;
}

String formatDisplayPhone(String phone) {
  final sanitized = sanitizePhone(phone);
  if (sanitized.startsWith('62') && sanitized.length > 2) {
    const code = '+62';
    final mainNumber = sanitized.substring(2);
    if (mainNumber.length > 3) {
      final part1 = mainNumber.substring(0, 3);
      final part2 = mainNumber.substring(3);
      return '$code $part1-$part2';
    }
    return '$code $mainNumber';
  }
  return phone;
}
