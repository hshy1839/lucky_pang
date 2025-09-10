import 'dart:convert';
import 'package:attedance_app/views/widget/shipped_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../controllers/giftcode_controller.dart';
import '../../controllers/order_screen_controller.dart';
import '../../routes/base_url.dart';
import '../widget/box_storage_card.dart';
import '../widget/pagination_bar.dart';
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
  String selectedTab = 'box'; // 'box', 'product', 'shipped'
  bool isLoading = true;
  final storage = const FlutterSecureStorage();
  final _httpClient = http.Client();
  // 현재 페이지 데이터(서버사이드)
  static const int _pageSize = 30;

  // 박스
  int _pageBox = 1;
  int _totalBoxCount = 0;
  List<Map<String, dynamic>> _boxPageItems = [];

  // 상품(미배송)
  int _pageProduct = 1;
  int _totalProductCount = 0;
  List<Map<String, dynamic>> _productPageItems = [];

  // 배송 조회(배송신청된)
  int _pageShipped = 1;
  int _totalShippedCount = 0;
  List<Map<String, dynamic>> _shippedPageItems = [];

  // 체크/락 상태 (페이지 단위로 동작)
  Set<String> selectedOrderIds = {};     // 상품 탭 선택 (현재 페이지 한정)
  Set<String> selectedBoxOrderIds = {};  // 박스 탭 선택 (현재 페이지 한정)
  Map<String, bool> lockedProductIds = {}; // orderId -> manual lock (페이지 내)

  // URL 유틸
  String get _root => BaseUrl.value.trim().replaceAll(RegExp(r'/+$'), '');
  String get _base {
    final u = Uri.tryParse(_root);
    if (u != null && u.hasPort) return _root;
    return '$_root:7778';
  }
  String _join(String a, String b) {
    final left = a.replaceAll(RegExp(r'/+$'), '');
    final right = b.replaceAll(RegExp(r'^/+'), '');
    return '$left/$right';
  }
  String _fixAbsoluteUrl(String s) {
    final m = RegExp(r'^(https?:\/\/[^\/\s]+)(\/?.*)$').firstMatch(s);
    if (m == null) return s;
    final authority = m.group(1)!;
    var rest = m.group(2)!;
    if (rest.isEmpty) return s;
    if (!rest.startsWith('/')) rest = '/$rest';
    return '$authority$rest';
  }
  String _resolveImage(dynamic value) {
    if (value == null) return '';
    final s = value.toString().trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http://') || s.startsWith('https://')) return _fixAbsoluteUrl(s);
    if (s.startsWith('/uploads/')) return _join(_base, s);
    final encodedKey = Uri.encodeComponent(s);
    return _join(_base, _join('media', encodedKey));
  }

  // 날짜 16자리 안전 자르기
  String _safeDate16(dynamic decidedAt) {
    final s = (decidedAt ?? '').toString();
    return s.length >= 16 ? s.substring(0, 16) : s;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialForTab(selectedTab);
    });
  }


  Future<void> _loadInitialForTab(String tab) async {
    setState(() => isLoading = true);
    if (tab == 'box') {
      _pageBox = 1;
      await _fetchPage('box', _pageBox);
    } else if (tab == 'product') {
      _pageProduct = 1;
      await _fetchPage('product', _pageProduct);
    } else if (tab == 'shipped') {
      _pageShipped = 1;
      await _fetchPage('shipped', _pageShipped);
    }
    if (mounted) setState(() => isLoading = false);
  }


  // ─────────────────────────────────────────────────────────────
  // 서버사이드 페이지 API 호출부
  // ─────────────────────────────────────────────────────────────
  Future<void> _fetchPage(String tab, int page) async {
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;

    try {
      late Uri uri;

      if (tab == 'box') {
        uri = Uri.parse(
          '${_base}/api/orders/boxes'
              '?userId=$userId&status=paid&unboxed=false&page=$page&limit=$_pageSize',
        );
      } else if (tab == 'product') {
        uri = Uri.parse(
          '${_base}/api/orders/unboxed-products'
              '?userId=$userId&status=unshipped&refunded=false&page=$page&limit=$_pageSize',
        );
      } else if (tab == 'shipped') {
        uri = Uri.parse(
          '${_base}/api/orders/unboxed-products'
              '?userId=$userId&status=shipped&page=$page&limit=$_pageSize',
        );
      } else {
        throw Exception('Unknown tab: $tab');
      }

      final res = await _httpClient.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = json.decode(res.body) as Map<String, dynamic>;

      if (tab == 'box') {
        final items = List<Map<String, dynamic>>.from(body['items'] ?? const []);
        // 서버 불일치 대비: giftCodeExists 최소 보정
        for (final o in items) {
          o['giftCodeExists'] =
              (o['giftCode'] != null) || (o['giftCodeExists'] == true);
        }
        if (!mounted) return;
        setState(() {
          _boxPageItems = items;
          _totalBoxCount = (body['totalCount'] as int?) ?? items.length;
          _pageBox = page;
          selectedBoxOrderIds.clear();
        });
      }

      if (tab == 'product') {
        final rawList = List.from(body['items'] ?? const []);

        // 현재 동작 유지: product는 per-item giftcode 확인 (서버에서 보장되면 이 블록을 box처럼 단순화 가능)
        final items = await Future.wait(rawList.map((raw) async {
          final o = Map<String, dynamic>.from(raw as Map);
          final productId = o['unboxedProduct']?['product']?['_id'];
          if (productId != null) {
            try {
              final exists = await GiftCodeController.checkGiftCodeExists(
                type: 'product',
                orderId: o['_id'],
                productId: productId,
              );
              o['giftCodeExists'] = exists;
            } catch (_) {
              o['giftCodeExists'] = (o['giftCodeExists'] == true);
            }
          } else {
            o['giftCodeExists'] = false;
          }
          return o;
        }));

        if (!mounted) return;
        setState(() {
          _productPageItems = items.cast<Map<String, dynamic>>();
          _totalProductCount = (body['totalCount'] as int?) ?? _productPageItems.length;
          _pageProduct = page;
          selectedOrderIds.clear();
          lockedProductIds.clear();
        });
      }

      if (tab == 'shipped') {
        final list = List<Map<String, dynamic>>.from(body['items'] ?? const []);
        if (!mounted) return;
        setState(() {
          _shippedPageItems = list;
          _totalShippedCount = (body['totalCount'] as int?) ?? _shippedPageItems.length;
          _pageShipped = page;
        });
      }
    } catch (e) {
      debugPrint('[_fetchPage][$tab] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목록을 불러오지 못했습니다. $e')),
      );

      setState(() {
        if (tab == 'box') {
          _boxPageItems = [];
          _totalBoxCount = 0;
        } else if (tab == 'product') {
          _productPageItems = [];
          _totalProductCount = 0;
        } else if (tab == 'shipped') {
          _shippedPageItems = [];
          _totalShippedCount = 0;
        }
      });
    }
  }
  Future<int?> _refundOne({
    required String orderId,
    required double refundRate,
    required String description,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return null;

      final uri = Uri.parse('$_base/api/orders/$orderId/refund');
      final res = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'refundRate': refundRate,
          'description': description,
        }),
      );

      if (res.statusCode != 200) return null;
      final data = json.decode(res.body);
      if (data['success'] == true && data['refundedAmount'] != null) {
        return data['refundedAmount'] as int;
      }
      return null;
    } catch (e) {
      debugPrint('[_refundOne] $e');
      return null;
    }
  }

  Future<void> _fetchBoxPage(int page) async {
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;

    try {
      final uri = Uri.parse(
        '${_base}/api/orders/boxes'
            '?userId=$userId&status=paid&unboxed=false&page=$page&limit=$_pageSize',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = json.decode(res.body) as Map<String, dynamic>;

      final items = List<Map<String, dynamic>>.from(body['items'] ?? const []);

      for (final o in items) {
        o['giftCodeExists'] =
            (o['giftCode'] != null) || (o['giftCodeExists'] == true);
      }


      if (!mounted) return;
      setState(() {
        _boxPageItems = items;
        _totalBoxCount = (body['totalCount'] as int?) ?? items.length;
        _pageBox = page;
        selectedBoxOrderIds.clear();
      });
    } catch (e) {
      debugPrint('[_fetchBoxPage] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('박스 목록을 불러오지 못했습니다. $e')),
      );
      setState(() {
        _boxPageItems = [];
        _totalBoxCount = 0;
      });
    }
  }



  Future<void> _fetchProductPage(int page) async {
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;

    try {
      final uri = Uri.parse(
        '${_base}/api/orders/unboxed-products'
            '?userId=$userId&status=unshipped&refunded=false&page=$page&limit=$_pageSize',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = json.decode(res.body) as Map<String, dynamic>;
      final List list = (body['items'] ?? []) as List;

      // 페이지 아이템의 giftCodeExists 보정 (최대 30개, 순차 확인)
      final items = await Future.wait(list.map((raw) async {
        final o = Map<String, dynamic>.from(raw as Map);
        final productId = o['unboxedProduct']?['product']?['_id'];
        if (productId != null) {
          final exists = await GiftCodeController.checkGiftCodeExists(
            type: 'product',
            orderId: o['_id'],
            productId: productId,
          );
          o['giftCodeExists'] = exists;
        } else {
          o['giftCodeExists'] = false;
        }
        return o;
      }));

      setState(() {
        _productPageItems = items.cast<Map<String, dynamic>>();
        _totalProductCount = (body['totalCount'] ?? _productPageItems.length) as int;
        _pageProduct = page;
        selectedOrderIds.clear();
        lockedProductIds.clear();
      });
    } catch (e) {
      debugPrint('[_fetchProductPage] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상품 목록을 불러오지 못했습니다. $e')),
        );
      }
      setState(() {
        _productPageItems = [];
        _totalProductCount = 0;
      });
    }
  }

  Future<void> _fetchShippedPage(int page) async {
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;

    try {
      final uri = Uri.parse(
        '${_base}/api/orders/unboxed-products'
            '?userId=$userId&status=shipped&page=$page&limit=$_pageSize',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = json.decode(res.body) as Map<String, dynamic>;
      final List list = (body['items'] ?? []) as List;

      setState(() {
        _shippedPageItems = list.cast<Map<String, dynamic>>();
        _totalShippedCount = (body['totalCount'] ?? _shippedPageItems.length) as int;
        _pageShipped = page;
      });
    } catch (e) {
      debugPrint('[_fetchShippedPage] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('배송 목록을 불러오지 못했습니다. $e')),
        );
      }
      setState(() {
        _shippedPageItems = [];
        _totalShippedCount = 0;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 선택/동작 (페이지 단위)
  // ─────────────────────────────────────────────────────────────

  bool isSelected(String orderId) => selectedOrderIds.contains(orderId);
  bool isBoxSelected(String orderId) => selectedBoxOrderIds.contains(orderId);

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
    // 현재 페이지에 보이는 것 중 선택 + 열 수 있는 박스만
    final validSelected = _boxPageItems.where((o) {
      final isSelected = selectedBoxOrderIds.contains(o['_id']);
      final hasGiftCode = o['giftCode'] != null || o['giftCodeExists'] == true;
      final isUnboxed = o['unboxedProduct'] != null && o['unboxedProduct']['product'] != null;
      return isSelected && !hasGiftCode && !isUnboxed;
    }).toList();

    if (validSelected.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('선택 오류'),
          content: Text('열 수 있는 박스를 선택하세요.'),
        ),
      );
      return;
    }

    List<Map<String, dynamic>> toOpen = validSelected;
    if (validSelected.length > _maxBatchOpen) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('일괄열기'),
          content: Text('선택된 ${validSelected.length}개 중\n'
              '최대 $_maxBatchOpen개만 일괄 열기가 가능합니다.\n'
              '진행 하시겠습니까?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소', style: TextStyle(color: Colors.red),)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('진행', style: TextStyle(color: Colors.blue))),
          ],
        ),
      );
      if (proceed != true) return;
      toOpen = validSelected.take(_maxBatchOpen).toList();
    }

    final orderIds = toOpen.map((o) => o['_id'].toString()).toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenBoxVideoScreen(
          orderIds: orderIds,
          isBatch: true,
        ),
      ),
    );

    await _fetchBoxPage(_pageBox);
    if (mounted) setState(() => selectedBoxOrderIds.clear());
  }

  Future<void> _handleBatchRefund() async {
    final selectedOrders = _productPageItems
        .where((o) => selectedOrderIds.contains(o['_id']))
        .toList();

    if (selectedOrders.isEmpty) return;

    // 총 환급 예상 포인트(표시용)
    int totalRefundPoints = 0;
    for (final order in selectedOrders) {
      final product = order['unboxedProduct']?['product'] ?? {};
      final refundRateStr = product['refundProbability']?.toString() ?? '0';
      final refundRate = double.tryParse(refundRateStr) ?? 0.0;
      final purchasePrice = (order['paymentAmount'] ?? 0) + (order['pointUsed'] ?? 0);
      totalRefundPoints += (purchasePrice * refundRate / 100).floor() as int;
    }
    final formattedTotal = NumberFormat('#,###').format(totalRefundPoints);

    // 확인 다이얼로그
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

    // 개수에 따라 분기: 1개는 기존 UX 유지, 2개 이상은 동시 전송
    if (selectedOrders.length == 1) {
      final order = selectedOrders.first;
      final product = order['unboxedProduct']?['product'] ?? {};
      final refundRateStr = product['refundProbability']?.toString() ?? '0';
      final refundRate = double.tryParse(refundRateStr) ?? 0.0;
      final orderId = (order['_id'] ?? '').toString();

      final refunded = await _refundOne(
        orderId: orderId,
        refundRate: refundRate,
        description: '[${product['brand'] ?? ''}] ${product['name'] ?? ''} 포인트 환급',
      );

      if (!mounted) return;
      if (refunded != null) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('환급 완료'),
            content: Text('$refunded원이 환급되었습니다!'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
          ),
        );
        setState(() {
          _productPageItems.removeWhere((o) => (o['_id'] ?? '').toString() == orderId);
          selectedOrderIds.remove(orderId);
        });
        await _fetchProductPage(_pageProduct);
      } else {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('환급 실패'),
            content: const Text('서버 오류로 환급이 처리되지 않았습니다.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
          ),
        );
      }
      return;
    }

    // ✅ 2개 이상: 동시 전송 (keep-alive, Future.wait)
    _showFullscreenLoader();
    int successCnt = 0;
    try {
      final futures = <Future<void>>[];

      for (final order in selectedOrders) {
        futures.add(() async {
          final product = order['unboxedProduct']?['product'] ?? {};
          final refundRateStr = product['refundProbability']?.toString() ?? '0';
          final refundRate = double.tryParse(refundRateStr) ?? 0.0;
          final orderId = (order['_id'] ?? '').toString();

          final refunded = await _refundOne(
            orderId: orderId,
            refundRate: refundRate,
            description: '[${product['brand'] ?? ''}] ${product['name'] ?? ''} 포인트 환급',
          );

          if (refunded != null) {
            successCnt++;
          }
        }());
      }

      await Future.wait(futures);

      if (mounted) {
        setState(() {
          _productPageItems.removeWhere((o) => selectedOrderIds.contains((o['_id'] ?? '').toString()));
          selectedOrderIds.clear();
        });
      }
    } finally {
      if (mounted) _hideFullscreenLoader();
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('환급 처리 결과'),
        content: Text('$successCnt/${selectedOrders.length}개 환급이 처리되었습니다.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );

    await _fetchProductPage(_pageProduct);
  }

  // 로더
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

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    // 상품 탭 - 현재 페이지에서 선택 가능 대상
    final selectableProductOnPage = _productPageItems.where((o) =>
    o['unboxedProduct']?['product']?['isLocked'] != true &&
        (o['refunded']?['point'] ?? 0) == 0 &&
        o['giftCodeExists'] != true &&
        (lockedProductIds[(o['_id'] ?? '').toString()] != true)
    ).toList();

    final allSelectedProductOnPage = selectableProductOnPage.isNotEmpty &&
        selectableProductOnPage.every((o) => selectedOrderIds.contains((o['_id'] ?? '').toString()));

    // 박스 탭 - 현재 페이지에서 선택 가능 대상
    final boxSelectableOnPage = _boxPageItems.where((o) =>
    o['giftCode'] == null &&
        o['giftCodeExists'] != true &&
        (o['unboxedProduct'] == null || o['unboxedProduct']['product'] == null)
    ).toList();

    final allBoxSelectedOnPage = boxSelectableOnPage.isNotEmpty &&
        boxSelectableOnPage.every((o) => selectedBoxOrderIds.contains((o['_id'] ?? '').toString()));

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
              if (_totalProductCount == 0) ...[
                _emptyState(
                  title: '아직 당첨된 상품이 없습니다',
                  subtitle: '다음 럭키박스 당첨의 주인공이 되어보세요!',
                ),
              ] else ...[
                // 상단 툴바: 페이지 기준 전체선택
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Checkbox(
                        value: allSelectedProductOnPage,
                        onChanged: (val) {
                          setState(() {
                            // 현재 페이지의 모든 ID 제거
                            selectedOrderIds.removeAll(
                              _productPageItems.map((o) => (o['_id'] ?? '').toString()),
                            );
                            // 체크 시 선택 가능한 것만 다시 추가
                            if (val == true) {
                              selectedOrderIds.addAll(
                                selectableProductOnPage.map((o) => (o['_id'] ?? '').toString()),
                              );
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
                      Text('전체 $_totalProductCount개  |  ${selectedOrderIds.length}개 선택'),
                      const Spacer(),
                      TextButton(
                        onPressed: selectedOrderIds.isEmpty ? null : _handleBatchRefund,
                        style: TextButton.styleFrom(
                          foregroundColor: selectedOrderIds.isEmpty ? Colors.grey : Theme.of(context).primaryColor,
                        ),
                        child: const Text('일괄환급하기'),
                      ),
                    ],
                  ),
                ),

                // 리스트 (현재 페이지)
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 12.h),
                    itemCount: _productPageItems.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final order = _productPageItems[index] as Map<String, dynamic>?;
                      if (order == null) return const SizedBox.shrink();

                      final orderId = (order['_id'] ?? '').toString();
                      final Map<String, dynamic>? product =
                      (order['unboxedProduct']?['product'] as Map?)?.cast<String, dynamic>();
                      final decidedAt = order['unboxedProduct']?['decidedAt'];
                      if (product == null) return const SizedBox.shrink();

                      return ProductStorageCard(
                        productId: (product['_id'] ?? '').toString(),
                        mainImageUrl: _resolveImage(product['mainImageUrl'] ?? product['mainImage']),
                        productName: '${product['name'] ?? ''}',
                        isManuallyLocked: lockedProductIds[orderId] ?? false,
                        onManualLockChanged: (val) {
                          setState(() {
                            lockedProductIds[orderId] = val;
                            if (val) selectedOrderIds.remove(orderId);
                          });
                        },
                        orderId: orderId,
                        acquiredAt: '${_safeDate16(decidedAt)} 획득',
                        purchasePrice: ((order['paymentAmount'] ?? 0) as int) + ((order['pointUsed'] ?? 0) as int),
                        consumerPrice: (product['consumerPrice'] ?? 0) as int,
                        brand: '${product['brand'] ?? ''}',
                        isSelected: isSelected(orderId),
                        onSelectChanged: (val) => toggleSelection(orderId, val ?? false),
                        dDay: 'D-90',
                        isLocked: false,
                        onRefundPressed: () {
                          final refundRateStr = product['refundProbability']?.toString() ?? '0';
                          final refundRate = double.tryParse(refundRateStr) ?? 0.0;
                          final purchasePrice = ((order['paymentAmount'] ?? 0) as int) + ((order['pointUsed'] ?? 0) as int);
                          final int refundAmount = (purchasePrice * refundRate / 100).floor();

                          final dialogContext = context;

                          showDialog(
                            context: dialogContext,
                            builder: (context) => AlertDialog(
                              title: const Text('포인트 환급'),
                              content: Text('$refundAmount원으로 환급하시겠습니까?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('아니요')),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final refunded = await OrderScreenController.refundOrder(
                                      orderId, refundRate,
                                      description: '[${product['brand'] ?? ''}] ${product['name'] ?? ''} 포인트 환급',
                                    );

                                    if (refunded != null && dialogContext.mounted) {
                                      await showDialog(
                                        context: dialogContext,
                                        builder: (_) => AlertDialog(
                                          title: const Text('환급 완료'),
                                          content: Text('$refunded원이 환급되었습니다!'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(dialogContext);
                                                setState(() {
                                                  _productPageItems.removeWhere((o) => (o['_id'] ?? '').toString() == orderId);
                                                  selectedOrderIds.remove(orderId);
                                                });
                                              },
                                              child: const Text('확인'),
                                            )
                                          ],
                                        ),
                                      );
                                      await _fetchProductPage(_pageProduct);
                                    } else if (dialogContext.mounted) {
                                      await showDialog(
                                        context: dialogContext,
                                        builder: (_) => AlertDialog(
                                          title: const Text('환급 실패'),
                                          content: const Text('서버 오류로 환급이 처리되지 않았습니다.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('확인')),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('예'),
                                ),
                              ],
                            ),
                          );
                        },
                        onGiftPressed: () {
                          final productId = (product['_id'] ?? '').toString();
                          Navigator.pushNamed(
                            context,
                            '/giftcode/create',
                            arguments: {
                              'type': 'product',        // ✅ 올바른 타입
                              'orderId': orderId,
                              'productId': productId,   // ✅ productId 전달
                            },
                          ).then((_) async {
                            await _fetchProductPage(_pageProduct); // 돌아오면 최신반영
                          });
                        },
                        onDeliveryPressed: () {
                          final productMap = Map<String, dynamic>.from(product);
                          final boxInfo = Map<String, dynamic>.from(order['box'] ?? {});

                          final log = {
                            'event': 'onDeliveryPressed',
                            'orderId': orderId,
                            'productId': productMap['_id'],
                            'name': productMap['name'],
                            'brand': productMap['brand'],
                            'shippingFee': productMap['shippingFee'],
                            'price': productMap['price'],
                            'consumerPrice': productMap['consumerPrice'],
                            'mainImage': productMap['mainImage'] ?? productMap['mainImageUrl'],
                            'createdAt': productMap['createdAt'],
                            'box': {
                              'boxId': boxInfo['_id'],
                              'name': boxInfo['name'],
                              'shippingFee': boxInfo['shippingFee'],
                            },
                          };
                          debugPrint('[OrderScreen] ${jsonEncode(log)}');

                          Navigator.pushNamed(
                            context,
                            '/deliveryscreen',
                            arguments: {
                              'product': productMap,
                              'orderId': orderId,
                              'decidedAt': decidedAt,
                              'box': boxInfo,
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                // 하단 페이징
                Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: PaginationBar(
                      currentPage: _pageProduct,
                      totalItems: _totalProductCount,
                      pageSize: _pageSize,
                      onPageChanged: (p) async {
                        setState(() => isLoading = true);
                        await _fetchPage('product', p);
                        if (mounted) setState(() => isLoading = false);
                      },
                      showWhenSinglePage: true,
                      showWhenEmpty: false,
                    )
                ),
              ],
            ] else if (selectedTab == 'box') ...[
              if (_totalBoxCount == 0) ...[
                _emptyState(
                  title: '아직 구매한 박스가 없습니다',
                  subtitle: '다음 럭키박스 당첨의 주인공이 되어보세요!',
                ),
              ] else ...[
                // 상단 툴바
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Checkbox(
                        value: allBoxSelectedOnPage,
                        onChanged: (val) {
                          setState(() {
                            // 1) 현재 페이지의 모든 박스 ID 제거
                            selectedBoxOrderIds.removeAll(
                              _boxPageItems.map((e) => (e['_id'] ?? '').toString()),
                            );
                            // 2) 체크면, 선택 가능한 것만 추가
                            if (val == true) {
                              selectedBoxOrderIds.addAll(
                                boxSelectableOnPage.map((e) => (e['_id'] ?? '').toString()),
                              );
                            }
                          });
                        },
                        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) return Colors.black;
                          return Colors.white;
                        }),
                        checkColor: Colors.white,
                      ),
                      Text('전체 $_totalBoxCount개  |  ${selectedBoxOrderIds.length}개 선택'),
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

                // 리스트
                Expanded(
                  child: ListView.builder(
                    itemCount: _boxPageItems.length,
                    itemBuilder: (context, index) {
                      final order = _boxPageItems[index] as Map<String, dynamic>?;
                      if (order == null) return const SizedBox.shrink();

                      final box = order['box'] as Map<String, dynamic>?;
                      final orderId = (order['_id'] ?? '').toString();

                      return BoxStorageCard(
                        key: ValueKey(orderId.isEmpty ? index : orderId),
                        boxId: box?['_id'] ?? '',
                        orderId: orderId,
                        boxName: box?['name'] ?? '알 수 없음',
                        createdAt: order['createdAt'] ?? DateTime.now().toIso8601String(),
                        paymentAmount: (order['paymentAmount'] ?? 0) as int,
                        paymentType: (order['paymentType'] ?? 'point').toString(),
                        pointUsed: (order['pointUsed'] ?? 0) as int,
                        boxPrice: (box?['price'] ?? 0) as int,
                        status: (order['status'] ?? 'paid').toString(),

                        isSelected: isBoxSelected(orderId),
                        onSelectChanged: (val) => toggleBoxSelection(orderId, val ?? false),

                        // ✅ 여기 정리
                        initialGiftCodeExists: (order['giftCode'] != null) || (order['giftCodeExists'] == true),
                        isDisabled: (order['giftCode'] != null) || (order['giftCodeExists'] == true),

                        onOpenPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OpenBoxVideoScreen(
                                orderId: orderId,
                                isBatch: true,
                              ),
                            ),
                          );
                          await _fetchBoxPage(_pageBox);
                        },
                        onGiftPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/giftcode/create',
                            arguments: {
                              'type': 'box',
                              'boxId': box?['_id'] ?? '',
                              'orderId': orderId,
                            },
                          ).then((_) async {
                            await _fetchBoxPage(_pageBox);
                          });
                        },
                        onCancelled: () async {
                          await _fetchBoxPage(_pageBox);
                        },
                      );
                    },
                  ),
                ),

                // 하단 페이징
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: PaginationBar(
                    currentPage: _pageBox,
                    totalItems: _totalBoxCount,
                    pageSize: _pageSize,
                    onPageChanged: (p) async {
                      setState(() => isLoading = true);
                      await _fetchPage('box', p);
                      if (mounted) setState(() => isLoading = false);
                    },
                  ),
                ),
              ],
            ] else if (selectedTab == 'shipped') ...[
              if (_totalShippedCount == 0) ...[
                _emptyState(
                  title: '아직 배송 신청한 상품이 없습니다',
                  subtitle: '다음 럭키박스 당첨의 주인공이 되어보세요!',
                ),
              ] else ...[
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 12.h),
                    itemCount: _shippedPageItems.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final order = _shippedPageItems[index] as Map<String, dynamic>?;
                      if (order == null) return const SizedBox.shrink();

                      final Map<String, dynamic>? product =
                      (order['unboxedProduct']?['product'] as Map?)?.cast<String, dynamic>();
                      final decidedAt = order['unboxedProduct']?['decidedAt'];
                      final orderId = (order['_id'] ?? '').toString();
                      if (product == null) return const SizedBox.shrink();

                      return ShippedProductCard(
                        productId: (product['_id'] ?? '').toString(),
                        mainImageUrl: _resolveImage(product['mainImageUrl'] ?? product['mainImage']),
                        productName: '${product['name'] ?? ''}',
                        orderId: orderId,
                        acquiredAt: '${_safeDate16(decidedAt)} 획득',
                        purchasePrice: ((order['paymentAmount'] ?? 0) as int) + ((order['pointUsed'] ?? 0) as int),
                        consumerPrice: (product['consumerPrice'] ?? 0) as int,
                        brand: '${product['brand'] ?? ''}',
                        dDay: 'D-90',
                        isLocked: false,
                        onCopyPressed: () {
                          final trackingNumber = order['trackingNumber'];
                          if (trackingNumber == null || trackingNumber.toString().isEmpty) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('알림'),
                                content: const Text('아직 운송장 번호가 등록되지 않은 상품입니다!'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
                                ],
                              ),
                            );
                          } else {
                            Clipboard.setData(ClipboardData(text: trackingNumber.toString()));
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('복사 완료'),
                                content: const Text('운송장 번호가 클립보드에 복사되었습니다!'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
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
                                title: const Text('오류'),
                                content: const Text('브라우저를 열 수 없습니다.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
                                ],
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: PaginationBar(
                    currentPage: _pageShipped,
                    totalItems: _totalShippedCount,
                    pageSize: _pageSize,
                    onPageChanged: (p) async {
                      setState(() => isLoading = true);
                      await _fetchPage('shipped', p);
                      if (mounted) setState(() => isLoading = false);
                    },
                  ),
                ),
              ],
            ],
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
            await _loadInitialForTab(key);
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

  Widget _emptyState({required String title, required String subtitle}) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/BoxEmptyStateImage.png', width: 192.w, height: 192.w),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(fontSize: 23.sp, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w400, color: const Color(0xFF465461)),
            ),
            SizedBox(height: 64.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: SizedBox(
                width: double.infinity, height: 48.h,
                child: ElevatedButton(
                  onPressed: () => widget.onTabChanged?.call(4),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5C43),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                  ),
                  child: Text(
                    '럭키박스 구매하기',
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
                  icon: const Icon(Icons.qr_code, color: Color(0xFFFF5C43)),
                  label: Text(
                    '선물코드 입력하기',
                    style: TextStyle(color: const Color(0xFFFF5C43), fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF5C43)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
