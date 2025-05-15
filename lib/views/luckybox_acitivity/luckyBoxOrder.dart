import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class LuckyBoxOrderPage extends StatelessWidget {
  const LuckyBoxOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('구매완료',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '박스 결제가 완료되었어요!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    // 👉 박스 열기 로직 또는 페이지 이동
                    Navigator.pushNamed(context, '/unbox');
                  },
                  icon: const Icon(Icons.card_giftcard, size: 24),
                  label: const Text(
                    '바로 박스 열기',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    // 👉 보관함 페이지 이동
                    Navigator.pushNamed(context, '/storage');
                  },
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '보관함',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MainScreenWithFooter(initialTabIndex: 2),
                                ),
                              );
                            },
                        ),
                        const TextSpan(
                          text: '으로 가기',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
