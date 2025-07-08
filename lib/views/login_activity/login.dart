import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../controllers/login/login_controller.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(LoginController controller) async {
    if (_isLoading) return; // debounce
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      await controller.login(username, password);
      // 로그인 성공시 자동 이동, 실패시 에러처리 내부에서
    } catch (e) {
      // 에러 핸들링 (스낵바 등)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), style: TextStyle(color: Colors.white))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginController = LoginController(context);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고
                const SizedBox(height: 80),
                Image.asset(
                  'assets/icons/app_logo.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),
                const Text(
                  '당신의 행운을 테스트해보세요. 럭키탕',
                  style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  '핫한 상품들이 기다리고있어요',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),

                // 이메일 입력
                _LoginField(
                  controller: _usernameController,
                  label: '이메일',
                  hint: '이메일을 입력하세요',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),

                // 비밀번호 입력
                _LoginField(
                  controller: _passwordController,
                  label: '비밀번호',
                  hint: '비밀번호를 입력하세요',
                  obscureText: true,
                ),
                const SizedBox(height: 26),

                // 회원가입/로그인 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('럭키탕 회원이 아니신가요?', style: TextStyle(color: Colors.black87, fontSize: 13)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signupAgree'),
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: 350,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _handleLogin(loginController),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text(
                      '로그인',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 이메일/비번 찾기
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/findEmail'),
                      child: const Text('이메일 찾기',
                        style: TextStyle(color: Colors.black, fontSize: 14, decoration: TextDecoration.underline),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/findPassword'),
                      child: const Text('비밀번호 찾기',
                        style: TextStyle(color: Colors.black, fontSize: 14, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // or 구분선
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Flexible(child: Divider(thickness: 1, color: Colors.grey)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                    const Flexible(child: Divider(thickness: 1, color: Colors.grey)),
                  ],
                ),

                const SizedBox(height: 20),

                // 소셜 로그인 버튼
                _SocialLoginButton(
                  assetPath: 'assets/icons/kakao_icon.svg',
                  text: '카카오 로그인',
                  onTap: _isLoading ? null : () => loginController.loginWithKakao(context),
                ),
                const SizedBox(height: 12),
                _SocialLoginButton(
                  assetPath: 'assets/icons/google_icon.svg',
                  text: '구글 로그인',
                  onTap: _isLoading ? null : () => loginController.loginWithGoogle(context),
                ),
                const SizedBox(height: 12),
                _SocialLoginButton(
                  assetPath: 'assets/icons/apple_icon.svg',
                  text: '애플 로그인',
                  onTap: _isLoading ? null : () {}, // 추후 연결
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 입력 필드 따로 빼기
class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 6),
          child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black)),
        ),
        SizedBox(
          width: 350,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: hint,
              labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12.0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.blue, width: 1),
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 소셜 로그인 버튼 위젯
class _SocialLoginButton extends StatelessWidget {
  final String assetPath;
  final String text;
  final VoidCallback? onTap;
   _SocialLoginButton({
    required this.assetPath,
    required this.text,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 300,
          height: 56,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SvgPicture.asset(assetPath, width: 24, height: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
