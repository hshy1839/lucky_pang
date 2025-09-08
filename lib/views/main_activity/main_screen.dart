import 'package:attedance_app/controllers/order_screen_controller.dart';
import 'package:attedance_app/controllers/product_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as secureStorage;
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import '../../controllers/main_screen_controller.dart';
import '../../controllers/notification_controller.dart';
import '../product_activity/product_detail_screen.dart';
import '../setting_activity/event_activity/event_detail_screen.dart';

class MainScreen extends StatefulWidget {
  final Function(int)? onTabTapped;

  const MainScreen({super.key, this.onTabTapped});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, String>> products = [];
  List<Map<String, dynamic>> ads = [];
  List<Map<String, dynamic>> latestUnboxedLogs = [];
  bool hasUnreadNoti = false;
  final secureStorage = const FlutterSecureStorage();
  bool _loadingNoti = false;


  String selectedBox = '5,000원 박스';
  int _currentAdIndex = 0;

  ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();

    _loadProducts();
    _loadAds();
    _loadUnboxedLogs();
    _loadUnreadNoti();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  String formatPrice(String? price) {
    if (price == null || price.isEmpty) return '0';
    final formatter = NumberFormat('#,###');
    return formatter.format(int.parse(price));
  }
  Future<void> _loadUnreadNoti() async {
    setState(() { _loadingNoti = true; });
    String? userId = await secureStorage.read(key: 'userId');
    String? token = await secureStorage.read(key: 'token');
    if (userId != null && token != null) {
      try {
        final notiList = await NotificationController().fetchNotifications(
          userId: userId,
          token: token,
        );
        setState(() {
          hasUnreadNoti = notiList.any((n) => n['read'] == false);
          _loadingNoti = false;
        });
      } catch (e) {
        setState(() {
          hasUnreadNoti = false;
          _loadingNoti = false;
        });
      }
    } else {
      setState(() {
        hasUnreadNoti = false;
        _loadingNoti = false;
      });
    }
  }

  Future<void> _loadUnboxedLogs() async {
    try {
      final logs = await OrderScreenController.getAllUnboxedOrders(); // 직접 만든 API 함수
      final recent = logs
          .where((order) =>
      (order['unboxedProduct']?['product']?['consumerPrice'] ?? 0) >= 30000)
          .toList()
        ..sort((a, b) => DateTime.parse(b['unboxedProduct']?['decidedAt'] ?? '')
            .compareTo(DateTime.parse(a['unboxedProduct']?['decidedAt'] ?? '')));
      setState(() {
        latestUnboxedLogs = recent.take(10).toList();
      });
    } catch (e) {
      print('언박싱 기록 로딩 오류: $e');
    }
  }


