import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../routes/base_url.dart';

class MainScreenController extends ChangeNotifier {
  int selectedIndex = 0;
  List<String> titles = [];
  List<String> contents = [];
  List<String> authorNames = [];
  List<String> createdAts = [];
  List<String> promotionImages = [];

  final FlutterSecureStorage storage = FlutterSecureStorage(); // ✅ SecureStorage 선언

  void onTabTapped(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  Future<void> getNotices() async {
    final token = await storage.read(key: 'token'); // ✅ SecureStorage에서 토큰 읽기


    final url = '${BaseUrl.value}:7778/api/users/noticeList/find';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      notifyListeners();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> notices = data['notices'];

        titles.clear();
        contents.clear();
        authorNames.clear();
        createdAts.clear();

        if (notices.isNotEmpty) {
          for (var notice in notices) {
            titles.add(notice['title'] ?? '');
            contents.add(notice['content'] ?? '');
            authorNames.add(notice['authorName'] ?? '');
            createdAts.add(notice['created_at'] ?? '');
          }
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getPromotions() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      final baseUrl = '${BaseUrl.value}:7778';

      // presigned/절대 URL -> 그대로
      // /uploads/... -> baseUrl 붙이기
      // 그 외(S3 key로 간주) -> /media/{key}
      String _resolveImage(dynamic value) {
        if (value == null) return '';
        final s = value.toString();
        if (s.startsWith('http://') || s.startsWith('https://')) return s;
        if (s.startsWith('/uploads/')) return '$baseUrl$s';
        return '$baseUrl/media/$s';
      }

      List<String> _resolveImageList(dynamic images) {
        if (images is List) {
          return images.map((e) => _resolveImage(e)).toList().cast<String>();
        }
        return const [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/promotion/read'),
        headers: { 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['promotions'] is List<dynamic>) {
          final promotions = decoded['promotions'] as List<dynamic>;

          return promotions.map<Map<String, dynamic>>((p) {
            final m = (p as Map<String, dynamic>);

            // 우선순위: promotionImageUrls(프리사인) → promotionImage(키/레거시) → ''
            String mainImageUrl = '';
            if (m['promotionImageUrls'] is List &&
                (m['promotionImageUrls'] as List).isNotEmpty) {
              mainImageUrl = _resolveImage(m['promotionImageUrls'][0]);
            } else if (m['promotionImage'] is List &&
                (m['promotionImage'] as List).isNotEmpty) {
              mainImageUrl = _resolveImage(m['promotionImage'][0]);
            } else if (m['promotionImage'] is String) {
              mainImageUrl = _resolveImage(m['promotionImage']);
            }

            return {
              'id': m['_id']?.toString() ?? '',
              'name': m['name']?.toString() ?? '',
              'link': m['link']?.toString() ?? '',
              'promotionImageUrl': mainImageUrl,
            };
          }).toList();
        } else {
          print('Unexpected data format: $decoded');
          return [];
        }
      } else {
        print('API 호출 실패: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (e) {
      print('프로모션 조회 오류: $e');
      return [];
    }
  }
}
