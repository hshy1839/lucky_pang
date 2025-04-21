import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../controllers/order_screen_controller.dart';
import '../widget/box_storage_card.dart';
import '../widget/product_storage_card.dart';

class OrderScreen extends StatefulWidget {
  final void Function(int)? onTabChanged;
  final PageController? pageController;

  const OrderScreen({super.key, this.pageController, this.onTabChanged});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String selectedTab = 'box'; // 'box', 'product', 'delivery'
  List<Map<String, dynamic>> paidOrders = [];
  bool isLoading = true;
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> unboxedProducts = [];


  @override
  void initState() {
    super.initState();
    loadOrders();
    loadUnboxedProducts();
  }

  Future<void> loadUnboxedProducts() async {
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;
    final result = await OrderScreenController.getUnboxedProducts(userId);
    setState(() => unboxedProducts = result ?? []);
  }

  Future<void> loadOrders() async {
    final userId = await storage.read(key: 'userId');
    if (userId == null) {
      print('userId not found in secure storage');
      return;
    }

    final orders = await OrderScreenController.getOrdersByUserId(userId);
    setState(() {
      paidOrders = orders as List<Map<String, dynamic>>;
      isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTab('박스 보관함', selectedTab == 'box', 'box'),
                  _buildTab('상품 보관함', selectedTab == 'product', 'product'),
                  _buildTab('배송 조회', selectedTab == 'delivery', 'delivery'),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            if (selectedTab == 'product') ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${unboxedProducts.length}개', style: TextStyle(fontSize: 14.sp)),
                ),
              ),
              Divider(thickness: 1, color: Colors.grey.shade300),
              if (unboxedProducts.isEmpty) ...[
                SizedBox(height: 40.h),
                Image.asset(
                  'assets/icons/app_icon.jpg',
                  width: 160.w,
                  height: 160.w,
                ),
                SizedBox(height: 24.h),
                Text(
                  '보유한 상품이 없어요',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 80.h),
                Text(
                  '특별한 상품들이 와딩 님을 기다리고 있어요.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    itemCount: unboxedProducts.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final order = unboxedProducts[index];
                      final product = order['unboxedProduct']['product'];

                      return ProductStorageCard(
                        imageUrl: 'http://172.30.1.22:7778${product['mainImage']}',
                        productName: '[${product['brand']}] ${product['name']}',
                        acquiredAt: '${order['unboxedProduct']['decidedAt'].substring(0, 16)} 획득',
                        purchasePrice: (order['paymentAmount'] ?? 0) + (order['pointUsed'] ?? 0),
                        consumerPrice: product['consumerPrice'],
                        dDay: 'D-90',
                        isLocked: false,
                        onRefundPressed: () {
                          final refundRateStr = product['refundProbability']?.toString() ?? '0';
                          final refundRate = double.tryParse(refundRateStr) ?? 0.0;
                          final purchasePrice = (order['paymentAmount'] ?? 0) + (order['pointUsed'] ?? 0);

                          final refundAmount = (purchasePrice * refundRate / 100).floor();

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('포인트 환급'),
                              content: Text('$refundAmount원으로 환급하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context), // 닫기
                                  child: Text('아니요'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // TODO: 환급 처리 로직 추가
                                  },
                                  child: Text('예'),
                                ),
                              ],
                            ),
                          );
                        },

                        onGiftPressed: () {},
                        onDeliveryPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/deliveryscreen',
                            arguments: {
                              'product': product,
                              'orderId': order['_id'],
                              'decidedAt': order['unboxedProduct']['decidedAt'],
                              'box': order['box'],
                            },
                          );
                        },
                      );
                    },
                  ),
                )
              ],
              SizedBox(height: 16.h),
              _buildMainButton(
                title: '선물코드 입력하기',
                icon: Icons.confirmation_number,
                onTap: () {},
              ),
            ]
            else if (selectedTab == 'box') ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${paidOrders.length}개', style: TextStyle(fontSize: 14.sp)),
                ),
              ),
              Divider(thickness: 1, color: Colors.grey.shade300),
              isLoading
                  ? CircularProgressIndicator()
                  : paidOrders.isEmpty
                  ? Column(
                children: [
                  SizedBox(height: 40.h),
                  Image.asset(
                    'assets/icons/app_icon.jpg',
                    width: 160.w,
                    height: 160.w,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    '보유한 럭키박스가 없어요',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
                  : Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  itemCount: paidOrders.length,
                  separatorBuilder: (_, __) => SizedBox(height: 16.h),
                  itemBuilder: (context, index) {
                    final order = paidOrders[index];
                    final boxName = order['box']['name'] ?? '알 수 없음';
                    final createdAt = order['createdAt'] ?? DateTime.now().toIso8601String();
                    final paymentAmount = order['paymentAmount'] ?? 0;
                    final paymentType = order['paymentType'] ?? 'point';

                    return BoxStorageCard(
                      boxName: boxName,
                      createdAt: createdAt,
                      paymentAmount: paymentAmount,
                      paymentType: paymentType,
                      pointUsed: order['pointUsed'] ?? 0,
                      onOpenPressed: () {
                        OrderScreenController.handleBoxOpen(context, order['_id'], (updatedOrder) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('🎉 박스 열림!'),
                              content: Text(
                                '당첨된 상품: ${updatedOrder['unboxedProduct']['product']['name']}',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      paidOrders.removeWhere((o) => o['_id'] == order['_id']);
                                    });
                                    loadUnboxedProducts();
                                  },
                                  child: const Text('확인'),
                                )
                              ],
                            ),
                          );
                        });
                      },

                      onGiftPressed: () {
                        // TODO: 선물하기 처리
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              _buildMainButton(
                title: '선물코드 입력하기',
                icon: Icons.confirmation_number,
                onTap: () {},
              ),
            ]


          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, String key) {
    final textStyle = TextStyle(
      fontSize: 12.sp,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    final underlineWidth = _textWidth(label, textStyle);

    return GestureDetector(
      onTap: () => setState(() => selectedTab = key),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40.h, // ✅ 텍스트 높이 + 여유 공간 고정
            child: Center(
              child: Text(label, style: textStyle),
            ),
          ),
          SizedBox(height: 4.h),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: isSelected ? underlineWidth : 0,
            height: 2.h,
            color: isSelected ? Colors.black : Colors.transparent,
          ),
        ],
      ),
    );
  }
  double _textWidth(String text, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.size.width;
  }

  Widget _buildMainButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5C43),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          onPressed: onTap,
          label: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          icon: Icon(icon, size: 20.sp, color: Colors.white),
        ),
      ),
    );
  }
}
