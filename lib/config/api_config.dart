import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String webhookUrl =
      'https://unwashed-saloon-occupancy.ngrok-free.dev/webhook/warungai/transaksi';

  // Hapus storeId static, ganti dengan getter async
  static Future<String> getStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('store_id') ?? 'warung_test_001';
  }

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };
}