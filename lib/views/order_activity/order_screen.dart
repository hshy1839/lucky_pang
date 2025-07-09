import 'package:attedance_app/views/widget/shipped_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/order_screen_controller.dart';
import '../../routes/base_url.dart';
import '../widget/box_storage_card.dart';
import '../widget/product_storage_card.dart';
import '../widget/video_player.dart';

class OrderScreen extends StatefulWidget {
  final void Function(int)? onTabChanged;
  final PageController? pageController;

  const OrderScreen({super.key, this.pageController, this.onTabChanged});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String selectedTab = 'box'; // 'box', 'product'
  List<Map<String, dynamic>> paidOrders = [];
  bool isLoading = true;
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> unboxedProducts = [];
  List<Map<String, dynamic>> unboxedShippedProducts = [];

  @override
  void initState() {
    super.initState();
    loadOrders();
    loadUnboxedProducts();
    loadUnboxedShippedProducts();
  }

  Future<void> loadUnboxedProducts() async {
    setState(() { isLoading = true; });
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;
    final result = await OrderScreenController.getUnboxedProducts(userId);
    setState(() {
      unboxedProducts = (result ?? [])
          .where((o) =>
      o['status'] != 'shipped' &&
          (o['refunded']?['point'] ?? 0) == 0 &&
          o['unboxedProduct'] != null &&
          o['unboxedProduct']['product'] != null // ★ 여기를 추가
      )
          .toList();
      isLoading = false;
    });
  }
  Future<void> loadUnboxedShippedProducts() async {
    setState(() { isLoading = true; });
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;
    final result = await OrderScreenController.getUnboxedProducts(userId);

    // 정렬 추가!
    final list = (result ?? []).where((o) => o['status'] == 'shipped').toList();
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a['unboxedProduct']?['decidedAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['unboxedProduct']?['decidedAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    setState(() => unboxedShippedProducts = list);
    isLoading = false;
  }

  Future<void> loadOrders() async {
    setState(() { isLoading = true; });
    final userId = await storage.read(key: 'userId');
    if (userId == null) {
      print('userId not found in secure storage');
      return;
    }

    final orders = await OrderScreenController.getOrdersByUserId(userId);
    print('📦 전체 주문 수: ${orders.length}');
    print('📦 paid: ${orders.where((o) => o['status'] == 'paid').length}');

    setState(() {
      paidOrders = orders.where((o) =>
      o['status'] == 'paid' &&
          (o['unboxedProduct'] == null || o['unboxedProduct']['product'] == null)).toList();
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
                  _buildTab('배송 조회', selectedTab == 'shipped', 'shipped'),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            if (isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              )
            else if (selectedTab == 'product') ...[
              if (unboxedProducts.isEmpty) ...[
                Expanded(
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
                          '아직 당첨된 상품이 없습니다',
                          style: TextStyle(
                            fontSize: 23.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '다음 럭키박스 당첨의 주인공이 되어보세요!',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF465461),
                          ),
                        ),
                        SizedBox(height: 64.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.onTabChanged != null) {
                                  widget.onTabChanged!(4);
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
                        mainImageUrl: '${BaseUrl.value}:7778${product['mainImage']}',
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

                          // ✅ 현재 context 저장
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
                                    debugPrint('✅ refundOrder 응답: $refunded');

                                    // ✅ context 유효성 검사 후 다이얼로그 표시
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
                  ? CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              )
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
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: ElevatedButton(
                            onPressed: () {
                              if (widget.onTabChanged != null) {
                                widget.onTabChanged!(4);
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
                child: ListView.builder(
                  itemCount: paidOrders.length,
                  itemBuilder: (context, index) {
                    final order = paidOrders[index];
                    return BoxStorageCard(
                      boxId: order['box']?['_id'] ?? '',
                      orderId: order['_id'],
                      boxName: order['box']['name'] ?? '알 수 없음',
                      createdAt: order['createdAt'] ?? '',
                      paymentAmount: order['paymentAmount'] ?? 0,
                      paymentType: order['paymentType'] ?? 'point',
                      pointUsed: order['pointUsed'] ?? 0,
                      boxPrice: order['box']['price'] ?? 0,
                      onOpenPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OpenBoxVideoScreen(orderId: order['_id']),
                          ),
                        );
                      },
                      onGiftPressed: () {},
                    );
                  },
                ),
              ),
            ]
           else if (selectedTab == 'shipped') ...[
              if (unboxedShippedProducts.isEmpty) ...[
                Expanded(
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
                          '아직 배송 신청한 상품이 없습니다',
                          style: TextStyle(
                            fontSize: 23.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '다음 럭키박스 당첨의 주인공이 되어보세요!',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF465461),
                          ),
                        ),
                        SizedBox(height: 64.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.onTabChanged != null) {
                                  widget.onTabChanged!(4);
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
              ] else ...[
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 12.h),
                    itemCount: unboxedShippedProducts.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final order = unboxedShippedProducts[index];
                      final product = order['unboxedProduct']['product'];

                      return ShippedProductCard(
                        productId: order['unboxedProduct']?['product']['_id'] ?? '',
                        mainImageUrl: '${BaseUrl.value}:7778${product['mainImage']}',
                        productName: '${product['name']}',
                        orderId: order['_id'],
                        acquiredAt: '${order['unboxedProduct']['decidedAt'].substring(0, 16)} 획득',
                        purchasePrice: (order['paymentAmount'] ?? 0) + (order['pointUsed'] ?? 0),
                        consumerPrice: product['consumerPrice'],
                        brand: '${product['brand']}',
                        dDay: 'D-90',
                        isLocked: false,
                          onCopyPressed: () {
                            final trackingNumber = order['trackingNumber'];

                            if (trackingNumber == null || trackingNumber.toString().isEmpty) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('알림'),
                                  content: Text('아직 운송장 번호가 등록되지 않은 상품입니다!'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('확인'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Clipboard.setData(ClipboardData(text: trackingNumber.toString()));
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('복사 완료'),
                                  content: Text('운송장 번호가 클립보드에 복사되었습니다!'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('확인'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          onTrackPressed: () async {
                            const url = 'https://search.naver.com/search.naver?where=nexearch&sm=top_hty&fbm=0&ie=utf8&query=%EC%9A%B4%EC%86%A1%EC%9E%A5+%EC%A1%B0%ED%9A%8C';

                            if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('오류'),
                                  content: Text('브라우저를 열 수 없습니다.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('확인'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }


                      );

                    },
                  ),
                ),
              ],
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
          onTap: () async {
            setState(() => selectedTab = key);

            // 탭 변경 후 해당 데이터 다시 로딩
            if (key == 'box') {
              await loadOrders();
            } else if (key == 'product') {
              await loadUnboxedProducts();
            } else if (key == 'shipped') {
              await loadUnboxedShippedProducts();
            }
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            height: 50.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : const Color(0xFFF5F6F6),
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF8D969D),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
