import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/profile_screen_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/qna_controller.dart'; // QnaController 추가

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileScreenController _controller = ProfileScreenController(); // 프로필 컨트롤러 인스턴스
  final QnaController _qnaController = QnaController(); // Qna 컨트롤러 인스턴스
  final CartController _cartController = CartController(); // 장바구니 컨트롤러 인스턴스

  String username = "회원님"; // 초기 사용자 이름
  String name = "회원"; // 초기 이름
  int orderCount = 0; // 초기 주문 내역 개수
  int cartCount = 0; // 장바구니 항목 개수
  int inquiryCount = 0; // 문의 개수 초기화

  @override
  void initState() {
    super.initState();
    fetchUserDetails(); // 사용자 정보 가져오기
    fetchUserOrders(); // 주문 내역 가져오기
    fetchCartItems(); // 장바구니 항목 개수 가져오기
    fetchInquiryCount(); // 문의 개수 가져오기
  }

  Future<void> fetchUserDetails() async {
    try {
      // 사용자 정보 가져오기
      await _controller.fetchUserDetails(context);

      setState(() {
        username = _controller.username; // 사용자 이름 업데이트
        name = _controller.name;
      });
    } catch (e) {
      print('사용자 정보를 가져오는 중 오류 발생: $e');
    }
  }

  Future<void> fetchUserOrders() async {
    try {
      // 주문 내역 가져오기
      await _controller.fetchUserOrders(context);

      setState(() {
        orderCount = _controller.orders.length; // 주문 내역 개수 업데이트
      });
    } catch (e) {
      print('주문 내역을 가져오는 중 오류 발생: $e');
    }
  }

  Future<void> fetchCartItems() async {
    try {
      final String token = await _getToken();

      // userId를 SharedPreferences에서 가져오기
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      // userId가 없는 경우 서버에서 가져오기
      if (userId == null || userId.isEmpty) {
        final profileController = ProfileScreenController();
        await profileController.fetchUserId(context);
        userId = profileController.userId;

        if (userId.isEmpty) {
          throw Exception('userId를 가져올 수 없습니다.');
        }

        // SharedPreferences에 userId 저장
        await prefs.setString('userId', userId);
      }

      if (token.isEmpty) {
        throw Exception('로그인 토큰이 없습니다.');
      }

      final cartItems = await _cartController.fetchCartData(userId, token);

      setState(() {
        cartCount = cartItems.length; // 장바구니 항목 개수 업데이트
      });
    } catch (e) {
      print('장바구니 항목 개수를 가져오는 중 오류 발생: $e');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }


  Future<void> fetchInquiryCount() async {
    try {
      // QnA 문의 글 개수 가져오기
      final qnaList = await _qnaController.getQnaInfo();

      setState(() {
        inquiryCount = qnaList.length; // 문의 글 개수 업데이트
      });
    } catch (e) {
      print('문의 글 개수를 가져오는 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MY PAGE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black), // 톱니바퀴 아이콘
            onPressed: () {
              Navigator.pushNamed(context, '/setting'); // 설정 페이지로 이동
            },
          ),
        ],
      ),

      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            // 회원 이름 섹션
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 왼쪽 정렬
                children: [
                  Text(
                    '안녕하세요,',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5.0),
                  Text(
                    '$name 님',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.0),
            // 장바구니, 주문내역, 문의 (하나의 사각형으로 묶음)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!), // 테두리 색상
                  borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      title: '장바구니',
                      count: cartCount, // 장바구니 항목 개수
                      onTap: () {
                        Navigator.pushNamed(context, '/cart'); // 장바구니 화면으로 이동
                      },
                    ),
                    _buildStatItem(
                      context,
                      title: '주문내역',
                      count: orderCount,
                      onTap: () {
                        Navigator.pushNamed(context, '/orders'); // 주문 내역 화면으로 이동
                      },
                    ),
                    _buildStatItem(
                      context,
                      title: '문의',
                      count: inquiryCount,
                      onTap: () {
                        Navigator.pushNamed(context, '/qna'); // QnA 화면으로 이동
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Divider(color: Colors.grey[300], thickness: 1.0),

            // 공지사항, 약관 및 정책
            ListTile(
              title: Text('내 포인트 내역', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              leading: Icon(Icons.notifications, color: Colors.grey), // 공지사항 아이콘
              trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
              onTap: () {
                Navigator.pushNamed(context, '/notice');
              },
            ),
            Divider(color: Colors.grey[300], thickness: 1.0),
            ListTile(
              title: Text('배송지 관리', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              leading: Icon(Icons.back_hand_outlined, color: Colors.grey), // 문의 아이콘
              trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
              onTap: () {
                Navigator.pushNamed(context, '/qna');
              },
            ),
            Divider(color: Colors.grey[300], thickness: 1.0),
            ListTile(
              title: Text('친구 초대하기', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              leading: Icon(Icons.person_outline, color: Colors.grey), // 개인정보 수정 아이콘
              trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
              onTap: () {
                Navigator.pushNamed(context, '/userinfo'); // 개인정보 수정 화면으로 이동
              },
            ),
            Divider(color: Colors.grey[300], thickness: 1.0),
            ListTile(
              title: Text('선물코드 입력', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              leading: Icon(Icons.call, color: Colors.grey), // 고객센터 아이콘
              trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
              onTap: () {
                // 고객센터 화면으로 이동
                Navigator.pushNamed(context, '/accountInfo');
              },
            ),
            Divider(color: Colors.grey[300], thickness: 1.0),
            ListTile(
              title: Text('쿠폰코드 입력', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              leading: Icon(Icons.logout, color: Colors.grey),
              trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
              onTap: () => _controller.logout(context), // 로그아웃 함수 호출
            ),
          ],
        ),
      ),
    );
  }

  // 통계 항목 빌드 함수
  Widget _buildStatItem(BuildContext context, {required String title, required int count, required Function? onTap}) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap() : null, // onTap이 null이면 아무 동작도 하지 않음
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 8.0),
          Text(
            '$count',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
