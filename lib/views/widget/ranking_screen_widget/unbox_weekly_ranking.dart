import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UnboxWeeklyRanking extends StatelessWidget {
  const UnboxWeeklyRanking({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        child: ListView(
      padding: EdgeInsets.only(bottom: 100.h),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('랭킹전 종료까지', style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('3D 13:02:21 🔥', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text('랭킹전 룰', style: TextStyle(fontSize: 13.sp)),
                        SizedBox(width: 4.w),
                        Icon(Icons.help_outline, size: 16.sp),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildUser(rank: '1위', name: '힘드네', amount: '73,289,720원 만큼 획득', point: '1,465,794 P', isFirst: true),
        _buildUser(rank: '2위', name: '크크크', amount: '39,956,850원 만큼 획득', point: '599,353 P'),
        _buildUser(rank: '3위', name: '큰것좀', amount: '25,533,320원 만큼 획득', point: '255,333 P'),
      ],
    ),
    );
  }

  Widget _buildUser({
    required String rank,
    required String name,
    required String amount,
    required String point,
    bool isFirst = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Container(
        decoration: BoxDecoration(
          color: isFirst ? Colors.white : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: isFirst
              ? [BoxShadow(color: Colors.black12, blurRadius: 6.r, offset: Offset(0, 2))]
              : [],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Text(rank, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          subtitle: Text(amount, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          trailing: Text(point, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
