import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(

        title: const Text(
          '설정',
          style: TextStyle(color: Colors.black),
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
          _buildListTile(context, title: '이용약관', route: '/terms'),
          _divider(),
          _buildListTile(context, title: '개인정보처리방침', route: '/privacy'),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required String title, required String route}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // ← 여기서 패딩 조절
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
