import 'package:flutter/material.dart';
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

  Widget _buildSocialButton(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all( // ✅ 테두리 추가
            color: Colors.grey.shade300,
            width: 1.5,
          ),
          image: DecorationImage(
            image: AssetImage(assetPath),
            fit: BoxFit.cover,
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
      appBar: AppBar(
        title: const Text(
          '회원가입 및 로그인',
          style: TextStyle(color: Colors.black,
          fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 0,
      ),
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

                  SizedBox(height: 10),
                  Image.asset(
                    'assets/icons/app_icon.jpg',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: 30),
                  Text(
                    '어서오세요, 뜨끈뜨끈 럭키탕',
                    style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10,),
                  Text(
                    '핫한 상품들이 기다리고있어요',
                    style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: 30,),
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
              SizedBox(height: 5),
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
              SizedBox(height: 50),
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
                  '시작하기',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
          ),
              SizedBox(height: 30),
              Text(
                '소셜 로그인',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 카카오톡 버튼
                  _buildSocialButton('assets/icons/kakao_icon.png', () {
                    loginController.loginWithKakao(context);  // ✅ 인스턴스로 호출
                  }),

                  SizedBox(width: 16),

                  // 구글 버튼
                  _buildSocialButton('assets/icons/google_icon.png', () {
                    loginController.loginWithGoogle(context);
                  }),

                  SizedBox(width: 16),

                  // 애플 버튼
                  _buildSocialButton('assets/icons/apple_icon.png', () {
                  }),
                ],
              ),
              SizedBox(height: 30,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/findEmail');
                    },
                    child: Text('이메일 찾기', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ),
                  Text('|', style: TextStyle(color: Colors.grey[400])),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/findPassword');
                    },
                    child: Text('비밀번호 찾기', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ),
                  Text('|', style: TextStyle(color: Colors.grey[400])),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signupAgree');
                    },
                    child: Text('회원가입', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
