// lib/controllers/shipping_controller.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ShippingController {
  static const _baseUrl = 'http://192.168.219.107:7778';
  static const _storage = FlutterSecureStorage();

  static Future<bool> addShipping({
    required String postcode,
    required String address,
    required String address2,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('토큰 없음');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/shipping'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'postcode': postcode,
          'address': address,
          'address2': address2,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      print('배송지 등록 실패: $e');
      return false;
    }
  }

}
