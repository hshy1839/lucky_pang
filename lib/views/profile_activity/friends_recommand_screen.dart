import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/userinfo_screen_controller.dart';

class FriendsRecommendScreen extends StatefulWidget {
  @override
  State<FriendsRecommendScreen> createState() => _FriendsRecommendScreenState();
}

class _FriendsRecommendScreenState extends State<FriendsRecommendScreen> {
  final UserInfoScreenController _controller = UserInfoScreenController();
  String referralCode = '';

  @override
  void initState() {
    super.initState();
    fetchReferralCode();
  }

  Future<void> fetchReferralCode() async {
    await _controller.fetchUserInfo(context);
    setState(() {
      referralCode = _controller.referralCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(375, 812));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('친구 초대하기', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: BackButton(color: Colors.black),
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(height: 40.h),
          Image.asset(
            'assets/icons/friend_invite_icon.png',
            width: 120.w,
            height: 120.w,
          ),
          SizedBox(height: 20.h),
          Text('아, 딱 500원만 더 있으면 되는데..',
              style: TextStyle(fontSize: 14.sp, color: Colors.black)),
          SizedBox(height: 8.h),
          Text('공유하고 500P 나눠받기',
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          SizedBox(height: 40.h),
          Text('내 친구코드',
              style: TextStyle(fontSize: 14.sp, color: Colors.black)),
          SizedBox(height: 12.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 40.w),
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Text(
              referralCode.isNotEmpty ? referralCode : '불러오는 중...',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(height: 40.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Share.share(
                          '내 친구코드: $referralCode\n앱 다운로드하고 500P 받아봐!');
                    },
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/icons/kakao_icon.png',
                          width: 60.w,
                          height: 60.w,
                        ),
                        SizedBox(height: 8.h),
                        Text('카카오톡으로\n공유하기',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.sp)),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('친구코드가 복사되었습니다.'),
                      ));
                    },
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/icons/copy_icon.png',
                          width: 60.w,
                          height: 60.w,
                        ),
                        SizedBox(height: 8.h),
                        Text('친구코드만\n복사하기',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.sp)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
