import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../controllers/order_screen_controller.dart';
import '../../controllers/giftcode_controller.dart';
import '../../main.dart';
import '../../routes/base_url.dart';
import '../widget/video_player.dart'; // OpenBoxVideoScreen

class BoxesopenScreen extends StatefulWidget {
  final List<String> orderIds;

  const BoxesopenScreen({super.key, required this.orderIds});

  @override
  State<BoxesopenScreen> createState() => _BoxesopenScreenState();
}

class _BoxesopenScreenState extends State<BoxesopenScreen> {
  List<Map<String, dynamic>> unboxedProducts = [];
  bool isLoading = true;

  // ✅ 추가: 하단 버튼 스위칭용 상태
  String? _userId;
  List<String> _openableOrderIds = [];
  bool _checkingOpenables = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final List<Map<String, dynamic>> temp = [];
    String? tempUserId;

    // 선택된 orderId들 언박싱
    for (final orderId in widget.orderIds) {
      final data = await OrderScreenController.unboxOrder(orderId);
      final product = data?['unboxedProduct']?['product'];

      // ✅ userId 확보 (첫 응답에서 가져옴)
      tempUserId ??= (data?['user']?['_id'] ?? data?['userId'] ?? data?['user'])?.toString();

      if (product != null) {
        temp.add({
          'productName': product['name'],
          'brand': product['brand'],
          'mainImageUrl': product['mainImage'] != null
              ? '${BaseUrl.value}:7778${product['mainImage']}'
              : null,
          'consumerPrice': product['consumerPrice'] ?? 0,
        });
      }
    }

    setState(() {
      unboxedProducts = temp;
      _userId = tempUserId;
      isLoading = false;
    });

    // ✅ 잔여 열 수 있는 박스 계산
    await _loadOpenableOrders();
  }

  Future<void> _loadOpenableOrders() async {
    try {
      if (_userId == null) {
        setState(() {
          _openableOrderIds = [];
          _checkingOpenables = false;
        });
        return;
      }

      // 사용자 전체 주문 조회
      final orders = await OrderScreenController.getOrdersByUserId(_userId!);

      // 미개봉 후보 (박스 주문만)
      final unopenedCandidates = orders.where((o) {
        final isBox = o['box'] != null || (o['type'] == 'box');
        final notOpened = (o['unboxedProduct'] == null);
        // 필요하면 상태 조건 추가: final isPaid = o['status'] == 'paid';
        return isBox && notOpened;
      }).toList();

      // 선물코드 없는 것만 남기기
      final resultIds = <String>[];
      for (final o in unopenedCandidates) {
        final orderId = (o['_id'] ?? o['orderId'])?.toString();
        final boxId = (o['box'] is Map) ? o['box']['_id'] : o['box'];
        if (orderId == null || boxId == null) continue;

        final gifted = await GiftCodeController.checkGiftCodeExists(
          type: 'box',
          boxId: boxId.toString(),
          orderId: orderId,
        );
        if (!gifted) resultIds.add(orderId);
      }

      if (!mounted) return;
      setState(() {
        _openableOrderIds = resultIds;
        _checkingOpenables = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _openableOrderIds = [];
        _checkingOpenables = false;
      });
    }
  }

  // ✅ N개 열기 → OpenBoxVideoScreen 이동
  Future<void> _openNextBoxes(int n) async {
    if (_openableOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('열 수 있는 박스가 없습니다.')),
      );
      return;
    }
    final take = _openableOrderIds.length >= n ? n : _openableOrderIds.length;
    final ids = _openableOrderIds.take(take).toList();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OpenBoxVideoScreen(
          orderId: n == 1 ? ids.first : null, // 단건이면 orderId로
          orderIds: n > 1 ? ids : null,       // 다건이면 orderIds로
          isBatch: n > 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'ko_KR');

    // 로딩 중(언박싱 로딩 또는 잔여 체크 로딩)엔 스피너
    if (isLoading || _checkingOpenables) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    final hasOpenable = _openableOrderIds.isNotEmpty;
    final canOpenTen = _openableOrderIds.length >= 10;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 30.h),
                Text(
                  '당첨을 축하드립니다!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: GridView.builder(
                      itemCount: unboxedProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10.h,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 0.6,
                      ),
                      itemBuilder: (context, index) {
                        final product = unboxedProducts[index];
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: const Color(0xFFE5E5E5)),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12.r),
                                  topRight: Radius.circular(12.r),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: product['mainImageUrl'] != null
                                      ? Image.network(
                                    product['mainImageUrl'],
                                    fit: BoxFit.cover,
                                  )
                                      : const Icon(Icons.image, size: 48),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['brand'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      product['productName'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF465461),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '정가: ${currency.format(product['consumerPrice'])}원',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 80.h), // 버튼 공간
              ],
            ),

            // ✅ 하단 버튼: 잔여 박스 있으면 1개/10개 열기, 없으면 박스 보관함/다시 구매
            Positioned(
              bottom: 16.h,
              left: 24.w,
              right: 24.w,
              child: hasOpenable
                  ? Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () => _openNextBoxes(1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFFF5722)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        child: const Text(
                          '1개 열기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: canOpenTen ? () => _openNextBoxes(10) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          disabledBackgroundColor: const Color(0xFFFF5722).withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        child: const Text(
                          '10개 열기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  : Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainScreenWithFooter(initialTabIndex: 2),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF5722)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        child: const Text(
                          '박스 보관함',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFF5722),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainScreenWithFooter(initialTabIndex: 4),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        child: const Text(
                          '박스 다시 구매하기',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
