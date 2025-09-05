import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../routes/base_url.dart';

class EventScreenController {
  final _secureStorage = const FlutterSecureStorage();
  final _baseUrl = '${BaseUrl.value}:7778';

  // presigned/절대 URL -> 그대로
  // /uploads/... -> baseUrl 붙이기
  // 그 외(S3 key로 간주) -> /media/{key}
  String _resolveImage(dynamic value) {
    if (value == null) return '';
    final s = value.toString();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/uploads/')) return '$_baseUrl$s';
    return '$_baseUrl/media/$s';
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

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null || token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      final resp = await http.get(
        Uri.parse('$_baseUrl/api/promotion/read'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);

        if (decoded is Map<String, dynamic> &&
            decoded['promotions'] is List<dynamic>) {
          final List<dynamic> data = decoded['promotions'];

          return data.reversed.map<Map<String, dynamic>>((item) {
            final created = _formatDate(item['createdAt']?.toString() ?? '');

            // 메인 이미지: 프리사인 필드 우선 → 없으면 키/레거시 처리
            // 백엔드 컨트롤러에서 promotionImage(키 배열), promotionImageUrls(프리사인 배열) 구조를 가정
            final mainImageUrl = (() {
              if (item['promotionImageUrls'] != null &&
                  item['promotionImageUrls'] is List &&
                  (item['promotionImageUrls'] as List).isNotEmpty) {
                return _resolveImage(item['promotionImageUrls'][0]);
              }
              // 과거 데이터: promotionImage가 키 배열/경로 배열
              if (item['promotionImage'] is List && item['promotionImage'].isNotEmpty) {
                return _resolveImage(item['promotionImage'][0]);
              }
              if (item['promotionImage'] is String) {
                return _resolveImage(item['promotionImage']);
              }
              return '';
            })();

            return {
              'id': item['_id'],
              'name': item['name']?.toString() ?? '',
              'title': item['title']?.toString() ?? '',
              'content': item['content']?.toString() ?? '',
              'created_at': created,
              'mainImage': mainImageUrl,
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
      print('프로모션 목록 조회 중 오류 발생: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchEventById(String id) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final resp = await http.get(
        Uri.parse('$_baseUrl/api/promotion/read/$id'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        final promo = decoded['promotion'] ?? {};
        final createdAt = _formatDate(promo['createdAt']?.toString() ?? '');

        // 상세 이미지: 프리사인 우선 → 없으면 키/레거시 처리
        // 백엔드 컨트롤러에서 promotionDetailImage(키 배열), promotionDetailImageUrls(프리사인 배열) 구조를 가정
        final images = (promo['promotionDetailImageUrls'] != null)
            ? _resolveImageList(promo['promotionDetailImageUrls'])
            : _resolveImageList(promo['promotionDetailImage']);

        return {
          'id': promo['_id'],
          'name': promo['name']?.toString() ?? '',
          'title': promo['title']?.toString() ?? '',
          'content': promo['content']?.toString() ?? '',
          'created_at': createdAt,
          'images': images,
        };
      } else {
        print('상세 프로모션 조회 실패: ${resp.statusCode}');
        return null;
      }
    } catch (e) {
      print('프로모션 상세 조회 오류: $e');
      return null;
    }
  }
}
