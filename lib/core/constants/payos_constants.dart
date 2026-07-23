import 'package:flutter_dotenv/flutter_dotenv.dart';

class PayOSConstants {
  static String get clientId => dotenv.env['PAYOS_CLIENT_ID'] ?? '';
  static String get apiKey => dotenv.env['PAYOS_API_KEY'] ?? '';
  static String get checksumKey => dotenv.env['PAYOS_CHECKSUM_KEY'] ?? '';

  // Cấu hình URL callback (Bạn có thể sửa theo ý muốn)
  static const String returnUrl = 'https://your-app.com/payment-success';
  static const String cancelUrl = 'https://your-app.com/payment-cancel';
  
  static const String apiUrl = 'https://api-merchant.payos.vn/v2/payment-requests';
}
