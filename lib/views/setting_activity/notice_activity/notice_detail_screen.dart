import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../controllers/notice_screen_controller.dart';
import '../../widget/endOfScreen.dart'; // ✅ 추가

class NoticeDetailScreen extends StatelessWidget {
  final String noticeId;

  const NoticeDetailScreen({required this.noticeId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = NoticeScreenController();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: const Text('공지사항'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: controller.fetchNoticeById(noticeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('공지사항을 불러오지 못했습니다.'));
          }

          final notice = snapshot.data!;
          final List<dynamic> images = notice['images'] ?? [];

          return ListView(
            children: [
              // 제목 ~ 날짜/아이콘 영역
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '작성일자: ${notice['created_at'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '공지사항',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                        const Spacer(),
                        SvgPicture.asset(
                          'assets/icons/smartphone_icon.svg',
                          width: 18,
                          height: 20,
                        ),
                        const SizedBox(width: 18),
                      ],
                    ),
                  ],
                ),
              ),

              // 회색 구분선
              Container(height: 10, color: Colors.grey[100]),

              // 내용 영역
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (images.isNotEmpty) ...[
                      Column(
                        children: images.map<Widget>((imgUrl) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      notice['content'] ?? '',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),

              // 🔹 마지막에 EndOfScreen 추가
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(child: EndOfScreen()),
              ),
            ],
          );
        },
      ),
    );
  }
}
