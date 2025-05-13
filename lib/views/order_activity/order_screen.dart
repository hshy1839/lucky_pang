import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../controllers/order_screen_controller.dart';
import '../luckybox_acitivity/luckyBoxPurchase_screen.dart';
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
              padding: EdgeInsets.symmetric(horizontal: 10.w),
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
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 12.h),
                    itemCount: unboxedProducts.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final order = unboxedProducts[index];
                      final product = order['unboxedProduct']['product'];

                      return ProductStorageCard(
                        productId: order['unboxedProduct']?['product']['_id'] ?? '',
                        mainImageUrl: 'http://192.168.219.108:7778${product['mainImage']}',
                        productName: '${product['name']}',
                        orderId: order['_id'],
                        acquiredAt: '${order['unboxedProduct']['decidedAt'].substring(0, 16)} 획득',
                        purchasePrice: (order['paymentAmount'] ?? 0) + (order['pointUsed'] ?? 0),
                        consumerPrice: product['consumerPrice'],
                        brand: '${product['brand']}',
                        dDay: 'D-90',
                        isLocked: false,
                        onRefundPressed: () {
                          final refundRateStr = product['refundProbability']?.toString() ?? '0';
                          final refundRate = double.tryParse(refundRateStr) ?? 0.0;
                          final purchasePrice = (order['paymentAmount'] ?? 0) + (order['pointUsed'] ?? 0);
                          final refundAmount = (purchasePrice * refundRate / 100).floor();

                          final dialogContext = context;

                          showDialog(
                            context: dialogContext,
                            builder: (context) => AlertDialog(
                              title: Text('포인트 환급'),
                              content: Text('$refundAmount원으로 환급하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('아니요'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);

                                    final refunded = await OrderScreenController.refundOrder(
                                      order['_id'],
                                      refundRate,
                                      description: '[${product['brand']}] ${product['name']} 포인트 환급',
                                    );

                                    if (refunded != null && dialogContext.mounted) {
                                      await showDialog(
                                        context: dialogContext,
                                        builder: (_) => AlertDialog(
                                          title: Text('환급 완료'),
                                          content: Text('$refunded원이 환급되었습니다!'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(dialogContext);
                                                setState(() {
                                                  unboxedProducts.removeWhere((o) => o['_id'] == order['_id']);
                                                });
                                              },
                                              child: Text('확인'),
                                            )
                                          ],
                                        ),
                                      );
                                    } else if (dialogContext.mounted) {
                                      await showDialog(
                                        context: dialogContext,
                                        builder: (_) => AlertDialog(
                                          title: Text('환급 실패'),
                                          content: Text('서버 오류로 환급이 처리되지 않았습니다.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogContext),
                                              child: Text('확인'),
                                            )
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  child: Text('예'),
                                ),
                              ],
                            ),
                          );
                        },
                        onGiftPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/giftcode/create',
                            arguments: {
                              'type': 'product',
                              'productId': product['_id'],
                              'orderId': order['_id'],
                            },
                          ).then((_) {
                            loadUnboxedProducts();
                          });
                        },
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
                ),
              ],
            ] else if (selectedTab == 'box') ...[
              isLoading
                  ? CircularProgressIndicator()
                  : paidOrders.isEmpty
                  ? Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/BoxEmptyStateImage.png',
                        width: 192.w,
                        height: 192.w,
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        '아직 구매한 박스가 없습니다',
                        style: TextStyle(
                          fontSize: 23.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        '다음 럭키박스 당첨의 주인공이 되어보세요!',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF465461),
                        ),
                      ),
                      SizedBox(height: 64.h),
                      // 첫 번째 버튼
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: ElevatedButton(
                            onPressed: () {
                              if (widget.onTabChanged != null) {
                                widget.onTabChanged!(4); // 4번 인덱스로 전환
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF5C43),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                            ),
                            child: Text(
                              '럭키박스 구매하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // 두 번째 버튼
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/giftCode');
                            },
                            icon: Icon(Icons.qr_code, color: Color(0xFFFF5C43)),
                            label: Text(
                              '선물코드 입력하기',
                              style: TextStyle(
                                color: Color(0xFFFF5C43),
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Color(0xFFFF5C43)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                      boxId: order['box']?['_id'] ?? '',
                      orderId: order['_id'],
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
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, String key) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => selectedTab = key),
          splashColor: Colors.transparent, // 눌렀을 때 효과 제거
          highlightColor: Colors.transparent,
          child: Container(
            height: 50.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Color(0xFFF5F6F6),
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Color(0xFF8D969D)
                ,
              ),
            ),
          ),
        ),
      ),
    );
  }

}