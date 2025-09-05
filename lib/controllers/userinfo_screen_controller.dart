import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../routes/base_url.dart';

class UserInfoScreenController {
  String nickname = "";
  String email = "";
  String phoneNumber = "";
  String referralCode = "";
  String profileImage = ""; // <- 화면에서 바로 쓸 수 있는 최종 URL 형태로 저장
  String createdAt = '';
  bool _fetched = false;

  final storage = const FlutterSecureStorage();
  String get _baseUrl => '${BaseUrl.value}:7778';

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

  Future<void> fetchUserInfo(BuildContext context) async {
    if (_fetched) return; // 🔥 이미 불러왔으면 재요청 막기
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('로그인 정보가 없습니다.');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/userinfoget'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final user = data['user'];

          nickname     = user['nickname']     ?.toString() ?? '';
          email        = user['email']        ?.toString() ?? '';
          phoneNumber  = user['phoneNumber']  ?.toString() ?? '';
          referralCode = user['referralCode'] ?.toString() ?? '';
          createdAt    = user['created_at']   ?.toString() ?? '';

          // ✅ 프로필 이미지: presigned/절대 → 그대로, 키 → /media/{key}, /uploads → baseUrl 붙이기
          // 백엔드가 profileImageUrl(프리사인)을 내려주는 경우 우선 사용
          final rawProfile = user['profileImageUrl'] ?? user['profileImage'];
          profileImage = _resolveImage(rawProfile);

          _fetched = true; // ✅ 캐싱 완료 표시
        } else {
          throw Exception('사용자 정보를 불러올 수 없습니다.');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('사용자 정보 가져오기 오류: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 가져오는 중 오류가 발생했습니다.')),
      );
    }
  }

  void clearCache() {
    _fetched = false;
  }

  // 사용자 정보 업데이트 (이름과 전화번호만)
  Future<void> updateUserInfo(BuildContext context, String updatedName, String updatedPhoneNumber) async {
    try {
      // SharedPreferences에서 토큰 가져오기 (기존 코드 유지)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다. 다시 로그인해주세요.');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/users/userinfoUpdate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': updatedName.trim(),
          'phoneNumber': updatedPhoneNumber.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          nickname = updatedName;
          phoneNumber = updatedPhoneNumber;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('사용자 정보가 성공적으로 업데이트되었습니다.')),
            );
          }
        } else {
          throw Exception('사용자 정보를 업데이트할 수 없습니다.');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('사용자 정보 업데이트 오류: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 정보를 업데이트하는 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  Future<bool> withdrawUser(BuildContext context) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('로그인 정보가 없습니다.');

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/users/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await storage.delete(key: 'token');
          return true;
        } else {
          throw Exception(data['message'] ?? '탈퇴 처리 실패');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('회원탈퇴 오류: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 탈퇴 중 오류가 발생했습니다.')),
        );
      }
      return false;
    }
  }
}
