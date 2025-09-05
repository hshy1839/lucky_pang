import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../routes/base_url.dart';

class NoticeScreenController {
  final _secureStorage = const FlutterSecureStorage();
  final _baseUrl = '${BaseUrl.value}:7778';

  /// presigned/절대 URL이면 그대로,
  /// /uploads/... 옛 로컬 경로면 baseUrl 붙이고,
  /// 그 외(S3 key로 보이면)는 /media/{key} 프록시로 접근
  String _resolveImage(dynamic value) {
    if (value == null) return '';
    final s = value.toString();
    if (s.startsWith('http://') || s.startsWith('https://')) return s; // presigned or absolute
    if (s.startsWith('/uploads/')) return '$_baseUrl$s';               // legacy local path
    return '$_baseUrl/media/$s';                                       // s3 key -> proxy
  }

  List<String> _resolveImageList(dynamic images) {
    if (images is List) {
      return images.map((v) => _resolveImage(v)).toList().cast<String>();
    }
    return const [];
  }

  String _formatDate(String originalDate) {
    try {
      final dt = DateTime.parse(originalDate);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return originalDate;
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotices() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null || token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      final resp = await http.get(
        Uri.parse('$_baseUrl/api/notice'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);

        if (decoded is Map<String, dynamic> && decoded['notices'] is List<dynamic>) {
          final List<dynamic> data = decoded['notices'];

          // 목록에 썸네일이 필요하면 첫 이미지도 함께 매핑
          return data.reversed.map<Map<String, dynamic>>((item) {
            final created = _formatDate(item['created_at']?.toString() ?? '');

            // 백엔드가 presigned 배열을 내려줄 수도 있음
            final imgUrls = (item['noticeImageUrls'] != null)
                ? _resolveImageList(item['noticeImageUrls'])
                : _resolveImageList(item['noticeImage']);

            return {
              'id': item['_id'],
              'title': item['title']?.toString() ?? '',
              'content': item['content']?.toString() ?? '',
              'created_at': created,
              'thumbnail': imgUrls.isNotEmpty ? imgUrls.first : '', // 필요 없으면 제거해도 됨
            };
          }).toList();
        } else {
          throw Exception('응답 데이터 형식이 올바르지 않습니다.');
        }
      } else {
        print('API 호출 실패: ${resp.statusCode}, ${resp.body}');
        return [];
      }
    } catch (error) {
      print('공지사항 조회 중 오류 발생: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchNoticeById(String id) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final resp = await http.get(
        Uri.parse('$_baseUrl/api/notice/$id'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        final notice = decoded['notice'] ?? {};
        final createdAt = _formatDate(notice['created_at']?.toString() ?? '');

        // presigned 우선 → 없으면 key 배열 처리
        final images = (notice['noticeImageUrls'] != null)
            ? _resolveImageList(notice['noticeImageUrls'])
            : _resolveImageList(notice['noticeImage']);

        return {
          'id': notice['_id'],
          'title': notice['title']?.toString() ?? '',
          'content': notice['content']?.toString() ?? '',
          'created_at': createdAt,
          'images': images,
        };
      } else {
        print('상세 공지 조회 실패: ${resp.statusCode}');
        return null;
      }
    } catch (e) {
      print('공지사항 상세 조회 오류: $e');
      return null;
    }
  }
}
