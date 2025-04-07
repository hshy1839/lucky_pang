import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreenController extends ChangeNotifier {
  String userId = ''; // 사용자 ID 초기화
  String username = ''; // 사용자 이름 초기화
  String name = '';
  List<dynamic> orders = []; // 주문 정보 리스트

  Future<void> fetchUserId(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('http://172.30.1.42:7778/api/users/userinfoget'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['user'] != null && data['user']['_id'] != null) {
          userId = data['user']['_id'];
          notifyListeners();
        } else {
          throw Exception('유저 ID를 찾을 수 없습니다. ${response.body}');
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

  Future<void> fetchUserDetails(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('http://172.30.1.42:7778/api/users/userinfoget'),
        headers: {
          'Authorization': 'Bearer $token',
        },
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('http://172.30.1.42:7778/api/orderByUser'),
        headers: {
          'Authorization': 'Bearer $token',
        },
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

      throw e;
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
