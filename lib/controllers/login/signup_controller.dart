import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../routes/base_url.dart';
import '../../views/login_activity/login.dart';
import '../../views/widget/danal_auth_webview.dart';

class SignupController extends ChangeNotifier {
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final referralCodeController = TextEditingController();
  String kakaoId = '';
  bool eventAgree = false;
  String referralCodeError = '';
  bool referralCodeChecked = false;
  String provider = '';
  String providerId = '';

  String nicknameError = '';
  String emailError = '';
  bool nicknameChecked = false;
  bool emailChecked = false;

  String errorMessage = '';

  SignupController({String? initialEmail}) {
    if (initialEmail != null && initialEmail.isNotEmpty) {
      emailController.text = initialEmail;
      emailChecked = true;
    }

    nicknameController.addListener(() {
      nicknameChecked = false;
      notifyListeners();
    });

    emailController.addListener(() {
      emailChecked = false;
      notifyListeners();
    });

    referralCodeController.addListener(() {
      referralCodeChecked = false;
      notifyListeners();
    });
  }

  Future<void> checkNicknameDuplicate(BuildContext context) async {
    final nickname = nicknameController.text.trim();

    if (nickname.isEmpty) {
      nicknameError = '닉네임을 입력해주세요.';
    } else {
      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/users/check-duplicate'),
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
        Uri.parse('${BaseUrl.value}:7778/api/users/check-duplicate'),
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
        Uri.parse('${BaseUrl.value}:7778/api/users/check-referral'),
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
    if (nicknameController.text.isEmpty ||
        (provider == 'local' && (
            emailController.text.isEmpty ||
                passwordController.text.isEmpty ||
                confirmPasswordController.text.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 항목을 입력해주세요'), backgroundColor: Colors.red),
      );
      return;
    }

    if (provider == 'local' && (!nicknameChecked || !emailChecked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임과 이메일 중복확인을 완료해주세요.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (referralCodeController.text.isNotEmpty && !referralCodeChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추천인 코드를 확인해주세요.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (provider != 'local' && emailController.text.isNotEmpty && !emailChecked) {
      // 소셜 로그인은 자동으로 이메일 중복 검사 수행
      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/users/check-duplicate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );

      final data = jsonDecode(response.body);
      if (data['exists'] == true) {
        emailError = '이미 사용 중인 이메일입니다.';
        notifyListeners();
        return;
      } else {
        emailChecked = true;
      }
    }

    final body = {
      'provider': provider,
      'nickname': nicknameController.text.trim(),
      'phoneNumber': phoneController.text.trim(),
      'is_active': true,
      'eventAgree': eventAgree,
    };

    if (provider == 'local') {
      body['email'] = emailController.text.trim();
      body['password'] = passwordController.text;
    } else {
      body['providerId'] = providerId;
      body['email'] = emailController.text.trim(); // 소셜 로그인 시 이메일 포함
    }

    if (referralCodeController.text.isNotEmpty && referralCodeChecked) {
      body['referralCode'] = referralCodeController.text.trim();
    }

    final response = await http.post(
      Uri.parse('${BaseUrl.value}:7778/api/users/signup'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('회원가입 성공')));
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

  Future<void> startDanalAuth(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/users/danal/request-auth'),
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DanalAuthWebView(htmlContent: response.body),
          ),
        );
      } else {
        throw Exception('서버 오류');
      }
    } catch (e) {
      debugPrint('❌ 본인인증 요청 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('본인인증 요청에 실패했습니다.')),
      );
    }
  }
}