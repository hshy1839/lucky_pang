// controllers/order_screen_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../routes/base_url.dart';
import 'box_controller.dart'; // 박스 목록 접근용

class OrderScreenController {
  static final _storage = FlutterSecureStorage();

  static Future<void> submitOrder({
    required BuildContext context,
    required String? selectedBoxId,
    required int quantity,
    required int totalAmount,
    required int pointsUsed,
    required String paymentMethod,
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

    // ✅ Payletter PG 결제일 경우
    if (totalAmount > 0 && paymentMethod == '신용/체크카드') {
      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/payletter'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "box": selectedBox['_id'],
          "boxCount": quantity,
          "paymentAmount": totalAmount,
          "amount" : selectedBox['price'],
          "pointUsed": pointsUsed,
          "orderNo": DateTime.now().millisecondsSinceEpoch.toString(),
          "productName": selectedBox['name'],
          "callbackUrl": "https://yourdomain.com/payletter/callback",
          "returnUrl": "https://yourdomain.com/payletter/return",
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentUrl = data['paymentUrl'];

        if (paymentUrl != null) {
          Navigator.pushNamed(context, '/webview', arguments: paymentUrl);
          return;
        }
      }

      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('결제 실패'),
          content: Text('PG 결제 URL을 가져오지 못했습니다.'),
        ),
      );
      return;
    }

    // ✅ 포인트 결제 또는 무통장 등의 일반 처리
    final response = await http.post(
      Uri.parse('${BaseUrl.value}:7778/api/order'),
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
        "deliveryFee": {"point": 0, "cash": 0}
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      final orders = data['orders'] ?? [];
      final orderCount = orders.length;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('결제 완료'),
          content: Text('$orderCount개의 박스가 성공적으로 구매되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/luckyboxOrder');
              },
              child: const Text('확인'),
            )
          ],
        ),
      );
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
        Uri.parse('${BaseUrl.value}:7778/api/order?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = List<Map<String, dynamic>>.from(data['orders']);
        return orders; // ✅ 모든 주문 반환
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
        Uri.parse('${BaseUrl.value}:7778/api/orders/$orderId/unbox'),
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

  static Future<List<Map<String, dynamic>>> getUnboxedProducts(String userId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${BaseUrl.value}:7778/api/orders/unboxed?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['orders']);
      } else {
        debugPrint('❌ 언박싱 상품 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ 언박싱 상품 조회 오류: $e');
      return [];
    }
  }


  static Future<int?> refundOrder(String orderId, double refundRate, {required String description}) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/orders/$orderId/refund'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'refundRate': refundRate,
          'description': description, // ✅ 추가됨
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['refundedAmount'] != null) {
          return data['refundedAmount'];
        } else {
          debugPrint('⚠️ 환급 실패 응답: $data');
          return null;
        }
      } else {
        debugPrint('❌ 서버 상태 코드 오류: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 환급 요청 오류: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUnboxedOrders() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${BaseUrl.value}:7778/api/orders/unboxed/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['orders']);
      } else {
        debugPrint('❌ 전체 언박싱 로그 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ 전체 언박싱 로그 조회 오류: $e');
      return [];
    }
  }



  static Future<void> requestCardPayment({
    required BuildContext context,
    required String boxId,
    required String boxName,
    required int amount,
  }) async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('로그인 필요'),
          content: Text('로그인이 필요합니다.'),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/payletter/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "amount": amount,
          "productName": boxName,
          "boxId": boxId,
        }),
      );

      print('🔁 서버 응답 statusCode: ${response.statusCode}');
      print('🔁 서버 응답 body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded['data'] != null &&
            decoded['data']['paymentUrl'] != null &&
            decoded['data']['paymentUrl'] is String) {
          final paymentUrl = decoded['data']['paymentUrl'];
          final uri = Uri.parse(paymentUrl);

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            showDialog(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text('오류'),
                content: Text('외부 브라우저를 열 수 없습니다.'),
              ),
            );
          }
          return;
        } else {
          showDialog(
            context: context,
            builder: (_) => const AlertDialog(
              title: Text('결제 URL 없음'),
              content: Text('서버 응답에 paymentUrl이 없습니다.'),
            ),
          );
          return;
        }
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('결제 실패'),
          content: Text('서버 응답 오류: ${response.statusCode}'),
        ),
      );
    } catch (e, stack) {
      print('❌ 예외 발생: $e');
      print('❌ 스택트레이스: $stack');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('에러 발생'),
          content: Text('에러: $e'),
        ),
      );
    }
  }


  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) return;

    final response = await http.patch(
      Uri.parse('${BaseUrl.value}:7778/api/order/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      debugPrint('❌ 주문 상태 업데이트 실패: ${response.statusCode}');
    } else {
      debugPrint('✅ 주문 상태 업데이트 성공');
    }
  }




}
