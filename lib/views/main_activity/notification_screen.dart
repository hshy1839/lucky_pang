import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../controllers/notification_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final secureStorage = const FlutterSecureStorage();
  Future<List<Map<String, dynamic>>>? _notificationFuture;

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    String? userId = await secureStorage.read(key: 'userId');
    String? token = await secureStorage.read(key: 'token');
    if (userId == null || token == null) {
      setState(() {
        _notificationFuture = Future.value([]); // 로그인 안된 경우 등
      });
      return;
    }

    // 1. PATCH로 전체 읽음 처리
    try {
      await NotificationController().readNotifications(
        userId: userId,
        token: token,
      );
    } catch (e) {
      print('[알림] 읽음 처리 중 오류: $e');
      // 읽음 실패해도 목록은 계속 불러오게 둠
    }

    // 2. 실제 알림 리스트 불러오기
    setState(() {
      _notificationFuture = NotificationController().fetchNotifications(
        userId: userId,
        token: token,
      );
    });
  }

  Future<void> _refresh() async => await _loadAndFetch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('알림'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationFuture,
        builder: (context, snapshot) {
          if (_notificationFuture == null) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('알림 로드 에러: ${snapshot.error}');
            return Center(child: Text('알림을 불러오는 데 실패했습니다.'));
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(child: Text('알림이 없습니다.'));
          }
          return RefreshIndicator(
            color: Theme.of(context).primaryColor,
            backgroundColor: Colors.white,
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, idx) => Divider(
                color: Colors.grey[300],
                thickness: 0.7,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, idx) {
                final noti = notifications[idx];
                final msg = noti['message'] ?? '';
                final url = noti['url'] ?? '';
                final createdAtStr = noti['createdAt'] ?? '';
                final isRead = (noti['read'] ?? false) == true;
                // 날짜 파싱
                String dateStr = '';
                try {
                  final dt = DateTime.parse(createdAtStr);
                  dateStr = _formatDate(dt);
                } catch (_) {
                  dateStr = createdAtStr.toString();
                }
                return ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: isRead
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    msg,
                    style: isRead
                        ? TextStyle(color: Colors.grey)
                        : TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
          onTap: () {
          if (url.isNotEmpty && url != '/order') {
          Navigator.pushNamed(context, url);
          }
                  },
                  tileColor: isRead ? Colors.grey[50] : Colors.white,
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
