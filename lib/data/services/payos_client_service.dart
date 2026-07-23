import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/payos_constants.dart';

class PayOSClientService {
  /// Hàm tạo chữ ký (Signature) theo chuẩn PayOS
  /// Lưu ý: Việc tạo chữ ký dưới Client (Flutter) là KHÔNG BẢO MẬT.
  /// Chỉ dùng cho mục đích học tập/demo.
  String _generateSignature(Map<String, dynamic> data, String checksumKey) {
    // 1. Sắp xếp các key theo thứ tự bảng chữ cái
    var sortedKeys = data.keys.toList()..sort();
    
    // 2. Nối thành chuỗi key=value&key=value
    var queryString = sortedKeys.map((key) => '$key=${data[key]}').join('&');
    
    // 3. HmacSHA256 với Checksum Key
    var key = utf8.encode(checksumKey);
    var bytes = utf8.encode(queryString);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    
    return digest.toString();
  }

  Future<String> createPaymentLink({
    required int orderCode,
    required double amount,
    required String description,
  }) async {
    final intAmount = amount.toInt();
    
    // Dữ liệu cần thiết để tạo chữ ký
    final dataToSign = {
      'amount': intAmount,
      'cancelUrl': PayOSConstants.cancelUrl,
      'description': description,
      'orderCode': orderCode,
      'returnUrl': PayOSConstants.returnUrl,
    };

    final signature = _generateSignature(dataToSign, PayOSConstants.checksumKey);

    // Body đầy đủ gửi lên PayOS
    final body = {
      ...dataToSign,
      'signature': signature,
    };

    final response = await http.post(
      Uri.parse(PayOSConstants.apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-client-id': PayOSConstants.clientId,
        'x-api-key': PayOSConstants.apiKey,
      },
      body: jsonEncode(body),
    );

    debugPrint('PayOS Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['code'] == '00') {
        return jsonData['data']['checkoutUrl'];
      } else {
        throw Exception('PayOS Error: ${jsonData['desc']}');
      }
    } else {
      throw Exception('Failed to connect to PayOS API: ${response.body}');
    }
  }

  /// Hàm kiểm tra trạng thái đơn hàng (Polling)
  Future<String> getPaymentStatus(int orderCode) async {
    try {
      final response = await http.get(
        Uri.parse('${PayOSConstants.apiUrl}/$orderCode'),
        headers: {
          'x-client-id': PayOSConstants.clientId,
          'x-api-key': PayOSConstants.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['data']['status']; // Ví dụ: 'PAID', 'PENDING', 'CANCELLED'
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    }
    return 'UNKNOWN';
  }
}
