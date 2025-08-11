import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widget/endOfScreen.dart'; // 🔹 EndOfScreen import
import '../../../controllers/event_screen_controller.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({required this.eventId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = EventScreenController();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: const Text('이벤트'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: controller.fetchEventById(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('이벤트를 불러오지 못했습니다.'));
          }

          final event = snapshot.data!;
          final List<dynamic> images = event['images'] ?? [];

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // 상단: 제목 ~ 날짜/아이콘 (흰색)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '작성일자: ${event['created_at'] ?? ''}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '이벤트',
                          style: TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                        const Spacer(),
                        SvgPicture.asset(
                          'assets/icons/event_icon.svg',
                          width: 30,
                          height: 32,
                        ),
                        const SizedBox(width: 18),
                      ],
                    ),
                  ],
                ),
              ),

              // 회색 구분 띠
              Container(height: 10, color: Colors.grey[100]),

              // 내용 영역 (흰색)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
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
                      event['content'] ?? '',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),

              // 🔹 EndOfScreen
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
