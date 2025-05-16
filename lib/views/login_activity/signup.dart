  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../../controllers/login/signup_controller.dart';

  class SignUpScreen extends StatefulWidget {
    const SignUpScreen({super.key});

    @override
    State<SignUpScreen> createState() => _SignUpScreenState();
  }

  class _SignUpScreenState extends State<SignUpScreen> {
    bool eventOptIn = false; // ✅ 이벤트 정보 수신 여부
    bool _isInitialized = false;

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();

      if (!_isInitialized) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        final signupController = Provider.of<SignupController>(context, listen: false);

        if (args != null) {
          signupController.provider = args['provider'] ?? 'local';
          signupController.providerId = args['providerId'] ?? '';
          signupController.nicknameController.text = args['nickname'] ?? '';
          signupController.emailController.text = args['email'] ?? '';
        }

        _isInitialized = true;
      }
    }

    @override
    Widget build(BuildContext context) {
      final signupController = Provider.of<SignupController>(context);

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('회원가입',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 36),
                _buildInputWithButton(
                  context,
                  '닉네임 (2~8자)',
                  signupController.nicknameController,
                  '중복검사',
                      () => signupController.checkNicknameDuplicate(context),
                  errorText: signupController.nicknameError,
                  isButtonEnabled: !signupController.nicknameChecked,
                ),
                const SizedBox(height: 36),
                if (signupController.provider == 'local') ...[
                  _buildInputWithButton(
                    context,
                    '이메일',
                    signupController.emailController,
                    '중복검사',
                        () => signupController.checkEmailDuplicate(context),
                    errorText: signupController.emailError,
                    isButtonEnabled: !signupController.emailChecked,
                  ),
                  const SizedBox(height: 36),
                  _buildTextField('비밀번호', signupController.passwordController, obscureText: true),
                  const SizedBox(height: 36),
                  _buildTextField('비밀번호 확인', signupController.confirmPasswordController, obscureText: true),
                ],

                const SizedBox(height: 36),
                _buildTextField('휴대폰 번호', signupController.phoneController),
                const SizedBox(height: 36),
                _buildInputWithButton(
                  context,
                  '추천인 코드',
                  signupController.referralCodeController,
                  '코드확인',
                      () => signupController.checkReferralCode(context),
                  errorText: signupController.referralCodeError,
                  isButtonEnabled: !signupController.referralCodeChecked,
                ),
                const SizedBox(height: 60),
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: eventOptIn,
                        onChanged: (value) {
                          setState(() {
                            eventOptIn = value ?? false;
                          });
                          signupController.eventAgree = value ?? false; // ✅ 동기화
                        },
                        activeColor: Theme.of(context).primaryColor,
                        checkColor: Colors.white,
                      ),
                    ),
                    const Text('이벤트 정보 받아보기 (선택)',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '럭키탕에 회원가입을 신청하시면 신청자는 만 14세 이상이며, 서비스 이용약관과 개인정보 수집 및 이용 동의 내용을 확인하고 동의한 것으로 간주합니다.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => signupController.submitData(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: const Text('가입완료',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildInputWithButton(
        BuildContext context,
        String hint,
        TextEditingController controller,
        String buttonText,
        VoidCallback onPressed, {
          String? errorText,
          bool isButtonEnabled = true,
        }) {
      final Color buttonColor =
      isButtonEnabled ? Theme.of(context).primaryColor : Colors.grey;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[200]!)),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isButtonEnabled ? onPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child:
                Text(buttonText, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          if (errorText != null && errorText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(errorText,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      );
    }

    Widget _buildTextField(String hint, TextEditingController controller,
        {bool obscureText = false}) {
      return TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!)),
        ),
      );
    }
  }
