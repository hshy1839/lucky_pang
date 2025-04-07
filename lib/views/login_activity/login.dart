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

  @override
  Widget build(BuildContext context) {
    final loginController = LoginController(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 150),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(height: 30),
                  Text(
                    'Alice',
                    style: TextStyle(color: Colors.black, fontSize: 50, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),
                  Text(
                    '쉽고 빠르게',
                    style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '쇼핑하세요',
                    style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 100),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '아이디',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final username = _usernameController.text;
                  final password = _passwordController.text;
                  loginController.login(username, password);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 56),
                ).copyWith(
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,  // 사각형으로 만들기 위해 radius를 0으로 설정
                    ),
                  ),
                ),
                child: Text(
                  '로그인',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,  // 배경색을 흰색으로 설정
                  minimumSize: Size(double.infinity, 56),
                ).copyWith(
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,  // 사각형 모양으로 설정
                    ),
                  ),
                ),
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    color: Colors.white,  // 텍스트 색을 검은색으로 설정
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
