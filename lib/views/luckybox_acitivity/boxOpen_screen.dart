import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../controllers/order_screen_controller.dart';
import '../../controllers/giftcode_controller.dart';
import '../../main.dart';
import '../../routes/base_url.dart';
import '../widget/video_player.dart'; // OpenBoxVideoScreen

class BoxOpenScreen extends StatefulWidget {
  const BoxOpenScreen({super.key});

  @override
  State<BoxOpenScreen> createState() => _BoxOpenScreenState();
}

class _BoxOpenScreenState extends State<BoxOpenScreen> {
  // 서버의 응답에서 "order" 객체만 저장 (기존: 전체 응답을 저장 → NPE/Key mismatch 원인)
  Map<String, dynamic>? _order; // ← 단일 주문 객체
  bool _loading = true;
  bool _isInit = false;

  List<String> _openableOrderIds = [];
  bool _checkingOpenables = true;

  // ─────────────────────────────────────────────
  // URL 유틸
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
  /// 레거시(/product_main_images/... 또는 product_main_images/...)는 key로 간주해 /media/{key},
  /// 그 외(S3 key)는 /media/{encodeURIComponent(key)}
  String _resolveImage(dynamic value) {
    if (value == null) {
      return '';
    }
    final raw = value.toString().trim();
    if (raw.isEmpty) {
      return '';
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _fixAbsoluteUrl(raw);
    }

    if (raw.startsWith('/uploads/')) {
      return _join(_base, raw);
    }

    // 레거시: /product_main_images/... 또는 product_main_images/... → key로 취급
    final looksLegacyMain =
        raw.startsWith('/product_main_images/') || raw.startsWith('product_main_images/');
    final key = looksLegacyMain ? raw.replaceFirst(RegExp(r'^/'), '') : raw;

    final encodedKey = Uri.encodeComponent(key);
    return _join(_base, _join('media', encodedKey));
  }

  // ─────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final String? orderId = args?['orderId']?.toString();

    // ✅ OpenBoxVideoScreen에서 미리 받아온 단건 결과(preResult)가 있으면 즉시 씀
    final Map<String, dynamic>? preResult = args?['preResult'];
    if (preResult != null && preResult['success'] == true && preResult['order'] != null) {
      _order = Map<String, dynamic>.from(preResult['order'] as Map);
      _loading = false;
      _isInit = true;
      setState(() {});
      _loadOpenableOrders(); // 잔여 열 수 있는 박스 계산
      return;
    }

    // preResult 없으면 서버 배치 API를 단건으로 사용 (boxes와 동일한 경로)
    if (orderId != null) {
      _initAll(orderId);
      _isInit = true;
    } else {
      // 인자 없음 → 예외 처리
      _loading = false;
      setState(() {});
    }
  }

  Future<void> _initAll(String orderId) async {
    await _loadOrderDataBatch(orderId); // ← 배치 API로 단건 언박싱
    await _loadOpenableOrders();
  }

  /// boxes처럼 "배치 API"를 사용하되, 단건 리스트로 호출
  Future<void> _loadOrderDataBatch(String orderId) async {
    setState(() => _loading = true);

    try {
      final results = await OrderScreenController.unboxOrdersBatch([orderId]);
      // 서버: [{ orderId, success, order, message }] 형태
      if (results.isNotEmpty && results.first['success'] == true && results.first['order'] != null) {
        _order = Map<String, dynamic>.from(results.first['order'] as Map);
      } else {
        final msg = (results.isNotEmpty ? results.first['message'] : '언박싱 실패')?.toString() ?? '언박싱 실패';
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('박스 열기 실패'),
              content: Text(msg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('오류'),
            content: Text('언박싱 중 오류가 발생했습니다.\n$e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadOpenableOrders() async {
    try {
      // _order는 "주문 객체"이므로, 여기서 user id 추출
      final userId =
          _order?['user']?['_id'] ?? _order?['userId'] ?? _order?['user'];

      if (userId == null) {
        setState(() {
          _openableOrderIds = [];
          _checkingOpenables = false;
        });
        return;
      }

      final orders = await OrderScreenController.getOrdersByUserId(userId.toString());

      // 미개봉 & 결제완료 상태만
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
    } catch (_) {
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
    final formatCurrency = NumberFormat('#,###', 'ko_KR');

    if (_loading || _checkingOpenables) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // _order는 단일 주문 객체
    final product = _order?['unboxedProduct']?['product'];
    final productName = product?['name'] ?? '상품명 없음';
    final brand = product?['brand'] ?? '브랜드 없음';
    final price = product?['consumerPrice'] ?? 0;

    // presigned → 그대로, /uploads → base, key → /media/{key}
    final imageUrl = _resolveImage(
      product?['mainImageUrl'] ??
          product?['mainImage'] ??
          (product?['images'] is List && (product?['images'] as List).isNotEmpty
              ? product['images'][0]
              : null),
    );

    final hasOpenable = _openableOrderIds.isNotEmpty;
    final canOpenTen = _openableOrderIds.length >= 10;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 80.h),
                    Text(
                      '당첨을 축하드립니다!',
                      style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 40.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50.r),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        width: 260.w,
                        height: 260.w,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 260.w,
                            height: 260.w,
                            color: const Color(0xFFF5F6F6),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 260.w,
                            height: 260.w,
                            color: const Color(0xFFF5F6F6),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 56,
                              color: Colors.grey[500],
                            ),
                          );
                        },
                      )
                          : Container(
                        width: 260.w,
                        height: 260.w,
                        color: const Color(0xFFF5F6F6),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Column(
                      children: [
                        Text(brand, style: TextStyle(fontSize: 16.sp)),
                        SizedBox(height: 6.h),
                        Text(
                          productName,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
                    Text(
                      '정가: ${formatCurrency.format(price)}원',
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF5722),
                      ),
                    ),
                    SizedBox(height: 50.h),
                    if (hasOpenable)
                      Row(
                        children: [
                          Expanded(
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
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: canOpenTen ? () => _openNextBoxes(10) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                disabledBackgroundColor:
                                const Color(0xFFFF5722).withOpacity(0.35),
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
                                    builder: (_) =>
                                    const MainScreenWithFooter(initialTabIndex: 2),
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
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const MainScreenWithFooter(initialTabIndex: 4),
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
                        ],
                      ),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8.h,
              left: 8.w,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const MainScreenWithFooter(initialTabIndex: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    child: Icon(
                      Icons.close_rounded,
                      size: 28.r,
                      color: const Color(0xFF465461),
                    ),
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
