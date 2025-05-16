import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleLoginWidget extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const GoogleLoginWidget({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  _GoogleLoginWidgetState createState() => _GoogleLoginWidgetState();
}

class _GoogleLoginWidgetState extends State<GoogleLoginWidget> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // 로그인 취소
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      // ✅ SecureStorage에 저장
      await secureStorage.write(key: 'isLoggedIn', value: 'true');
      await secureStorage.write(key: 'token', value: googleAuth.idToken ?? '');

      widget.onLoginSuccess();
    } catch (e) {
      print('❌ 로그인 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인 실패: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? CircularProgressIndicator()
        : ElevatedButton.icon(
      onPressed: _signInWithGoogle,
      icon: Icon(Icons.login),
      label: Text("Google로 로그인"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }
}
