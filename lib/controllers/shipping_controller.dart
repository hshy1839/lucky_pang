// lib/controllers/shipping_controller.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../routes/base_url.dart';

class ShippingController {
  static const _baseUrl = '${BaseUrl.value}:7778';
  static const _storage = FlutterSecureStorage();

  static Future<bool> addShipping({
    required String recipient,
    required String phone,
    required String memo,
    required String postcode,
    required String address,
    required String address2,
    required bool isDefault,
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
          'recipient': recipient,
          'phone': phone,
          'memo': memo,
          'postcode': postcode,
          'address': address,
          'address2': address2,
          'is_default': isDefault,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      print('배송지 등록 실패: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserShippings() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('토큰 없음');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/shipping'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> list = data['shippings'];
        print('서버 응답: $data');
        print('배송지 수: ${data['shippings']?.length}');

        return list.cast<Map<String, dynamic>>();
      } else {
        throw Exception(data['message'] ?? '배송지 조회 실패');
      }
    } catch (e) {
      print('배송지 조회 실패: $e');
      return [];
    }
  }

  // 배송지 수정
  static Future<bool> updateShipping({
    required String shippingId,
    required String recipient,
    required String phone,
    required String memo,
    required String postcode,
    required String address,
    required String address2,
    required bool isDefault,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('토큰 없음');

      final response = await http.put(
        Uri.parse('$_baseUrl/api/shipping/$shippingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipient': recipient,
          'phone': phone,
          'memo': memo,
          'postcode': postcode,
          'address': address,
          'address2': address2,
          'is_default': isDefault,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('배송지 수정 실패: $e');
      return false;
    }
  }

// 배송지 삭제
  static Future<bool> deleteShipping(String shippingId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('토큰 없음');

      print('== 배송지 삭제 요청: $shippingId');
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/shipping/$shippingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('== 응답 status: ${response.statusCode}');
      print('== 응답 body: ${response.body}');

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('배송지 삭제 실패: $e');
      return false;
    }
  }



}
