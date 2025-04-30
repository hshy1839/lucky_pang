import 'package:flutter/material.dart';
import '../../../controllers/event_screen_controller.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({required this.eventId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = EventScreenController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('이벤트'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: controller.fetchEventById(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('이벤트를 불러오지 못했습니다.'));
          }

          final event = snapshot.data!;
          final List<dynamic> images = event['images'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // 제목
                Text(
                  event['title'] ?? '',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                // 날짜
                Text(
                  event['created_at'] ?? '',
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
                  event['content'] ?? '',
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
