import 'package:attedance_app/controllers/product_controller.dart';
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
  List<Map<String, String>> products = [];
  List<String> ads = [];

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
            .map((promotion) => promotion['promotionImageUrl'] ?? '')
            .where((url) => url.isNotEmpty)
            .toList()
            .cast<String>(); // 🔥 이렇게!st<String>() 대신 toList()
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
        margin: EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          borderRadius: BorderRadius.circular(5),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              child: Image.network(
                product['mainImageUrl'] ?? 'assets/images/nike1.png',
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: Icon(Icons.error)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Text(
                product['name'] ?? '상품 제목',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${formatPrice(product['price'])}원',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fiveThousandProducts = products.where((p) => p['category'] == '5,000원 박스').toList();
    final tenThousandProducts = products.where((p) => p['category'] == '10,000원 박스').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (_isHeaderVisible) SliverToBoxAdapter(child: Header()),

          // 광고 배너
          SliverToBoxAdapter(
            child: ads.isNotEmpty
                ? CarouselSlider(
              items: ads.map((url) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
              options: CarouselOptions(
                height: 400.0,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 3),
                enlargeCenterPage: false,
                viewportFraction: 1.0,
              ),
            )
                : Center(child: CircularProgressIndicator()),
          ),

          // 5,000원 박스
          SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
          SliverToBoxAdapter(
            child: _buildCategoryHeader('5,000원 박스', context),
          ),
          SliverToBoxAdapter(
            child: _buildCarousel(fiveThousandProducts, context),
          ),

          // 10,000원 박스
          SliverToBoxAdapter(
            child: _buildCategoryHeader('10,000원 박스', context),
          ),
          SliverToBoxAdapter(
            child: _buildCarousel(tenThousandProducts, context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/boxProducts'),
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
    );
  }

  Widget _buildCarousel(List<Map<String, String>> items, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 0, bottom: 20),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 200,
          enableInfiniteScroll: false,
          enlargeCenterPage: false,
          viewportFraction: 0.4,
          autoPlay: false,
          padEnds: false,
        ),
        items: items.map((product) {
          return Builder(
            builder: (_) => _buildProductCard(product, context),
          );
        }).toList(),
      ),
    );
  }
}
