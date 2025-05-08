import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../controllers/order_screen_controller.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool showRealtimeLog = true;
  List<Map<String, dynamic>> unboxedOrders = [];
  int highestPrice = 0;

  @override
  void initState() {
    super.initState();
    fetchUnboxedLogs();
  }

  Future<void> fetchUnboxedLogs() async {
    final orders = await OrderScreenController.getAllUnboxedOrders();

    final now = DateTime.now();
    final startDate = showRealtimeLog
        ? now.subtract(const Duration(hours: 24))
        : now.subtract(const Duration(days: 6)); // 주간은 오늘 포함 7일

    final filteredOrders = orders.where((order) {
      final createdAtStr = order['createdAt'];
      if (createdAtStr == null) return false;

      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) return false;

      return createdAt.isAfter(startDate);
    }).toList();

    int maxPrice = 0;
    for (var order in filteredOrders) {
      final product = order['unboxedProduct']?['product'];
      final price = product?['price'] ?? 0;
      if (price > maxPrice) maxPrice = price;
    }

    setState(() {
      unboxedOrders = filteredOrders;
      highestPrice = maxPrice;
    });
  }



  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    String _twoDigits(int n) => n.toString().padLeft(2, '0');

    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 6));
    final dateFormat = "${weekAgo.year}-${_twoDigits(weekAgo.month)}-${_twoDigits(weekAgo.day)}"
        " - ${today.year}-${_twoDigits(today.month)}-${_twoDigits(today.day)}";

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
            showRealtimeLog ? '최근 24시간' : dateFormat,
            style: TextStyle(fontSize: 14.sp, color: Colors.white),
          ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildStatCard('언박싱 최고가', (highestPrice ~/ 10000).toString(), '만원')),
                SizedBox(width: 8.w),
                Flexible(
                  child: _buildStatCard('언박싱 횟수', unboxedOrders.length.toString(), '회'),
                ),

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
        fetchUnboxedLogs();
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
    if (unboxedOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      itemCount: unboxedOrders.length,
      itemBuilder: (context, index) {
        final order = unboxedOrders[index];
        final user = order['user'];
        final product = order['unboxedProduct']?['product'];
        final box = order['box'];
        final rawProfileImage = user?['profileImage'];
        final userProfileImage = rawProfileImage != null && rawProfileImage.isNotEmpty
            ? (rawProfileImage.startsWith('http')
            ? rawProfileImage
            : 'http://192.168.219.107:7778${rawProfileImage.startsWith('/') ? '' : '/'}$rawProfileImage')
            : null;
        
        return _buildUnboxItem(
          profileName: user?['nickname'] ?? '익명',
          userProfileImage: userProfileImage,
          productName: product?['name'] ?? '상품명 없음',
          price: '정가 ${(product?['price'] ?? 0).toString()}원',
          boxPrice: '${box?['price'] ?? 0}원 박스',
          dateTime: DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '')?.toLocal().toString().substring(0, 16) ?? '',
          image: product?['mainImage'] != null && product['mainImage'].isNotEmpty
              ? 'http://192.168.219.107:7778${product['mainImage']}'
              : 'https://via.placeholder.com/50',

        );
      },
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
                    Text('3D 13:02:21 🔥',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
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
        _buildWeeklyRankUser(
          rank: '1위',
          name: '힘드네',
          amount: '73,289,720원 만큼 획득',
          point: '1,465,794 P',
          isFirst: true,
        ),
        _buildWeeklyRankUser(
          rank: '2위',
          name: '크크크',
          amount: '39,956,850원 만큼 획득',
          point: '599,353 P',
        ),
        _buildWeeklyRankUser(
          rank: '3위',
          name: '큰것좀',
          amount: '25,533,320원 만큼 획득',
          point: '255,333 P',
        ),
      ],
    );
  }

  Widget _buildWeeklyRankUser({
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
              ? [BoxShadow(color: Colors.black12, blurRadius: 6.r, offset: const Offset(0, 2))]
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



  Widget _buildUnboxItem({
    required String profileName,
    required String productName,
    required String price,
    required String boxPrice,
    required String dateTime,
    required String image,
    String? userProfileImage,
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
          title: Row(
            children: [
              // 🔥 프로필 이미지 or 기본 아이콘
              userProfileImage != null && userProfileImage.isNotEmpty
                  ? CircleAvatar(
                radius: 12.r,
                backgroundImage: NetworkImage('$userProfileImage'),
              )
                  : const Icon(Icons.account_circle, size: 24, color: Colors.grey),

              SizedBox(width: 6.w),

              // 🔥 닉네임
              Expanded(
                child: Text(
                  profileName,
                  style: TextStyle(
                    color: isHighlighted ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
