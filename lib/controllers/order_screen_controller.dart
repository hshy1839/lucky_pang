import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderScreenController {
  // 서버 주소
  static const String orderApiUrl = 'http://172.30.1.42:7778/api/order';
  static const String shippingApiUrl = 'http://172.30.1.42:7778/api/shipping';
  static const String shippingInfoApiUrl = 'http://172.30.1.42:7778/api/shippinginfo';

  // 주문 추가 함수
  static Future<http.Response> addToOrder({
    required List<Map<String, dynamic>> account,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String address, // address 파라미터 추가
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? ''; // 저장된 토큰 불러오기

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }
      final response = await http.post(
        Uri.parse(orderApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'account': account,
          'items': items,
          'totalAmount': totalAmount,
          'address': address, // address 데이터 포함
        }),
      );

      return response;
    } catch (e) {
      throw Exception('Failed to add order: $e');
    }
  }

  // 배송 추가 함수
  static Future<http.Response> addToShipping({
    required String name,
    required String phone,
    required String address,
    required String address2,
    required String postalCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? ''; // 저장된 토큰 불러오기

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }
      final response = await http.post(
        Uri.parse(shippingApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'shippingAddress': {
            'name': name,
            'phone': phone,
            'address': address,
            'address2': address2,
            'postalCode': postalCode,
          },
        }),
      );

      return response;
    } catch (e) {
      throw Exception('Failed to add shipping: $e');
    }
  }

  // controllers/order_screen_controller.dart
  static Future<http.Response> verifyCoupon(String code) async {
    final url = Uri.parse('http://172.30.1.42:7778/api/verifyCoupon?code=$code');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? ''; // 토큰 불러오기

    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // 서버에서 인증을 요구한다면 토큰 추가
      },
    );
  }



  // 배송 정보 가져오기 함수
  static Future<Map<String, dynamic>> getShipping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? ''; // 저장된 토큰 불러오기

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      final response = await http.get(
        Uri.parse(shippingInfoApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // JSON 데이터를 파싱하여 반환
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch shipping info: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get shipping: $e');
    }
  }

  // 토큰 가져오기 (SharedPreferences 활용)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
