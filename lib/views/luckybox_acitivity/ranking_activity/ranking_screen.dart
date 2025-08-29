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
  bool showRealtimeLog = true;
  List<Map<String, dynamic>> unboxedOrders = [];
  int highestPrice = 0;
  int totalPrice = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUnboxedLogs();
  }

  Future<void> fetchUnboxedLogs() async {
    setState(() => isLoading = true);

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
      final price = rawPrice is int ? rawPrice : (rawPrice as num).toInt();
      if (price > maxPrice) maxPrice = price;
      sumPrice += price;
    }

    setState(() {
      unboxedOrders = filteredOrders;
      highestPrice = maxPrice;
      totalPrice = sumPrice;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final dateFormat =
        "${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}"
        " ~ ${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}";

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
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 타이틀 & 날짜
              Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: Column(
                  children: [

                    // ✅ 여기! 탭바 헤더 위에 배치되는 가로 슬라이드 카드(고가 언박싱 하이라이트)
                    _buildHighValueCarousel(context),
                  ],
                ),
              ),

              // 탭바 헤더
              Padding(
                padding: EdgeInsets.only(top: 30.h),
                child: RankingTabBarHeader(
                  isSelected: showRealtimeLog,
                  onTap: (selected) async {
                    setState(() => showRealtimeLog = selected);
                    await fetchUnboxedLogs();
                  },
                ),
              ),

              // 본문
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: showRealtimeLog
                      ? UnboxRealtimeList(unboxedOrders: unboxedOrders) // 실시간
                      : UnboxWeeklyRanking(unboxedOrders: unboxedOrders),       // 주간 랭킹
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// 클래스 내부에 추가 헬퍼: 상대시간 표시
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('MM/dd').format(dt);
  }

  /// 상단 가로 슬라이드 카드 영역 (최근 고가 언박싱 하이라이트)
  Widget _buildHighValueCarousel(BuildContext context) {
    const int highValueThreshold = 100000; // ✅ 10만원 이상만
    final formatCurrency = NumberFormat('#,###');

    int _priceOf(Map<String, dynamic> o) {
      final raw = o['unboxedProduct']?['product']?['consumerPrice'];
      return raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    }

    String? _imageUrl(dynamic raw) {
      if (raw == null) return null;
      final s = '$raw';
      if (s.isEmpty) return null;
      return s.startsWith('http')
          ? s
          : '${BaseUrl.value}:7778${s.startsWith('/') ? '' : '/'}$s';
    }

    // ✅ 상세 페이지에 맞춰 product를 정규화
    Map<String, dynamic> _sanitizeProductForDetail(dynamic rawProduct) {
      final Map<String, dynamic> p = Map<String, dynamic>.from(rawProduct ?? {});

      // 숫자 -> 문자열 (Detail 화면이 String을 기대)
      for (final key in ['consumerPrice', 'price']) {
        final v = p[key];
        if (v is num) p[key] = v.toString();
      }

      // 메인 이미지 후보 → 절대경로화
      final mainCandidate =
          p['mainImageUrl'] ?? p['mainImage'] ?? p['image'] ?? p['main_image'];
      final mainAbs = _imageUrl(mainCandidate);
      if (mainAbs != null && mainAbs.isNotEmpty) {
        p['mainImageUrl'] = mainAbs;
      } else if (p['mainImageUrl'] != null) {
        p['mainImageUrl'] = p['mainImageUrl'].toString();
      }

      // 추가 이미지 (List/CSV/JSON 문자열/Map 모두 지원) → CSV로 저장 + 절대경로화
      dynamic aiu = p['additionalImageUrls'] ??
          p['additionalImages'] ??
          p['detailImages'] ??
          p['images'] ??
          p['detailImageUrls'] ??
          p['detail_images'];

      final List<String> urls = [];

      String? _fromMap(dynamic m) {
        if (m is Map) {
          for (final k in ['url', 'imageUrl', 'image', 'src', 'path', 'fileUrl', 'uri']) {
            if (m[k] != null && m[k].toString().trim().isNotEmpty) {
              return m[k].toString().trim();
            }
          }
        }
        return null;
      }

      void _add(dynamic e) {
        String? candidate;
        if (e == null) return;
        if (e is String) {
          candidate = e.trim();
        } else if (e is Map) {
          candidate = _fromMap(e);
        } else {
          candidate = e.toString().trim();
        }
        if (candidate == null || candidate.isEmpty) return;

        final abs = _imageUrl(candidate) ?? candidate;
        final t = abs.trim();
        if (t.isNotEmpty) urls.add(t);
      }

      if (aiu is List) {
        for (final e in aiu) _add(e);
      } else if (aiu is Map) {
        for (final k in ['urls', 'images', 'list', 'data']) {
          if (aiu[k] is List) {
            for (final e in aiu[k]) _add(e);
          }
        }
        final one = _fromMap(aiu);
        if (one != null) _add(one);
      } else if (aiu is String && aiu.trim().isNotEmpty) {
        final s = aiu.trim();
        if ((s.startsWith('[') && s.endsWith(']')) || (s.startsWith('{') && s.endsWith('}'))) {
          try {
            final decoded = jsonDecode(s);
            if (decoded is List) {
              for (final e in decoded) _add(e);
            } else if (decoded is Map) {
              for (final k in ['urls', 'images', 'list', 'data']) {
                if (decoded[k] is List) {
                  for (final e in decoded[k]) _add(e);
                }
              }
              final one = _fromMap(decoded);
              if (one != null) _add(one);
            }
          } catch (_) {
            for (final part in s.split(RegExp(r'[,\|\n]'))) _add(part);
          }
        } else {
          for (final part in s.split(RegExp(r'[,\|\n]'))) _add(part);
        }
      }

      final cleaned = urls.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();

      // 메인 이미지가 없고 추가 이미지가 있으면 첫 이미지를 메인으로
      if ((p['mainImageUrl'] == null || p['mainImageUrl'].toString().isEmpty) && cleaned.isNotEmpty) {
        p['mainImageUrl'] = cleaned.first;
      }

      p['additionalImageUrls'] = cleaned.join(',');

      for (final key in ['brand', 'brandName', 'name', 'category']) {
        if (p[key] != null) p[key] = p[key].toString();
      }

      return p;
    }

    // ✅ 10만원 이상만 필터 + 최신순 정렬
    final highValueOrders = unboxedOrders
        .where((o) => _priceOf(o) >= highValueThreshold)
        .toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['unboxedProduct']?['decidedAt'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b['unboxedProduct']?['decidedAt'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

    final items = highValueOrders.take(20).toList(); // ✅ 최근 20개만

    // 카드 UI (이미지 탭 가능)
    Widget _card({
      String? profileName,
      String rightTimeText = '',
      String? brand,
      String? productName,
      int? price,
      String? productImageUrl,
      String? boxName,
      VoidCallback? onImageTap, // 👈 추가
      bool isEmpty = false,
    }) {
      return Container(
        width: 330.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: const Offset(0, 2))],
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: GestureDetector(
                onTap: (productImageUrl != null && !isEmpty) ? onImageTap : null, // 👈 탭 이동
                child: SizedBox(
                  width: 130.r,
                  height: 130.r,
                  child: productImageUrl != null && !isEmpty
                      ? CachedNetworkImage(
                    imageUrl: productImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (c, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (c, _, __) => Container(color: Colors.grey[200]),
                  )
                      : Container(color: Colors.grey[200]),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height:4.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEmpty ? '최근 내역이 없습니다.' : '${profileName ?? '익명'}님이 당첨됐어요!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black87, fontSize: 16.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isEmpty ? '' : (brand ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black45, fontSize: 16.sp),
                  ),
                  if (!isEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      productName ?? '상품명 없음',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.black54, fontSize: 18.sp),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  if (!(isEmpty || price == null))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '정가: ${formatCurrency.format(price)} 원',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFFF5722),
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                        if ((boxName ?? '').trim().isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Align(
                              alignment: Alignment.centerRight, // ✅ 정가 '아랫줄'의 '우측'
                              child: Text(
                                boxName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black26, // ✅ 요청 색상
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )

                ],
              ),
            ),
          ],
        ),
      );
    }

    // 데이터 없을 때
    if (items.isEmpty) {
      return SizedBox(
        height: 150.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 12.w),
              child: _card(
                isEmpty: true,
                rightTimeText: showRealtimeLog ? '최근 24시간' : '이번주',
              ),
            ),
          ],
        ),
      );
    }

    // 데이터 있을 때
    return SizedBox(
      height: 150.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final order = items[index];
          final user = order['user'];
          final product = order['unboxedProduct']?['product'];
          final decidedAt = DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '');
          final brand = product?['brand'] ?? product?['brandName'];
          final name = product?['name'];
          final price = _priceOf(order);
          final productImgUrl = _imageUrl(product?['mainImage'] ?? product?['mainImageUrl']);
          final productId = (product?['_id'] ?? product?['id'] ?? product?['productId'] ?? '').toString();
          final timeText = decidedAt != null ? _timeAgo(decidedAt.toLocal()) : '';


          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 16.w : 8.w, right: 12.w),
            child: _card(
              profileName: user?['nickname'],
              rightTimeText: timeText,
              brand: brand,
              productName: name,
              price: price,
              productImageUrl: productImgUrl,
              boxName: (() {
                final box = order['box'];
                final bn = box?['name'] ?? box?['title'] ?? box?['boxName'];
                return (bn == null || bn.toString().trim().isEmpty) ? '' : bn.toString();
              })(),
              onImageTap: () {
                final sanitized = _sanitizeProductForDetail(product);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      product: sanitized,
                      productId: productId,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }





}

