  import 'dart:convert';
  import 'package:http/http.dart' as http;

  import '../routes/base_url.dart';

  class TermController {
    static const String baseUrl = '${BaseUrl.value}:7778/api/terms';

    // 카테고리별 약관 불러오기
    static Future<String?> getTermByCategory(String category) async {
      try {
        final response = await http.get(Uri.parse('$baseUrl/$category'));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['term'] != null) {
            return data['term']['content'];
          } else {
            return null;
          }
        } else {
          print('📛 서버 응답 오류: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        print('📛 약관 조회 실패: $e');
        return null;
      }
    }
  }
