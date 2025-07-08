import 'package:flutter/material.dart';
import '../../../controllers/term_controller.dart';
import '../../../controllers/userinfo_screen_controller.dart';

class WithdrawAgreementScreen extends StatefulWidget {
  const WithdrawAgreementScreen({super.key});

  @override
  State<WithdrawAgreementScreen> createState() => _WithdrawAgreementScreenState();
}

class _WithdrawAgreementScreenState extends State<WithdrawAgreementScreen> {
  bool _agree1 = false;
  bool _agree2 = false;
  bool _withdrawing = false;
  late final UserInfoScreenController _userInfoController; // ✅ 선언
  Future<String?>? _withdrawalTermFuture;

  @override
  void initState() {
    super.initState();
    _userInfoController = UserInfoScreenController(); // ✅ 인스턴스 생성
    _withdrawalTermFuture = TermController.getTermByCategory('withdrawal');
  }

  Future<void> _handleWithdraw() async {
    setState(() => _withdrawing = true);

    final result = await _userInfoController.withdrawUser(context); // ✅ 실제 탈퇴 API 호출

    setState(() => _withdrawing = false);

    if (result && mounted) {
      // (필요하면 토큰 삭제 등도 여기서)
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final allAgreed = _agree1 && _agree2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('회원탈퇴 약관동의', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [

            const Text(
              '회원탈퇴 약관',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<String?>(
              future: _withdrawalTermFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 160,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return Container(
                    height: 160,
                    alignment: Alignment.center,
                    child: const Text('약관을 불러올 수 없습니다.', style: TextStyle(color: Colors.red)),
                  );
                }
                return Container(
                  constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      snapshot.data!,
                      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.7),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            CheckboxListTile(
              value: _agree1,
              onChanged: (v) => setState(() => _agree1 = v ?? false),
              title: const Text('[필수] 회원탈퇴 약관에 동의합니다.'),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.black,
              checkColor: Colors.white,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _agree2,
              onChanged: (v) => setState(() => _agree2 = v ?? false),
              title: const Text('[필수] 탈퇴 후 데이터 삭제 및 복구 불가에 동의합니다.'),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.black,
              checkColor: Colors.white,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: allAgreed && !_withdrawing ? _handleWithdraw : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: allAgreed ? Colors.red : Colors.grey[400],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _withdrawing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '탈퇴하기',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
