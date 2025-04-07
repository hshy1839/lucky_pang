import 'package:flutter/material.dart';

import '../product_activity/product_detail_screen.dart';

class CategoryScreen extends StatelessWidget {
  // 각 카테고리의 항목들
  final List<Map<String, String>> categories = [
    {'name': '아우터', 'image': 'assets/icons/outer.png'},
    {'name': '상의', 'image': 'assets/icons/top.png'},
    {'name': '하의', 'image': 'assets/icons/pants.png'},
  ];

  final List<Map<String, String>> outerItems = [
    {'name': '가디건', 'image': 'assets/images/cardigan.jpg'},
    {'name': '자켓', 'image': 'assets/images/jacket.jpg'},
    {'name': '코트', 'image': 'assets/images/coat.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('카테고리'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {},
          ),
        ],
      ),
      body: Row(
        children: [
          // 사이드바
          Container(
            width: 120,
            color: Colors.grey[200],
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Image.asset(categories[index]['image']!),
                  title: Text(categories[index]['name']!),
                  onTap: () {
                    // 카테고리 클릭 시 해당 아이템 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryItemsScreen(
                          categoryName: categories[index]['name']!,
                          items: outerItems, // 임시로 outerItems로 설정
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // 카테고리 아이템 목록
          Expanded(
            child: CategoryItemsScreen(
              categoryName: '아우터',
              items: outerItems,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItemsScreen extends StatelessWidget {
  final String categoryName;
  final List<Map<String, String>> items;

  CategoryItemsScreen({required this.categoryName, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = items[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to the product detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: item,
                            productId: item['id'] ?? '',
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
                              child: Image.asset(
                                item['image']!,
                                fit: BoxFit.cover,
                                height: 200,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '₩ ${item['price']}', // Assuming 'price' key holds the price
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              item['category'] ?? '카테고리',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              item['name']!,
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
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}