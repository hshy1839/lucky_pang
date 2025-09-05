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
  // 예: http://192...https://bucket... -> https://bucket...
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
    // 프리사인드 특징: s3 도메인 + X-Amz-* 쿼리 파라미터들
    final hasS3 = host.contains('amazonaws.com');
    final hasSig = qp.keys.any((k) => k.toLowerCase().startsWith('x-amz-')) ||
        qp.containsKey('X-Amz-Algorithm') ||
        qp.containsKey('X-Amz-Signature');
    return hasS3 && hasSig;
  }
  // ──────────────────────────────────────────────────
  // 우리 서버 베이스
  // ──────────────────────────────────────────────────
  String get _server => '${BaseUrl.value}:7778';

  bool _isOurMediaUrl(String s) {
    return s.startsWith('$_server/media/');
  }

  bool _isOurUploadsUrl(String s) {
    return s.startsWith('$_server/uploads/') || s.startsWith('/uploads/');
  }

  // ──────────────────────────────────────────────────
  // 프로필/상품 이미지 공용 URL 빌더
  // 규칙:
  //  1) 이미 /media/… 절대 URL이면 그대로
  //  2) 이미 /uploads/… (절대/상대)면 서버 베이스 붙여 반환
  //  3) 절대 URL 중 S3 or .heic → /media/{key} 프록시로 강제
  //  4) 나머지가 키처럼 보이면 /media/{key}
  // ──────────────────────────────────────────────────
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

      // ✅ (A) 프로필: 프리사인드 S3면 "항상" 그대로 사용
      if (isProfile && _isPresignedS3(uri)) {
        return s;
      }

      // ✅ (B) 프로필이 아닌 경우(상품 등) HEIC는 프록시로 우회
      final isHeic = lower.endsWith('.heic') || lower.contains('.heic?');
      if (!isProfile && isHeic) {
        final rawPath = uri?.path ?? '';
        final key = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
        final encodedKey = key.split('/').map(Uri.encodeComponent).join('/');
        return '$_server/media/$encodedKey';
      }

      // 그 외 절대 URL은 그대로
      return s;
    }

    // 키처럼 보이면 프록시
    final key = s.startsWith('/') ? s.substring(1) : s;
    final encodedKey = key.split('/').map(Uri.encodeComponent).join('/');
    return '$_server/media/$encodedKey';
  }

  // ──────────────────────────────────────────────────
  // 제품 상세로 넘길 때 데이터 정리 (이미지/가격 등)
  // ──────────────────────────────────────────────────
  Map<String, dynamic> _sanitizeProductForDetail(dynamic rawProduct) {
    final Map<String, dynamic> p = Map<String, dynamic>.from(rawProduct ?? {});

    // 숫자 → 문자열
    for (final key in ['consumerPrice', 'price']) {
      final v = p[key];
      if (v is num) p[key] = v.toString();
    }

    // 메인 이미지 후보 → 절대 URL로
    final mainCandidate =
        p['mainImageUrl'] ?? p['mainImage'] ?? p['image'] ?? p['main_image'];
    final mainAbs = _buildImageUrl(mainCandidate);
    if (mainAbs != null && mainAbs.isNotEmpty) {
      p['mainImageUrl'] = mainAbs;
    } else if (p['mainImageUrl'] != null) {
      p['mainImageUrl'] = p['mainImageUrl'].toString();
    }

    // 추가 이미지 다양한 포맷 지원 → 절대 URL 리스트로 통일
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

    // 중복 제거 & 비어있는 값 제거
    final cleaned = urls.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();

    // 메인 이미지가 비었으면 첫 추가 이미지를 메인으로 승격
    if ((p['mainImageUrl'] == null || p['mainImageUrl'].toString().isEmpty) && cleaned.isNotEmpty) {
      p['mainImageUrl'] = cleaned.first;
    }

    // 상세 화면에서 CSV로 쓰는 경우 대비
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

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,###');

    if (unboxedOrders.isEmpty) {
      return SizedBox(
        height: 100.h,
        child: const Center(child: Text("최근 언박싱 기록이 없습니다.")),
      );
    }

    // 20,000원 이상 ~ 100,000원 미만만 노출
    final visibleOrders = unboxedOrders
        .where((o) {
      final p = _priceOf(o);
      return p >= 20000 && p < 100000;
    })
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

          // ✅ 이미지 URL 빌드
          final productImgUrl = _buildImageUrl(
            product?['mainImageUrl'] ?? product?['mainImage'] ?? product?['image'],
          );
          final rawProfile = user?['profileImageUrl'] ?? user?['profileImage'];
          final profileImgUrl = _buildImageUrl(
            user?['profileImageUrl'] ?? user?['profileImage'],
            isProfile: true,
          );
          debugPrint('[RANK] profile raw=$rawProfile -> final=$profileImgUrl');

          final timeText = decidedAt != null ? _timeAgo(decidedAt.toLocal()) : '';
          final decidedAtText = decidedAt != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(decidedAt.toLocal())
              : '';
          final boxName = (() {
            final box = order['box'];
            final bn = box?['name'] ?? box?['title'] ?? box?['boxName'];
            return bn?.toString();
          })();

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: _card(
              profileName: user?['nickname'],
              rightTimeText: timeText,
              brand: brand,
              productName: name,
              price: price,
              productImageUrl: productImgUrl,
              profileImage: profileImgUrl, // ✅ 안전한 규칙 적용
              decidedAtText: decidedAtText,
              boxName: boxName,
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

  // ──────────────────────────────────────────────────
  // 프로필 아바타 (에러/플레이스홀더 포함)
  // ──────────────────────────────────────────────────
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
          placeholder: (c, _) =>
              Center(child: SizedBox(width: radius, height: radius, child: const CircularProgressIndicator(strokeWidth: 2))),
          errorWidget: (c, _, __) => Icon(Icons.person, size: radius * 1.6, color: Colors.grey[600]),
        )
            : Icon(Icons.person, size: radius * 1.6, color: Colors.grey[600]),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // 공용 카드 위젯
  // ──────────────────────────────────────────────────
  Widget _card({
    String? profileName,
    String rightTimeText = '',
    String? brand,
    String? productName,
    int? price,
    String? productImageUrl,
    String? profileImage,   // ✅ 절대 URL
    String? decidedAtText,
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
          // 상품 이미지
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

          // 텍스트 영역
          Expanded(
            child: SizedBox(
              height: 140.r,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 + 닉네임
                  Row(
                    children: [
                      _profileAvatar(profileImage, 11.r),
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

                  // 오른쪽 하단: 박스명 + 시간
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
}
