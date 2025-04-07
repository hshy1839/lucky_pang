import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../footer.dart';
import '../../header.dart';

// NoticeScreenController
class NoticeScreenController {
  Future<List<Map<String, String>>> fetchNotices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? ''; // 저장된 토큰 불러오기

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      final response = await http.get(
        Uri.parse('http://172.30.50.104:7776/api/users/noticeList/find'),
        headers: {
          'Authorization': 'Bearer $token', // Bearer 토큰 추가
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse is Map<String, dynamic> && decodedResponse['notices'] is List<dynamic>) {
          final List<dynamic> data = decodedResponse['notices'];
          return data.reversed.map((item) {
            final originalDate = item['created_at']?.toString() ?? '';
            final formattedDate = _formatDate(originalDate);
            return {
              'title': item['title']?.toString() ?? '',
              'content': item['content']?.toString() ?? '',
              'created_at': formattedDate,
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
      print('공지사항 조회 중 오류 발생: $error');
      return [];
    }
  }

  // 날짜 포맷 함수
  String _formatDate(String originalDate) {
    try {
      final dateTime = DateTime.parse(originalDate);
      return DateFormat('yyyy년 MM월 dd일').format(dateTime); // 원하는 형식으로 포맷팅
    } catch (e) {
      return originalDate; // 날짜 형식이 잘못된 경우 원본 반환
    }
  }
}