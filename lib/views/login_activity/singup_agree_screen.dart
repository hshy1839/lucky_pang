import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignupAgreeScreen extends StatefulWidget {
  const SignupAgreeScreen({super.key});

  @override
  State<SignupAgreeScreen> createState() => _SignupAgreeScreenState();
}

class _SignupAgreeScreenState extends State<SignupAgreeScreen> {
  bool agree1 = false;
  bool agree2 = false;

  String term1Text = '';
  String term2Text = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTermsText();
  }

  Future<void> _loadTermsText() async {
    try {
      final term1 =
          await rootBundle.loadString('assets/terms/signup_term_1.txt');
      final term2 =
          await rootBundle.loadString('assets/terms/signup_term_2.txt');
      setState(() {
        term1Text = term1;
        term2Text = term2;
        isLoading = false;
      });
    } catch (e) {
      print('약관 로딩 중 오류 발생: $e');
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
                  // 첫 번째 약관
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

                  // 두 번째 약관
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
                        Navigator.pushNamed(context, '/signup',
                            arguments: ModalRoute.of(context)!.settings.arguments != null
                                ? {
                              'provider': (ModalRoute.of(context)!.settings.arguments as Map)['provider'],
                              'providerId': (ModalRoute.of(context)!.settings.arguments as Map)['providerId'],
                              'nickname': (ModalRoute.of(context)!.settings.arguments as Map)['nickname'] ?? '',
                              'email': (ModalRoute.of(context)!.settings.arguments as Map)['email'] ?? '',
                            }
                                : {});
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
