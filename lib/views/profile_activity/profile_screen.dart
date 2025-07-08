import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../controllers/point_controller.dart';
import '../../controllers/profile_screen_controller.dart';
import '../../controllers/shipping_controller.dart';
import '../../controllers/userinfo_screen_controller.dart';
import 'package:image_picker/image_picker.dart';

import '../../routes/base_url.dart';
import '../widget/endOfScreen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserInfoScreenController _controller = UserInfoScreenController();
  final PointController _pointController = PointController();
  final ProfileScreenController _profileController = ProfileScreenController();

  String nickname = '';
  int totalPoints = 0;
  String? profileImage = '';
  String createdAt = '';
  String referralCode = '';
  final ImagePicker _picker = ImagePicker();
  int shippingCount = 0;
  bool hasShipping = false;
  bool isLoading= false;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadUserPoints();
    loadShippingInfo();
  }

  Future<void> loadShippingInfo() async {
    setState(() {
      isLoading = true;
    });
    try {
      final list = await ShippingController.getUserShippings();
      setState(() {
        shippingCount = list.length;
        hasShipping = list.isNotEmpty;
      });
    } catch (_) {
      setState(() {
        shippingCount = 0;
        hasShipping = false;
        isLoading = false;
      });
    }
  }

  String formatJoinDate(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (_) {
      return '';
    }
  }

  Future<void> loadUserPoints() async {
    setState(() {
      isLoading = true;
    });
    final userId = await _pointController.storage.read(key: 'userId'); // ✅ userId 가져오기
    if (userId != null) {
      final points = await _pointController.fetchUserTotalPoints(userId);
      setState(() {
        totalPoints = points;
        isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await _profileController.uploadProfileImage(context, imageFile);
      _controller.clearCache();
      await loadUserInfo();
    }
  }

  Future<void> loadUserInfo() async {
    setState(() {
      isLoading = true;
    });
    await _controller.fetchUserInfo(context);
    setState(() {
      nickname = _controller.nickname;
      profileImage = _controller.profileImage;
      createdAt = _controller.createdAt;
      referralCode = _controller.referralCode;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = profileImage?.isNotEmpty == true ? '${BaseUrl.value}:7778/$profileImage' : null;
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            '내 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '내 정보',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            SizedBox(height: 16),

            // 🔵 프로필 사진
            GestureDetector(
              onTap: _pickAndUploadProfileImage,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
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
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade200,
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                          strokeWidth: 0.5,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.person, size: 60, color: Colors.grey.shade400),
                    ),
                  )
                      : Icon(Icons.person, size: 80, color: Colors.grey.shade400),

                ),



              ),
            ),


            SizedBox(height: 12),
            Text(nickname, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('가입일자: ${formatJoinDate(createdAt)}', style: TextStyle(fontSize: 12, color: Color(0xFF465461)
            )),

            SizedBox(height: 24),

            // 🔶 2 x 2 정보 박스
            Row(
              children: [
                Expanded(child: _infoBox(title: '보유 포인트', value: NumberFormat('#,###').format(totalPoints), valueColor: Color(0xFFFF5C43))),
                SizedBox(width: 12),
                Expanded(child: _infoBox(title: '친구 추천인 코드',value: referralCode.isNotEmpty ? referralCode : '-', valueColor: Color(0xFFFF5C43))),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _infoBox(title: '', value: '본인인증 완료', valueColor: Color(0xFF2EB520), border: true)),
                SizedBox(width: 12),
                Expanded(
                  child: _infoBox(
                    title: '',
                    value: hasShipping ? '배송지 등록완료' : '배송지 없음',
                    valueColor: hasShipping ? Color(0xFF2EB520) : Colors.red,
                    border: true,
                  ),
                ),
              ],
            ),

            SizedBox(height: 44),

            // 🔽 설정 리스트
            _menuItem('앱 설정', 'assets/icons/profile_icons/profile_setting_icon.svg', () => Navigator.pushNamed(context, '/setting')),
            _menuItem('내 포인트 내역', 'assets/icons/profile_icons/profile_point_icon.svg', () => Navigator.pushNamed(context, '/pointInfo')),
            _menuItem('배송지 관리', 'assets/icons/profile_icons/profile_shipping_icon.svg', () => Navigator.pushNamed(context, '/shippingInfo')),
            _menuItem('선물코드 입력', 'assets/icons/profile_icons/profile_gift_icon.svg', () => Navigator.pushNamed(context, '/giftCode')),
            _menuItem('쿠폰코드 입력', 'assets/icons/profile_icons/profile_coupon_icon.svg', () => Navigator.pushNamed(context, '/couponCode')),
            SizedBox(height: 82),
            EndOfScreen(),
            SizedBox(height: 102),
          ],
        ),
      ),
    );
  }

  Widget _infoBox({
    required String title,
    required String value,
    required Color valueColor,
    bool border = false,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFF0F1F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // 🔹 가운데 정렬
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              textAlign: TextAlign.center, // 🔹 텍스트 자체도 가운데 정렬
              style: TextStyle(fontSize: 12, color: Color(0xFF8D969D)),
            ),
          SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center, // 🔹 텍스트 자체도 가운데 정렬
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }


  Widget _menuItem(String title, String assetImagePath, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 10),
          leading: SvgPicture.asset(
            assetImagePath,
            width: 40,
            height: 40,
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w400)),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
          onTap: onTap,
        ),
      ],
    );
  }


}
