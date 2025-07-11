import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../routes/base_url.dart';

class ProductController {
  final String baseUrl = '${BaseUrl.value}:7778';
  final FlutterSecureStorage storage = FlutterSecureStorage(); // ✅ SecureStorage 사용

  Future<List<Map<String, String>>> fetchProducts() async {
    try {
      final token = await storage.read(key: 'token'); // ✅ 토큰 읽기
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final response = await http.get(
        Uri.parse('$baseUrl/api/products/allProduct'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['products'] is List) {
          final List<dynamic> data = decoded['products'];

          return data.map<Map<String, String>>((item) {
            final mainImageUrl = _getImageUrl(item['mainImage']);
            final additionalImageUrls = _getImageList(item['additionalImages']);

            return {
              'id': item['_id']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'price': item['price']?.toString() ?? '',
              'category': item['category']?.toString() ?? '',
              'brand': item['brand']?.toString() ?? '',
              'mainImageUrl': mainImageUrl,
              'consumerPrice': item['consumerPrice']?.toString() ?? '',
              'description': item['description']?.toString() ?? '',
              'additionalImageUrls': additionalImageUrls.join(','),
            };
          }).toList();
        }
      }

      print('API 오류: ${response.statusCode}, ${response.body}');
      return [];
    } catch (e) {
      print('오류 발생: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> fetchProductsByCategory({required String category}) async {
    try {
      final token = await storage.read(key: 'token'); // ✅ 토큰 읽기
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final url = Uri.parse('$baseUrl/api/products/allProduct/category?category=$category');

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['products'];

        return data.map<Map<String, String>>((item) {
          final mainImageUrl = _getImageUrl(item['mainImage']);
          final additionalImageUrls = _getImageList(item['additionalImages']);

          return {
            'id': item['_id']?.toString() ?? '',
            'name': item['name']?.toString() ?? '',
            'price': item['price']?.toString() ?? '',
            'brand': item['brand']?.toString() ?? '',
            'category': item['category']?.toString() ?? '',
            'mainImageUrl': mainImageUrl,
            'description': item['description']?.toString() ?? '',
            'additionalImageUrls': additionalImageUrls.join(','),
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print('카테고리별 조회 오류: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getProductInfoById(String productId) async {
    try {
      final token = await storage.read(key: 'token'); // ✅ 토큰 읽기
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final response = await http.get(
        Uri.parse('$baseUrl/api/products/Product/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final product = decoded['product'];

        return {
          'id': product['_id'],
          'name': product['name'],
          'price': product['price']?.toString() ?? '',
          'mainImageUrl': _getImageUrl(product['mainImage']),
          'category': product['category']?.toString() ?? '',
          'brand': product['brand']?.toString() ?? '',
          'description': product['description'],
          'sizeStock': product['sizeStock'] ?? {},
          'isSourceSoldOut': product['isSourceSoldOut'] ?? false,
          'refundProbability' : product['refundProbability'] ?? '',
        };
      }

      return {};
    } catch (e) {
      print('상세 조회 오류: $e');
      return {};
    }
  }



  String _getImageUrl(dynamic image) {
    if (image is List && image.isNotEmpty) {
      return '$baseUrl${image[0]}';
    } else if (image is String) {
      return '$baseUrl$image';
    }
    return '';
  }

  List<String> _getImageList(dynamic images) {
    if (images is List) {
      return images.map((img) => '$baseUrl$img').toList().cast<String>();
    }
    return [];
  }
}
