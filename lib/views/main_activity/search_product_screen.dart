import 'package:flutter/material.dart';
import '../../controllers/product_controller.dart';
import '../product_activity/product_detail_screen.dart';

class SearchProductScreen extends StatefulWidget {
  final String searchQuery;

  const SearchProductScreen({Key? key, required this.searchQuery}) : super(key: key);

  @override
  _SearchProductScreenState createState() => _SearchProductScreenState();
}

class _SearchProductScreenState extends State<SearchProductScreen> {
  List<Map<String, String>> products = []; // 전체 상품 리스트
  List<Map<String, String>> filteredProducts = []; // 검색된 상품 리스트

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // 상품 데이터 로드
  Future<void> _loadProducts() async {
    try {
      ProductController controller = ProductController();
      List<Map<String, String>> fetchedProducts = await controller.fetchProducts();

      setState(() {
        products = fetchedProducts;
        filteredProducts = products.where((product) {
          final name = product['name']?.toLowerCase() ?? '';
          final category = product['category']?.toLowerCase() ?? '';
          return name.contains(widget.searchQuery.toLowerCase()) || category.contains(widget.searchQuery.toLowerCase());
        }).toList();
      });
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('<${widget.searchQuery}>의 검색 결과'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
      ),
      body: filteredProducts.isEmpty
          ? Center(
        child: Text(
          '검색 결과가 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: GridView.builder(
          itemCount: filteredProducts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(child: Icon(Icons.error));
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '₩ ${product['price'] ?? '상품 가격'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
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
        ),
      ),
    );
  }
}
