import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider 패키지 import
import '../../../controllers/login/signup_controller.dart';

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 60),
            // 타이틀/로고/이모지 부분은 그대로

            SizedBox(height: 120),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '정말 떠나시나요..? ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text('😭', style: TextStyle(fontSize: 26)),
              ],
            ),
            SizedBox(height: 24),
            Text(
              '본인확인을 위해 휴대폰 번호를 인증합니다.',
              style: TextStyle(color: Colors.black54, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
            // "조금 더 생각해볼게요" 버튼
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF5722),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  '조금 더 생각해볼게요',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 24),

            // ✅ 회원탈퇴 버튼 (본인인증 연동)
            Consumer<SignupController>(
              builder: (context, signupController, child) {
                return InkWell(
                  onTap: () {
                    signupController.startBootpayAuth(context);
                  },
                  child: Text(
                    '회원탈퇴',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
