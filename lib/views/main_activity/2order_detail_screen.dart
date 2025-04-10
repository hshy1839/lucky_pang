import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/profile_screen_controller.dart';
import '../../controllers/product_controller.dart';

class aOrderDetailScreen extends StatefulWidget {
  @override
  _aOrderDetailScreenState createState() => _aOrderDetailScreenState();
}

class _aOrderDetailScreenState extends State<aOrderDetailScreen> {
  final ProfileScreenController _controller = ProfileScreenController();
  final ProductController _productController = ProductController();
  bool isLoading = true;

  int currentPage = 0; // 현재 페이지
  int itemsPerPage = 5; // 페이지당 아이템 수
  final NumberFormat currencyFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    fetchOrders(); // 주문 데이터를 가져옵니다.
  }

  Future<void> fetchOrders() async {
    try {
      await _controller.fetchUserOrders(context); // 주문 데이터를 가져옵니다.

      setState(() {
        // 데이터를 최신순에서 오래된 순으로 정렬
        _controller.orders.sort((a, b) {
          final dateA = DateTime.parse(a['createdAt']);
          final dateB = DateTime.parse(b['createdAt']);
          return dateB.compareTo(dateA); // 내림차순 정렬
        });

        isLoading = false; // 로딩 상태를 false로 설정
      });
    } catch (e) {
      print('주문 데이터를 가져오는 중 오류 발생: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> getOrdersForPage() {
    final totalOrders = _controller.orders.length;

    // 마지막 페이지부터 5개씩 슬라이싱
    final start = totalOrders - (currentPage + 1) * itemsPerPage;
    final end = totalOrders - currentPage * itemsPerPage;

    // 범위가 초과되지 않도록 조정하고 타입을 변환
    return _controller.orders
        .sublist(
      start < 0 ? 0 : start,
      end > totalOrders ? totalOrders : end,
    )
        .cast<Map<String, dynamic>>(); // 명시적으로 타입 변환
  }

  Future<String> fetchMainImage(String productId) async {
    try {
      final productInfo = await _productController.getProductInfoById(productId);
      return productInfo['mainImageUrl'] ?? ''; // mainImageUrl 반환
    } catch (e) {
      print('상품 정보를 가져오는 중 오류 발생: $e');
      return ''; // 오류 발생 시 빈 문자열 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalOrders = _controller.orders.length;
    final totalPages = (totalOrders / itemsPerPage).ceil();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '주문내역',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : _controller.orders.isEmpty
          ? Center(
        child: Text(
          '주문 내역이 없습니다.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: getOrdersForPage().length,
              itemBuilder: (context, index) {
                final order = getOrdersForPage()[index];
                return _buildOrderItem(order);
              },
            ),
          ),
          _buildPaginationControls(totalPages),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final formattedDate = _formatDate(order['createdAt'] ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var item in items)
          FutureBuilder<String>(
            future: fetchMainImage(item['productId'] ?? ''),
            builder: (context, snapshot) {
              final mainImageUrl = snapshot.data ?? '';
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey[300]!, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      spreadRadius: 2.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: mainImageUrl.isNotEmpty
                                ? Image.network(
                              mainImageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey,
                              child: Icon(Icons.image, color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'] ?? '상품명 없음',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '사이즈: ${item['sizes']?[0]['size'] ?? '알 수 없음'}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '수량: ${item['sizes']?[0]['quantity'] ?? 0}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '총 ${currencyFormat.format(order['totalAmount'] ?? 0)} 원', // 쉼표 포맷 적용
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Divider(color: Colors.grey[300]),
                      Text(
                        '결제 상태: ${order['paymentStatus'] ?? '알 수 없음'}',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '주문 상태: ${order['orderStatus'] ?? '알 수 없음'}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '주문일시: $formattedDate',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: currentPage > 0
              ? () {
            setState(() {
              currentPage--;
            });
          }
              : null,
        ),
        Text('${currentPage + 1} / $totalPages'),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: currentPage < totalPages - 1
              ? () {
            setState(() {
              currentPage++;
            });
          }
              : null,
        ),
      ],
    );
  }

  String _formatDate(String originalDate) {
    try {
      final dateTime = DateTime.parse(originalDate).toLocal();
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return originalDate; // 날짜 형식이 잘못된 경우 원본 반환
    }
  }
}
