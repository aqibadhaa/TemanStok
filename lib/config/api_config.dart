import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_exceptions.dart';

class ApiConfig {
  static const String baseUrl =
      'https://unwashed-saloon-occupancy.ngrok-free.dev';

  static const String webhookUrl = '$baseUrl/webhook/warungai/transaksi';
  static const String otpRequestUrl = '$baseUrl/webhook/otp/request';
  static const String otpVerifyUrl = '$baseUrl/webhook/otp/verify';

  static Future<String> getStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getString('store_id');
    if (storeId == null || storeId.isEmpty) {
      throw const SessionExpiredException();
    }
    return storeId;
  }

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };
}
