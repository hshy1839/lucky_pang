import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/giftcode_controller.dart'; // ✅ import 필요

class GiftCodeScreen extends StatefulWidget {
  const GiftCodeScreen({super.key});

  @override
  State<GiftCodeScreen> createState() => _GiftCodeScreenState();
}

class _GiftCodeScreenState extends State<GiftCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('코드를 입력해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    final result = await GiftCodeController.claimGiftCode(code);

    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? '성공')));
      Navigator.pop(context, true); // 🔥 중요: true를 반환해야 위에서 catch됨
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? '실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          '선물코드 입력',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 30.h),
            Container(
              width: 180.w,
              height: 180.w,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(40.r),
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.white, size: 100),
            ),
            SizedBox(height: 32.h),
            const Text(
              '어떤 선물이 기다리고 있을까요?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 48.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '선물코드 입력',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '예: ABCD1234',
                ),
              ),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C43),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                onPressed: _isLoading ? null : _submitCode,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('확인', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
