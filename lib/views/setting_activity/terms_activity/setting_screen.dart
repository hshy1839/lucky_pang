import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[100],
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Column(

        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 50),
              children: [
                _buildListTile(context, title: '공지사항', route: '/notice'),
                _divider(),
                _buildListTile(context, title: '이벤트', route: '/event'),
                _divider(),
                _buildListTile(context, title: 'FAQ', route: '/faq'),
                _divider(),
                _buildListTile(context, title: '이용약관', route: '/serviceTerm'),
                _divider(),
                _buildListTile(context, title: '개인정보처리방침', route: '/privacy'),
              ],
            ),
          ),

          // 하단 버튼 영역
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 로그아웃 버튼
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _logout(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 회원탈퇴 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/withdraw');
                    },
                    child: const Text(
                      '회원탈퇴',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'token');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildListTile(BuildContext context, {required String title, required String route}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.black),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.grey[100], thickness: 8);
  }
}
