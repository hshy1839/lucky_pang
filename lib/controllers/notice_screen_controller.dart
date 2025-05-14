import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../routes/base_url.dart';

class NoticeScreenController {
  final _secureStorage = const FlutterSecureStorage();
  final _baseUrl = '${BaseUrl.value}:7778';

  Future<List<Map<String, dynamic>>> fetchNotices() async {
    try {
      final token = await _secureStorage.read(key: 'token'); // SecureStorage에서 토큰 불러오기

      if (token == null || token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/notice'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse is Map<String, dynamic> && decodedResponse['notices'] is List<dynamic>) {
          final List<dynamic> data = decodedResponse['notices'];

          return data.reversed.map<Map<String, dynamic>>((item) {
            final originalDate = item['created_at']?.toString() ?? '';
            final formattedDate = _formatDate(originalDate);

            return {
              'id': item['_id'],
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

  String _getImageUrl(dynamic image) {
    if (image is List && image.isNotEmpty) {
      return '$_baseUrl${image[0]}';
    } else if (image is String) {
      return '$_baseUrl$image';
    }
    return '';
  }

  List<String> _getImageList(dynamic images) {
    if (images is List) {
      return images.map((img) => '$_baseUrl$img').toList().cast<String>();
    }
    return [];
  }

  String _formatDate(String originalDate) {
    try {
      final dateTime = DateTime.parse(originalDate);
      return DateFormat('yyyy-MM-dd').format(dateTime);
    } catch (e) {
      return originalDate;
    }
  }

  Future<Map<String, dynamic>?> fetchNoticeById(String id) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/notice/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final notice = decoded['notice'];
        final createdAt = _formatDate(notice['created_at']?.toString() ?? '');



        return {
          'id': notice['_id'],
          'title': notice['title'],
          'content': notice['content'],
          'created_at': createdAt,
          'images': _getImageList(notice['noticeImage']),
        };
      } else {
        print('상세 공지 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('공지사항 상세 조회 오류: $e');
      return null;
    }
  }

}

