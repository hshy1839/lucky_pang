  import 'dart:convert';
  import 'package:bootpay/bootpay.dart';
import 'package:bootpay/model/item.dart';
import 'package:bootpay/model/payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import 'package:http/http.dart' as http;

  import '../routes/base_url.dart';

  class ShippingOrderController {
    static const _baseUrl = '${BaseUrl.value}:7778';
    static const _storage = FlutterSecureStorage();

    // controllers/order_screen_controller.dart 내부에 추가

    static Future<void> submitShippingOrder({
      required BuildContext context,
      required String orderId,             // 언박싱 주문ID
      required String shippingId,          // 선택 배송지 ID
      required int totalAmount,            // 결제할 배송비 (포인트 차감 반영)
      required int pointsUsed,             // 포인트 사용량
      required String paymentMethod,       // '계좌이체', '신용/체크카드', 'point' 등
    }) async {
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

      // 카드/계좌 결제(포인트 혼합) → 부트페이 연동(결제 성공 후 서버 전달)
      if (totalAmount > 0 && (paymentMethod == '신용/체크카드' || paymentMethod == '계좌이체')) {
        final String paymentOrderId = DateTime.now().millisecondsSinceEpoch.toString();
        await launchBootpayPayment(
          context: context,
          boxId: orderId, // 배송 결제엔 orderId를 넘겨도 됨(결제 성공 후 서버에서 구분)
          boxName: '배송비 결제',
          amount: totalAmount,
          orderId: paymentOrderId,
          userPhone: '', // 필요 시 추가
          payMethod: paymentMethod == '계좌이체' ? 'bank' : 'card',
          pointsUsed: pointsUsed,
          quantity: 1,
          onSuccess: () async {
            // 결제 성공 시 서버에 결제/배송비 결제 정보 전달 (배송 엔드포인트)
            await _finishShippingPayment(
              context: context,
              orderId: orderId,
              shippingId: shippingId,
              totalAmount: totalAmount,
              pointsUsed: pointsUsed,
              paymentMethod: paymentMethod,
            );
            Navigator.pushReplacementNamed(context, '/main');
          },
          onError: (errMsg) {
            // 결제 실패 안내 등
          },
        );
        return;
      }

      // 포인트만 결제 → 바로 서버 배송 결제/신청 API 호출
      await _finishShippingPayment(
        context: context,
        orderId: orderId,
        shippingId: shippingId,
        totalAmount: totalAmount,
        pointsUsed: pointsUsed,
        paymentMethod: paymentMethod,
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('결제 완료'),
          content: const Text('배송비 결제가 완료되었습니다!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/main');
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }

// 내부에서만 호출되는 배송 결제/신청 API 호출 함수
    static Future<void> _finishShippingPayment({
      required BuildContext context,
      required String orderId,
      required String shippingId,
      required int totalAmount,
      required int pointsUsed,
      required String paymentMethod,
    }) async {
      final token = await _storage.read(key: 'token');
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${BaseUrl.value}:7778/api/orders/deliver'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "orderId": orderId,
          "shippingId": shippingId,
          "paymentType": paymentMethod,
          "paymentAmount": totalAmount,
          "pointUsed": pointsUsed,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // 성공시 아무 처리 X(상위에서 다이얼로그 등 처리)
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('결제 실패'),
            content: Text('배송비 결제/신청 서버 오류: ${response.statusCode}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }

    /// 배송 주문 생성
    static Future<bool> createShippingOrder({
      required String productId,
      required String shippingId,
      required String orderId,
      required String paymentType,
      required int shippingFee,
      required int pointUsed,
      required int paymentAmount,
    }) async {
      try {
        final token = await _storage.read(key: 'token');
        if (token == null) throw Exception('토큰 없음');

        final response = await http.post(
          Uri.parse('$_baseUrl/api/shipping-orders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'product': productId,
            'shipping': shippingId,
            'orderId': orderId,
            'paymentType': paymentType,
            'shippingFee': shippingFee,
            'pointUsed': pointUsed,
            'paymentAmount': paymentAmount,
          }),
        );

        final data = jsonDecode(response.body);
        return response.statusCode == 201 && data['success'] == true;
      } catch (e) {
        print('배송 주문 생성 오류: $e');
        return false;
      }
    }

    /// 유저의 배송 주문 조회
    static Future<List<Map<String, dynamic>>> getUserShippingOrders(String userId) async {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/api/shipping-orders?userId=$userId'),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          final List<dynamic> list = data['orders'];
          return list.cast<Map<String, dynamic>>();
        } else {
          throw Exception(data['message'] ?? '배송 주문 조회 실패');
        }
      } catch (e) {
        print('배송 주문 조회 오류: $e');
        return [];
      }
    }

    /// 배송 주문 환불 요청
    static Future<bool> refundShippingOrder({
      required String orderId,
      required int refundRate,
      String? description,
    }) async {
      try {
        final token = await _storage.read(key: 'token');
        if (token == null) throw Exception('토큰 없음');

        final response = await http.post(
          Uri.parse('$_baseUrl/api/shipping-orders/$orderId/refund'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'refundRate': refundRate,
            if (description != null) 'description': description,
          }),
        );

        final data = jsonDecode(response.body);
        return response.statusCode == 200 && data['success'] == true;
      } catch (e) {
        print('배송 주문 환불 오류: $e');
        return false;
      }
    }
    static Future<void> launchBootpayPayment({
      required BuildContext context,
      required String boxName,
      required String boxId,  // <-- orderId로 받아와도 됨
      required int amount,
      required String orderId, // <- 실제로는 orderId만 필요. 변수명만 boxId여도 됨
      required String userPhone,
      required String payMethod,
      required int pointsUsed,
      required int quantity,
      required Function() onSuccess,
      Function(String error)? onError,
    }) async {
      Payload payload = Payload();
      payload.pg = '페이레터';
      payload.method = payMethod;
      payload.orderName = boxName;
      payload.price = amount.toDouble();
      payload.orderId = orderId;
      payload.webApplicationId = '61e7c9c9e38c30001f7b8247';
      payload.androidApplicationId = '61e7c9c9e38c30001f7b8248';
      payload.iosApplicationId = '61e7c9c9e38c30001f7b8249';

      payload.items = [
        Item(
          name: boxName,
          qty: quantity,
          id: orderId,
          price: amount.toDouble(),
        ),
      ];

      Bootpay().requestPayment(
        context: context,
        payload: payload,
        showCloseButton: true,
        onCancel: (data) {
          if (onError != null) onError('결제 취소');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('결제가 취소되었습니다.'), backgroundColor: Colors.red),
          );
        },
        onError: (data) {
          if (onError != null) onError(data.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('결제 중 오류가 발생했습니다.'), backgroundColor: Colors.red),
          );
        },
        onClose: () {
          Bootpay().dismiss(context);
        },
        onDone: (data) async {
          try {
            final parsed = data is String ? jsonDecode(data) : data;
            final receiptId = parsed['data']['receipt_id'];
            final token = await _storage.read(key: 'token');

            // **배송 결제용 API 엔드포인트로 요청!!**
            final res = await http.post(
              Uri.parse('${BaseUrl.value}:7778/api/bootpay/verify/shipping'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'receipt_id': receiptId,
                'orderId': boxId,   // boxId가 실제로는 주문(order) id 임!
                'amount': amount,
                'paymentType': payMethod == 'card' ? 'card' : 'bank',
                'pointUsed': pointsUsed,
              }),
            );

            if (res.statusCode == 200) {
              onSuccess();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('결제 성공!')),
              );
            } else {
              if (onError != null) onError('결제 검증 실패');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('결제 검증에 실패했습니다.'), backgroundColor: Colors.red),
              );
            }
          } catch (e) {
            if (onError != null) onError('결제 검증 중 예외 발생');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('결제 검증 중 오류'), backgroundColor: Colors.red),
            );
          }
        },
      );
    }

  }