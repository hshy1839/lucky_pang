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
  String profileImage = "";
  String createdAt = '';
  bool _fetched = false;

  final storage = FlutterSecureStorage();

  Future<void> fetchUserInfo(BuildContext context) async {
    if (_fetched) return; // 🔥 이미 불러왔으면 재요청 막기
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('로그인 정보가 없습니다.');

      final response = await http.get(
        Uri.parse('${BaseUrl.value}:7778/api/users/userinfoget'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final user = data['user'];
          nickname = user['nickname'] ?? '';
          email = user['email'] ?? '';
          phoneNumber = user['phoneNumber'] ?? '';
          referralCode = user['referralCode'] ?? '';
          profileImage = user['profileImage'] ?? '';
          createdAt = user['created_at'] ?? '';
          _fetched = true; // ✅ 캐싱 완료 표시
        } else {
          throw Exception('사용자 정보를 불러올 수 없습니다.');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (error) {
      print('사용자 정보 가져오기 오류: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자 정보를 가져오는 중 오류가 발생했습니다.')),
      );
    }
  }

  void clearCache() {
    _fetched = false;
  }


  // 사용자 정보 업데이트 (이름과 전화번호만)
  Future<void> updateUserInfo(BuildContext context, String updatedName, String updatedPhoneNumber) async {
    try {
      // SharedPreferences에서 토큰 가져오기
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다. 다시 로그인해주세요.');
      }

      // 서버 요청
      final response = await http.put(
        Uri.parse('${BaseUrl.value}:7778/api/users/userinfoUpdate'), // 서버 주소에 맞게 수정
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // SharedPreferences에서 가져온 토큰 사용
        },
        body: json.encode({
          'name': updatedName.trim(), // 이름 업데이트
          'phoneNumber': updatedPhoneNumber.trim(), // 전화번호 업데이트
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          nickname = updatedName;
          phoneNumber = updatedPhoneNumber;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('사용자 정보가 성공적으로 업데이트되었습니다.')),
          );
        } else {
          throw Exception('사용자 정보를 업데이트할 수 없습니다.');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (error) {
      print('사용자 정보 업데이트 오류: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자 정보를 업데이트하는 중 오류가 발생했습니다.')),
      );
    }
  }


  Future<bool> withdrawUser(BuildContext context) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('로그인 정보가 없습니다.');

      final response = await http.delete(
        Uri.parse('${BaseUrl.value}:7778/api/users/withdraw'),
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
      print('회원탈퇴 오류: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원 탈퇴 중 오류가 발생했습니다.')),
      );
      return false;
    }
  }


}
