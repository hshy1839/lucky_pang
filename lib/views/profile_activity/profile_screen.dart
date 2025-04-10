// ProfileScreen.dart 완전 이미지 동일 UI로 재작성

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('MY PAGE', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {
              Navigator.pushNamed(context, '/setting');
            },
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(height: 20.h),
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 60.r,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: AssetImage('assets/images/profile_placeholder.jpg'),
              ),
              Positioned(
                bottom: 0,
                right: MediaQuery.of(context).size.width / 2 - 60.r,
                child: Icon(Icons.edit, size: 20.sp, color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text('와딩', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Column(
            children: [
              Text('보유포인트', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
              SizedBox(height: 4.h),
              Text('52,000', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoundLabel(context, '인증완료', selected: true),
              SizedBox(width: 10.w),
              _buildRoundLabel(context, '친구코드 미등록', selected: false),
            ],
          ),
          SizedBox(height: 20.h),
          Divider(thickness: 1, color: Colors.grey.shade300),
          Expanded(
            child: ListView(
              children: [
                _buildListItem('내 포인트 내역', onTap: () {Navigator.pushNamed(context, '/pointInfo');}),
                _buildListItem('배송지 관리', onTap: () {Navigator.pushNamed(context, '/shippingInfo');}),
                _buildListItem('친구 초대하기', onTap: () {Navigator.pushNamed(context, '/recommend');}),
                _buildListItem('선물코드 입력', onTap: () {Navigator.pushNamed(context, '/giftCode');}),
                _buildListItem('쿠폰코드 입력', onTap: () {Navigator.pushNamed(context, '/couponCode');}),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('token');        // 토큰 삭제
                        await prefs.remove('isLoggedIn');   // 로그인 상태 삭제

                        // 로그인 화면으로 이동, 이전 페이지 스택 모두 제거
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                      child: Text('로그아웃', style: TextStyle(color: Colors.black)),
                    ),  SizedBox(width: 20.w),
                    TextButton(onPressed: () {}, child: Text('회원탈퇴', style: TextStyle(color: Colors.black)))
                  ],
                ),
                SizedBox(height: 100.h),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRoundLabel(BuildContext context, String text, {bool selected = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.grey,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildListItem(String title, {required VoidCallback onTap}) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
        Divider(thickness: 1, color: Colors.grey.shade300),
      ],
    );
  }
}