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

  // ──────────────────────────────────────────────────
  // ⏱ 상대 시간
  // ──────────────────────────────────────────────────
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('MM/dd').format(dt);
  }

  // ──────────────────────────────────────────────────
  // URL Sanitizer (절대 URL이 앞에 서버 주소가 붙은 경우 교정)
  // ──────────────────────────────────────────────────
  String _sanitizeAbsolute(String value) {
    final v = value.trim();
    if (v.isEmpty) return v;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final httpsIdx = v.indexOf('https://');
    if (httpsIdx > 0) return v.substring(httpsIdx);
    final httpIdx = v.indexOf('http://');
    if (httpIdx > 0) return v.substring(httpIdx);
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      return v.substring(1, v.length - 1);
    }
    return v;
  }

  bool _isPresignedS3(Uri? u) {
    if (u == null) return false;
    final host = (u.host).toLowerCase();
    final qp = u.queryParameters;
    final hasS3 = host.contains('amazonaws.com');
    final hasSig = qp.keys.any((k) => k.toLowerCase().startsWith('x-amz-')) ||
        qp.containsKey('X-Amz-Algorithm') ||
        qp.containsKey('X-Amz-Signature');
    return hasS3 && hasSig;
  }

  // 우리 서버 베이스
  String get _server => '${BaseUrl.value}:7778';

  // 프로필/상품 이미지 공용 URL 빌더
  String? _buildImageUrl(dynamic raw, {bool isProfile = false}) {
    if (raw == null) return null;
    String s = raw.toString().trim();
    if (s.isEmpty) return null;

    s = _sanitizeAbsolute(s);

    if (s.startsWith('$_server/media/')) return s;
    if (s.startsWith('$_server/uploads/')) return s;
    if (s.startsWith('/uploads/')) return '$_server$s';

    if (s.startsWith('http://') || s.startsWith('https://')) {
      final uri = Uri.tryParse(s);
      final lower = s.toLowerCase();

      if (isProfile && _isPresignedS3(uri)) return s;

      final isHeic = lower.endsWith('.heic') || lower.contains('.heic?');
      if (!isProfile && isHeic) {
        final rawPath = uri?.path ?? '';
        final key = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
        final encodedKey = key.split('/').map(Uri.encodeComponent).join('/');
        return '$_server/media/$encodedKey';
      }
      return s;
    }

    final key = s.startsWith('/') ? s.substring(1) : s;
    final encodedKey = key.split('/').map(Uri.encodeComponent).join('/');
    return '$_server/media/$encodedKey';
  }

  Map<String, dynamic> _sanitizeProductForDetail(dynamic rawProduct) {
    final Map<String, dynamic> p = Map<String, dynamic>.from(rawProduct ?? {});
    for (final key in ['consumerPrice', 'price']) {
      final v = p[key];
      if (v is num) p[key] = v.toString();
    }

    final mainCandidate =
        p['mainImageUrl'] ?? p['mainImage'] ?? p['image'] ?? p['main_image'];
    final mainAbs = _buildImageUrl(mainCandidate);
    if (mainAbs != null && mainAbs.isNotEmpty) {
      p['mainImageUrl'] = mainAbs;
    } else if (p['mainImageUrl'] != null) {
      p['mainImageUrl'] = p['mainImageUrl'].toString();
    }

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

      final abs = _buildImageUrl(candidate) ?? candidate;
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
    if ((p['mainImageUrl'] == null || p['mainImageUrl'].toString().isEmpty) && cleaned.isNotEmpty) {
      p['mainImageUrl'] = cleaned.first;
    }
    p['additionalImageUrls'] = cleaned.join(',');

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

  @override
  Widget build(BuildContext context) {
    // 요청사항: 20,000원 이상 + 최신순 + 최대 30개
    final visibleOrders = unboxedOrders
        .where((o) => _priceOf(o) >= 20000)
        .toList()
      ..sort((a, b) => DateTime.parse(b['unboxedProduct']?['decidedAt'] ?? '')
          .compareTo(DateTime.parse(a['unboxedProduct']?['decidedAt'] ?? '')));

    final latestOrders = visibleOrders.take(30).toList();

    if (latestOrders.isEmpty) {
      return SizedBox(
        height: 100.h,
        child: const Center(child: Text("최근 언박싱 기록이 없습니다.")),
      );
    }

    // 카드 사이즈 축소(한 화면에 더 많은 카드 노출)
    final double kImage = 96.r;          // 이미지 한 변
    final double kCardHeight = kImage;   // 텍스트 영역도 같은 높이
    final double kGap = 8.w;             // 좌우 간격 축소
    final double kPad = 10.w;            // 카드 내부 패딩 축소

    return Container(
      color: Colors.white,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 12.h),
        itemCount: latestOrders.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h), // 아이템 간 간격 축소
        itemBuilder: (context, index) {
          final order = latestOrders[index];
          final user = order['user'];
          final product = order['unboxedProduct']?['product'];

          final productId = (product?['_id'] ?? product?['id'] ?? product?['productId'] ?? '').toString();
          final decidedAt = DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '');
          final brand = (product?['brand'] ?? product?['brandName'])?.toString();
          final name = product?['name']?.toString() ?? '상품명 없음';
          final price = _priceOf(order);

          final productImgUrl = _buildImageUrl(
            product?['mainImageUrl'] ?? product?['mainImage'] ?? product?['image'],
          );
          final profileImgUrl = _buildImageUrl(
            user?['profileImageUrl'] ?? user?['profileImage'],
            isProfile: true,
          );

          final timeText = decidedAt != null ? _timeAgo(decidedAt.toLocal()) : '';
          final decidedAtText = decidedAt != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(decidedAt.toLocal())
              : '';
          final boxName = (() {
            final box = order['box'];
            final bn = box?['name'] ?? box?['title'] ?? box?['boxName'];
            return bn?.toString() ?? '';
          })();

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3.r, offset: const Offset(0, 1))],
              border: Border.all(color: const Color(0x11000000)),
            ),
            padding: EdgeInsets.all(kPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상품 이미지 (더 작게)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: GestureDetector(
                    onTap: productImgUrl != null
                        ? () {
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
                    }
                        : null,
                    child: SizedBox(
                      width: kImage,
                      height: kImage,
                      child: productImgUrl != null
                          ? CachedNetworkImage(
                        imageUrl: productImgUrl,
                        fit: BoxFit.cover,
                        placeholder: (c, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (c, _, __) => Container(color: Colors.grey[200]),
                      )
                          : Container(color: Colors.grey[200]),
                    ),
                  ),
                ),
                SizedBox(width: kGap,),
                // 텍스트 영역(폰트/줄간격 축소)
                Expanded(
                  child: SizedBox(
                    height: kCardHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 프로필 + 닉네임 + 시간 (한 줄에 타이트하게)
                        Row(
                          children: [
                            _profileAvatar(profileImgUrl, 9.r),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                user?['nickname']?.toString() ?? '익명',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.black54, fontSize: 12.sp),
                              ),
                            ),

                          ],
                        ),

                        SizedBox(height: 4.h),

                        // 상품명 (조금 작게, bold 유지)
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18.sp),
                        ),

                        SizedBox(height: 2.h),

                        // 정가
                        Text(
                          '정가: ${NumberFormat('#,###').format(price)} 원',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black45, fontSize: 14.sp),
                        ),

                        const Spacer(),

                        // 박스명 + 결정 시각 (오른쪽 정렬, 더 타이트)
                        if (boxName.isNotEmpty || decidedAtText.isNotEmpty)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (boxName.isNotEmpty)
                                  Text(
                                    boxName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (decidedAtText.isNotEmpty) ...[
                                  SizedBox(height: 1.h),
                                  Text(
                                    decidedAtText,
                                    style: TextStyle(color: Colors.black38, fontSize: 10.sp),
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
        },
      ),
    );
  }

  // 프로필 아바타 (에러/플레이스홀더 포함) — 더 작게
  Widget _profileAvatar(String? url, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
          imageUrl: url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (c, _) => Center(
            child: SizedBox(width: radius, height: radius, child: const CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (c, _, __) => Icon(Icons.person, size: radius * 1.6, color: Colors.grey[600]),
        )
            : Icon(Icons.person, size: radius * 1.6, color: Colors.grey[600]),
      ),
    );
  }
}
