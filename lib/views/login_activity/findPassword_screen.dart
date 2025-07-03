import 'package:flutter/material.dart';

import '../../controllers/login/reset_password_controller.dart';

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100), // 너무 위에 붙지 않게
              Column(
                children: [
                  Image.asset(
                    'assets/icons/app_logo.png',
                    width: 72,
                    height: 72,
                  ),
                  SizedBox(height: 20),
                  Text(
                    '럭키탕 - 비밀번호 찾기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Color(0xFFFF5722),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 38),
                  Text(
                    '가입할 때 입력하신 이메일로\n인증코드를 보내드릴게요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: '이메일을 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    if (email.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('입력 필요'),
                          content: Text('이메일을 입력해주세요.'),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _isLoading = true;
                    });

                    await ResetPasswordController.sendTemporaryPassword(
                      email: email,
                      context: context,
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '비밀번호 찾기',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30,),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor, // primary 컬러 적용
                  ),
                ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
