import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../views/login_activity/login.dart';
import '../userinfo_screen_controller.dart';

class SignupController extends ChangeNotifier {
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final referralCodeController = TextEditingController();
  final phoneController = TextEditingController();

  String errorMessage = '';

  Future<void> checkNicknameDuplicate(BuildContext context) async {
    final nickname = nicknameController.text.trim();

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }

    final response = await http.post(
      Uri.parse('http://172.30.1.42:7778/api/users/check-duplicate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nickname': nickname}),
    );

    final data = jsonDecode(response.body);
    final exists = data['exists'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(exists ? '이미 사용 중인 닉네임입니다.' : '사용 가능한 닉네임입니다.')),
    );
  }

  Future<void> checkEmailDuplicate(BuildContext context) async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }

    final response = await http.post(
      Uri.parse('http://172.30.1.42:7778/api/users/check-duplicate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);
    final exists = data['exists'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(exists ? '이미 사용 중인 이메일입니다.' : '사용 가능한 이메일입니다.')),
    );
  }

  Future<void> checkReferralCode(BuildContext context) async {
    final referralCode = referralCodeController.text.trim();

    if (referralCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }

    final response = await http.post(
      Uri.parse('http://172.30.1.42:7778/api/users/check-referral'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'referralCode': referralCode}),
    );

    final data = jsonDecode(response.body);
    final exists = data['exists'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(exists ? '사용 가능한 코드 입니다.' : '사용 불가능한 코드입니다.')),
    );
  }


  Future<void> submitData(BuildContext context) async {
    if (nicknameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 항목을 입력해주세요'), backgroundColor: Colors.red),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.'), backgroundColor: Colors.red),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://172.30.1.42:7778/api/users/signup'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'email': emailController.text,
        'nickname': nicknameController.text,
        'password': passwordController.text,
        'phoneNumber': phoneController.text,
        'referralCode': referralCodeController.text,
        'is_active': true,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('회원가입 성공')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    } else {
      final responseData = jsonDecode(response.body);
      errorMessage = responseData['message'] ?? '회원가입 실패';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    referralCodeController.dispose();
    super.dispose();
  }
}

