import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RankingTabBarHeader extends StatelessWidget {
  final bool isSelected;
  final void Function(bool) onTap;

  const RankingTabBarHeader({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15.r),
        topRight: Radius.circular(15.r),
      ),
      child: Container(
        color: Colors.white,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: 40.h), // ✅ 원래 값 유지
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 좌우 22.w 여백 + 버튼 간 16.w 간격 유지
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: Row(
                children: [
                  Expanded(
                    child: _tabButton(
                      context,
                      '실시간 로그',
                      isSelected,
                          () => onTap(true),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _tabButton(
                      context,
                      '위클리 랭킹',
                      !isSelected,
                          () => onTap(false),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 50.h), // ✅ 원래 간격 유지
            Text(
              "당첨을 축하드립니다!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [
                      Color(0xFFBF00FF), // 보라
                      Color(0xFFFF4081), // 핑크
                      Color(0xFFFF5722), // 주황
                    ],
                  ).createShader(Rect.fromLTWH(0.0, 0.0, 380.0, 70.0)),
              ),
            ),
            SizedBox(height: 0.h),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(
      BuildContext context,
      String label,
      bool selected,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF5722) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10.r), // ✅ 버튼 radius 유지
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
