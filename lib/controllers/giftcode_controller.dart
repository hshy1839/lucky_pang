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
    String? productId, // ✅ productId 추가
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
        if (productId != null) 'productId': productId, // ✅ 추가됨
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
    String? productId,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      final fromUser = await _storage.read(key: 'userId'); // ✅ 사용자 본인 ID 사용

      if (token == null || fromUser == null) return false;

      final queryParams = {
        'type': type,
        'fromUser': fromUser, // ✅ 현재 로그인한 사용자 기준으로
        if (boxId != null) 'boxId': boxId,
        if (orderId != null) 'orderId': orderId,
        if (productId != null) 'productId': productId,
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



  /// 선물 코드 입력 및 수령 처리
  static Future<Map<String, dynamic>> claimGiftCode(String code) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        print('❌ 토큰 없음');
        return {
          'success': false,
          'message': '로그인이 필요합니다.',
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/giftcode/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      final data = json.decode(response.body);
      print('🎁 선물 코드 입력 응답: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'giftType': data['giftType'],
          'message': data['message'] ?? '선물이 등록되었습니다.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '선물 등록 실패',
        };
      }
    } catch (e) {
      print('❌ 선물 코드 입력 오류: $e');
      return {
        'success': false,
        'message': '네트워크 오류 또는 서버 오류 발생',
      };
    }
  }


}
