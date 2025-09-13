import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../routes/base_url.dart';

class LoginController {
  final BuildContext context;

  LoginController(this.context);

  Future<void> login(String email, String password) async {
    final url = Uri.parse('${BaseUrl.value}:7778/api/users/login');
    final storage = FlutterSecureStorage();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': 'local',
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      final loginSuccess = responseData['loginSuccess'] ?? false;
      final token = responseData['token'] ?? '';

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

  Future<void> loginWithKakao(BuildContext context) async {
    try {
      final isInstalled = await isKakaoTalkInstalled();

      final OAuthToken token = isInstalled
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      // 1차 사용자 정보
      var user = await UserApi.instance.me();
      final kakaoId = user.id.toString();
      final nickname = user.kakaoAccount?.profile?.nickname ?? '카카오사용자';

      var email = user.kakaoAccount?.email;
      final emailNeedsAgreement = user.kakaoAccount?.emailNeedsAgreement ?? false;
      final isEmailValid = user.kakaoAccount?.isEmailValid ?? false;
      final isEmailVerified = user.kakaoAccount?.isEmailVerified ?? false;

      print('✅ 카카오 로그인 성공: id=$kakaoId, nickname=$nickname');
      print('📦 kakaoAccount email=${email ?? "(null)"} '
          'hasEmail=${email != null && email.isNotEmpty} '
          'emailNeedsAgreement=$emailNeedsAgreement '
          'isEmailValid=$isEmailValid '
          'isEmailVerified=$isEmailVerified');

      // 이메일이 없고 동의가 필요할 때 스코프 재요청
      if ((email == null || email.isEmpty) && emailNeedsAgreement) {
        print('🟨 account_email 동의 필요 → 스코프 재요청...');
        try {
          await UserApi.instance.loginWithNewScopes(['account_email']);
          user = await UserApi.instance.me();
          email = user.kakaoAccount?.email;

          print('🟩 재동의 후 email=${email ?? "(null)"} '
              'hasEmail=${email != null && email.isNotEmpty} '
              'emailNeedsAgreement=${user.kakaoAccount?.emailNeedsAgreement} '
              'isEmailValid=${user.kakaoAccount?.isEmailValid} '
              'isEmailVerified=${user.kakaoAccount?.isEmailVerified}');
        } catch (e) {
          print('❌ 스코프 재동의 실패/취소: $e');
        }
      }

      // 서버에 로그인 시도 (디버깅용으로 email도 함께 전송)
      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/users/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': 'kakao',
          'providerId': kakaoId,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginSuccess = data['loginSuccess'] == true;
        final exists = data['exists'] == true;

        if (loginSuccess || exists) {
       final storage = FlutterSecureStorage();
       // ✅ 서버가 내려준 token / userId 저장 (반드시 필요)
       if (data['token'] != null) {
         await storage.write(key: 'token', value: data['token']);
       }
       if (data['userId'] != null) {
         await storage.write(key: 'userId', value: data['userId']);
       }
       await storage.write(key: 'isLoggedIn', value: 'true'); // (선택) 쓰고 있다면 유지

       print('🟢 소셜 로그인 성공 → 메인 이동');
       if (!context.mounted) return;
       Navigator.pushReplacementNamed(context, '/main');
     } else {
          print('🟡 신규 회원 → 약관동의 이동 (email=${email ?? "(null)"})');
          if (!context.mounted) return;
          Navigator.pushNamed(
            context,
            '/signupAgree',
            arguments: {
              'provider': 'kakao',
              'providerId': kakaoId,
              'nickname': nickname,
              'email': email ?? '',
              'kakaoFlags': {
                'hasEmail': email != null && email.isNotEmpty,
                'emailNeedsAgreement': emailNeedsAgreement,
                'isEmailValid': isEmailValid,
                'isEmailVerified': isEmailVerified,
              },
            },
          );
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 카카오 로그인 실패: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오 로그인에 실패했어요.')),
      );
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return; // 로그인 취소
      }

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential);
      final user = userCredential.user;
      final googleId = user?.uid ?? '';
      final nickname = user?.displayName ?? 'Google사용자';
      final email = user?.email ?? '';

      print('✅ 구글 로그인 성공: $googleId, $nickname, $email');

      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/users/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': 'google',
          'providerId': googleId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginSuccess = data['loginSuccess'] == true;
        final exists = data['exists'] == true;

        if (loginSuccess || exists) {
          final storage = FlutterSecureStorage();
          await storage.write(key: 'token', value: data['token']);
          await storage.write(key: 'userId', value: data['userId']);
          await storage.write(key: 'isLoggedIn', value: 'true');
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          Navigator.pushNamed(context, '/signupAgree', arguments: {
            'provider': 'google',
            'providerId': googleId,
            'nickname': nickname,
            'email': email,
          });

        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 구글 로그인 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인에 실패했어요.')),
      );
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