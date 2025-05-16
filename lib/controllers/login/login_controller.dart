import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> loginWithKakao(BuildContext context) async {
    try {
      bool isInstalled = await isKakaoTalkInstalled();

      OAuthToken token = isInstalled
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      final user = await UserApi.instance.me();
      final kakaoId = user.id.toString();
      final nickname = user.kakaoAccount?.profile?.nickname ?? '카카오사용자';

      print('✅ 카카오 로그인 성공: $kakaoId, $nickname');
      print('카카오 유저 정보 전체: ${user.toJson()}');

      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/users/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': 'kakao',
          'providerId': kakaoId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginSuccess = data['loginSuccess'] == true; // 서버가 로그인 성공시 true 반환
        final exists = data['exists'] == true; // exists가 true면 가입된 사용자

        if (loginSuccess || exists) {
          final storage = FlutterSecureStorage();
          await storage.write(key: 'token', value: data['token']);
          await storage.write(key: 'userId', value: data['userId']);

          Navigator.pushReplacementNamed(context, '/main');
        } else {
          Navigator.pushNamed(context, '/signupAgree', arguments: {
            'provider': 'kakao',
            'providerId': kakaoId,
            'nickname': nickname,
            'email': '',
          });
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 로그인 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인에 실패했어요.')),
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

          Navigator.pushReplacementNamed(context, '/main');
        } else {
          Navigator.pushNamed(context, '/signupAgree', arguments: {
            'provider': 'google',
            'providerId': googleId,
            'nickname': nickname,
            'email': '', // email이 없으면 빈 문자열
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
