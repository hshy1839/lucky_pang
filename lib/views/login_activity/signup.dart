import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/login/signup_controller.dart';
import '../../views/login_activity/login.dart';

class SignUpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignupController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            '',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '회원가입',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 60),

                // 아이디 입력 필드
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return TextField(
                      controller: controller.usernameController,
                      decoration: InputDecoration(
                        labelText: '아이디',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),

                // 비밀번호 입력 필드
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return TextField(
                      controller: controller.passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),

                // 비밀번호 확인 입력 필드
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return TextField(
                      controller: controller.confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '비밀번호 확인',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),

                // 이름 입력 필드
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return TextField(
                      controller: controller.nameController,
                      decoration: InputDecoration(
                        labelText: '이름',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),

                // 전화번호 입력 필드
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return TextField(
                      controller: controller.phoneController,
                      decoration: InputDecoration(
                        labelText: '전화번호',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),

                // 주소 입력 필드


                // 상세 주소 입력 필드

                SizedBox(height: 24),

                // 회원가입 버튼
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return ElevatedButton(
                      onPressed: () {
                        controller.submitData(context);
                      },
                      child: Text(
                        '회원가입',
                        style: TextStyle(color: Colors.white),  // 텍스트 색을 흰색으로 설정
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,  // 배경색을 검은색으로 설정
                        minimumSize: Size(double.infinity, 70),  // 버튼 크기 설정
                      ).copyWith(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,  // 사각형 모양으로 설정
                          ),
                        ),
                      ),
                    );

                  },
                ),
                SizedBox(height: 16),

                // 로그인 화면으로 이동하는 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text('이미 계정이 있으신가요? 로그인',  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent, )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
