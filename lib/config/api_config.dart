import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String webhookUrl =
      'https://n8n-mbpw.srv1978072.hstgr.cloud/webhook/warungai/transaksi';

  static Future<String> getStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('store_id') ?? 'warung_test_001';
  }

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
}