  Future<void> _loadAds() async {
    try {
      MainScreenController controller = MainScreenController();
      List<Map<String, dynamic>> promotions = await controller.getPromotions();

      setState(() {
        ads = promotions
            .where((promotion) => promotion['promotionImageUrl'] != '')
            .map((promotion) => {
          'id': promotion['id'], // ✅ 추가
          'image': promotion['promotionImageUrl'] ?? '',
        })
            .toList();
      });
    } catch (e) {
      print('광고 로딩 오류: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      ProductController controller = ProductController();
      List<Map<String, String>> fetchedProducts = await controller.fetchProducts();
      setState(() {
        products = fetchedProducts;
      });
    } catch (e) {
      print('상품 로딩 오류: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse && _isHeaderVisible) {
      setState(() => _isHeaderVisible = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward && !_isHeaderVisible) {
      setState(() => _isHeaderVisible = true);
    }
  }

  Widget _buildProductCard(Map<String, String> product, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: product,
              productId: product['id'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        width: 170,
        height: 200,
        margin: EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: (product['mainImageUrl'] != null && product['mainImageUrl'].toString().isNotEmpty)
                    ? Image.network(
                  product['mainImageUrl']!,
                  width: double.infinity,
                  height: 210,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 210,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, size: 40, color: Colors.grey),
                  ),
                )
                    : Container(
                  width: double.infinity,
                  height: 210,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                ),
              ),

              Container(
                height: 140,
                padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // 하단에 정렬
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['brand'] ?? '',
                          style: TextStyle(fontSize: 18, color: Color(0xFF021526)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          product['name'] ?? '',
                          style: TextStyle(fontSize: 16, color: Color(0xFF465461)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatPrice(product['price'])}원',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '정가: ${formatPrice(product['consumerPrice'])}원',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8D969D),
                            decorationThickness: 1.2,
                            decoration: TextDecoration.lineThrough,
                            decorationStyle: TextDecorationStyle.solid,
                          ),
                        )

                      ],
                    ),
                  ],
                ),
              ),

            ],
          )

      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((p) => p['category'] == selectedBox).toList();


    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [


          // 광고 배너
          SliverToBoxAdapter(
            child: ads.isNotEmpty
                ? Stack(
              children: [
                CarouselSlider(
                  items: ads.map((ad) {
                    final imageUrl = ad['image']!;
                    final promoId = ad['id']!;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(eventId: promoId),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.center, // ⭐ 중심 기준으로 잘림
                          errorBuilder: (_, __, ___) => Center(child: Icon(Icons.error)),
                        ),
                      ),

                    );
                  }).toList(),
                  options: CarouselOptions(
                    height: 420.0,
                    autoPlay: true,
                    autoPlayInterval: Duration(seconds: 3),
                    enlargeCenterPage: false,
                    viewportFraction: 1.0,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentAdIndex = index;
                      });
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _loadingNoti
                      ? CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                      : IconButton(
                    icon: Icon(
                      hasUnreadNoti ? Icons.notifications : Icons.notifications_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/notification');
                      // 알림화면 다녀온 후 다시 상태 갱신 (읽음 처리 반영)
                      _loadUnreadNoti();
                    },
                    tooltip: '알림',
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(ads.length, (index) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentAdIndex == index
                              ? Colors.white
                              : Colors.grey.shade400,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            )
                : Center(child: CircularProgressIndicator()),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 36,
              color: Color(0xFF021526),
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  widget.onTabTapped?.call(1); // ✅ 랭킹 탭으로 이동
                },
                child: latestUnboxedLogs.isNotEmpty
                    ? Marquee(
                  text: latestUnboxedLogs.map((log) {
                    final nickname = log['user']?['nickname'] ?? '익명';
                    final productName =
                        log['unboxedProduct']?['product']?['name'] ?? '상품';
                    return "🎉 $nickname 님이 [$productName] 상품을 획득하셨습니다 🎉";
                  }).join("   "),
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  blankSpace: 40.0,
                  velocity: 30.0,
                  pauseAfterRound: Duration(seconds: 1),
                  startPadding: 0.0,
                )
                    : Center(
                  child: Text(
                    "언박싱 기록을 불러오는 중...",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 64.0, left: 20.0, right: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,   // ✅ 기준선 정렬
                textBaseline: TextBaseline.alphabetic,            // ✅ 필수
                children: [
                  Text(
                    '전체상품',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
    '${NumberFormat('#,###').format(filteredProducts.length)}개',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5,000원 박스
          SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0 , horizontal: 16),
              child: Center( // ✅ Center로 감싸서 정중앙 배치
                child: Wrap(
                  spacing: 8, // 버튼 간격
                  alignment: WrapAlignment.center,
                  children: [
                    _buildBoxTab('5,000원 박스'),
                    _buildBoxTab('10,000원 박스'),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductCard(filteredProducts[index], context),

                childCount: filteredProducts.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 16,
                childAspectRatio: 0.51,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 80), // 원하는 높이 조절 가능
          ),
        ],
      ),
    );
  }

  Widget _buildBoxTab(String label) {
    final isSelected = selectedBox == label;
    return GestureDetector(
      onTap: () => setState(() => selectedBox = label),
      child: Container(
        width: 160,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.grey[200],
          borderRadius: BorderRadius.circular(10), // "BorderRadius/brand" 가이드 적용
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }


}
