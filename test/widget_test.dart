import 'package:flutter_test/flutter_test.dart';
import 'package:cgw_hacktathon/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Kita masukkan storeId: null karena kita ingin mengetes layar login
    await tester.pumpWidget(const MyApp(storeId: null));

    // Cek apakah teks 'TemanStok' ada di layar
    expect(find.text('TemanStok'), findsOneWidget);
    
    // Cek apakah ada input untuk Nomor HP
    expect(find.text('Nomor HP'), findsOneWidget);
  });
}
