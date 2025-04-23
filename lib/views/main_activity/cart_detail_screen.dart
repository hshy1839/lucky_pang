import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/profile_screen_controller.dart';
import '../product_activity/product_detail_screen.dart';

class CartDetailScreen extends StatefulWidget {
  @override
  _CartDetailScreenState createState() => _CartDetailScreenState();
}

class _CartDetailScreenState extends State<CartDetailScreen> {
  final CartController cartController = CartController();
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> productItems = [];
  List<Map<String, String>> products = [];

  bool isAllSelected = false;
  int totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _loadCartData();
    _loadProducts();
  }

  // 장바구니 데이터 로드
  Future<void> _loadCartData() async {
    try {
      final profileController = ProfileScreenController();
      await profileController.fetchUserDetails(context);
      final String userId = profileController.userId;
      final String token = await _getToken();

      if (userId.isEmpty || token.isEmpty) {
        throw Exception('로그인 정보가 부족합니다.');
      }

      final items = await CartController().fetchCartData(userId, token);

      if (mounted) {
        setState(() {
          cartItems = items;
          totalPrice = getTotalPrice();
        });

        // cartItems 로드 후 product 데이터 불러오기
        _loadProductsData();
      }
    } catch (e) {
      showErrorDialog(e.toString());
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  void showErrorDialog(String message) {
    print('오류: $message');
  }

  int getTotalPrice() {
    return cartItems.fold(0, (total, item) {
      if (item['isSelected'] == true) {
        return total + (item['totalPrice'] as num).toInt();
      }
      return total;
    });
  }

  // 선택된 항목 삭제
  Future<void> _deleteSelectedItems() async {
    List<String> selectedCartIds = [];

    // 먼저 token을 가져옵니다.
    final String token = await _getToken();

    if (token.isEmpty) {
      showErrorDialog('로그인 정보가 부족합니다.');
      return;
    }

    // 선택된 항목의 cartId 수집
    for (var item in cartItems) {
      if (item['isSelected'] == true) {
        selectedCartIds.add(item['cartId']); // cartId를 수집
      }
    }

    if (selectedCartIds.isEmpty) {
      showErrorDialog('선택된 항목이 없습니다.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("삭제 확인"),
          content: Text("선택된 항목을 삭제하시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () {
                // 취소 버튼 클릭 시
                Navigator.of(context).pop();
              },
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () async {
                // 삭제 버튼 클릭 시
                try {
                  // 선택된 각 항목에 대해 deleteCartItem 호출
                  for (var cartId in selectedCartIds) {
                    await CartController.deleteCartItem(cartId);
                  }

                  // cartItems에서 삭제된 항목을 제거 후 새로운 리스트로 상태 갱신
                  setState(() {
                    cartItems.removeWhere((item) => selectedCartIds.contains(item['cartId']));
                    totalPrice = getTotalPrice();
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  showErrorDialog('삭제 실패: $e');
                  Navigator.of(context).pop();
                }
              },
              child: Text("삭제", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }



  void _toggleSelectAll(bool value) {
    setState(() {
      isAllSelected = value;
      for (var item in cartItems) {
        item['isSelected'] = value;
      }
      totalPrice = getTotalPrice();
    });
  }
  Future<void> _loadProducts() async {
    try {
      ProductController controller = ProductController();
      List<Map<String, String>> fetchedProducts = await controller.fetchProducts();
      setState(() {
        products = fetchedProducts;
      });
    } catch (e) {
      // 데이터를 불러오지 못했을 때 콘솔에 오류 메시지 출력
      print('Error loading products: $e');
    }
  }
  // 상품 정보 불러오기
  Future<void> _loadProductsData() async {
    try {
      final productsController = ProductController();

      for (var item in cartItems) {
        final productId = item['productId'];

        final product = await productsController.getProductInfoById(productId);

        if (product.isNotEmpty) {
          if (mounted) {
            setState(() {
              productItems.add(product);
            });
          }
        } else {
          print('Product data is empty for ID: $productId');
        }
      }
    } catch (e) {
      print('Error occurred while loading products: $e');
      showErrorDialog(e.toString());
    }
  }

  // productItems에서 productId에 해당하는 제품의 mainImageUrl 가져오기
  String _getMainImageUrl(String productId) {
    final product = productItems.firstWhere(
          (item) => item['id'] == productId,
      orElse: () => <String, String>{},  // 빈 Map<String, String> 반환
    );

    // URL이 유효하지 않으면 기본 이미지 URL을 반환
    return product['mainImageUrl']?.isNotEmpty == true
        ? product['mainImageUrl']
        : ''; // 기본 이미지 URL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '장바구니',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
        child: Text(
          '장바구니 항목이 없습니다.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isAllSelected,
                      onChanged: (value) => _toggleSelectAll(value!),
                      activeColor: Colors.blue,
                    ),
                    Text("전체 선택", style: TextStyle(fontSize: 16)),
                  ],
                ),
                TextButton(
                  onPressed: _deleteSelectedItems,
                  child: Text(
                    "선택 삭제",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final mainImageUrl = _getMainImageUrl(item['productId']); // productId로 이미지 URL 가져오기

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 이미지 클릭 시 이동
                          GestureDetector(
                            onTap: () {
                              if (products.isNotEmpty && products[index].containsKey('id')) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      product: products[index],
                                      productId: products[index]['id']!,
                                    ),
                                  ),
                                );
                              } else {
                                // 제품 정보가 없을 때 처리
                                showErrorDialog('제품 정보가 없습니다.');
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(mainImageUrl),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          // 텍스트 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 상품명
                                Text(
                                  item['productName'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                // 사이즈/수량을 하나의 Row로 묶기
                                if (item['sizes'] is List) ...[
                                  Row(
                                    children: [
                                      for (var size in item['sizes'])
                                        Padding(
                                          padding: const EdgeInsets.only(right: 16.0), // 각 항목 간 간격
                                          child: Row(
                                            children: [
                                              Text(
                                                "${size['size']}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              SizedBox(width: 8), // 사이즈와 수량 간 간격
                                              Text(
                                                ": ${size['quantity']}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ] else if (item['sizes'] is Map) ...[
                                  Row(
                                    children: [
                                      Text(
                                        "${item['sizes']['size']}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        ": ${item['sizes']['quantity']}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Text(
                                    "사이즈 정보 없음",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 8),
                                // 금액
                                Text(
                                  "총 ${item['totalPrice']} 원",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 체크박스
                          Checkbox(
                            value: item['isSelected'] ?? false,
                            onChanged: (value) {
                              setState(() {
                                item['isSelected'] = value;
                                totalPrice = getTotalPrice();
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriceRow("총 상품 금액", "$totalPrice 원"),
                SizedBox(height: 16),
    ElevatedButton(
    onPressed: () {
    // 선택된 상품 정보 수집
    List<Map<String, dynamic>> selectedItems = cartItems
        .where((item) => item['isSelected'] == true)
        .toList();

    if (selectedItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('상품을 선택해주세요.')),
    );
    return;
    }


    // 선택된 상품들의 정보를 OrderScreen으로 전달
    Navigator.pushNamed(
    context,
    '/order',
    arguments: {
    'items': selectedItems, // 선택된 상품들의 전체 정보
    },
    );
    },
    child: Text(
    "$totalPrice 원 결제하기",
    style: TextStyle(color: Colors.white),
    ),
    style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, 50),
    backgroundColor: Colors.blue,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    ),
    ),
    ],
            ),
          ),
        ],
      ),
    );
  }

  // 가격 정보를 표시하는 행 생성
  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}
