import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../views/login_activity/login.dart';

class SignupController extends ChangeNotifier {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  String errorMessage = '';

  Future<void> submitData(BuildContext context) async {

    if (nameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        phoneController.text.isEmpty)
         {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('칸을 모두 채워주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // 비밀번호와 비밀번호 확인 비교
    if (passwordController.text != confirmPasswordController.text) {
      errorMessage = '비밀번호와 비밀번호 확인이 일치하지 않습니다.';
      notifyListeners();
      return;
    }

    final response = await http.post(
      Uri.parse('http://172.30.1.42:7778/api/users/signup'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, Object>{
        'name': nameController.text,
        'username': usernameController.text,
        'password': passwordController.text,
        'phoneNumber': phoneController.text,
        'is_active': true,
      }),
    );

    // 서버 응답 처리
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 성공')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      final responseData = jsonDecode(response.body);
      errorMessage = responseData['message'] ?? '회원가입 실패';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
