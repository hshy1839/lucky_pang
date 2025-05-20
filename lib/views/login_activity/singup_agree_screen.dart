import 'package:flutter/material.dart';
import '../../controllers/term_controller.dart'; // TermController 불러오기

class SignupAgreeScreen extends StatefulWidget {
  const SignupAgreeScreen({super.key});

  @override
  State<SignupAgreeScreen> createState() => _SignupAgreeScreenState();
}

class _SignupAgreeScreenState extends State<SignupAgreeScreen> {
  bool agree1 = false;
  bool agree2 = false;

  String term1Text = ''; // 서비스 이용약관
  String term2Text = ''; // 개인정보 처리방침
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTermsText();
  }

  Future<void> _loadTermsText() async {
    try {
      final serviceTerm = await TermController.getTermByCategory('serviceTerm');
      final privacyTerm = await TermController.getTermByCategory('privacyTerm');

      setState(() {
        term1Text = serviceTerm ?? '서비스 이용약관을 불러오지 못했습니다.';
        term2Text = privacyTerm ?? '개인정보처리방침을 불러오지 못했습니다.';
        isLoading = false;
      });
    } catch (e) {
      print('📛 약관 로딩 오류: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '약관 · 개인정보처리방침 동의',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 서비스 이용약관
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    term1Text,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87, height: 1.6),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: agree1,
                  onChanged: (value) {
                    setState(() {
                      agree1 = value ?? false;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  checkColor: Colors.white,
                ),
                const Text('동의합니다.'),
              ],
            ),
            const SizedBox(height: 16),

            // 개인정보 처리방침
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    term2Text,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87, height: 1.6),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: agree2,
                  onChanged: (value) {
                    setState(() {
                      agree2 = value ?? false;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  checkColor: Colors.white,
                ),
                const Text('동의합니다.'),
              ],
            ),
            const SizedBox(height: 16),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (agree1 && agree2)
                    ? () {
                  final args = ModalRoute.of(context)?.settings.arguments as Map?;
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamed(
                    '/signup',
                    arguments: {
                      'provider': args?['provider'] ?? '',
                      'providerId': args?['providerId'] ?? '',
                      'nickname': args?['nickname'] ?? '',
                      'email': args?['email'] ?? '',
                    },
                  );
                }
                    : null,



                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
