import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../controllers/order_screen_controller.dart';
import '../../controllers/giftcode_controller.dart'; // ✅ 추가
import '../../main.dart';
import '../../routes/base_url.dart';
import '../widget/video_player.dart';

class BoxOpenScreen extends StatefulWidget {
  const BoxOpenScreen({super.key});

  @override
  State<BoxOpenScreen> createState() => _BoxOpenScreenState();
}

class _BoxOpenScreenState extends State<BoxOpenScreen> {
  Map<String, dynamic>? orderData;
  bool loading = true;
  bool _isInit = false;

  // ✅ 추가: 열 수 있는(미개봉 + 선물코드 없음) 박스 주문ID들
  List<String> _openableOrderIds = [];
  bool _checkingOpenables = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final orderId = args?['orderId'];
      if (orderId != null) {
        _initAll(orderId);
        _isInit = true;
      }
    }
  }

  Future<void> _initAll(String orderId) async {
    await _loadOrderData(orderId);
    await _loadOpenableOrders(); // ✅ 미개봉 & 선물X 박스 목록 산출
  }

  Future<void> _loadOrderData(String orderId) async {
    final data = await OrderScreenController.unboxOrder(orderId);
    if (!mounted) return;
    setState(() {
      orderData = data;
      loading = false;
    });
  }

  Future<void> _loadOpenableOrders() async {
    try {
      // ✅ userId 확보: 서버 응답 구조에 따라 user 또는 userId로 들어올 수 있음
      final userId = orderData?['user']?['_id']
          ?? orderData?['userId']
          ?? orderData?['user'];

      if (userId == null) {
        setState(() {
          _openableOrderIds = [];
          _checkingOpenables = false;
        });
        return;
      }

      // ✅ 사용자 주문 전체
      final orders = await OrderScreenController.getOrdersByUserId(userId);

      // ✅ 미개봉 후보(박스 주문만)
      final unopenedCandidates = orders.where((o) {
        final isBox = o['box'] != null || (o['type'] == 'box');
        final notOpened = (o['unboxedProduct'] == null);
        // 상태 필드가 있다면 필요 시 추가: final isPaid = (o['status'] == 'paid' || o['paymentStatus'] == 'paid');
        return isBox && notOpened;
      }).toList();

      // ✅ 선물코드 없는 것만 남기기 (비동기 체크)
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

  // ✅ N개 열기 → BoxesopenScreen 이동
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
          orderId: n == 1 ? ids.first : null,   // ✅ 단일은 orderId로
          orderIds: n > 1 ? ids : null,         // ✅ 다건은 orderIds로
          isBatch: n > 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,###', 'ko_KR');

    if (loading || _checkingOpenables) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final product = orderData?['unboxedProduct']?['product'];
    final productName = product?['name'] ?? '상품명 없음';
    final brand = product?['brand'] ?? '브랜드 없음';
    final imageUrl = product?['mainImage'] != null
        ? '${BaseUrl.value}:7778${product?['mainImage']}'
        : '';
    final price = product?['consumerPrice'] ?? 0;

    final hasOpenable = _openableOrderIds.isNotEmpty;
    final canOpenTen = _openableOrderIds.length >= 10;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 80.h),
                Text('당첨을 축하드립니다!',
                    style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Text('아쉽게도 당첨금액 랭킹엔 들지 못했어요',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[700])),
                SizedBox(height: 40.h),

                ClipRRect(
                  borderRadius: BorderRadius.circular(50.r),
                  child: Image.network(
                    imageUrl,
                    width: 260.w,
                    height: 260.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Image.asset('assets/images/default_product.png', fit: BoxFit.cover),
                  ),
                ),

                SizedBox(height: 24.h),
                Column(
                  children: [
                    Text(brand, style: TextStyle(fontSize: 16.sp)),
                    SizedBox(height: 6.h),
                    Text(productName,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: Colors.black54)),
                  ],
                ),
                SizedBox(height: 40.h),

                Text('정가: ${formatCurrency.format(price)}원',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF5722),
                    )),
                SizedBox(height: 50.h),

                // ✅ 버튼 스위칭
                if (hasOpenable)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openNextBoxes(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // 배경 흰색
                            side: const BorderSide(color: Color(0xFFFF5722)), // 테두리 색
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
                              color: Color(0xFFFF5722), // 글자색 테두리색과 맞춤
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
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
                          child: Text(
                            canOpenTen ? '10개 열기' : '10개 열기',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
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
                          child: const Text('박스 보관함',
                              style: TextStyle(fontSize: 16, color: Color(0xFFFF5722), fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
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
                          child: const Text('박스 다시 구매하기',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 80.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
