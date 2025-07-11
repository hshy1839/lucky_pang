import 'dart:convert';
import 'package:http/http.dart' as http;
import '../routes/base_url.dart';

class NotificationController {
  Future<List<Map<String, dynamic>>> fetchNotifications({
    required String userId,
    required String token,
  }) async {
    final url = Uri.parse('${BaseUrl.value}:7778/api/notifications/$userId');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('[알림] statusCode: ${response.statusCode}');
      print('[알림] responseBody: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['notifications'] != null) {
          return List<Map<String, dynamic>>.from(data['notifications']);
        } else {
          print('[알림] 서버 success false 또는 notifications 없음: $data');
          return [];
        }
      } else {
        print('[알림] 서버 statusCode 200 아님: ${response.statusCode}');
        print('[알림] body: ${response.body}');
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e, stack) {
      print('[알림] fetchNotifications 예외 발생: $e');
      print(stack);
      throw Exception('알림을 불러오는 중 오류 발생: $e');
    }
  }

  Future<void> readNotifications({
    required String userId,
    required String token,
  }) async {
    final url = Uri.parse('${BaseUrl.value}:7778/api/notifications/$userId/read-all');
    final response = await http.patch(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      print('[알림] 전체 읽음 처리 완료');
    } else {
      print('[알림] 전체 읽음 실패: ${response.body}');
    }
  }
}
