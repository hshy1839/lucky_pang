import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class GiftCodeController {
  static const _baseUrl = 'http://172.30.1.22:7778'; // 🛠️ 서버 주소에 맞게 수정
  static final _storage = FlutterSecureStorage();

  /// 선물코드 생성 (박스 또는 상품)
  static Future<Map<String, dynamic>?> createGiftCode({
    required String type, // 'box' 또는 'product'
    String? boxId,
    String? orderId,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        print('❌ 토큰 없음');
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
        };
      }

      final body = {
        'type': type,
        if (boxId != null) 'boxId': boxId,
        if (orderId != null) 'orderId': orderId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/giftcode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = json.decode(response.body);
      print('🌐 응답 바디: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ 선물 코드 수신 완료: $data');
        return {
          'success': true,
          'code': data['code'],
          'giftId': data['giftId'],
        };
      } else {
        print('❌ 선물 코드 생성 실패: ${response.statusCode} ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? '알 수 없는 오류가 발생했습니다.',
        };
      }
    } catch (e) {
      print('❌ 선물 코드 생성 오류: $e');
      return {
        'success': false,
        'message': '네트워크 오류 또는 서버 오류 발생',
      };
    }
  }

  static Future<bool> checkGiftCodeExists({
    required String type,
    String? boxId,
    String? orderId,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return false;

      final queryParams = {
        'type': type,
        if (boxId != null) 'boxId': boxId,
        if (orderId != null) 'orderId': orderId,
      };

      final uri = Uri.parse('$_baseUrl/api/giftcode').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      final data = json.decode(response.body);
      return response.statusCode == 200 && data['exists'] == true;
    } catch (e) {
      print('❌ 선물 코드 확인 오류: $e');
      return false;
    }
  }

}
