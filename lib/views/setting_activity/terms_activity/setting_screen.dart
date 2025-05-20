import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildListTile(context, title: '공지사항', route: '/notice'),
          _divider(),
          _buildListTile(context, title: '이벤트', route: '/event'),
          _divider(),
          _buildListTile(context, title: '알림 설정', route: '/notifications'),
          _divider(),
          _buildListTile(context, title: 'FAQ', route: '/faq'),
          _divider(),
          _buildListTile(context, title: '이용약관', route: '/serviceTerm'),
          _divider(),
          _buildListTile(context, title: '개인정보처리방침', route: '/privacy'),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _logout(context),
                child: const Text('로그아웃', style: TextStyle(color: Colors.black)),
              ),
              SizedBox(width: 20),
              TextButton(
                onPressed: () {},
                child: const Text('회원탈퇴', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'token'); // 🔑 토큰 삭제

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // 👤 로그인 상태 초기화

    // 원하면 로그인 화면으로 이동하거나 이전 화면으로 pop
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildListTile(BuildContext context, {required String title, required String route}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.black),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.grey[300]);
  }
}
