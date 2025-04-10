import 'package:flutter/material.dart';
import '../../../controllers/notice_screen_controller.dart';
import 'notice_detail_screen.dart';

class NoticeScreen extends StatefulWidget {
  @override
  _NoticeScreenState createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  List<Map<String, String>> notices = [];
  final NoticeScreenController _controller = NoticeScreenController();

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    final fetchedNotices = await _controller.fetchNotices();
    setState(() {
      notices = fetchedNotices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '공지사항',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
      backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: notices.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                ListTile(
                  title: Text(
                    notices[index]['title']!,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    notices[index]['created_at']!,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoticeDetailScreen(
                          title: notices[index]['title']!,
                          date: notices[index]['created_at']!,
                          content: notices[index]['content']!,
                        ),
                      ),
                    );
                  },
                ),
                Divider(
                  color: Colors.grey[300],
                  thickness: 1.0,
                  height: 1.0,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
