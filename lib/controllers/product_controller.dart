import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../footer.dart';
import '../../header.dart';

class ProductController {
  Future<List<Map<String, String>>> fetchProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? ''; // 저장된 토큰 불러오기

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      final response = await http.get(
        Uri.parse('http://172.30.1.42:7778/api/products/allProduct'),
        headers: {
          'Authorization': 'Bearer $token', // Bearer 토큰 추가
        },
      );

      // 응답 데이터 출력

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        // 디코드된 데이터 출력

        if (decodedResponse is Map<String, dynamic> && decodedResponse['products'] is List<dynamic>) {
          final List<dynamic> data = decodedResponse['products'];
          const serverUrl = 'http://172.30.1.42:7778'; // 서버 URL 설정

          return data.reversed.map((item) {
            final originalDate = item['createdAt']?.toString() ?? '';
            final formattedDate = _formatDate(originalDate);

            // category 값을 main > sub 형식으로 변환
            final category = item['category'] != null && item['category'] is Map<String, dynamic>
                ? '${item['category']['main'] ?? ''} > ${item['category']['sub'] ?? ''}'
                : '';

            // mainImage 값 처리
            final mainImageUrl = item['mainImage'] != null && item['mainImage'] is List<dynamic>
                ? (item['mainImage'] as List<dynamic>).isNotEmpty
                ? '$serverUrl${item['mainImage'][0]}' // 서버 URL 추가
                : ''  // 비어있으면 빈 문자열 반환
                : '';  // mainImage가 null이거나 List가 아니면 빈 문자열 반환

            // additionalImages 값 처리: 여러 개의 이미지 URL을 배열로 저장
            final additionalImageUrls = item['additionalImages'] != null && item['additionalImages'] is List<dynamic>
                ? (item['additionalImages'] as List<dynamic>).map((image) => '$serverUrl$image').toList() // 서버 URL 추가
                : [];  // 빈 배열 반환

            // 상품 ID 추가
            final productId = item['_id']?.toString() ?? '';

            return {
              'id': productId,  // id 추가
              'name': item['name']?.toString() ?? '',
              'price': item['price']?.toString() ?? '',
              'category': category,
              'mainImageUrl': mainImageUrl, // mainImageUrl 추가
              'description' : item['description']?.toString() ?? '',
              'additionalImageUrls': additionalImageUrls.join(','), // 추가 이미지들을 ','로 구분하여 저장
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

  Future<List<Map<String, String>>> fetchProductsByCategory({
    required String category,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      // 쿼리 파라미터 설정
      final url = Uri.parse(
          'http://172.30.1.42:7778/api/products/allProduct/category?category=$category');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Bearer 토큰 추가
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse is Map<String, dynamic> && decodedResponse['products'] is List<dynamic>) {
          final List<dynamic> data = decodedResponse['products'];
          const serverUrl = 'http://172.30.1.42:7778';

          return data.map((item) {
            final category = item['category'] != null && item['category'] is Map<String, dynamic>
                ? '${item['category']['main'] ?? ''} > ${item['category']['sub'] ?? ''}'
                : '';

            final additionalImageUrls = item['additionalImages'] != null && item['additionalImages'] is List<dynamic>
                ? (item['additionalImages'] as List<dynamic>).map((image) => '$serverUrl$image').toList() // 서버 URL 추가
                : [];  // 빈 배열 반환

            return {
              'id': item['_id']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'price': item['price']?.toString() ?? '',
              'category': category,
              'mainImageUrl': serverUrl + (item['mainImage']?[0] ?? ''),
              'additionalImageUrls': additionalImageUrls.join(','), // 추가 이미지들을 ','로 구분하여 저장
              'description': item['description']?.toString() ?? '',
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
      print('상품 조회 중 오류 발생: $error');
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

  Future<Map<String, dynamic>> getProductInfoById(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? ''; // 저장된 토큰 불러오기

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다. 로그인 상태를 확인하세요.');
      }

      final response = await http.get(
        Uri.parse('http://172.30.1.42:7778/api/products/Product/$productId'),
        headers: {
          'Authorization': 'Bearer $token', // Bearer 토큰 추가
        },
      );


      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        const serverUrl = 'http://172.30.1.42:7778';


        final mainImageUrl = decodedResponse['product']['mainImage'] != null &&  decodedResponse['product']['mainImage'] is List<dynamic>
            ? ( decodedResponse['product']['mainImage'] as List<dynamic>).isNotEmpty
            ? '$serverUrl${ decodedResponse['product']['mainImage'][0]}' // 서버 URL 추가
            : ''  // 비어있으면 빈 문자열 반환
            : '';  // mainImage가 null이거나 List가 아니면 빈 문자열 반환

        final category = decodedResponse['product']['category'] != null && decodedResponse['product']['category'] is Map<String, dynamic>
            ? '${decodedResponse['product']['category']['main'] ?? ''} > ${decodedResponse['product']['category']['sub'] ?? ''}'
            : '';

        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse['product'] is Map<String, dynamic>) {
          // 서버에서 제공하는 제품 데이터를 포함한 Map 반환
          return {
            'id': decodedResponse['product']['_id'], // _id를 id로 매핑
            'name': decodedResponse['product']['name']?.toString() ?? '',
            'price': decodedResponse['product']['price']?.toString() ?? '',
            'mainImageUrl':mainImageUrl,
            'category':category,
            'description': decodedResponse['product']['description']?.toString() ?? '',
            'sizeStock': decodedResponse['product']['sizeStock'] ?? {}, // 사이즈 스탁 추가
          };
        } else {
          return {}; // 예상과 다른 응답 데이터일 경우 빈 Map 반환
        }
      } else {
        print('API 호출 실패: ${response.statusCode}, ${response.body}');
        return {}; // 실패 시 빈 Map 반환
      }
    } catch (error) {
      print('제품 이미지 조회 중 오류 발생: $error');
      return {}; // 오류 발생 시 빈 Map 반환
    }
  }

}


