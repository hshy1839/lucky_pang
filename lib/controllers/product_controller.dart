import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../routes/base_url.dart';

class ProductController {
  // BaseUrl.value 예: "http://192.168.219.108" (끝 슬래시 없이 보관 권장)
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  String get _root {
    final v = BaseUrl.value.trim();
    return v.replaceAll(RegExp(r'/+$'), ''); // 끝 슬래시 제거
  }

  // BaseUrl에 이미 포트가 있으면 그대로, 아니면 :7778 추가
  String get _base {
    final u = Uri.tryParse(_root);
    if (u != null && u.hasPort) return _root;
    return '$_root:7778';
  }


  String _join(String a, String b) {
    final left = a.replaceAll(RegExp(r'/+$'), '');
    final right = b.replaceAll(RegExp(r'^/+'), '');
    return '$left/$right';
  }

  // 절대 URL인데 authority 뒤에 슬래시가 없다면 보정 (예: http://host:7778path → http://host:7778/path)
  String _fixAbsoluteUrl(String s) {
    final m = RegExp(r'^(https?:\/\/[^\/\s]+)(\/?.*)$').firstMatch(s);
    if (m == null) return s; // 절대 URL 아님
    final authority = m.group(1)!;
    var rest = m.group(2)!; // "path" or "/path" or ""
    if (rest.isEmpty) return s;
    if (!rest.startsWith('/')) rest = '/$rest';
    return '$authority$rest';
  }

  /// presigned/절대 URL이면 그대로,
  /// /uploads/...이면 base 붙이고,
  /// 그 외(S3 key)는 /media/{key}
  String _resolveImage(dynamic value) {
    if (value == null) return '';
    final s = value.toString().trim();
    if (s.isEmpty) return '';

    // 1) 서버가 준 presigned/절대 URL이면 보정만 하고 그대로
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return _fixAbsoluteUrl(s);
    }

    // 2) 로컬 업로드 경로 (레거시 호환)
    if (s.startsWith('/uploads/')) {
      return _join(_base, s);
    }

    // 3) 그 외는 S3 key로 간주 → /media/{key}
    final encodedKey = Uri.encodeComponent(s);
    return _join(_base, _join('media', encodedKey));
  }

  List<String> _resolveImageList(dynamic list) {
    if (list is List) {
      return list.map((v) => _resolveImage(v)).toList().cast<String>();
    }
    return const [];
  }

  Future<List<Map<String, String>>> fetchProducts() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final resp = await http.get(
        Uri.parse('$_base/api/products/allProduct'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded['products'] is List) {
          final List<dynamic> data = decoded['products'];
          return data.map<Map<String, String>>((item) {
            // 서버가 presigned mainImageUrl을 주면 그걸 우선 사용
            final mainImageUrl = _resolveImage(
              item['mainImageUrl'] ?? item['mainImage'], // presigned or key
            );

            final additionalImageUrls = (item['additionalImageUrls'] != null)
                ? _resolveImageList(item['additionalImageUrls'])
                : _resolveImageList(item['additionalImages']);

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

      print('API 오류: ${resp.statusCode}, ${resp.body}');
      return [];
    } catch (e) {
      print('오류 발생: $e');
      return [];
    }
  }
  Future<List<Map<String, String>>> fetchProductsPaged({
    required String category, // '5,000원 박스' | '10,000원 박스'
    required int page,
    required int limit,
  }) async {
    final uri = Uri.parse('${BaseUrl.value}:7778/api/products')
        .replace(queryParameters: {
      'category': category,
      'page': '$page',
      'limit': '$limit',
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('상품 로드 실패 (${res.statusCode})');
    }

    final data = jsonDecode(res.body);

    // 서버 응답 형태에 맞춰 매핑
    // - 배열 그대로 오면 data as List
    // - { items: [...], total: 123 } 형태면 data['items']
    final List list =
    (data is Map && data['items'] != null) ? data['items'] : (data as List);

    return list.map<Map<String, String>>((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      return {
        'id':            '${m['_id'] ?? m['id'] ?? ''}',
        'name':          '${m['name'] ?? ''}',
        'brand':         '${m['brand'] ?? ''}',
        'price':         '${m['price'] ?? '0'}',
        'consumerPrice': '${m['consumerPrice'] ?? '0'}',
        'mainImageUrl':  '${m['mainImageUrl'] ?? ''}',
        'category':      '${m['category'] ?? ''}',
      };
    }).toList();
  }

  Future<List<Map<String, String>>> fetchProductsByCategory({required String category}) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final url = Uri.parse('$_base/api/products/allProduct/category?category=$category');
      final resp = await http.get(url, headers: { 'Authorization': 'Bearer $token' });

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        final List<dynamic> data = decoded['products'] ?? [];

        return data.map<Map<String, String>>((item) {
          final mainImageUrl = _resolveImage(item['mainImageUrl'] ?? item['mainImage']);
          final additionalImageUrls = (item['additionalImageUrls'] != null)
              ? _resolveImageList(item['additionalImageUrls'])
              : _resolveImageList(item['additionalImages']);

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
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final resp = await http.get(
        Uri.parse('$_base/api/products/Product/$productId'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        final product = decoded['product'] ?? {};

        final mainImageUrl = _resolveImage(product['mainImageUrl'] ?? product['mainImage']);
        final additionalImageUrls = (product['additionalImageUrls'] != null)
            ? _resolveImageList(product['additionalImageUrls'])
            : _resolveImageList(product['additionalImages']);

        return {
          'id': product['_id']?.toString() ?? '',
          'name': product['name']?.toString() ?? '',
          'price': product['price']?.toString() ?? '',
          'mainImageUrl': mainImageUrl,
          'additionalImageUrls': additionalImageUrls, // 상세는 리스트 유지
          'category': product['category']?.toString() ?? '',
          'brand': product['brand']?.toString() ?? '',
          'description': product['description'] ?? '',
          'sizeStock': product['sizeStock'] ?? {},
          'isSourceSoldOut': product['isSourceSoldOut'] ?? false,
          'shippingFee': product['shippingFee'] ?? 0,
          'refundProbability': product['refundProbability']?.toString() ?? '',
        };
      }

      return {};
    } catch (e) {
      print('상세 조회 오류: $e');
      return {};
    }
  }
}
