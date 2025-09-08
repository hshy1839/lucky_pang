import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../controllers/order_screen_controller.dart';
import '../../../routes/base_url.dart';
import '../../product_activity/product_detail_screen.dart';
import '../../widget/ranking_screen_widget/ranking_tab_bar_header.dart';
import '../../widget/ranking_screen_widget/unbox_realtime_list.dart';
import '../../widget/ranking_screen_widget/unbox_weekly_ranking.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  // 탭 상태
  bool showRealtimeLog = true;

  // 본문 리스트용 데이터
  List<Map<String, dynamic>> unboxedOrders = [];
  int highestPrice = 0;
  int totalPrice = 0;
  bool isLoadingBody = true;

  // 상단 프리미엄(10만원↑) 슬라이드용 데이터 — 탭 전환과 무관하게 유지
  List<Map<String, dynamic>> premiumOrders = [];
  bool isLoadingPremium = true;

  // 무한 슬라이드 컨트롤러/타이머
  late final PageController _premiumCtrl;
  int _premiumPageIndex = 0;
  Timer? _premiumAutoTimer;
  bool _userDraggingPremium = false;

  // 무한 슬라이드 구현용 가상 페이지 폭
  static const int _kVirtualCycles = 100000;
  int _virtualBase(int itemCount) =>
      (itemCount <= 0) ? 0 : (itemCount * (_kVirtualCycles ~/ 2));
  int _currentVirtualPage() => _premiumCtrl.hasClients
      ? (_premiumCtrl.page?.round() ?? _premiumCtrl.initialPage)
      : _premiumCtrl.initialPage;

  String get _baseUrl => '${BaseUrl.value}:7778';

  String _resolveImage(dynamic value) {
    if (value == null) return '';
    final s = value.toString().trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/uploads/')) return '$_baseUrl$s';
    final key = s.startsWith('/') ? s.substring(1) : s;
    return '$_baseUrl/media/$key';
  }

  /// ✅ 닉네임 안전 추출 (API 응답 형태 다양성 대응)
  String _nicknameOf(Map<String, dynamic> order) {
    // user가 문자열(ObjectId)로 오고, 평면 닉네임이 있는 경우
    if (order['user'] is String && order['nickname'] is String) {
      final n = (order['nickname'] as String).trim();
      if (n.isNotEmpty) return n;
    }

    // 1) populate된 일반 케이스
    final u = order['user'];
    if (u is Map) {
      final n1 =
      (u['nickname'] ?? u['nickName'] ?? u['name'] ?? '').toString().trim();
      if (n1.isNotEmpty) return n1;
    }

    // 2) 다른 키명으로 유저 객체가 올 수 있는 케이스
    final alt = order['userInfo'] ??
        order['buyer'] ??
        order['owner'] ??
        order['userDoc'] ??
        order['profile'] ??
        order['member'];
    if (alt is Map) {
      final n2 = (alt['nickname'] ?? alt['nickName'] ?? alt['name'] ?? '')
          .toString()
          .trim();
      if (n2.isNotEmpty) return n2;
    }

    // 3) 납작한(플랫) 형태로 닉네임이 바로 들어오는 케이스
    final flat = (order['userNickname'] ??
        order['nickname'] ??
        order['user_name'] ??
        order['userNick'])
        ?.toString()
        .trim();
    if (flat != null && flat.isNotEmpty) return flat;

    // 4) 전부 없으면 익명
    return '익명';
  }

  @override
  void initState() {
    super.initState();

    // 프리미엄 데이터 로드 전 초기값 0
    _premiumCtrl = PageController(initialPage: 0);

    // 상단 슬라이드와 본문을 각각 로드 (분리!)
    _fetchPremiumOrders(); // 한 번만 로드해서 유지
    _fetchBodyOrders(); // 탭 전환 시마다 다시 로드

    // 3초 자동 슬라이드
    _premiumAutoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final count = _premiumItemCount;
      if (count <= 1) return;
      if (_userDraggingPremium) return;
      if (!_premiumCtrl.hasClients) return;

      // ✔ 무한 루프: 단순히 다음 페이지로만 진행
      _premiumCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );

      // ✔ 드리프트 방지: 양 끝단에 가까워지면 가운데로 점프(사용자 체감 없음)
      final vp = _currentVirtualPage();
      final leftEdge = count * 2;
      final rightEdge = count * (_kVirtualCycles - 2);
      if (vp <= leftEdge || vp >= rightEdge) {
        final target = _virtualBase(count) + (vp % count);
        _premiumCtrl.jumpToPage(target);
      }
    });
  }

  @override
  void dispose() {
    _premiumAutoTimer?.cancel();
    _premiumCtrl.dispose();
    super.dispose();
  }

  int get _premiumItemCount => premiumOrders.length;

  // ──────────────────────────────────────────────────
  // 상단 프리미엄 슬라이드: 앱 시작 시 1회 로드 후 유지(닉네임 캐싱 포함)
  // ──────────────────────────────────────────────────
  Future<void> _fetchPremiumOrders() async {
    setState(() => isLoadingPremium = true);

    final orders = await OrderScreenController.getAllUnboxedOrders();

    int _priceOf(Map<String, dynamic> o) {
      final raw = o['unboxedProduct']?['product']?['consumerPrice'];
      return raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    }

    // 10만원 이상만, 최신순 정렬 후 20개
    final highValue = orders.where((o) => _priceOf(o) >= 100000).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['unboxedProduct']?['decidedAt'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b['unboxedProduct']?['decidedAt'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

    // ✅ 표시용 닉네임을 한 번만 계산해서 캐싱
    final prepared = highValue.take(20).map<Map<String, dynamic>>((o) {
      return {
        ...o,
        '_displayNickname': _nicknameOf(o),
      };
    }).toList();

    setState(() {
      premiumOrders = prepared;
      isLoadingPremium = false;
    });

    // ✔ 아이템이 준비되면, 가상의 가운데 페이지로 점프(무한 루프 시작점)
    final count = _premiumItemCount;
    if (count > 0 && _premiumCtrl.hasClients) {
      final start = _virtualBase(count);
      _premiumCtrl.jumpToPage(start);
      _premiumPageIndex = 0; // 사용자에게 보이는 실제 인덱스
    }
  }

  // ──────────────────────────────────────────────────
  // 본문 리스트: 탭 전환 시마다 24시간/이번주로 필터 로드
  // ──────────────────────────────────────────────────
  Future<void> _fetchBodyOrders() async {
    setState(() => isLoadingBody = true);

    final orders = await OrderScreenController.getAllUnboxedOrders();

    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    final startDate = showRealtimeLog ? now.subtract(const Duration(hours: 24)) : monday;

    final filteredOrders = orders.where((order) {
      final decidedAtStr = order['unboxedProduct']?['decidedAt'];
      if (decidedAtStr == null) return false;
      final decidedAt = DateTime.tryParse(decidedAtStr);
      if (decidedAt == null) return false;
      return decidedAt.isAfter(startDate);
    }).toList();

    int maxPrice = 0;
    int sumPrice = 0;
    for (var order in filteredOrders) {
      final product = order['unboxedProduct']?['product'];
      final rawPrice = product?['consumerPrice'] ?? 0;
      final price = rawPrice is int ? rawPrice : (rawPrice as num?)?.toInt() ?? 0;
      if (price > maxPrice) maxPrice = price;
      sumPrice += price;
    }

    setState(() {
      unboxedOrders = filteredOrders;
      highestPrice = maxPrice;
      totalPrice = sumPrice;
      isLoadingBody = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF5722), Color(0xFFC622FF)],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 프리미엄(10만원↑) 자동 슬라이드 — 탭과 무관하게 유지
              Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: isLoadingPremium
                    ? SizedBox(
                  height: 150.h,
                  child: const Center(child: CircularProgressIndicator()),
                )
                    : _buildHighValueCarousel(context),
              ),

              // 탭 헤더
              Padding(
                padding: EdgeInsets.only(top: 30.h),
                child: RankingTabBarHeader(
                  isSelected: showRealtimeLog,
                  onTap: (selected) async {
                    setState(() => showRealtimeLog = selected);
                    await _fetchBodyOrders(); // ← 프리미엄은 재로드 안 함!
                  },
                  showMessage: showRealtimeLog, // 실시간에서만 "당첨을 축하드립니다!" 보임
                ),
              ),

              // 본문
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: isLoadingBody
                      ? const Center(child: CircularProgressIndicator())
                      : (showRealtimeLog
                      ? UnboxRealtimeList(unboxedOrders: unboxedOrders)
                      : UnboxWeeklyRanking(unboxedOrders: unboxedOrders)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('MM/dd').format(dt);
  }

  // 상단 프리미엄(10만원↑) 자동 슬라이드 — 무한 루프 구현
  Widget _buildHighValueCarousel(BuildContext context) {
    final items = premiumOrders; // ← 이미 정렬/상한 20개로 준비됨

    if (items.isEmpty) {
      return SizedBox(
        height: 150.h,
        child: const Center(child: Text("최근 고가 언박싱 내역이 없습니다.")),
      );
    }

    final formatCurrency = NumberFormat('#,###');

    int _priceOf(Map<String, dynamic> o) {
      final raw = o['unboxedProduct']?['product']?['consumerPrice'];
      return raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    }

    final count = items.length;

    return SizedBox(
      height: 150.h,
      child: Listener(
        onPointerDown: (_) => _userDraggingPremium = true,
        onPointerUp: (_) => _userDraggingPremium = false,
        child: PageView.builder(
          // ✔ itemCount 생략 → 사실상 무한
          controller: _premiumCtrl,
          onPageChanged: (page) {
            // ✔ 실제 노출 인덱스는 모듈로 계산
            setState(() => _premiumPageIndex = count == 0 ? 0 : (page % count));
          },
          itemBuilder: (context, page) {
            final index = count == 0 ? 0 : (page % count);
            final order = items[index];

            // ✅ 캐싱된 닉네임 우선 사용 (없으면 백업으로 _nicknameOf)
            final displayNickname = (order['_displayNickname'] as String?)?.trim();
            final nickname = (displayNickname?.isNotEmpty ?? false)
                ? displayNickname!
                : _nicknameOf(order);

            final product = order['unboxedProduct']?['product'];
            final decidedAt = DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '');
            final brand = product?['brand'] ?? product?['brandName'];
            final name = product?['name'];
            final price = _priceOf(order);
            final productImgUrl = _resolveImage(
              product?['mainImageUrl'] ?? product?['mainImage'] ?? product?['image'],
            );
            final timeText = decidedAt != null ? _timeAgo(decidedAt.toLocal()) : '';

            return Padding(
              key: ValueKey('${order['_id'] ?? 'v'}-$index'),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: const Offset(0, 2))
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: CachedNetworkImage(
                        imageUrl: productImgUrl,
                        width: 130.r,
                        height: 130.r,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$nickname님이 당첨됐어요!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
                          ),
                          SizedBox(height: 6.h),

                          // 브랜드
                          Text(
                            brand ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black45),
                          ),
                          SizedBox(height: 4.h),

                          // 상품명
                          Text(
                            name ?? '상품명 없음',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 18.sp, color: Colors.black54),
                          ),
                          SizedBox(height: 6.h),

                          // 정가
                          Text(
                            '정가: ${formatCurrency.format(price)}원',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF5722),
                            ),
                          ),
                          SizedBox(height: 2.h),

                          // 정가 아래: (좌) 박스가 / (우) 당첨 시간
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${formatCurrency.format(order['box']?['price'] ?? 0)}원 박스',
                                style: TextStyle(fontSize: 14.sp, color: Colors.black26),
                              ),
                              Text(
                                timeText,
                                style: TextStyle(fontSize: 13.sp, color: Colors.black45),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
