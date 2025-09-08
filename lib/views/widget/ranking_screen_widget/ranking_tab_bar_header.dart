import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RankingTabBarHeader extends StatelessWidget {
  final bool isSelected;               // 실시간 로그 선택 여부
  final void Function(bool) onTap;
  final bool showMessage;              // "당첨을 축하드립니다!" 노출 여부

  const RankingTabBarHeader({
    super.key,
    required this.isSelected,
    required this.onTap,
    this.showMessage = true,           // 기본값: true (보이게)
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
        padding: EdgeInsets.only(top: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 탭 버튼
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

            // 👇 showMessage 가 true일 때만 노출
           SizedBox(height: 30,),
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
          borderRadius: BorderRadius.circular(10.r),
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
