import 'package:flutter/material.dart';

class WithdrawAgreementScreen extends StatefulWidget {
  final VoidCallback onConfirm; // 실제 탈퇴 로직 콜백

  final String? termsText; // 서버에서 받아온 약관 문자열 (future get 적용 예정)

  const WithdrawAgreementScreen({
    super.key,
    required this.onConfirm,
    this.termsText,
  });

  @override
  State<WithdrawAgreementScreen> createState() => _WithdrawAgreementScreenState();
}

class _WithdrawAgreementScreenState extends State<WithdrawAgreementScreen> {
  bool _agree1 = false;
  bool _agree2 = false;

  @override
  Widget build(BuildContext context) {
    final terms = widget.termsText ??
        '여기에 회원탈퇴 약관이 들어갑니다.\n(서버 연동 전까지는 더미 텍스트)\n1. 탈퇴 후 정보 삭제\n2. 복구 불가\n3. 기타 등등...';

    final allAgreed = _agree1 && _agree2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('회원탈퇴 약관동의'),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text(
              '회원탈퇴 약관',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 180,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  terms,
                  style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.7),
                ),
              ),
            ),
            SizedBox(height: 24),

            CheckboxListTile(
              value: _agree1,
              onChanged: (v) => setState(() => _agree1 = v ?? false),
              title: Text('[필수] 회원탈퇴 약관에 동의합니다.'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: _agree2,
              onChanged: (v) => setState(() => _agree2 = v ?? false),
              title: Text('[필수] 탈퇴 후 데이터 삭제 및 복구 불가에 동의합니다.'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: allAgreed ? widget.onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: allAgreed ? Colors.red : Colors.grey[400],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
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
