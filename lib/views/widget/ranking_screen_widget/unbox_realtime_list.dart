import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../routes/base_url.dart';
import '../../product_activity/product_detail_screen.dart';

class UnboxRealtimeList extends StatelessWidget {
  final List<Map<String, dynamic>> unboxedOrders;

  const UnboxRealtimeList({super.key, required this.unboxedOrders});

  // 상대 시간
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('MM/dd').format(dt);
  }
  Map<String, dynamic> _sanitizeProductForDetail(dynamic rawProduct) {
    final Map<String, dynamic> p = Map<String, dynamic>.from(rawProduct ?? {});

    // 숫자 -> 문자열 (Detail 화면이 String을 기대)
    for (final key in ['consumerPrice', 'price']) {
      final v = p[key];
      if (v is num) p[key] = v.toString();
    }

    // 메인 이미지 후보
    final mainCandidate =
        p['mainImageUrl'] ?? p['mainImage'] ?? p['image'] ?? p['main_image'];
    final mainAbs = _imageUrl(mainCandidate);
    if (mainAbs != null && mainAbs.isNotEmpty) {
      p['mainImageUrl'] = mainAbs;
    } else if (p['mainImageUrl'] != null) {
      p['mainImageUrl'] = p['mainImageUrl'].toString();
    }

    // ---------- 추가 이미지 robust 파서 ----------
    // 지원 키들: additionalImageUrls, additionalImages, detailImages, images, detailImageUrls, detail_images
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
      for (final e in aiu) {
        // e: "string" 또는 {url: "..."} 등
        _add(e);
      }
    } else if (aiu is Map) {
      // { urls: [...]} 또는 { images:[...] } 형태
      for (final k in ['urls', 'images', 'list', 'data']) {
        if (aiu[k] is List) {
          for (final e in aiu[k]) _add(e);
        }
      }
      // map 내부 단일 url 필드만 있는 경우도 커버
      final one = _fromMap(aiu);
      if (one != null) _add(one);
    } else if (aiu is String && aiu.trim().isNotEmpty) {
      final s = aiu.trim();
      if ((s.startsWith('[') && s.endsWith(']')) || (s.startsWith('{') && s.endsWith('}'))) {
        // JSON 배열/객체로 들어온 경우
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            for (final e in decoded) _add(e);
          } else if (decoded is Map) {
            // {urls:[...]} 등
            for (final k in ['urls', 'images', 'list', 'data']) {
              if (decoded[k] is List) {
                for (final e in decoded[k]) _add(e);
              }
            }
            final one = _fromMap(decoded);
            if (one != null) _add(one);
          }
        } catch (_) {
          // 파싱 실패 시 CSV / 구분자 처리
          for (final part in s.split(RegExp(r'[,\|\n]'))) {
            _add(part);
          }
        }
      } else {
        // CSV 또는 단일 문자열 (콤마/파이프/개행 모두 지원)
        for (final part in s.split(RegExp(r'[,\|\n]'))) {
          _add(part);
        }
      }
    }

    // 중복 제거 & 비어있는 값 제거
    final cleaned = urls.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();

    // 메인 이미지가 비어 있고 추가 이미지가 있다면 첫 이미지를 메인으로 승격
    if ((p['mainImageUrl'] == null || p['mainImageUrl'].toString().isEmpty) && cleaned.isNotEmpty) {
      p['mainImageUrl'] = cleaned.first;
    }

    // 최종 CSV 저장 (ProductDetailScreen은 CSV split 사용)
    p['additionalImageUrls'] = cleaned.join(',');

    // 문자열 필드 방어
    for (final key in ['brand', 'brandName', 'name', 'category']) {
      if (p[key] != null) p[key] = p[key].toString();
    }

    return p;
  }



  // 안전한 가격 파싱
  int _priceOf(Map<String, dynamic> order) {
    final raw = order['unboxedProduct']?['product']?['consumerPrice'];
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  // 서버 이미지 URL 보정
  String? _imageUrl(dynamic raw) {
    if (raw == null) return null;
    final s = '$raw';
    if (s.isEmpty) return null;
    return s.startsWith('http') ? s : '${BaseUrl.value}:7778${s.startsWith('/') ? '' : '/'}$s';
  }

  // 공용 카드 위젯 (세로 리스트에서 사용)
// 공통: 카드 UI 빌더
  Widget _card({
    String? profileName,
    String rightTimeText = '',
    String? brand,
    String? productName,
    int? price,
    String? productImageUrl,
    String? profileImage,   // ⬅️ 추가
    String? decidedAtText,  // ⬅️ 추가
    String? boxName,
    VoidCallback? onImageTap,
    bool isEmpty = false,
  }) {
    final formatCurrency = NumberFormat('#,###');

    return Container(
      width: 330.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: const Offset(0, 2))],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⬅️ 상품 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: GestureDetector(
              onTap: (productImageUrl != null && !isEmpty) ? onImageTap : null,
              child: SizedBox(
                width: 140.r,
                height: 140.r,
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

          // ▶️ 텍스트 영역
          Expanded(
            child: SizedBox(
              height: 140.r, // 이미지와 동일 높이로 맞춰야 Spacer가 동작
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 11.r,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profileImage != null
                            ? CachedNetworkImageProvider(profileImage!)
                            : null,
                        child: profileImage == null
                            ? Icon(Icons.person, size: 13.r, color: Colors.grey[600])
                            : null,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          isEmpty ? '최근 내역이 없습니다.' : '${profileName ?? '익명'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black54, fontSize: 18.sp),
                        ),
                      ),
                    ],
                  ),

                  if (!isEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      productName ?? '상품명 없음',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20.sp),
                    ),
                  ],

                  SizedBox(height: 4.h),
                  Text(
                    isEmpty || price == null ? '' : '정가: ${formatCurrency.format(price)} 원',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black87, fontSize: 14.sp),
                  ),

                  const Spacer(),

                  // ✅ 오른쪽 하단: (박스명) + (당첨 시간)
                  if ((boxName ?? '').isNotEmpty || (decidedAtText ?? '').isNotEmpty)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if ((boxName ?? '').isNotEmpty)
                            Text(
                              boxName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if ((decidedAtText ?? '').isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              decidedAtText!,
                              style: TextStyle(color: Colors.black38, fontSize: 12.sp),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,###');

    if (unboxedOrders.isEmpty) {
      return SizedBox(
        height: 100.h,
        child: const Center(child: Text("최근 언박싱 기록이 없습니다.")),
      );
    }

    // 🔧 좌우 슬라이더 제거: 모든 20,000원 이상을 세로 리스트로 노출
    final visibleOrders = unboxedOrders
     .where((o) { final p = _priceOf(o); return p >= 20000 && p < 100000; })
        .toList()
      ..sort((a, b) => DateTime.parse(b['unboxedProduct']?['decidedAt'] ?? '')
          .compareTo(DateTime.parse(a['unboxedProduct']?['decidedAt'] ?? '')));

    final latestOrders = visibleOrders.take(50).toList();

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.h, top: 4.h),
        itemCount: latestOrders.length,
        itemBuilder: (context, index) {
          final order = latestOrders[index];
          final user = order['user'];
          final product = order['unboxedProduct']?['product'];
          final productId = (product?['_id'] ?? product?['id'] ?? product?['productId'] ?? '').toString();
          final decidedAt = DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '');
          final brand = product?['brand'] ?? product?['brandName'];
          final name = product?['name'];
          final price = _priceOf(order);
          final productImgUrl = _imageUrl(product?['mainImage'] ?? product?['mainImageUrl']);

          final timeText = decidedAt != null ? _timeAgo(decidedAt.toLocal()) : '';
          final profileImage = _imageUrl(user?['profileImage']);
          final decidedAtText = decidedAt != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(decidedAt.toLocal())
              : '';
          final boxName = (() {
            final box = order['box'];
            final bn = box?['name'] ?? box?['title'] ?? box?['boxName'];
            return bn?.toString();
          })();

          // ✅ 아이템 여백: 세로만
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: _card(
              profileName: user?['nickname'],
              rightTimeText: timeText,
              brand: brand,
              productName: name,
              price: price,
              productImageUrl: productImgUrl,
              profileImage: profileImage,
              decidedAtText: decidedAtText,
              boxName: boxName,
              onImageTap: () {
                final sanitized = _sanitizeProductForDetail(product); // ✅ 추가: 정규화
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      product: sanitized,          // ✅ 정규화된 제품 데이터 전달
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
