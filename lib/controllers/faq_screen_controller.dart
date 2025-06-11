import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../routes/base_url.dart';

class FaqScreenController {
  final _secureStorage = const FlutterSecureStorage();
  final _baseUrl = '${BaseUrl.value}:7778';

  Future<List<Map<String, dynamic>>> fetchFaq() async {
    try {
      final token = await _secureStorage.read(key: 'token'); // SecureStorage에서 토큰 불러오기

      if (token == null || token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/faq'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse is Map<String, dynamic> && decodedResponse['faqs'] is List<dynamic>) {
          final List<dynamic> data = decodedResponse['faqs'];

          return data.reversed.map<Map<String, dynamic>>((item) {

            return {
              'id': item['_id'],
              'category': item['category']?.toString() ?? '',
              'question': item['question']?.toString() ?? '',
              'answer': item['answer']?.toString() ?? '',
            };
          }).toList();
        } else {
          throw Exception('응답 데이터 형식이 올바르지 않습니다.');
        }
      } else {
        print('API 호출 실패: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (error) {
      print('FAQ 조회 중 오류 발생: $error');
      return [];
    }
  }


}
