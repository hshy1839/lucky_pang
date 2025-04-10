import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool showRealtimeLog = true;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      backgroundColor: const Color(0xFFFF5C43),
      body:
    SafeArea(
    child: Column(
        children: [
          SizedBox(height: 60.h),
          Icon(
            showRealtimeLog ? Icons.people : Icons.bar_chart,
            color: Colors.white,
            size: 40,
          ),
          SizedBox(height: 10.h),
          Text(
            showRealtimeLog ? '지금 언박싱하는 사람들' : '이번주 언박싱 랭킹',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            showRealtimeLog ? '최근 24시간' : '2025-04-06 - 2025-04-12',
            style: TextStyle(fontSize: 14.sp, color: Colors.white),
          ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildStatCard('언박싱 최고가', '216', '만원')),
                SizedBox(width: 8.w),
                Flexible(child: _buildStatCard('언박싱 횟수', '3.44', '천')),
                SizedBox(width: 8.w),
                Flexible(child: _buildStatCard('누적 최고가', '1', '천만원')),
              ],
            ),
          ),
          SizedBox(height: 30.h),
          Container(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTab('실시간 로그', showRealtimeLog),
                _buildTab('위클리 랭킹', !showRealtimeLog),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: showRealtimeLog
                  ? _buildRealtimeList()
                  : _buildWeeklyRanking(),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit) {
    return Container(
      width: 100.w,
      height: 120.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(unit, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          showRealtimeLog = label == '실시간 로그';
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: isSelected ? const Color(0xFFFF5C43) : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isSelected)
              Container(
                margin: EdgeInsets.only(top: 4.h),
                height: 2.h,
                width: 60.w,
                color: const Color(0xFFFF5C43),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeList() {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      children: [
        _buildUnboxItem(
          isHighlighted: true,
          profileName: '나도쥬라',
          productName: '[DIOR]소바쥬 오 드 퍼퓸 60ML',
          price: '정가 150,000원',
          boxPrice: '10,000원 박스',
          dateTime: '2025-04-10 00:06',
          image: 'https://via.placeholder.com/50',
        ),
        _buildUnboxItem(
          profileName: '또~또',
          productName: '[큐라덴]CTC202 Double Blade 혀클리너 (랜덤)',
          price: '정가 6,000원',
          boxPrice: '5,000원 박스',
          dateTime: '2025-04-10 09:23',
          image: 'https://via.placeholder.com/50',
        ),
        _buildUnboxItem(
          profileName: '또~또',
          productName: '[큐라덴]CTC202 Double Blade 혀클리너 (랜덤)',
          price: '정가 6,000원',
          boxPrice: '5,000원 박스',
          dateTime: '2025-04-10 09:23',
          image: 'https://via.placeholder.com/50',
        ),
      ],
    );
  }

  Widget _buildWeeklyRanking() {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
              ),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('랭킹전 종료까지', style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('2D 13:25:54 🔥',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text('랭킹전 룰', style: TextStyle(fontSize: 13.sp)),
                        SizedBox(width: 4.w),
                        Icon(Icons.help_outline, size: 16.sp),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildRankItem(
          rank: '1위',
          name: '폭삭속았수다🥲',
          amount: '192,786,040원 만큼 획득',
          point: '3,855,721 P',
          isFirst: true,
        ),
        _buildRankItem(
          rank: '2위',
          name: '큰것좀',
          amount: '62,903,860원 만큼 획득',
          point: '943,558 P',
        ),
      ],
    );
  }

  Widget _buildRankItem({
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
          color: isFirst ? const Color(0xFFFBE9E7) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: ListTile(
          leading: SizedBox(
            width: 40.w,
            child: Center(
              child: Text(
                rank,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: isFirst ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: isFirst ? Colors.redAccent : Colors.grey,
                radius: 16.r,
                child: Icon(Icons.person, color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                name,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          subtitle: Text(
            amount,
            style: TextStyle(fontSize: 12.sp, color: Colors.black54),
          ),
          trailing: Text(
            point,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildUnboxItem({
    required String profileName,
    required String productName,
    required String price,
    required String boxPrice,
    required String dateTime,
    required String image,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFFF5C43) : Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: isHighlighted
              ? []
              : [BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(image),
            radius: 24.r,
          ),
          title: Text(
            profileName,
            style: TextStyle(
              color: isHighlighted ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style: TextStyle(
                  color: isHighlighted ? Colors.white : Colors.black,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                price,
                style: TextStyle(
                  color: isHighlighted ? Colors.white70 : Colors.black54,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                boxPrice,
                style: TextStyle(
                  color: isHighlighted ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                dateTime,
                style: TextStyle(
                  color: isHighlighted ? Colors.white70 : Colors.black45,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
