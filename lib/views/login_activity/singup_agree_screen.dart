import 'package:flutter/material.dart';
import '../../controllers/term_controller.dart';

class SignupAgreeScreen extends StatefulWidget {
  const SignupAgreeScreen({super.key});

  @override
  State<SignupAgreeScreen> createState() => _SignupAgreeScreenState();
}

class _SignupAgreeScreenState extends State<SignupAgreeScreen> {
  // 필수
  bool agreeAge14 = false;
  bool agreeService = false;
  bool agreePrivacy = false;

  // 선택
  bool agreeSystemPush = false;
  bool agreeEventAds = false;
  bool agreeMarketingAll = false;

  // 전체
  bool agreeAll = false;

  // 약관 본문
  bool isLoading = true;
  String serviceTermText = '';
  String privacyTermText = '';

  Color get _primary => Theme.of(context).primaryColor;
  TextStyle get _smallGray =>
      const TextStyle(fontSize: 11, color: Color(0xFF777777), height: 1.4);

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
        serviceTermText = serviceTerm ?? '서비스 이용약관을 불러오지 못했습니다.';
        privacyTermText = privacyTerm ?? '개인정보 처리방침을 불러오지 못했습니다.';
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  bool get _requiredChecked => agreeAge14 && agreeService && agreePrivacy;

  void _toggleAll(bool v) {
    setState(() {
      agreeAll = v;
      agreeAge14 = v;
      agreeService = v;
      agreePrivacy = v;
      agreeSystemPush = v;
      agreeEventAds = v;
      agreeMarketingAll = v;
    });
  }

  void _recomputeAll() {
    final all = _requiredChecked &&
        agreeSystemPush &&
        agreeEventAds &&
        agreeMarketingAll;
    setState(() => agreeAll = all);
  }

  void _showTermSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Text(content,
                        style: const TextStyle(fontSize: 13, height: 1.6)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('닫기',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _titleArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text('회원가입 약관 동의',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(
          '세 가지 필수 항목에 동의해야만 회원가입이 가능하며, 동의하지 않을 시 서비스 이용이 제한됩니다.',
          style: _smallGray,
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _allAgreeTile() {
    return InkWell(
      onTap: () => _toggleAll(!agreeAll),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              agreeAll ? Icons.check_circle : Icons.radio_button_unchecked,
              color: agreeAll ? _primary : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('전체 동의(선택 정보 포함)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line() =>
      Divider(height: 20, thickness: 1, color: Colors.grey.shade200);

  Widget _agreeRow({
    required bool value,
    required void Function(bool v) onChanged,
    required String label,
    required String tagText,
    bool showDetail = false,
    VoidCallback? onDetail,
    String? description,
  }) {
    final isRequired = tagText.contains('필수');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            onChanged(!value);
            _recomputeAll();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  value ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: value ? _primary : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isRequired
                        ? const Color(0xFFFFEFEF)
                        : const Color(0xFFEFF5FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '[$tagText]',
                    style: TextStyle(
                      color: isRequired
                          ? _primary
                          : const Color(0xFF2C6AE4),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600))),
                if (showDetail)
                  TextButton(
                    onPressed: onDetail,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('자세히',
                        style: TextStyle(
                            decoration: TextDecoration.underline)),
                  ),
              ],
            ),
          ),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(left: 30, bottom: 8),
            child: Text(description, style: _smallGray),
          ),
        _line(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    print('🟨 [SignupAgree] args: $args');

    return Scaffold(
      appBar: AppBar(
        title: const Text('약관 · 개인정보처리방침 동의',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(
            children: [
              _titleArea(),
              _allAgreeTile(),
              _line(),

              _agreeRow(
                value: agreeAge14,
                onChanged: (v) => setState(() => agreeAge14 = v),
                label: '만 14세 이상입니다',
                tagText: '필수',
              ),
              _agreeRow(
                value: agreeService,
                onChanged: (v) => setState(() => agreeService = v),
                label: '서비스 이용약관 동의',
                tagText: '필수',
                showDetail: true,
                onDetail: () =>
                    _showTermSheet('서비스 이용약관', serviceTermText),
              ),
              _agreeRow(
                value: agreePrivacy,
                onChanged: (v) => setState(() => agreePrivacy = v),
                label: '개인정보 수집 및 이용 동의',
                tagText: '필수',
                showDetail: true,
                onDetail: () =>
                    _showTermSheet('개인정보 처리방침', privacyTermText),
                description:
                '목적: 서비스 가입, 계약체결, 회원관리\n항목: 이메일(아이디), 비밀번호\n보유기간: 회원탈퇴 시까지 (관계법령에 따라 별도 보관 가능)',
              ),
              _agreeRow(
                value: agreeSystemPush,
                onChanged: (v) => setState(() => agreeSystemPush = v),
                label: '시스템 알림 동의',
                tagText: '선택',
              ),
              _agreeRow(
                value: agreeEventAds,
                onChanged: (v) => setState(() => agreeEventAds = v),
                label: '이벤트 광고 알림 동의',
                tagText: '선택',
              ),
              _agreeRow(
                value: agreeMarketingAll,
                onChanged: (v) => setState(() => agreeMarketingAll = v),
                label: '마케팅정보 수신동의',
                tagText: '선택',
                description:
                'Email과 SMS를 통한 마케팅 정보 수신에 동의합니다.\n수신 거부 시에도 서비스 관련 공지는 발송됩니다.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _requiredChecked
                      ? () {
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamed(
                      '/signup',
                      arguments: {
                        'provider': args?['provider'] ?? '',
                        'providerId': args?['providerId'] ?? '',
                        'nickname': args?['nickname'] ?? '',
                        'email': args?['email'] ?? '',
                        'kakaoFlags': args?['kakaoFlags'],
                        'agreements': {
                          'age14': agreeAge14,
                          'serviceTerm': agreeService,
                          'privacyTerm': agreePrivacy,
                          'systemPush': agreeSystemPush,
                          'eventAds': agreeEventAds,
                          'marketingAll': agreeMarketingAll,
                          'agreedAt': DateTime.now()
                              .toIso8601String(),
                        },
                      },
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _requiredChecked ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('확인',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
