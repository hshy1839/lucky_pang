import 'package:attedance_app/controllers/product_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/main_screen_controller.dart';
import '../../controllers/notice_screen_controller.dart';
import '../../footer.dart';
import '../../header.dart';
import '../product_activity/product_detail_screen.dart';
import '../setting_activity/event_activity/event_detail_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, String>> products = [];
  List<Map<String, dynamic>> ads = [];
  String selectedBox = '5,000원 박스';
  int _currentAdIndex = 0;

  ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadAds();
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(
                  product['mainImageUrl'] ?? 'assets/icons/app_icon.jpg',
                  width: double.infinity,
                  height: 210, // ✅ 줄임
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(child: Icon(Icons.error)),
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
                          style: TextStyle(fontSize: 16, color: Color(0xFF021526)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          product['name'] ?? '',
                          style: TextStyle(fontSize: 14, color: Color(0xFF465461)),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '정가: ${formatPrice(product['consumerPrice'])}원',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8D969D),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
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
              color: Color(0xFF021526), // 배경색
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Marquee(
                text: "쪼매는 오른손잡이 님이 [루미에르 포슬린 머그] 상품을 획득하셨습니다",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 40.0,
                velocity: 30.0,
                pauseAfterRound: Duration(seconds: 1),
                startPadding: 0.0,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 64.0, left: 20.0, right: 20.0),
              child: Row(
                children: [
                  Text(
                    '전체상품',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
                childAspectRatio: 0.48,
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
