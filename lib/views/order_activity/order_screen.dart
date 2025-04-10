import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderScreen extends StatefulWidget {
  final void Function(int)? onTabChanged;
  final PageController? pageController;

  const OrderScreen({super.key, this.pageController, this.onTabChanged});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String selectedTab = 'box'; // 'box', 'product', 'delivery'

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTab('박스 보관함', selectedTab == 'box', 'box'),
                  _buildTab('상품 보관함', selectedTab == 'product', 'product'),
                  _buildTab('배송 조회', selectedTab == 'delivery', 'delivery'),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            if (selectedTab == 'product') ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    Checkbox(value: false, onChanged: (_) {}),
                    Text('전체 0개'),
                    SizedBox(width: 12.w),
                    Text('0개 선택'),
                    Spacer(),
                    Text('일괄환급하기',
                        style: TextStyle(color: Colors.grey.shade400)),
                  ],
                ),
              ),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 40.h),
              Image.asset(
                'assets/icons/app_icon.jpg',
                width: 160.w,
                height: 160.w,
              ),
              SizedBox(height: 24.h),
              Text(
                '보유한 상품이 없어요',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 80.h),
              Text(
                '특별한 상품들이 와딩 님을 기다리고 있어요.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 40.h),
              _buildMainButton(
                title: '선물코드 입력하기',
                icon: Icons.confirmation_number,
                onTap: () {},
              ),
            ] else ...[
              Text('0개', style: TextStyle(fontSize: 14.sp)),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 40.h),
              Image.asset(
                'assets/icons/app_icon.jpg',
                width: 160.w,
                height: 160.w,
              ),
              SizedBox(height: 24.h),
              Text(
                '보유한 럭키박스가 없어요',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 80.h),
              Text(
                '특별한 상품들이 와딩 님을 기다리고 있어요.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 40.h),
              _buildMainButton(
                title: '럭키박스 구매하기',
                icon: Icons.card_giftcard,
                onTap: () {
                  widget.onTabChanged?.call(4);
                  widget.pageController?.jumpToPage(4);
                },
              ),
              SizedBox(height: 16.h),
              _buildMainButton(
                title: '선물코드 입력하기',
                icon: Icons.confirmation_number,
                onTap: () {},
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, String key) {
    final textStyle = TextStyle(
      fontSize: 14.sp,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    final underlineWidth = _textWidth(label, textStyle);

    return GestureDetector(
      onTap: () => setState(() => selectedTab = key),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24.h, // ✅ 텍스트 높이 + 여유 공간 고정
            child: Center(
              child: Text(label, style: textStyle),
            ),
          ),
          SizedBox(height: 4.h),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: isSelected ? underlineWidth : 0,
            height: 2.h,
            color: isSelected ? Colors.black : Colors.transparent,
          ),
        ],
      ),
    );
  }
  double _textWidth(String text, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.size.width;
  }

  Widget _buildMainButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5C43),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          onPressed: onTap,
          label: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          icon: Icon(icon, size: 20.sp, color: Colors.white),
        ),
      ),
    );
  }
}
