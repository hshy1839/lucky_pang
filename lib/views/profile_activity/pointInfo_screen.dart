import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PointInfoScreen extends StatefulWidget {
  const PointInfoScreen({super.key});

  @override
  State<PointInfoScreen> createState() => _PointInfoScreenState();
}

class _PointInfoScreenState extends State<PointInfoScreen> {
  String selectedTab = 'total'; // 'total' or 'scheduled'

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 50.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LUCKY한',
                      style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('와딩 님!',
                      style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 12.h),
                  Text(
                    '현재 잔여 포인트는 57,000P 입니다.',
                    style: TextStyle(fontSize: 14.sp, color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabItem('전체 포인트 내역', 'total', selectedTab == 'total'),
                  SizedBox(width: 24.w),
                  _buildTabItem('소멸예정 포인트', 'scheduled', selectedTab == 'scheduled'),
                ],
              ),
            ),
            SizedBox(height: 8.h),
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
          textAlign: TextAlign.center,
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
    final items = [
      {
        'desc': '[한국문화재재단] 보자기문 나전소함 리필 포인트 환급',
        'date': '2025.04.10 10:32:20',
        'point': '+18,000 P',
        'color': Colors.redAccent
      },
      {
        'desc': '럭키박스 구매',
        'date': '2025.04.10 00:30:31',
        'point': '-5,000 P',
        'color': Colors.blue
      },
      {
        'desc': '[입상공간] 누워보게 에어베드 (1+1) 리필 포인트 환급',
        'date': '2025.04.10 00:30:19',
        'point': '+6,000 P',
        'color': Colors.redAccent
      },
      {
        'desc': '[카카오프렌즈] 세이치즈 심플 에코백 리필 포인트 환급',
        'date': '2025.04.10 00:30:16',
        'point': '+3,000 P',
        'color': Colors.redAccent
      },
      {
        'desc': '럭키박스 구매',
        'date': '2025.04.10 00:29:20',
        'point': '-10,000 P',
        'color': Colors.blue
      },
    ];

    return ListView.separated(
      padding: EdgeInsets.only(bottom: 16.h),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (_, i) => ListTile(
        title: Text(items[i]['desc'] as String, style: TextStyle(fontSize: 13.sp)),
        subtitle: Text(items[i]['date'] as String, style: TextStyle(fontSize: 11.sp)),
        trailing: Text(
          items[i]['point'] as String,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: (items[i]['point'] as String).startsWith('+') ? Colors.orange : Colors.blue,
          ),
        ),
      ),
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
      itemCount: items.length,
    );
  }
}
