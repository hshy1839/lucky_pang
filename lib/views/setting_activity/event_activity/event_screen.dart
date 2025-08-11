import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../widget/endOfScreen.dart'; // ✅ 추가
import '../../../controllers/event_screen_controller.dart';
import 'event_detail_screen.dart';

class EventScreen extends StatefulWidget {
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final EventScreenController _controller = EventScreenController();
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final result = await _controller.fetchEvents();
    setState(() {
      events = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          '이벤트',
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
        itemCount: events.length + 1, // ✅ EndOfScreen 위해 +1
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.grey[100],
          thickness: 8,
        ),
        itemBuilder: (context, index) {
          // ✅ 마지막에 EndOfScreen 추가
          if (index == events.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: EndOfScreen()),
            );
          }

          final event = events[index];

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(eventId: event['id']),
                ),
              );
            },
            child: Container(
              color: Colors.white, // 🔹 배경 흰색
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? '',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '작성일자: ${event['created_at'] ?? ''}',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '이벤트',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                      Spacer(),
                      SvgPicture.asset(
                        'assets/icons/event_icon.svg',
                        width: 30,
                        height: 32,
                      ),
                      SizedBox(width: 18),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
