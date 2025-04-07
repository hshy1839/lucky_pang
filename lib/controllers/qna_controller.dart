import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QnaController {
  final String apiUrl = 'http://172.30.50.104:7776/api/qnaQuestion'; // API 엔드포인트

  // QnA 생성
  Future<bool> createQna(String title, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다.');
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('QnA 등록 실패: ${response.statusCode}');
        print('응답 내용: ${response.body}');
        return false;
      }
    } catch (e) {
      print('QnA 등록 중 오류 발생: $e');
      return false;
    }
  }

  // 토큰을 사용한 QnA 조회
  Future<List<Map<String, dynamic>>> getQnaInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/getinfo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['questions'] is List) {
          return (jsonData['questions'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          return [];
        }
      } else {
        print('QnA 정보 조회 실패: ${response.statusCode}');
        print('응답 내용: ${response.body}');
        return [];
      }
    } catch (e) {
      print('QnA 정보 조회 중 오류 발생: $e');
      return [];
    }
  }

  // 특정 질문에 대한 답변 가져오기
  Future<List<Map<String, dynamic>>> getAnswersByQuestionId(String questionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/getAnswers/$questionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['answers'] is List) {
          return (jsonData['answers'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          return [];
        }
      } else {
        print('답변 정보 조회 실패: ${response.statusCode}');
        print('응답 내용: ${response.body}');
        return [];
      }
    } catch (e) {
      print('답변 정보 조회 중 오류 발생: $e');
      return [];
    }
  }
}
