import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/giftcode_controller.dart'; // 추가

class CreateGiftCodeScreen extends StatelessWidget {
  final String boxId; // 박스 ID 필요
  final String orderId;

  const CreateGiftCodeScreen({super.key, required this.boxId, required this.orderId,});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '선물하기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 40.h),
          Center(
            child: Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                color: Color(0xFFFF5C43),
                borderRadius: BorderRadius.circular(40.r),
              ),
              child: Center(
                child: Icon(Icons.card_giftcard, size: 120.sp, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            '럭키박스',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            '너에겐 어떤 행운이 등장할까?… 🥲',
            style: TextStyle(fontSize: 14.sp, color: Colors.black),
          ),
          SizedBox(height: 60.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF5C43),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
                minimumSize: Size(double.infinity, 56.h),
              ),
              icon: Icon(Icons.confirmation_num_outlined, color: Colors.white),
              label: Text(
                '선물코드 생성하기',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              onPressed: () async {
                final code = await GiftCodeController.createGiftCode(type: 'box', boxId: boxId, orderId: orderId,);
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('선물 코드'),
                      content: Text(code != null ? '생성된 코드: $code' : '코드 생성에 실패했습니다.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인'),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
