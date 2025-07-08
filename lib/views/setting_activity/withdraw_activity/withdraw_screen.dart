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
            SizedBox(height: 40),
            // 타이틀/로고/이모지 부분은 그대로
            Image.asset(
              'assets/icons/app_logo.png',
              width: 62,
              height: 62,
            ),
            const SizedBox(height: 20),
            const Text(
              '럭키탕 - 회원탈퇴',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
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
            SizedBox(height: 120),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '정말 떠나시나요..? ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
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
                    signupController.startBootpayAuth(
                      context,
                      onVerified: () {
                        Navigator.pushReplacementNamed(context, '/withdraw/agreement');
                      },
                    );
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
