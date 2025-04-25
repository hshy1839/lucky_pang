import 'package:flutter/material.dart';
import '../../../controllers/notice_screen_controller.dart';

class NoticeDetailScreen extends StatelessWidget {
  final String noticeId;

  const NoticeDetailScreen({required this.noticeId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = NoticeScreenController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('공지사항'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: controller.fetchNoticeById(noticeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('공지사항을 불러오지 못했습니다.'));
          }

          final notice = snapshot.data!;
          final List<dynamic> images = notice['images'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // 제목
                Text(
                  notice['title'] ?? '',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                // 날짜
                Text(
                  notice['created_at'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                // 이미지
                if (images.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Column(
                    children: images.map<Widget>((imgUrl) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // 내용
                SizedBox(height: 20),
                Text(
                  notice['content'] ?? '',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
