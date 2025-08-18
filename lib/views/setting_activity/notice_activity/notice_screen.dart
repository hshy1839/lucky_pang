import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../controllers/notice_screen_controller.dart';
import '../../widget/endOfScreen.dart';
import 'notice_detail_screen.dart';

class NoticeScreen extends StatefulWidget {
  @override
  _NoticeScreenState createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final NoticeScreenController _controller = NoticeScreenController();
  List<Map<String, dynamic>> notices = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    final result = await _controller.fetchNotices();
    setState(() {
      notices = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          '공지사항',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        backgroundColor: Colors.grey[100],
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
        body: ListView.separated(
          padding: const EdgeInsets.only(top: 30),
          itemCount: notices.length,
          separatorBuilder: (_, __) =>
              Divider(height: 10, color: Colors.grey[100], thickness: 5),
          itemBuilder: (context, index) {
            final notice = notices[index];

            Widget noticeItem = InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoticeDetailScreen(noticeId: notice['id']),
                  ),
                );
              },
              child: Container(
                color: Colors.white, // 각 항목 배경 흰색
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice['title'] ?? '',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '작성일자: ${notice['created_at'] ?? ''}',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '공지사항',
                          style: TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                        Spacer(), // 🔹 오른쪽 끝으로 밀기
                        SvgPicture.asset(
                          'assets/icons/smartphone_icon.svg',
                          width: 18,
                          height: 20,

                        ),
                        SizedBox(width: 4,)
                      ],
                    ),
                  ],
                ),
              ),
            );

            // 마지막 항목이라면 EndOfScreen 추가
            if (index == notices.length - 1) {
              return Column(
                children: [
                  noticeItem,
                  SizedBox(height: 50),
                  EndOfScreen(),
                ],
              );
            } else {
              return noticeItem;
            }
          },
        )

    );
  }
}
