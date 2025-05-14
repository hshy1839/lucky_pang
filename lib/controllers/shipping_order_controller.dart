import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../routes/base_url.dart';

class ShippingOrderController {
  static const _baseUrl = '${BaseUrl.value}:7778';
  static const _storage = FlutterSecureStorage();

  /// 배송 주문 생성
  static Future<bool> createShippingOrder({
    required String productId,
    required String shippingId,
    required String orderId,
    required String paymentType,
    required int shippingFee,
    required int pointUsed,
    required int paymentAmount,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('토큰 없음');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/shipping-orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product': productId,
          'shipping': shippingId,
          'orderId': orderId,
          'paymentType': paymentType,
          'shippingFee': shippingFee,
          'pointUsed': pointUsed,
          'paymentAmount': paymentAmount,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      print('배송 주문 생성 오류: $e');
      return false;
    }
  }

  /// 유저의 배송 주문 조회
  static Future<List<Map<String, dynamic>>> getUserShippingOrders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/shipping-orders?userId=$userId'),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> list = data['orders'];
        return list.cast<Map<String, dynamic>>();
      } else {
        throw Exception(data['message'] ?? '배송 주문 조회 실패');
      }
    } catch (e) {
      print('배송 주문 조회 오류: $e');
      return [];
    }
  }

  /// 배송 주문 환불 요청
  static Future<bool> refundShippingOrder({
    required String orderId,
    required int refundRate,
    String? description,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('토큰 없음');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/shipping-orders/$orderId/refund'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'refundRate': refundRate,
          if (description != null) 'description': description,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('배송 주문 환불 오류: $e');
      return false;
    }
  }
}