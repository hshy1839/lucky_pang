import 'package:bootpay/bootpay.dart';
import 'package:bootpay/model/payload.dart';
import 'package:bootpay/model/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../routes/base_url.dart';
import '../../views/login_activity/login.dart';

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
  bool isPhoneVerified = false;


  String nicknameError = '';
  String nicknameSuccess = '';
  String emailError = '';
  bool nicknameChecked = false;
  bool emailChecked = false;

  String errorMessage = '';

  String passwordError = '';
  bool _passwordListenerBound = false;

  static final RegExp _emailRegex =
  RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

  // ✅ 비밀번호: 영문+숫자+특수문자, 8~16자
  static final RegExp _passwordRegex =
  RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^\w\s]).{8,16}$');

  void bindPasswordListenerOnce() {
    if (_passwordListenerBound) return;
    _passwordListenerBound = true;
    passwordController.addListener(() {
      final pwd = passwordController.text;
      if (pwd.isEmpty) {
        passwordError = '';
      } else if (!_passwordRegex.hasMatch(pwd)) {
        passwordError = '영문, 숫자, 특수문자 조합 8~16자리 조건에 맞게 작성해주세요.';
      } else {
        passwordError = '';
      }
      notifyListeners();
    });
  }

  void reset() {
    nicknameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    phoneController.clear();
    referralCodeController.clear();

    kakaoId = '';
    provider = 'local';
    providerId = '';
    eventAgree = false;
    isPhoneVerified = false;
    referralCodeChecked = false;
    emailChecked = false;
    nicknameChecked = false;
    referralCodeError = '';
    emailError = '';
    nicknameError = '';
    errorMessage = '';

    notifyListeners();
  }


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
      nicknameSuccess = '';
      nicknameChecked = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/users/check-duplicate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nickname': nickname}),
      );

      final data = jsonDecode(response.body);

      // ✅ 신규 포맷(ok/reasons/message) 우선 처리
      if (data is Map && data.containsKey('ok')) {
        final bool ok = data['ok'] == true;
        final List reasons = (data['reasons'] as List?) ?? const [];

        if (ok) {
          nicknameError = '';
          nicknameSuccess = '사용 가능한 닉네임 입니다.';// 성공 시 에러문구 없음 (필요하면 성공 문구 별도 처리)
          nicknameChecked = true;
        } else {
          if (reasons.contains('blacklist')) {
            nicknameError = '사용할 수 없는 닉네임 입니다.';  // ← 금칙어 케이스
          } else if (reasons.contains('duplicate')) {
            nicknameError = '이미 사용 중인 닉네임입니다.';
          } else if (reasons.contains('length')) {
            nicknameError = '닉네임은 2~8자입니다.';
          } else {
            nicknameError = (data['message'] as String?) ?? '사용할 수 없는 닉네임 입니다.';
          }
          nicknameChecked = false;
          nicknameSuccess = '';
        }
      } else {
        // 🔙 구버전 서버( exists 만 반환 ) 대응
        final exists = data['exists'] == true;
        nicknameError = exists ? '이미 사용 중인 닉네임입니다.' : '';
        nicknameSuccess = '사용 가능한 닉네임 입니다.';
        nicknameChecked = !exists;
      }
    } catch (e) {
      nicknameError = '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
      nicknameChecked = false;
    }

    notifyListeners();
  }


  Future<void> checkEmailDuplicate(BuildContext context) async {
    final email = emailController.text.trim();

    // 1) 형식 검증 선행
    if (!_emailRegex.hasMatch(email)) {
      emailError = '이메일 형식에 맞게 작성해주세요';
      emailChecked = false;
      notifyListeners();
      return;
    }

    // 2) 형식 OK → 서버 중복검사
    try {
      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/users/check-duplicate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      final exists = data['exists'] == true;

      emailError = exists ? '이미 사용 중인 이메일입니다.' : '';
      emailChecked = !exists;
    } catch (e) {
      emailError = '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
      emailChecked = false;
    }
    notifyListeners();
  }

  bool validatePasswordForSubmit() {
    final pwd = passwordController.text;
    if (!_passwordRegex.hasMatch(pwd)) {
      passwordError = '영문, 숫자, 특수문자 조합 8~16자리 조건에 맞게 작성해주세요.';
      notifyListeners();
      return false;
    }
    passwordError = '';
    notifyListeners();
    return true;
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
    final phone = phoneController.text.trim();
    if (nicknameController.text.isEmpty ||
        (provider == 'local' && (
            emailController.text.isEmpty ||
                passwordController.text.isEmpty ||
                confirmPasswordController.text.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 항목을 입력해주세요'), backgroundColor: Colors.black),
      );
      return;
    }

    if (provider == 'local' && (!nicknameChecked || !emailChecked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임과 이메일 중복확인을 완료해주세요.'), backgroundColor: Colors.black),
      );
      return;
    }

    if (provider == 'local' && !validatePasswordForSubmit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호 형식은 영문, 숫자, 특수문자 조합 8~16자리 조건에 맞게 작성해주세요.'), backgroundColor: Colors.black),
      );
      return;
    }


    if (referralCodeController.text.isNotEmpty && !referralCodeChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추천인 코드를 확인해주세요.'), backgroundColor: Colors.red),
      );
      return;
    }

     if (!isPhoneVerified) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('휴대폰 본인인증을 완료해주세요.'), backgroundColor: Colors.black),
       );
       return;
     }
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.'), backgroundColor: Colors.black),
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
      'phoneNumber': phone,
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

  Future<void> startBootpayAuth(BuildContext context, {Function()? onVerified}) async {
    Payload payload = Payload();

    payload.pg = '다날';
    payload.method = '본인인증';
    payload.authenticationId = DateTime.now().millisecondsSinceEpoch.toString();
    payload.orderName = '럭키탕 본인인증';
    payload.price = 0;
    payload.webApplicationId = '61e7c9c9e38c30001f7b8247';
    payload.androidApplicationId = '61e7c9c9e38c30001f7b8248';
    payload.iosApplicationId = '61e7c9c9e38c30001f7b8249';

    payload.user = User()
      ..username = '사용자 이름'
      ..phone = phoneController.text.trim()
      ..area = '대한민국';

    Bootpay().requestAuthentication(
      context: context,
      payload: payload,
      showCloseButton: true,
      onCancel: (data) {
        print('❌ 본인인증 취소: $data');
      },
      onError: (data) {
        print('❌ 본인인증 에러: $data');
      },
      onClose: () {
        print('🔒 본인인증 창 닫힘');
        Bootpay().dismiss(context);
      },
      onDone: (data) async {
        print('✅ 본인인증 완료: $data');
        final parsed = jsonDecode(data);
        final receiptId = parsed['data']['receipt_id'];

        final res = await http.post(
          Uri.parse('${BaseUrl.value}:7778/api/users/bootpay/verify-auth'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'receipt_id': receiptId}),
        );

        if (res.statusCode == 200) {
          print('🎉 서버 인증 성공: ${res.body}');
          final resData = jsonDecode(res.body);
          final phone = resData['user']['phone'];
          final name = resData['user']['name'];

          print('🎉 본인인증 성공: $name, $phone');
          isPhoneVerified = true;
          phoneController.text = phone;
          notifyListeners();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('본인인증이 완료되었습니다.')),
          );
          if (onVerified != null) {
            onVerified();
          }
        } else {
          print('❌ 서버 인증 실패: ${res.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('본인인증에 실패했습니다.'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  Future<String?> findEmailByPhone(String phone) async {
    try {
      final findEmailRes = await http.get(
        Uri.parse('${BaseUrl.value}:7778/api/users/findEmail?phoneNumber=$phone'),
        headers: {'Content-Type': 'application/json'},
      );
      if (findEmailRes.statusCode == 200) {
        final emailData = jsonDecode(findEmailRes.body);
        print("emailData : ${emailData}");
        return emailData['email'];
      } else {
        return null;
      }
    } catch (e) {
      print('이메일 찾기 오류: $e');
      return null;
    }
  }
}
