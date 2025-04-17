import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PointController {
  final storage = FlutterSecureStorage();

  Future<int> fetchUserTotalPoints(String userId) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('http://localhost:7778/api/points/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final points = data['points'] as List<dynamic>;

        int total = 0;
        for (var point in points) {
          final type = point['type'];
          final amountRaw = point['amount'];
          final amount = int.tryParse(amountRaw.toString()) ?? 0;

          if (type == '추가' || type == '환불') {
            total += amount;
          } else if (type == '감소') {
            total -= amount;
          }
        }

        return total;
      } else {
        throw Exception('Failed to fetch points');
      }
    } catch (e) {
      print('포인트 로드 오류: $e');
      return 0;
    }
  }
}
