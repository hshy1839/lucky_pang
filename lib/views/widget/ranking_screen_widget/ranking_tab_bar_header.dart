import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RankingTabBarHeader extends SliverPersistentHeaderDelegate {
  final bool isSelected;
  final void Function(bool) onTap;

  RankingTabBarHeader({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final scale = 1.0 - (0.3 * progress); // 크기 점점 줄이기 (선택 사항)
    final Shader linearGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        Color(0xFFC622FF),
        Color(0xFFFF5722),
      ],
    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));


    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15.r),
        topRight: Radius.circular(15.r),
      ),
      child: Container(
        color: Colors.white,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: 50.h),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tabButton(context, '실시간 로그', isSelected, () => onTap(true)),
                  SizedBox(width: 10.w),
                  _tabButton(context, '위클리 랭킹', !isSelected, () => onTap(false)),
                ],
              ),
              SizedBox(height: 40.h),

              Text(
                "당첨을 축하드립니다!",
                style:TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()..shader = linearGradient,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF5722) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 180.h;

  @override
  double get minExtent => 100.h;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
