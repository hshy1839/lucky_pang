import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;


class ProfileScreenController extends ChangeNotifier {
  String userId = '';
  String username = '';
  String name = '';
  List<dynamic> orders = [];

  final storage = FlutterSecureStorage(); // ✅ secure storage 인스턴스


  Future<void> fetchUserDetails(BuildContext context) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      print('📦 토큰 확인: $token');

      final response = await http.get(
        Uri.parse('http://192.168.219.108:7778/api/users/userinfoget'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['user'] != null) {
          userId = data['user']['_id'] ?? '';
          username = data['user']['username'] ?? '';
          name = data['user']['name'] ?? '';
          notifyListeners();
        } else {
          throw Exception('사용자 정보를 찾을 수 없습니다. ${response.body}');
        }
      } else {
        throw Exception('사용자 정보 가져오기 실패: ${response.body}');
      }
    } catch (e) {
      print('오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자 정보를 가져오는 데 실패했습니다.')),
      );
      throw e;
    }
  }

  Future<void> fetchUserOrders(BuildContext context) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) throw Exception('토큰이 없습니다.');

      final response = await http.get(
        Uri.parse('http://192.168.219.108:7778/api/orderByUser'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['orders'] != null) {
          orders = data['orders'];
          notifyListeners();
        } else {
          throw Exception('주문 정보를 찾을 수 없습니다. ${response.body}');
        }
      } else {
        throw Exception('주문 정보 가져오기 실패: ${response.body}');
      }
    } catch (e) {
      print('주문 정보 오류: $e');
      throw e;
    }
  }

  Future<void> logout(BuildContext context) async {
    await storage.delete(key: 'token'); // ✅ secure storage에서 토큰 삭제
    await storage.delete(key: 'userId');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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

      final uri = Uri.parse('http://192.168.219.108:7778/api/users/profile');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath(
            'profileImage',
            imageFile.path,
          ),
        );

      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 이미지 업로드 성공')),
        );
      } else {
        throw Exception('프로필 이미지 업로드 실패 (${response.statusCode})');
      }
    } catch (e) {
      print('프로필 이미지 업로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 이미지 업로드 중 오류가 발생했습니다.')),
      );
    }
  }
}
