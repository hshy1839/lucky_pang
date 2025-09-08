import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/login/signup_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // ✅ 간격 상수(전역 통일)
  static const double _sectionGap = 36;      // 섹션 ↔ 섹션
  static const double _fieldButtonGap = 10;  // 입력필드 ↔ 버튼

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final signup = Provider.of<SignupController>(context, listen: false);

    // 🔸 빌드 중 알림 방지: 초기화는 빌드가 끝난 뒤로 미뤄서 수행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      signup.reset(silent: true); // 컨트롤러 리스너 무시하고 초기화
      if (args is Map) {
        signup.applyRouteArgs(
          provider: (args['provider']?.toString().isEmpty ?? true) ? 'local' : args['provider'],
          providerId: args['providerId'] ?? '',
          nickname: args['nickname'] ?? '',
          email: args['email'] ?? '',
        );
      }
      signup.bindPasswordListenerOnce();
    });

    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final signup = Provider.of<SignupController>(context);

    // ✅ 구글/카카오도 이메일 섹션 보이도록
    final bool showsEmail =
        signup.provider == 'local' || signup.provider == 'kakao' || signup.provider == 'google';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 26),
              Image.asset('assets/icons/app_logo.png', width: 50, height: 50),
              const SizedBox(height: 20),
              const Text(
                '럭키탕 - 회원가입',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: _sectionGap),

              // 닉네임
              _buildInputWithButton(
                context,
                '닉네임 (2~8자)',
                signup.nicknameController,
                '중복검사',
                    () => signup.checkNicknameDuplicate(context),
                errorText: signup.nicknameError,
                successText: signup.nicknameSuccess,
                isButtonEnabled: !signup.nicknameChecked,
              ),
              const SizedBox(height: _sectionGap),

              // 이메일 (로컬/카카오/구글)
              if (showsEmail) ...[
                _buildInputWithButton(
                  context,
                  '이메일',
                  signup.emailController,
                  '중복검사',
                      () => signup.checkEmailDuplicate(context),
                  errorText: signup.emailError,
                  isButtonEnabled: !signup.emailChecked,
                ),
              ],

              // 비밀번호 (로컬만)
              if (signup.provider == 'local') ...[
                const SizedBox(height: _sectionGap),
                _buildTextField(
                  '비밀번호',
                  signup.passwordController,
                  obscureText: true,
                  hintText: '영문+숫자+특수문자 조합 8~16자리',
                  footerErrorText: signup.passwordError,
                ),
                const SizedBox(height: _sectionGap),
                _buildTextField(
                  '비밀번호 확인',
                  signup.confirmPasswordController,
                  obscureText: true,
                ),
              ],

              // ✅ 휴대폰 섹션 (본인인증 + 자동 중복검사 연동)
              const SizedBox(height: _sectionGap),
              _buildPhoneSection(context, signup),

              // 추천인 코드
              const SizedBox(height: _sectionGap),
              _buildInputWithButton(
                context,
                '추천인 코드',
                signup.referralCodeController,
                '코드확인',
                    () => signup.checkReferralCode(context),
                errorText: signup.referralCodeError,
                isButtonEnabled: !signup.referralCodeChecked,
              ),

              const SizedBox(height: 60),
              const Text(
                '럭키탕에 회원가입을 신청하시면 신청자는 만 14세 이상이며, 서비스 이용약관과 개인정보 수집 및 이용 동의 내용을 확인하고 동의한 것으로 간주합니다.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 34),

              // 가입완료 버튼
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => signup.submitData(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: const Text(
                    '가입완료',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------- UI Builders -------------------------------

  Widget _buildPhoneSection(BuildContext context, SignupController signup) {
    final buttonColor =
    signup.isPhoneVerified ? Colors.green : Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '휴대폰 번호',
          style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: _fieldButtonGap),

        // 🔹 본인인증 버튼만 남김 (인증 완료시 비활성화)
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: signup.isPhoneVerified
                ? null
                : () async {
              await signup.startBootpayAuth(
                context,
                onVerified: () async {
                  // 인증 성공 후 서버 중복 체크
                  final ok = await signup.checkPhoneDuplicate(context);
                  if (!ok) {
                    signup.isPhoneVerified = false;
                    signup.notifyListeners();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            signup.phoneError.isEmpty
                                ? '이미 가입된 휴대폰 번호입니다.'
                                : signup.phoneError,
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('본인인증 및 번호 확인이 완료되었습니다.')),
                      );
                    }
                  }
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              signup.isPhoneVerified ? '본인인증 완료' : '본인인증',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),

        // 로딩 인디케이터 (번호 중복 확인 중)
        if (signup.isCheckingPhone) ...[
          const SizedBox(height: 8),
          Row(
            children: const [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('번호 중복 확인 중...'),
            ],
          ),
        ],

        // 에러/성공 메시지
        if ((signup.phoneError).isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(signup.phoneError, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ] else if (signup.phoneChecked && !signup.phoneExists && signup.isPhoneVerified) ...[
          const SizedBox(height: 6),
          const Text('사용 가능한 번호입니다.', style: TextStyle(color: Colors.green, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildInputWithButton(
      BuildContext context,
      String label,
      TextEditingController controller,
      String buttonText,
      VoidCallback onPressed, {
        String? errorText,
        String? successText,
        bool isButtonEnabled = true,
      }) {
    final buttonColor = isButtonEnabled ? Theme.of(context).primaryColor : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(label, controller),
        const SizedBox(height: _fieldButtonGap), // 입력필드 ↔ 버튼
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: isButtonEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(buttonText, style: const TextStyle(color: Colors.white)),
          ),
        ),
        if ((errorText ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ] else if ((successText ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(successText!, style: const TextStyle(color: Colors.green, fontSize: 12)),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool obscureText = false,
        bool readOnly = false,
        Widget? suffix,
        String? hintText,
        String? footerErrorText,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF7F7F7) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            readOnly: readOnly,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              suffixIcon: suffix,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        if ((footerErrorText ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(footerErrorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ],
    );
  }
}
