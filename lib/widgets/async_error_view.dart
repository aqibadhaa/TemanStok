import 'package:flutter/material.dart';
import '../utils/app_exceptions.dart';

/// Widget error generik untuk dipakai di branch `error:` pada `.when(...)`
/// AsyncValue di seluruh app. Membedakan [SessionExpiredException] (tampil
/// tombol "Masuk Kembali" yang redirect ke /phone_login) dari error lain
/// seperti network/Firestore (tampil pesan + tombol "Coba Lagi" lewat
/// [onRetry], biasanya `() => ref.invalidate(provider)`).
///
/// Set [compact] true untuk konteks sempit (kartu kecil, badge) — versi ini
/// gak nampilin ikon/tombol, cuma teks pendek, supaya gak ngerusak layout.
class AsyncErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  const AsyncErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  bool get _isSessionExpired => error is SessionExpiredException;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;

    if (compact) {
      return Text(
        _isSessionExpired ? 'Sesi habis' : 'Gagal memuat',
        style: TextStyle(color: color, fontSize: 12),
      );
    }

    if (_isSessionExpired) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              'Sesi habis, silakan masuk kembali',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil('/phone_login', (route) => false),
              child: const Text('Masuk Kembali'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            'Gagal memuat data',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ],
      ),
    );
  }
}
