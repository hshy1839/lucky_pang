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
      final token = await storage.read(key: 'token'); // ✅ SecureStorage에서 토큰 읽기
      if (token == null || token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      final response = await http.get(
        Uri.parse('${BaseUrl.value}:7778/api/promotion/read'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse['promotions'] is List<dynamic>) {
          final promotions = decodedResponse['promotions'] as List<dynamic>;
          const serverUrl = '${BaseUrl.value}:7778';

          return promotions.map((promotion) {
            final promotionMap = promotion as Map<String, dynamic>;
            final promotionImage = promotionMap['promotionImage'] as List<dynamic>?;

            return {
              'id': promotionMap['_id'] ?? '',
              'name': promotionMap['name']?.toString() ?? '',
              'link': promotionMap['link']?.toString() ?? '',
              'promotionImageUrl': promotionImage != null && promotionImage.isNotEmpty
                  ? '$serverUrl${promotionImage[0]}'
                  : '',
            };
          }).toList();
        } else {
          print('Unexpected data format: $decodedResponse');
          return [];
        }
      } else {
        print('API 호출 실패: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (error) {
      print('제품 이미지 조회 중 오류 발생: $error');
      return [];
    }
  }
}
