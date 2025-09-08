import 'package:attedance_app/views/widget/shipped_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/giftcode_controller.dart';
import '../../controllers/order_screen_controller.dart';
import '../../routes/base_url.dart';
import '../widget/box_storage_card.dart';
import '../widget/product_storage_card.dart';
import '../widget/video_player.dart';
import 'package:intl/intl.dart';

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
  Set<String> selectedOrderIds = {};
  Set<String> selectedBoxOrderIds = {};
  bool isBoxSelected(String orderId) => selectedBoxOrderIds.contains(orderId);
  Map<String, bool> lockedProductIds = {};

  // ─────────────────────────────────────────────
  // URL 유틸: MainScreen/ProductStorageCard와 동일 규칙
  // ─────────────────────────────────────────────
  String get _root => BaseUrl.value.trim().replaceAll(RegExp(r'/+$'), '');

  String get _base {
    final u = Uri.tryParse(_root);
    if (u != null && u.hasPort) return _root; // 이미 포트가 있으면 그대로
    return '$_root:7778';
  }

  String _join(String a, String b) {
    final left = a.replaceAll(RegExp(r'/+$'), '');
    final right = b.replaceAll(RegExp(r'^/+'), '');
    return '$left/$right';
  }

  // 절대 URL인데 host:port 뒤 슬래시가 없을 때 보정
  String _fixAbsoluteUrl(String s) {
    final m = RegExp(r'^(https?:\/\/[^\/\s]+)(\/?.*)$').firstMatch(s);
    if (m == null) return s; // 절대 URL 아님
    final authority = m.group(1)!; // http(s)://host[:port]
    var rest = m.group(2)!;        // path or /path or ""
    if (rest.isEmpty) return s;
    if (!rest.startsWith('/')) rest = '/$rest';
    return '$authority$rest';
  }

  /// presigned/절대 URL이면 그대로(슬래시 보정),
  /// /uploads/...는 base 붙이고,
  /// 그 외(S3 key)는 /media/{encodeURIComponent(key)}
  String _resolveImage(dynamic value) {
    if (value == null) return '';
    final s = value.toString().trim();
    if (s.isEmpty) return '';

    if (s.startsWith('http://') || s.startsWith('https://')) {
      return _fixAbsoluteUrl(s);
    }
    if (s.startsWith('/uploads/')) {
      return _join(_base, s);
    }
    final encodedKey = Uri.encodeComponent(s);
    return _join(_base, _join('media', encodedKey));
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedTab == 'box') {
        loadOrders();
      } else if (selectedTab == 'product') {
        loadUnboxedProducts();
      } else if (selectedTab == 'shipped') {
        loadUnboxedShippedProducts();
      }
    });
  }

  bool isSelected(String orderId) => selectedOrderIds.contains(orderId);

  void toggleSelection(String orderId, bool selected) {
    setState(() {
      if (selected) {
        selectedOrderIds.add(orderId);
      } else {
        selectedOrderIds.remove(orderId);
      }
    });
  }

  void toggleBoxSelection(String orderId, bool selected) {
    setState(() {
      if (selected) {
        selectedBoxOrderIds.add(orderId);
      } else {
        selectedBoxOrderIds.remove(orderId);
      }
    });
  }

  static const int _maxBatchOpen = 10;

  Future<void> _handleBatchOpenBoxes() async {
    // 선택 + 열 수 있는 박스만 필터
    final validSelectedOrders = paidOrders.where((o) {
      final isSelected = selectedBoxOrderIds.contains(o['_id']);
      final hasGiftCode = o['giftCode'] != null || o['giftCodeExists'] == true;
      final isUnboxed = o['unboxedProduct'] != null && o['unboxedProduct']['product'] != null;
      return isSelected && !hasGiftCode && !isUnboxed;
    }).toList();

    if (validSelectedOrders.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('선택 오류'),
          content: Text('열 수 있는 박스를 선택하세요.'),
        ),
      );
      return;
    }

    // 최대 10개로 컷팅
    List<Map<String, dynamic>> toOpen = validSelectedOrders;
    if (validSelectedOrders.length > _maxBatchOpen) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('일괄열기'),
          content: Text('선택된 ${validSelectedOrders.length}개 중\n'
              '최대 $_maxBatchOpen개만 일괄 열기가 가능합니다.\n'
              '진행 하시겠습니까?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('진행')),
          ],
        ),
      );
      if (proceed != true) return;
      toOpen = validSelectedOrders.take(_maxBatchOpen).toList(); // 최초 10개만
    }

    final orderIds = toOpen.map((o) => o['_id'].toString()).toList();

    // 일괄 열기는 VideoScreen에서 "직렬 + 재시도"로 수행
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenBoxVideoScreen(
          orderIds: orderIds,
          isBatch: true,
        ),
      ),
    );

    await loadOrders();
    if (mounted) {
      setState(() => selectedBoxOrderIds.clear());
    }
  }

  bool _isBoxSelectable(Map<String, dynamic> o) {
    final hasGiftCodeField = o['giftCode'] != null;
    final hasGiftCodeExists = o['giftCodeExists'] == true;
    final isUnboxed = o['unboxedProduct'] != null && o['unboxedProduct']['product'] != null;
    return !hasGiftCodeField && !hasGiftCodeExists && !isUnboxed;
  }

  Future<void> loadUnboxedProducts() async {
    setState(() { isLoading = true; });
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;
    final result = await OrderScreenController.getUnboxedProducts(userId);
    List<Map<String, dynamic>> temp = [];

    for (final o in result ?? []) {
      if (o['status'] == 'shipped') continue;
      if ((o['refunded']?['point'] ?? 0) > 0) continue;
      if (o['unboxedProduct'] == null || o['unboxedProduct']['product'] == null) continue;

      final exists = await GiftCodeController.checkGiftCodeExists(
        type: 'product',
        orderId: o['_id'],
        productId: o['unboxedProduct']['product']['_id'],
      );
      o['giftCodeExists'] = exists;

      temp.add(o);
    }

    setState(() {
      unboxedProducts = temp;
      isLoading = false;
    });
  }

  Future<void> loadUnboxedShippedProducts() async {
    setState(() { isLoading = true; });
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;
    final result = await OrderScreenController.getUnboxedProducts(userId);

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

    final futures = orders.map((o) async {
      final exists = await GiftCodeController.checkGiftCodeExists(
        type: 'box',
        boxId: o['box']['_id'],
        orderId: o['_id'],
      );
      o['giftCodeExists'] = exists;
      return o;
    }).toList();

    final ordersWithGiftCode = await Future.wait(futures);

    print('📦 전체 주문 수: ${orders.length}');
    print('📦 paid: ${orders.where((o) => o['status'] == 'paid').length}');

    final filtered = ordersWithGiftCode.where((o) =>
    o['status'] == 'paid' &&
        (o['unboxedProduct'] == null || o['unboxedProduct']['product'] == null)
    ).toList();

    setState(() {
      paidOrders = filtered;
      isLoading = false;
    });
  }

  void _showFullscreenLoader() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'loading',
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 3,
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideFullscreenLoader() {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  Future<void> _handleBatchRefund() async {
    final selectedOrders = unboxedProducts
        .where((o) => selectedOrderIds.contains(o['_id']))
        .toList();

    int totalRefundPoints = 0;
    for (final order in selectedOrders) {
      final product = order['unboxedProduct']['product'];
      final refundRateStr = product['refundProbability']?.toString() ?? '0';
      final refundRate = double.tryParse(refundRateStr) ?? 0.0;
      final purchasePrice = (order['paymentAmount'] ?? 0) + (order['pointUsed'] ?? 0);
      final int refundAmount = (purchasePrice * refundRate / 100).floor();
      totalRefundPoints += refundAmount;
    }

    final formattedTotal = NumberFormat('#,###').format(totalRefundPoints);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('일괄 환급'),
        content: Text('${selectedOrders.length}개의 상품을 $formattedTotal 포인트로 환급하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('환급')),
        ],
      ),
    );

    if (confirm != true) return;

    _showFullscreenLoader();
    int successCnt = 0;
    try {
      for (final order in selectedOrders) {
        final product = order['unboxedProduct']['product'];
        final refundRateStr = product['refundProbability']?.toString() ?? '0';
        final refundRate = double.tryParse(refundRateStr) ?? 0.0;

        final refunded = await OrderScreenController.refundOrder(
          order['_id'],
          refundRate,
          description: '[${product['brand']}] ${product['name']} 포인트 환급',
        );

        if (refunded != null) successCnt++;
      }

      setState(() {
        unboxedProducts.removeWhere((o) => selectedOrderIds.contains(o['_id']));
        selectedOrderIds.clear();
      });
    } catch (_) {
      // 에러 처리 필요 시 추가
    } finally {
      if (mounted) _hideFullscreenLoader();
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('환급 완료'),
        content: Text('$successCnt개 환급이 처리되었습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
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
                        Image.asset('assets/images/BoxEmptyStateImage.png', width: 192.w, height: 192.w),
                        SizedBox(height: 24.h),
                        Text('아직 당첨된 상품이 없습니다',
                          style: TextStyle(fontSize: 23.sp, fontWeight: FontWeight.w700, color: Colors.black),
                        ),
                        SizedBox(height: 10),
                        Text('다음 럭키박스 당첨의 주인공이 되어보세요!',
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w400, color: Color(0xFF465461)),
                        ),
                        SizedBox(height: 64.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: SizedBox(
                            width: double.infinity, height: 48.h,
                            child: ElevatedButton(
                              onPressed: () => widget.onTabChanged?.call(4),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF5C43),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                              ),
                              child: Text('럭키박스 구매하기',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: SizedBox(
                            width: double.infinity, height: 48.h,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/giftCode'),
                              icon: Icon(Icons.qr_code, color: Color(0xFFFF5C43)),
                              label: Text('선물코드 입력하기',
                                style: TextStyle(color: Color(0xFFFF5C43), fontWeight: FontWeight.bold, fontSize: 14.sp),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Color(0xFFFF5C43)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ] else ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Checkbox(
                        value: unboxedProducts
                            .where((o) =>
                        o['unboxedProduct']?['product']?['isLocked'] != true &&
                            (o['refunded']?['point'] ?? 0) == 0 &&
                            o['giftCodeExists'] != true &&
                            (lockedProductIds[o['_id']] != true))
                            .every((o) => selectedOrderIds.contains(o['_id'])),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              selectedOrderIds = unboxedProducts
                                  .where((o) =>
                              o['unboxedProduct']?['product']?['isLocked'] != true &&
                                  (o['refunded']?['point'] ?? 0) == 0 &&
                                  o['giftCodeExists'] != true &&
                                  (lockedProductIds[o['_id']] != true))
                                  .map((o) => o['_id'] as String)
                                  .toSet();
                            } else {
                              selectedOrderIds.clear();
                            }
                          });
                        },
                        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) return Colors.black;
                          return Colors.white;
                        }),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.black),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Text('전체 ${unboxedProducts.length}개  |  ${selectedOrderIds.length}개 선택'),
                      Spacer(),
                      TextButton(
                        onPressed: selectedOrderIds.isEmpty ? null : _handleBatchRefund,
                        style: TextButton.styleFrom(
                          foregroundColor: selectedOrderIds.isEmpty ? Colors.grey : Theme.of(context).primaryColor,
                        ),
                        child: Text('일괄환급하기'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 12.h),
                    itemCount: unboxedProducts.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final order = unboxedProducts[index];
                      final product = order['unboxedProduct']['product'];
                      final orderId = order['_id'];

                      return ProductStorageCard(
                        productId: order['unboxedProduct']?['product']['_id'] ?? '',
                        mainImageUrl: _resolveImage(product['mainImageUrl'] ?? product['mainImage']),
                        productName: '${product['name']}',
                        isManuallyLocked: lockedProductIds[order['_id']] ?? false,
                        onManualLockChanged: (val) {
                          setState(() {
                            lockedProductIds[order['_id']] = val;
                          });
                        },
                        orderId: order['_id'],
                        acquiredAt: '${order['unboxedProduct']['decidedAt'].substring(0, 16)} 획득',
                        purchasePrice: (order['paymentAmount'] ?? 0) + (order['pointUsed'] ?? 0),
                        consumerPrice: product['consumerPrice'],
                        brand: '${product['brand']}',
                        isSelected: isSelected(orderId),
                        onSelectChanged: (val) => toggleSelection(orderId, val ?? false),
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
                                TextButton(onPressed: () => Navigator.pop(context), child: Text('아니요')),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final refunded = await OrderScreenController.refundOrder(
                                      order['_id'], refundRate,
                                      description: '[${product['brand']}] ${product['name']} 포인트 환급',
                                    );
                                    debugPrint('✅ refundOrder 응답: $refunded');

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
                                            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('확인')),
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
                              'type': 'box',
                              'boxId': order['box']['_id'],
                              'orderId': order['_id'],
                            },
                          ).then((_) async {
                            await loadOrders();
                            setState(() {
                              selectedBoxOrderIds.remove(order['_id']);
                            });
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
              if (paidOrders.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Checkbox(
                        value: paidOrders
                            .where((o) =>
                        o['giftCode'] == null &&
                            o['giftCodeExists'] != true &&
                            (o['unboxedProduct'] == null || o['unboxedProduct']['product'] == null))
                            .every((o) => selectedBoxOrderIds.contains(o['_id'])),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              selectedBoxOrderIds = paidOrders
                                  .where((o) =>
                              o['giftCode'] == null &&
                                  o['giftCodeExists'] != true &&
                                  (o['unboxedProduct'] == null ||
                                      o['unboxedProduct']['product'] == null))
                                  .map((e) => e['_id'] as String)
                                  .toSet();
                            } else {
                              selectedBoxOrderIds.clear();
                            }
                          });
                        },
                        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) return Colors.black;
                          return Colors.white;
                        }),
                        checkColor: Colors.white,
                      ),
                      Text('전체 ${paidOrders.where((o) => o['giftCode'] == null).length}개  |  ${selectedBoxOrderIds.length}개 선택'),
                      const Spacer(),
                      TextButton(
                        onPressed: selectedBoxOrderIds.isEmpty ? null : _handleBatchOpenBoxes,
                        style: TextButton.styleFrom(
                          foregroundColor: selectedBoxOrderIds.isEmpty ? Colors.grey : Theme.of(context).primaryColor,
                        ),
                        child: const Text('일괄열기(10개)'),
                      ),
                    ],
                  ),
                ),
              ],
              isLoading
                  ? CircularProgressIndicator(color: Theme.of(context).primaryColor)
                  : !isLoading && paidOrders.isEmpty
                  ? Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/BoxEmptyStateImage.png', width: 192.w, height: 192.w),
                      SizedBox(height: 24.h),
                      Text('아직 구매한 박스가 없습니다',
                        style: TextStyle(fontSize: 23.sp, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                      SizedBox(height: 10.h),
                      Text('다음 럭키박스 당첨의 주인공이 되어보세요!',
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w400, color: Color(0xFF465461)),
                      ),
                      SizedBox(height: 64.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: SizedBox(
                          width: double.infinity, height: 48.h,
                          child: ElevatedButton(
                            onPressed: () => widget.onTabChanged?.call(4),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF5C43),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                            ),
                            child: Text('럭키박스 구매하기',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: SizedBox(
                          width: double.infinity, height: 48.h,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/giftCode'),
                            icon: Icon(Icons.qr_code, color: Color(0xFFFF5C43)),
                            label: Text('선물코드 입력하기',
                              style: TextStyle(color: Color(0xFFFF5C43), fontWeight: FontWeight.bold, fontSize: 14.sp),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Color(0xFFFF5C43)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
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
                            builder: (context) => OpenBoxVideoScreen(
                              orderId: order['_id'],
                              isBatch: true,
                            ),
                          ),
                        );
                        await loadOrders();
                      },
                      onGiftPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/giftcode/create',
                          arguments: {
                            'type': 'box',
                            'boxId': order['box']['_id'],
                            'orderId': order['_id'],
                          },
                        ).then((_) async {
                          await loadOrders();
                          setState(() {
                            selectedBoxOrderIds.remove(order['_id']);
                          });
                        });
                      },
                      isSelected: isBoxSelected(order['_id']),
                      onSelectChanged: (val) => toggleBoxSelection(order['_id'], val ?? false),
                      isDisabled: order['giftCode'] != null,
                    );
                  },
                ),
              ),
            ] else if (selectedTab == 'shipped') ...[
              if (unboxedShippedProducts.isEmpty) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/BoxEmptyStateImage.png', width: 192.w, height: 192.w),
                        SizedBox(height: 24.h),
                        Text('아직 배송 신청한 상품이 없습니다',
                          style: TextStyle(fontSize: 23.sp, fontWeight: FontWeight.w700, color: Colors.black),
                        ),
                        SizedBox(height: 10),
                        Text('다음 럭키박스 당첨의 주인공이 되어보세요!',
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w400, color: Color(0xFF465461)),
                        ),
                        SizedBox(height: 64.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: SizedBox(
                            width: double.infinity, height: 48.h,
                            child: ElevatedButton(
                              onPressed: () => widget.onTabChanged?.call(4),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF5C43),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                              ),
                              child: Text('럭키박스 구매하기',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: SizedBox(
                            width: double.infinity, height: 48.h,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/giftCode'),
                              icon: Icon(Icons.qr_code, color: Color(0xFFFF5C43)),
                              label: Text('선물코드 입력하기',
                                style: TextStyle(color: Color(0xFFFF5C43), fontWeight: FontWeight.bold, fontSize: 14.sp),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Color(0xFFFF5C43)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
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
                        mainImageUrl: _resolveImage(product['mainImageUrl'] ?? product['mainImage']),
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
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text('확인')),
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
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text('확인')),
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
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text('확인')),
                                ],
                              ),
                            );
                          }
                        },
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
            setState(() {
              selectedTab = key;
              isLoading = true;
            });

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
