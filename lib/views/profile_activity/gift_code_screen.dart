import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/giftcode_controller.dart';

class GiftCodeScreen extends StatefulWidget {
  const GiftCodeScreen({super.key});

  @override
  State<GiftCodeScreen> createState() => _GiftCodeScreenState();
}

class _GiftCodeScreenState extends State<GiftCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isInvalidCode = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      final isValid = _codeController.text.trim().length >= 7;
      if (_isButtonEnabled != isValid) {
        setState(() {
          _isButtonEnabled = isValid;
        });
      }
    });
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();

    if (code.length < 7) {
      setState(() => _isInvalidCode = true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isInvalidCode = false;
    });

    final result = await GiftCodeController.claimGiftCode(code);

    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? '성공')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? '실패')));
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30.h),
            Image.asset(
              'assets/images/present_image.png',
              width: double.infinity,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 30.h),
            Text(
              '선물코드를 입력하면 당첨된 상품을 받을 수 있어요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '    선물코드 입력',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF465461),
                ),
              ),
            ),
            SizedBox(height: 5.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '선물코드를 입력해 주세요',
                  hintStyle: TextStyle(
                    color: Color(0xFF8D969D),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (_isInvalidCode) ...[
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '쿠폰 번호는 최소 7자리 이상입니다',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
            SizedBox(height: 36.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: (_isButtonEnabled && !_isLoading) ? _submitCode : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonEnabled
                      ? const Color(0xFFFF5C43)
                      : Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                ),
                child: Text(
                  '선물코드 입력하기',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (_isLoading) ...[
              SizedBox(height: 16.h),
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

}

