import 'package:attedance_app/controllers/product_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../../controllers/main_screen_controller.dart';
import '../../controllers/notice_screen_controller.dart';
import '../../footer.dart';
import '../../header.dart';
import '../product_activity/product_detail_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Map<String, String>> notices = []; // 공지사항 리스트
  List<Map<String, String>> products = [];
  List<String> ads = []; // 서버에서 가져온 광고 이미지 URL 리스트


  ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    _loadNotices();
    _loadProducts();
    _loadAds(); // 광고 이미지 불러오기
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


  // 광고 이미지 불러오기
  Future<void> _loadAds() async {
    try {
      MainScreenController controller = MainScreenController();
      List<Map<String, dynamic>> promotions = await controller.getPromotions();

      setState(() {
        ads = promotions
            .map((promotion) => promotion['promotionImageUrl'] ?? '')
            .toList()
            .cast<String>(); // 명시적으로 String 리스트로 변환
      });
    } catch (e) {
      print('Error loading ads: $e');
    }
  }


  // 공지사항 불러오기
  Future<void> _loadNotices() async {
    NoticeScreenController controller = NoticeScreenController();
    List<Map<String, String>> fetchedNotices = await controller.fetchNotices();
    setState(() {
      notices = fetchedNotices;
    });
  }

  // 상품 불러오기
  Future<void> _loadProducts() async {
    try {
      ProductController controller = ProductController();
      List<Map<String, String>> fetchedProducts = await controller.fetchProducts();
      setState(() {
        products = fetchedProducts;
      });
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          if (_isHeaderVisible) SliverToBoxAdapter(child: Header()),

          // 광고 슬라이더
          SliverToBoxAdapter(
            child: ads.isNotEmpty
                ? CarouselSlider(
              items: ads.map((adUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(adUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
              options: CarouselOptions(
                height: 400.0,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 3),
                enlargeCenterPage: false, // 중앙 확대 효과 제거
                viewportFraction: 1.0, // 화면 전체 너비 사용
              ),
            )
                : Center(child: CircularProgressIndicator()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '5,000원 박스',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // 모두 보기 클릭 시 이동할 라우트로 바꿔줘!
                      Navigator.pushNamed(context, '/boxProducts');
                    },
                    child: Text(
                      '모두 보기',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 추천 상품
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 0, bottom: 20),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  enableInfiniteScroll: false,
                  enlargeCenterPage: false,
                  viewportFraction: 0.4,
                  autoPlay: false,
                  initialPage: 0,
                  padEnds: false,
                ),
                items: products.map((product) {
                  return Builder(
                    builder: (BuildContext context) {
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
                          margin: EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white, // 🔥 카드 배경색
                            border: Border.all(
                              color: Colors.grey.shade300, // 🔥 테두리 색상
                              width: 0.5,                   // 🔥 테두리 두께
                            ),
                            borderRadius: BorderRadius.circular(5), // 🔥 둥근 모서리
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
                                borderRadius:
                                BorderRadius.vertical(top: Radius.circular(5)),
                                child: Image.network(
                                  product['mainImageUrl'] ?? 'assets/images/nike1.png',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Center(child: Icon(Icons.error)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4),
                                child: Text(
                                  product['name'] ?? '상품 제목',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '${formatPrice(product['price'])}원',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '10,000원 박스',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // 모두 보기 클릭 시 이동할 라우트로 바꿔줘!
                      Navigator.pushNamed(context, '/boxProducts');
                    },
                    child: Text(
                      '모두 보기',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 추천 상품
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 0, bottom: 20),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  enableInfiniteScroll: false,
                  enlargeCenterPage: false,
                  viewportFraction: 0.4,
                  autoPlay: false,
                  initialPage: 0,
                  padEnds: false,
                ),
                items: products.map((product) {
                  return Builder(
                    builder: (BuildContext context) {
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
                          margin: EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white, // 🔥 카드 배경색
                            border: Border.all(
                              color: Colors.grey.shade300, // 🔥 테두리 색상
                              width: 0.5,                   // 🔥 테두리 두께
                            ),
                            borderRadius: BorderRadius.circular(5), // 🔥 둥근 모서리
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
                                borderRadius:
                                BorderRadius.vertical(top: Radius.circular(5)),
                                child: Image.network(
                                  product['mainImageUrl'] ?? 'assets/images/nike1.png',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Center(child: Icon(Icons.error)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4),
                                child: Text(
                                  product['name'] ?? '상품 제목',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '${formatPrice(product['price'])}원',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),


        ],
      ),
    );
  }
}
