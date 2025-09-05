import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../routes/base_url.dart';

class ProfileScreenController extends ChangeNotifier {
  String userId = '';
  String username = '';
  String name = '';
  String profileImageUrl = ''; // ✅ 항상 최종 절대 URL만 저장
  List<dynamic> orders = [];

  final storage = const FlutterSecureStorage();

  String get _baseUrl => '${BaseUrl.value}:7778';

  /// 실수로 'http://server/https://...' 형태가 들어오면 절대 URL만 뽑아내는 안전장치
  String _sanitizeAbsolute(String value) {
    if (value.isEmpty) return value;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;

    // 'http://server/https://bucket/...' 형태라면 뒤쪽의 https부터 잘라냄
    final httpsIdx = value.indexOf('https://');
    if (httpsIdx > 0) return value.substring(httpsIdx);

    final httpIdx = value.indexOf('http://');
    if (httpIdx > 0) return value.substring(httpIdx);

    return value;
  }

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

  Future<void> fetchUserDetails(BuildContext context) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final resp = await http.get(
        Uri.parse('$_baseUrl/api/users/userinfoget'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final user = data['user'];
        if (user == null) {
          throw Exception('사용자 정보를 찾을 수 없습니다. ${resp.body}');
        }

        userId = user['_id']?.toString() ?? '';
        username = user['username']?.toString() ?? '';
        name = (user['name'] ?? user['nickname'])?.toString() ?? '';

        // ✅ 백엔드가 내려준 presigned(=profileImageUrl) 우선 → 없으면 profileImage(S3 key/레거시) 사용
        final rawProfile = user['profileImageUrl'] ?? user['profileImage'];

        // 1) 규칙에 따라 URL 생성
        final resolved = _resolveImage(rawProfile?.toString());

        // 2) 혹시 어디선가 잘못 합쳐져 온 경우(서버/https://...) 교정
        profileImageUrl = _sanitizeAbsolute(resolved);

        debugPrint('👤 raw=$rawProfile  -> resolved=$resolved -> final=$profileImageUrl');

        notifyListeners();
      } else {
        throw Exception('사용자 정보 가져오기 실패: ${resp.body}');
      }
    } catch (e) {
      debugPrint('오류 발생: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 정보를 가져오는 데 실패했습니다.')),
        );
      }
      rethrow;
    }
  }

  Future<void> fetchUserOrders(BuildContext context) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final resp = await http.get(
        Uri.parse('$_baseUrl/api/orderByUser'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['orders'] != null) {
          orders = data['orders'];
          notifyListeners();
        } else {
          throw Exception('주문 정보를 찾을 수 없습니다. ${resp.body}');
        }
      } else {
        throw Exception('주문 정보 가져오기 실패: ${resp.body}');
      }
    } catch (e) {
      debugPrint('주문 정보 오류: $e');
      rethrow;
    }
  }

  Future<void> logout(BuildContext context) async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'userId');
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> uploadProfileImage(BuildContext context, File imageFile) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('웹에서는 이미지 업로드가 지원되지 않습니다.')),
      );
      return;
    }

    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final uri = Uri.parse('$_baseUrl/api/users/profile'); // 서버 라우트와 필드명: 'profileImage'
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath(
            'profileImage', // 백엔드 multer 필드명과 반드시 일치
            imageFile.path,
          ),
        );

      // ❗ 절대 'Content-Type: multipart/form-data' 직접 세팅하지 말 것 (boundary 깨짐)
      final resp = await req.send();

      if (resp.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로필 이미지 업로드 성공')),
          );
        }
        // 업로드 후 최신 정보 반영
        await fetchUserDetails(context);
      } else {
        throw Exception('프로필 이미지 업로드 실패 (${resp.statusCode})');
      }
    } catch (e) {
      debugPrint('프로필 이미지 업로드 오류: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 이미지 업로드 중 오류가 발생했습니다.')),
        );
      }
    }
  }
}
