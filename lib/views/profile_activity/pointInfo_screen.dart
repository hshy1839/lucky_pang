import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../controllers/point_controller.dart';
import '../../controllers/userinfo_screen_controller.dart';

class PointInfoScreen extends StatefulWidget {
  const PointInfoScreen({super.key});

  @override
  State<PointInfoScreen> createState() => _PointInfoScreenState();
}

class _PointInfoScreenState extends State<PointInfoScreen> {
  String selectedTab = 'total';
  final PointController _pointController = PointController();
  final UserInfoScreenController _controller = UserInfoScreenController();

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
      Uri.parse('http://172.30.1.22:7778/api/points/$userId'),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          '전체 포인트 내역',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 50.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LUCKY한', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('$nickname 님!', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 12.h),
                  Text('현재 잔여 포인트는 ${totalPoints.toString()}P 입니다.', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabItem('전체 포인트 내역', 'total', selectedTab == 'total'),
                SizedBox(width: 24.w),
                _buildTabItem('소멸예정 포인트', 'scheduled', selectedTab == 'scheduled'),
              ],
            ),
            Divider(height: 1, color: Colors.grey.shade300),
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
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
      itemBuilder: (_, i) {
        final item = pointLogs[i];
        final amount = int.tryParse(item['amount'].toString()) ?? 0;
        final isPlus = item['type'] == '추가' || item['type'] == '환불';

        return ListTile(
          title: Text(item['description'] ?? '-', style: TextStyle(fontSize: 13.sp)),
          subtitle: Text(item['createdAt']?.toString().substring(0, 19).replaceAll('T', ' ') ?? '', style: TextStyle(fontSize: 11.sp)),
          trailing: Text(
            '${isPlus ? '+' : '-'}${amount.toString()} P',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPlus ? Colors.orange : Colors.blue,
            ),
          ),
        );
      },
    );
  }
}
