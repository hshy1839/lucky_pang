import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
        Uri.parse('http://172.30.1.22:7778/api/users/userinfoget'),
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
        Uri.parse('http://172.30.1.22:7778/api/orderByUser'),
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
}
