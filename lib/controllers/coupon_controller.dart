import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../routes/base_url.dart';

class CouponController {
  String? couponMessage;

  // BuildContext 파라미터 제거!
  Future<Map<String, dynamic>> useCoupon(String code) async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': '로그인 필요'};
    }
    try {
      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/coupon/use'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'code': code}),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? (response.statusCode == 200 ? '쿠폰 사용 성공' : '쿠폰 사용 실패')
      };
    } catch (e, stack) {
      print('쿠폰 useCoupon 통신 오류: $e\n$stack');
      return {'success': false, 'message': '서버 통신 오류: $e'};
    }
  }

  // 메시지 초기화 (필요 시)
  void clearMessage() {
    couponMessage = null;
  }

  // 토큰 가져오는 로직은 구현 필요!
  Future<String?> getToken() async {
    final storage = FlutterSecureStorage();
    // 너가 저장한 키 이름에 따라 아래 키 이름 수정 (보통 'token' 또는 'accessToken')
    return await storage.read(key: 'token');
  }
}
