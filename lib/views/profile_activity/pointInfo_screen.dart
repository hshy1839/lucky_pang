import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../controllers/point_controller.dart';
import '../../controllers/userinfo_screen_controller.dart';
import '../../routes/base_url.dart';

class PointInfoScreen extends StatefulWidget {
  const PointInfoScreen({super.key});

  @override
  State<PointInfoScreen> createState() => _PointInfoScreenState();
}

class _PointInfoScreenState extends State<PointInfoScreen> {
  String selectedTab = 'total';
  final PointController _pointController = PointController();
  final UserInfoScreenController _controller = UserInfoScreenController();

  String? profileImage = '';
  final storage = FlutterSecureStorage();
  String nickname = '';
  int totalPoints = 0;
  List<dynamic> pointLogs = [];

  @override
  void initState() {
    super.initState();
    loadData();
    loadUserInfo();
  }

  Future<void> loadData() async {
    final userId = await storage.read(key: 'userId');
    final token = await storage.read(key: 'token');

    if (userId == null || token == null) return;

    // 포인트 총합
    totalPoints = await _pointController.fetchUserTotalPoints(userId);

    // 포인트 내역
    final response = await http.get(
      Uri.parse('${BaseUrl.value}:7778/api/points/$userId'),
      headers: { 'Authorization': 'Bearer $token' },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      pointLogs = data['points'] ?? [];
    }

    setState(() {});
  }

  Future<void> loadUserInfo() async {
    await _controller.fetchUserInfo(context);
    setState(() {
      nickname = _controller.nickname;
      profileImage = _controller.profileImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    final String? imageUrl = profileImage?.isNotEmpty == true
        ? '${BaseUrl.value}:7778/$profileImage'
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          '현재 포인트 내역',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 상단 카드
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1121), Color(0xFF0D1121)],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6.r, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 프로필 이미지 + 닉네임
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                          image: (imageUrl != null && imageUrl.isNotEmpty)
                              ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                              : null,
                          boxShadow: [
                            // 오른쪽 위 방향 그림자 (주황색)
                            BoxShadow(
                              color: Color(0xFFFF5722),
                              offset: Offset(2, -2),
                              blurRadius: 0,
                              spreadRadius: 0,
                            ),
                            // 왼쪽 아래 방향 그림자 (보라색)
                            BoxShadow(
                              color: Color(0xFFC622FF),
                              offset: Offset(-2, 2),
                              blurRadius: 0,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? const FittedBox(
                          fit: BoxFit.cover,
                          child: Icon(Icons.person, color: Colors.grey),
                        )
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '$nickname 님',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // 🔹 잔여 포인트 텍스트 & 값
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '현재 잔여 포인트',
                        style: TextStyle(fontSize: 14.sp, color: Colors.white),
                      ),
                      Text(
                        NumberFormat('#,###').format(totalPoints) + ' P',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // 🔹 탭 선택
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 'total'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 'total' ? Theme.of(context).primaryColor : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '현재 포인트 내역',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedTab == 'total' ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 'scheduled'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 'scheduled' ? Theme.of(context).primaryColor : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '소멸예정 포인트',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedTab == 'scheduled' ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // 🔹 포인트 내역 리스트
            _buildPointList(),
          ],
        ),
      ),
    );
  }


  Widget _buildTabItem(String label, String key, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => selectedTab = key),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFFFFFF00) : Colors.transparent,
              width: 3.h,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
            color: selected ? Theme.of(context).primaryColor : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPointList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: pointLogs.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, i) {
        final item = pointLogs[i];
        final amount = int.tryParse(item['amount'].toString()) ?? 0;
        final isPlus = item['type'] == '추가' || item['type'] == '환불';

        final formattedAmount = NumberFormat('#,###').format(amount.abs());
        final formattedDate = item['createdAt']?.toString().substring(0, 19).replaceAll('T', ' ') ?? '';

        return Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['description'] ?? '-', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formattedDate, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
                  Text(
                    '${isPlus ? '+' : '-'}$formattedAmount P',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isPlus ? Colors.blue : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

}
