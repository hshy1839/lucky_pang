import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../controllers/order_screen_controller.dart';
import '../../controllers/giftcode_controller.dart';
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

  List<String> _openableOrderIds = [];
  bool _checkingOpenables = true;

  // ─────────────────────────────────────────────
  // URL 유틸: OrderScreen/ProductStorageCard와 동일 규칙
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
    if (value == null) {
      debugPrint('[BoxOpen][_resolveImage] value=null → ""');
      return '';
    }
    final raw = value.toString().trim();
    if (raw.isEmpty) {
      debugPrint('[BoxOpen][_resolveImage] value="" → ""');
      return '';
    }

    debugPrint('[BoxOpen][_resolveImage] IN   base=$_base raw="$raw"');

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final fixed = _fixAbsoluteUrl(raw);
      debugPrint('[BoxOpen][_resolveImage] ABS  "$raw" → "$fixed"');
      return fixed;
    }

    if (raw.startsWith('/uploads/')) {
      final url = _join(_base, raw);
      debugPrint('[BoxOpen][_resolveImage] UP   "$raw" → "$url"');
      return url;
    }

    final encodedKey = Uri.encodeComponent(raw);
    final url = _join(_base, _join('media', encodedKey));
    debugPrint('[BoxOpen][_resolveImage] KEY  "$raw" → "$url"');
    return url;
  }

  // ─────────────────────────────────────────────

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
    await _loadOpenableOrders();
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

      final orders = await OrderScreenController.getOrdersByUserId(userId);

      final unopenedCandidates = orders.where((o) {
        final isBox = o['box'] != null || (o['type'] == 'box');
        final notOpened = (o['unboxedProduct'] == null);
        return isBox && notOpened;
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

    if (loading || _checkingOpenables) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final product = orderData?['unboxedProduct']?['product'];
    final productName = product?['name'] ?? '상품명 없음';
    final brand = product?['brand'] ?? '브랜드 없음';

    // ✅ 동일 규칙 적용: presigned → 그대로, /uploads → base, key → /media/{key}
    final imageUrl = _resolveImage(product?['mainImageUrl'] ?? product?['mainImage']);

    final price = product?['consumerPrice'] ?? 0;

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
                          debugPrint('[BoxOpen] Image error: $error');
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
