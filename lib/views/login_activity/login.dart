import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../controllers/login/login_controller.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildSocialLoginButton({
    required String assetPath,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 300,
          height: 60,
          margin: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. 텍스트: 완전 중앙
              Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 2. 아이콘: 같은 위치에서 시작 + 수직 중앙
              Positioned(
                left: 24, // 모든 버튼에서 동일한 시작 위치
                top: 0,
                bottom: 0,
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }







  @override
  Widget build(BuildContext context) {
    final loginController = LoginController(context);

    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  SizedBox(height: 80),
                  Image.asset(
                    'assets/icons/app_icon.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: 30),
                  Text(
                    '당신의 행운을 테스트해보세요. 럭키탕',
                    style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10,),
                  Text(
                    '핫한 상품들이 기다리고있어요',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: 30,),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    '이메일',
                    style: TextStyle(fontSize: 13,  color: Colors.black),
                  ),
                ),
              ),

              SizedBox(height: 6),
              SizedBox(
                width: 350, // 원하는 너비 설정
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '이메일을 입력하세요',
                    labelStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12.0,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide(color: Colors.blue, width: 1),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    '비밀번호',
                    style: TextStyle(fontSize: 13,  color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 6),
        SizedBox(
          width: 350, // 원하는 너비 설정
          child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호를 입력하세요',
                  labelStyle: TextStyle(
                    color: Colors.grey[400], // ✅ 라벨 텍스트 색상
                    fontSize: 12.0,          //,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1),
                    borderRadius: BorderRadius.circular(20.0), // 포커스 됐을 때도 radius 적용
                  ),
                ),
              ),
        ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '럭키탕 회원이 아니신가요?',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signupAgree');
                    },
                    child: Text(
                      '회원가입',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 13,
                        decoration: TextDecoration.underline,             // ✅ 밑줄
                        decorationColor: Theme.of(context).primaryColor,  // ✅ 밑줄 색상 지정
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

          SizedBox(
            width: 350, // 원하는 너비 설정
            child: ElevatedButton(
                onPressed: () {
                  final username = _usernameController.text;
                  final password = _passwordController.text;
                  loginController.login(username, password);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,

                  minimumSize: Size(double.infinity, 56),
                ).copyWith(
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),  // 사각형으로 만들기 위해 radius를 0으로 설정
                    ),
                  ),
                ),

                child: Text(
                  '로그인',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
          ),
              SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/findEmail');
                    },
                    child: Text(
                      '이메일 찾기',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/findPassword');
                    },
                    child: Text(
                      '비밀번호 찾기',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140, // 왼쪽 선 길이
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey[500],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 140, // 오른쪽 선 길이
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),


              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 카카오톡 버튼
                  _buildSocialLoginButton(
                    assetPath: 'assets/icons/kakao_icon.svg',
                    text: '카카오 로그인',
                    onTap: () => loginController.loginWithKakao(context),
                  ),

                  SizedBox(width: 16),

                  // 구글 버튼
                  _buildSocialLoginButton(
                    assetPath: 'assets/icons/google_icon.svg',
                    text: '구글 로그인',
                    onTap: () => loginController.loginWithGoogle(context),
                  ),

                  SizedBox(width: 16),

                  // 애플 버튼
                  _buildSocialLoginButton(
                    assetPath: 'assets/icons/apple_icon.svg',
                    text: '애플 로그인',
                    onTap: () {},
                  ),
                ],
              ),

              SizedBox(height: 50,)
            ],
          ),
        ),
      ),
    );
  }
}


