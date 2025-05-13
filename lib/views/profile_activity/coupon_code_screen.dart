import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CouponCodeScreen extends StatefulWidget {
  const CouponCodeScreen({super.key});

  @override
  State<CouponCodeScreen> createState() => _CouponCodeScreenState();
}

class _CouponCodeScreenState extends State<CouponCodeScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _couponController.addListener(() {
      final isValid = _couponController.text.trim().length >= 2 &&
          _couponController.text.trim().length <= 12;
      if (_isButtonEnabled != isValid) {
        setState(() => _isButtonEnabled = isValid);
      }
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
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
          '쿠폰코드 입력',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30.h),
            Container(
              width: double.infinity,
              child: Image.asset(
                'assets/images/coupon_code_image.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 30.h),
            Text(
              '쿠폰번호를 입력하면 럭키박스를 받을 수 있어요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h,),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '   쿠폰코드 입력',
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
                    color: Color(0x1F000000), // #0000001F
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: TextField(
                controller: _couponController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '2~12자 쿠폰코드를 입력해 주세요',
                  hintStyle: TextStyle(
                    color: Color(0xFF8D969D),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(height: 36.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _isButtonEnabled
                    ? () {
                  // 실제 제출 처리 로직
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonEnabled
                      ? const Color(0xFFFF5C43)
                      : Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                ),
                child: Text(
                  '쿠폰코드 입력하기',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
