import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartController {
  // 장바구니 데이터 가져오기
  List<Map<String, dynamic>> cartItems = [];

  // 서버에서 장바구니 데이터를 가져오는 함수
  Future<List<Map<String, dynamic>>> fetchCartData(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.25.15:7778/api/cart/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body); // Map으로 파싱

        // cartItems가 null일 수 있으므로, null 체크를 추가
        final List<dynamic> cartItems = data['carts'] ?? []; // null일 경우 빈 리스트 반환

        return cartItems.map<Map<String, dynamic>>((item) {
          return {
            'cartId': item['_id'],
            'productId': item['productId'],
            'productName': item['productName'],
            'sizes': item['sizes'],
            'price': item['price'],
            'totalPrice': item['totalPrice'],
            'isSelected': false, // 기본적으로 선택 안됨
          };
        }).toList();
      } else {
        throw Exception('장바구니 데이터를 불러오는 데 실패했습니다.');
      }
    } catch (e) {
      throw Exception('오류: $e');
    }
  }




  static const String apiUrl = 'http://192.168.25.15:7778/api/cart'; // 서버 주소

  // 장바구니에 상품 추가하는 함수
  static Future<http.Response> addToCart({
    required String userId,
    required String productId,
    required String productName,
    required List<Map<String, dynamic>> sizes, // 여러 사이즈를 리스트로 받음
    required int price,
  }) async {
    try {
      // API 요청에 사용할 데이터
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final Map<String, dynamic> data = {
        'userId': userId,
        'productId': productId,
        'productName': productName,
        'sizes': sizes, // 사이즈 배열을 전달
        'price': price,
      };

      // POST 요청을 보내기 위한 headers와 body 설정
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // JWT 토큰을 헤더에 추가
        },
        body: json.encode(data),
      );

      // 요청이 성공했는지 확인
      if (response.statusCode == 200) {
        print('장바구니에 상품이 추가되었습니다.');
      } else {
        print('장바구니 추가 실패: ${response.body}');
      }

      return response;  // response 객체 반환
    } catch (e) {
      print('오류 발생: $e');
      rethrow;  // 오류가 발생하면 다시 던짐
    }
  }

  static Future<void> deleteCartItem(String cartId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      // DELETE 요청을 보내기 위한 headers 설정
      final response = await http.delete(
        Uri.parse('http://192.168.25.15:7778/api/cart/delete/$cartId'),
        headers: {
          'Authorization': 'Bearer $token', // JWT 토큰을 헤더에 추가
        },
      );

      // 요청이 성공했는지 확인
      if (response.statusCode == 200) {
        print('장바구니에서 상품이 삭제되었습니다.');
      } else {
        print('장바구니 삭제 실패: ${response.body}');
      }
    } catch (e) {
      print('오류 발생: $e');
      rethrow;  // 오류가 발생하면 다시 던짐
    }
  }
}
