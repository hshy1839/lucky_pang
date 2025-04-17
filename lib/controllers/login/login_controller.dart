import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginController {
  final BuildContext context;

  LoginController(this.context);

  Future<void> login(String email, String password) async {
    final url = Uri.parse('http://172.30.1.22:7778/api/users/login');
    final storage = FlutterSecureStorage();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      final loginSuccess = responseData['loginSuccess'] ?? false;
      final token = responseData['token'] ?? '';
      final isActive = responseData['is_active'] ?? false; // 추가: is_active 값 확인

      if (loginSuccess) {
          // 로그인 성공 후 token 저장
          await storage.write(key: 'token', value: token);
          await storage.write(key: 'isLoggedIn', value: 'true');

          final userId = responseData['userId']; // 서버에서 전달된 userId
          if (userId != null) {
            await storage.write(key: 'userId', value: userId);
          }


          _showSuccessDialog();
      } else {
        _showErrorDialog(responseData['message'] ?? 'Error: 500');
      }
    } else {
      _showErrorDialog('로그인 실패. 아이디와 비밀번호를 확인해 주세요.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '로그인',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text('환영합니다'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        actions: [
          TextButton(
            child: Text('확인', style: TextStyle(color: Colors.blueAccent)),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '로그인 실패',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        actions: [
          TextButton(
            child: Text('확인', style: TextStyle(color: Colors.blueAccent)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