/// 본문 리스트에서 "상단 슬라이더"는 제거한 버전
/// (중복 노출 방지용: 기존 UnboxRealtimeList에서 상단 가로 슬라이드를 빼고 리스트만 남긴 형태)
class UnboxRealtimeListNoHeader extends StatelessWidget {
  final List<Map<String, dynamic>> unboxedOrders;
  const UnboxRealtimeListNoHeader({super.key, required this.unboxedOrders});

  @override
  Widget build(BuildContext context) {
    if (unboxedOrders.isEmpty) {
      return SizedBox(
        height: 100.h,
        child: const Center(child: Text("최근 언박싱 기록이 없습니다.")),
      );
    }

    final filteredOrders = unboxedOrders
        .where((order) {
      final consumerPrice = order['unboxedProduct']?['product']?['consumerPrice'] ?? 0;
      return consumerPrice >= 20000 && consumerPrice < 100000;
    })
        .toList()
      ..sort((a, b) => DateTime.parse(b['unboxedProduct']?['decidedAt'] ?? '')
          .compareTo(DateTime.parse(a['unboxedProduct']?['decidedAt'] ?? '')));

    final latest20Orders = filteredOrders.take(20).toList();
    final formatCurrency = NumberFormat('#,###');

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: latest20Orders.length,
      itemBuilder: (context, index) {
        final order = latest20Orders[index];
        final user = order['user'];
        final product = order['unboxedProduct']?['product'];
        final box = order['box'];
        final consumerPrice = product?['consumerPrice'] ?? 0;

        final rawProfileImage = user?['profileImage'];
        final userProfileImage = (rawProfileImage != null && rawProfileImage.isNotEmpty)
            ? (rawProfileImage.startsWith('http')
            ? rawProfileImage
            : '${BaseUrl.value}:7778${rawProfileImage.startsWith('/') ? '' : '/'}$rawProfileImage')
            : null;
        final boxNameText = (() {
          final bn = box?['name'] ?? box?['title'] ?? box?['boxName'];
          return (bn == null || bn.toString().trim().isEmpty) ? '' : bn.toString();
        })();


        return Padding(
          padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 6.h),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: Colors.grey[300],
                    child: userProfileImage != null
                        ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: userProfileImage,
                        fit: BoxFit.cover,
                        width: 48.r,
                        height: 48.r,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.person, size: 28.r, color: Colors.grey[600]),
                      ),
                    )
                        : Icon(Icons.person, size: 28.r, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      user?['nickname'] ?? '익명',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 상품 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                product?['name'] ?? '상품명 없음',
                                style: TextStyle(fontSize: 15.sp, color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '정가: ${formatCurrency.format(consumerPrice)}원',
                                    style: const TextStyle(fontSize: 15, color: Color(0xFF465461)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (boxNameText.isNotEmpty)
                                  Text(
                                    boxNameText,
                                    style: TextStyle(fontSize: 14.sp, color: Colors.black26),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 박스/시간
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${formatCurrency.format(box?['price'] ?? 0)}원 박스',
                            style: TextStyle(color: Colors.black, fontSize: 14.sp),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '')
                                ?.toLocal()
                                .toString()
                                .substring(0, 16) ??
                                '',
                            style: const TextStyle(fontSize: 13, color: Colors.black45),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
