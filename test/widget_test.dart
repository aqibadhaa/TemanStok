import 'package:flutter_test/flutter_test.dart';
import 'package:temanstok/main.dart';

void main() {
  testWidgets('Landing screen smoke test', (WidgetTester tester) async {
    // hasSession: false karena kita ingin mengetes layar landing (belum login).
    await tester.pumpWidget(const MyApp(hasSession: false));

    // LandingScreen menampilkan logo SVG (bukan teks 'TemanStok') dan dua
    // tombol CTA. Assertion lama ('TemanStok', 'Nomor HP') salah sasaran —
    // 'Nomor HP' baru muncul di PhoneLoginScreen setelah tombol kedua
    // ditekan, bukan di layar pertama. Lihat temuan M-2 di code review.
    expect(find.text('Mulai Sekarang'), findsOneWidget);
    expect(find.text('Sudah punya akun'), findsOneWidget);
  });
}
