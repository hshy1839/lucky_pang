// controllers/order_screen_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'box_controller.dart'; // 박스 목록 접근용

class OrderScreenController {
  static final _storage = FlutterSecureStorage();

  static Future<void> submitOrder({
    required BuildContext context,
    required String? selectedBoxId,
    required int quantity,
    required int totalAmount,
    required int pointsUsed,
  }) async {
    if (selectedBoxId == null) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('에러'),
          content: Text('선택된 박스가 없습니다.'),
        ),
      );
      return;
    }

    final boxController = Provider.of<BoxController>(context, listen: false);
    final selectedBox = boxController.boxes.firstWhere(
          (box) => box['_id'] == selectedBoxId,
      orElse: () => null,
    );

    if (selectedBox == null) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('에러'),
          content: Text('박스 정보를 찾을 수 없습니다.'),
        ),
      );
      return;
    }

    final token = await _storage.read(key: 'token');
    if (token == null) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('로그인 필요'),
          content: Text('로그인 후 이용해주세요.'),
        ),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://172.30.1.22:7778/api/order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        "box": selectedBox['_id'],
        "boxCount": quantity,
        "paymentType": totalAmount == 0 ? "point" : "mixed",
        "paymentAmount": totalAmount,
        "pointUsed": pointsUsed,
        "deliveryFee": {
          "point": 0,
          "cash": 0
        }
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pushNamed(context, '/luckyboxOrder');
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('주문 실패'),
          content: Text('서버 오류 (${response.statusCode})'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            )
          ],
        ),
      );
    }
  }



  static Future<List<Map<String, dynamic>>> getOrdersByUserId(String userId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        debugPrint('❌ 토큰이 없습니다.');
        return [];
      }

      final response = await http.get(
        Uri.parse('http://172.30.1.22:7778/api/order?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = List<Map<String, dynamic>>.from(data['orders']);
        return orders.where((order) => order['status'] == 'paid').toList();
      } else {
        debugPrint('❌ 주문 불러오기 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ 주문 불러오기 중 오류: $e');
      return [];
    }
  }


  static void handleBoxOpen(
      BuildContext context,
      String orderId,
      Function(Map<String, dynamic>) onSuccess,
      ) async {
    final result = await unboxOrder(orderId);
    if (result != null) {
      onSuccess(result);
    } else {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('박스 열기 실패'),
          content: Text('이미 열린 박스이거나 오류가 발생했습니다.'),
        ),
      );
    }
  }

  static Future<Map<String, dynamic>?> unboxOrder(String orderId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        debugPrint('❌ 토큰 없음');
        return null;
      }

      final response = await http.post(
        Uri.parse('http://172.30.1.22:7778/api/orders/$orderId/unbox'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['order'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

}
