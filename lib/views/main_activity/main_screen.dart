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

  final List<Map<String, String>> categories = [
    {'name': '골프의류', 'icon': 'assets/icons/golf_cloth.png'},
    {'name': '일반의류', 'icon': 'assets/icons/cloth_man.png'},
    {'name': '남성의류', 'icon': 'assets/icons/outer.png'},
    {'name': '여성의류', 'icon': 'assets/icons/cloth_woman.png'},
    {'name': '지갑', 'icon': 'assets/icons/wallet.png'},
    {'name': '가방', 'icon': 'assets/icons/bag.png'},
    {'name': '신발', 'icon': 'assets/icons/shoes.png'},
    {'name': '기타', 'icon': 'assets/icons/cap.png'},

  ];

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
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
              child: ads.isNotEmpty
                  ? CarouselSlider(
                items: ads.map((adUrl) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5), // 그림자 색상
                              spreadRadius: 2, // 그림자 확산 반경
                              blurRadius: 5, // 그림자 흐림 정도
                              offset: Offset(0, 3), // 그림자의 위치 (x, y)
                            ),
                          ],
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
                  height: 250.0,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 3),
                  enlargeCenterPage: true,
                  aspectRatio: 2,
                  onPageChanged: (index, reason) {},
                ),
              )
                  : Center(child: CircularProgressIndicator()),
            ),
          ),

          // 공지사항
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공지사항',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (notices.isNotEmpty)
                      Text(
                        notices[0]['title'] ?? '공지사항 제목',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.black,
                        ),
                      )
                    else
                      Text(
                        '공지사항을 불러올 수 없습니다.',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.black,
                        ),
                      ),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/notice');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                          textStyle: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text('전체보기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 카테고리
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(top: 50.0, left: 8.0, right: 8.0, bottom: 50.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10.0,
                runSpacing: 16.0,
                children: categories.map((category) {
                  return GestureDetector(
                    onTap: () {

                      Navigator.pushNamed(
                        context,
                        '/shoppingscreen', // ShoppingScreen의 라우트 이름
                        arguments: category['name'], // 선택한 카테고리 이름 전달
                      );

                    },
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 40) / 5,
                      child: Column(
                        children: [
                          Image.asset(
                            category['icon']!,
                            width: 25,
                            height: 25,
                          ),
                          SizedBox(height: 8),
                          Text(
                            category['name']!,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 추천 상품
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final product = products[index];
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
                    child: Card(
                      color: Colors.white,
                      elevation: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                product['mainImageUrl'] ?? 'assets/images/nike1.png',
                                fit: BoxFit.cover,
                                height: 250,
                                width: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(child: Icon(Icons.error));
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '₩ ${formatPrice(product['price'])}',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              product['category'] ?? '카테고리',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0.0),
                            child: Text(
                              product['name'] ?? '상품 제목',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
