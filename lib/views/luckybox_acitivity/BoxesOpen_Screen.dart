import 'dart:async';
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
  static const int _maxBatchOpen = 10;

  List<Map<String, dynamic>> unboxedProducts = [];
  bool isLoading = true;

  String? _userId;
  List<String> _openableOrderIds = [];
  bool _checkingOpenables = true;

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
    final raw = value.toString().trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final fixed = _fixAbsoluteUrl(raw);
      return fixed;
    }
    if (raw.startsWith('/uploads/')) {
      return _join(_base, raw);
    }
    final looksLegacyMain =
        raw.startsWith('/product_main_images/') || raw.startsWith('product_main_images/');
    final key = looksLegacyMain ? raw.replaceFirst(RegExp(r'^/'), '') : raw;
    return _join(_base, _join('media', Uri.encodeComponent(key)));
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        unboxedProducts = [];
      });
    }

    final List<Map<String, dynamic>> temp = [];
    String? tempUserId;

    // 한 번에 최대 10개
    final ids = widget.orderIds.take(_maxBatchOpen).toList();

    // ✅ 배치 언박싱 호출
    final results = await OrderScreenController.unboxOrdersBatch(ids);

    int successCnt = 0;
    int failCnt = 0;

    for (final r in results) {
      if (r['success'] == true && r['order'] != null) {
        final order = r['order'] as Map<String, dynamic>;
        final product = order['unboxedProduct']?['product'];
        tempUserId ??= (order['user']?['_id'] ?? order['userId'] ?? order['user'])?.toString();
        if (product != null) {
          final dynamic rawMain = product['mainImageUrl'] ??
              product['mainImage'] ??
              (product['images'] is List && (product['images'] as List).isNotEmpty
                  ? product['images'][0]
                  : null);
          final resolved = _resolveImage(rawMain);
          temp.add({
            'productName': product['name'],
            'brand': product['brand'],
            'mainImageUrl': resolved,
            'consumerPrice': product['consumerPrice'] ?? 0,
          });
          successCnt++;
        } else {
          failCnt++;
        }
      } else {
        failCnt++;
        if (mounted && r['message'] != null) {
          // 필요시 사용자 안내
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('언박싱 실패: ${r['message']}')));
        }
      }
    }

    if (!mounted) return;
    setState(() {
      unboxedProducts = temp;
      _userId = tempUserId;
      isLoading = false;
    });

    if (failCnt > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('언박싱 완료: $successCnt개, 실패: $failCnt개')),
      );
    }

    await _loadOpenableOrders();
  }

  Future<void> _loadOpenableOrders() async {
    try {
      if (_userId == null) {
        if (!mounted) return;
        setState(() {
          _openableOrderIds = [];
          _checkingOpenables = false;
        });
        return;
      }

      final orders = await OrderScreenController.getOrdersByUserId(_userId!);

      final unopenedCandidates = orders.where((o) {
        final isBox = o['box'] != null || (o['type'] == 'box');
        final notOpened =
            (o['unboxedProduct'] == null) || (o['unboxedProduct']?['product'] == null);
        final isPaid = (o['status'] == 'paid');
        return isBox && notOpened && isPaid;
      }).toList();

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _openableOrderIds = [];
        _checkingOpenables = false;
      });
    }
  }

  Future<void> _openNextBoxes(int n) async {
    if (_openableOrderIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('열 수 있는 박스가 없습니다.')),
      );
      return;
    }
    final take = _openableOrderIds.length >= n ? n : _openableOrderIds.length;
    final ids = _openableOrderIds.take(take).toList();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OpenBoxVideoScreen(
          orderId: n == 1 ? ids.first : null,
          orderIds: n > 1 ? ids : null,
          isBatch: n > 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'ko_KR');

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
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40.h),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: GridView.builder(
                      padding: EdgeInsets.only(bottom: 150.h),
                      itemCount: unboxedProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10.h,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 0.6,
                      ),
                      itemBuilder: (context, index) {
                        final product = unboxedProducts[index];
                        final imgUrl = (product['mainImageUrl'] ?? '').toString();

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
                                  child: imgUrl.isNotEmpty
                                      ? Image.network(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: const Color(0xFFF5F6F6),
                                        alignment: Alignment.center,
                                        child: const CircularProgressIndicator(strokeWidth: 2),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFF5F6F6),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[500]),
                                    ),
                                  )
                                      : Container(
                                    color: const Color(0xFFF5F6F6),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[500]),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(8.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (product['brand'] ?? '').toString(),
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        (product['productName'] ?? '').toString(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12.sp, color: const Color(0xFF465461)),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '정가: ${currency.format(product['consumerPrice'] ?? 0)}원',
                                        style: TextStyle(fontSize: 14.sp, color: Colors.redAccent, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8.h,
              left: 8.w,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreenWithFooter(initialTabIndex: 2)),
                      );
                    },
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      child: Icon(Icons.close_rounded, size: 28.r, color: const Color(0xFF465461)),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10.h,
              left: 24.w,
              right: 24.w,
              child: hasOpenable
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: () => _openNextBoxes(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFFF5722)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: const Text('1개 열기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFFF5722))),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: canOpenTen ? () => _openNextBoxes(10) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        disabledBackgroundColor: const Color(0xFFFF5722).withOpacity(0.35),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: const Text('10개 열기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48.h,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreenWithFooter(initialTabIndex: 2)),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF5722)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: const Text('박스 보관함',
                          style: TextStyle(fontSize: 16, color: Color(0xFFFF5722), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreenWithFooter(initialTabIndex: 4)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: const Text('박스 다시 구매하기',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
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
