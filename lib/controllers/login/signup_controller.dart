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
  final phoneController = TextEditingController();
  final referralCodeController = TextEditingController();

  bool eventAgree = false;
  String referralCodeError = '';
  bool referralCodeChecked = false;

  String nicknameError = '';
  String emailError = '';
  bool nicknameChecked = false;
  bool emailChecked = false;

  String errorMessage = '';

  SignupController() {
    nicknameController.addListener(() {
      nicknameChecked = false;
      notifyListeners();
    });

    referralCodeController.addListener(() {
      referralCodeChecked = false;
      notifyListeners();
    });

    emailController.addListener(() {
      emailChecked = false;
      notifyListeners();
    });
  }

  Future<void> checkNicknameDuplicate(BuildContext context) async {
    final nickname = nicknameController.text.trim();

    if (nickname.isEmpty) {
      nicknameError = '닉네임을 입력해주세요.';
    } else {
      final response = await http.post(
        Uri.parse('http://192.168.219.107:7778/api/users/check-duplicate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nickname': nickname}),
      );

      final data = jsonDecode(response.body);
      final exists = data['exists'] == true;

      nicknameError = exists ? '이미 사용 중인 닉네임입니다.' : '사용 가능한 닉네임 입니다.';
      nicknameChecked = !exists;
    }

    notifyListeners();
  }

  Future<void> checkEmailDuplicate(BuildContext context) async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      emailError = '이메일을 입력해주세요.';
    } else {
      final response = await http.post(
        Uri.parse('http://192.168.219.107:7778/api/users/check-duplicate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      final exists = data['exists'] == true;

      emailError = exists ? '이미 사용 중인 이메일입니다.' : '사용 가능한 이메일 입니다.';
      emailChecked = !exists;
    }

    notifyListeners();
  }

  Future<void> checkReferralCode(BuildContext context) async {
    final code = referralCodeController.text.trim();

    if (code.isEmpty) {
      referralCodeError = '추천인 코드를 입력해주세요.';
      notifyListeners();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.219.107:7778/api/users/check-referral'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'referralCode': code}),
      );

      final data = jsonDecode(response.body);
      final exists = data['exists'] == true;

      referralCodeError = exists ? '사용 가능한 코드 입니다.' : '존재하지 않는 추천인 코드입니다.';
      referralCodeChecked = exists;

      notifyListeners();
    } catch (e) {
      referralCodeError = '오류가 발생했습니다.';
      referralCodeChecked = false;
      notifyListeners();
    }
  }


  Future<void> submitData(BuildContext context) async {
    print('닉네임: ${nicknameController.text}, 닉네임확인여부: $nicknameChecked');
    print('이메일: ${emailController.text}, 이메일확인여부: $emailChecked');
    print('추천인코드: ${referralCodeController.text}, 코드확인여부: $referralCodeChecked');


    if (nicknameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 항목을 입력해주세요'), backgroundColor: Colors.red),
      );
      return;
    }

    // 닉네임, 이메일 중복확인 필수
    if (!nicknameChecked || !emailChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임과 이메일 중복확인을 완료해주세요.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 추천인 코드가 입력되어 있는데 중복검사를 안 한 경우
    if (referralCodeController.text.isNotEmpty && !referralCodeChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추천인 코드를 확인해주세요.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 비밀번호 확인
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 요청 데이터 구성
    final body = {
      'email': emailController.text.trim(),
      'nickname': nicknameController.text.trim(),
      'password': passwordController.text,
      'phoneNumber': phoneController.text.trim(),
      'is_active': true,
      'eventAgree': eventAgree,
    };

    // 추천인 코드가 있고, 확인까지 완료되었을 경우에만 포함
    if (referralCodeController.text.isNotEmpty && referralCodeChecked) {
      body['referralCode'] = referralCodeController.text.trim();
    }

    final response = await http.post(
      Uri.parse('http://192.168.219.107:7778/api/users/signup'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
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

