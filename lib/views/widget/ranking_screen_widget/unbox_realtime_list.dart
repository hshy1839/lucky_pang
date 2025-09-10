import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../routes/base_url.dart';
import '../../product_activity/product_detail_screen.dart';
import '../../../../controllers/userinfo_screen_controller.dart';
import '../avatar_cache_manager.dart';

class UnboxRealtimeList extends StatefulWidget {
  final List<Map<String, dynamic>> unboxedOrders;

  const UnboxRealtimeList({super.key, required this.unboxedOrders});

  @override
  State<UnboxRealtimeList> createState() => _UnboxRealtimeListState();
}

class _UnboxRealtimeListState extends State<UnboxRealtimeList> {
  // ✅ 내 정보(컨트롤러는 그대로 사용)
  final UserInfoScreenController _controller = UserInfoScreenController();
  String myNickname = '';
  String? myProfileImage = '';
  bool meLoading = false;
  String? myUserId;

  @override
  void initState() {
    super.initState();
    _loadMyInfo(); // ProfileScreen처럼 가져오기
  }

  // ──────────────────────────────────────────────────
  // 아바타 캐시 키/워밍
  // ──────────────────────────────────────────────────
  String _avatarCacheKeyFor({String? userId, String? nickname}) {
    // 같은 유저는 항상 같은 키 → 재검증 줄이기
    final base = (userId != null && userId.trim().isNotEmpty)
        ? userId.trim()
        : (nickname ?? 'unknown');
    return 'avatar_$base';
  }

  Future<void> _warmAvatarCache(String url, String key) async {
    try {
      // 디스크 캐시 워밍
      await AvatarCacheManager.instance.getSingleFile(url, key: key);
      // 메모리 캐시 워밍 (다음 빌드에서 즉시 표시)
      await precacheImage(
        CachedNetworkImageProvider(
          url,
          cacheManager: AvatarCacheManager.instance,
          cacheKey: key,
        ),
        context,
      );
    } catch (_) {}
  }

  Future<void> _loadMyInfo() async {
    setState(() => meLoading = true);
    await _controller.fetchUserInfo(context);
    setState(() {
      myNickname = _controller.nickname;
      myProfileImage = _controller.profileImage;
      // myUserId = _controller.userId; // 컨트롤러가 제공하면 사용 (없어도 OK)
      meLoading = false;
    });

    // 내 프로필을 미리 캐싱 (있을 때만)
    final url = _buildProfileImageUrl(myProfileImage);
    if (url != null && url.isNotEmpty) {
      final key = _avatarCacheKeyFor(userId: myUserId, nickname: myNickname);
      _warmAvatarCache(url, key);
    }
  }

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
  // (ProfileScreen과 동일 규칙) 프로필 이미지 URL 빌더
  // ──────────────────────────────────────────────────
  String _sanitizeAbsoluteProfile(String value) {
    if (value.isEmpty) return value;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    final httpsIdx = value.indexOf('https://');
    if (httpsIdx > 0) return value.substring(httpsIdx);
    final httpIdx = value.indexOf('http://');
    if (httpIdx > 0) return value.substring(httpIdx);
    return value;
  }

  String? _buildProfileImageUrl(dynamic raw) {
    if (raw == null) return null;
    final s0 = raw.toString().trim();
    if (s0.isEmpty) return null;

    String out;
    if (s0.startsWith('http://') || s0.startsWith('https://')) {
      out = _sanitizeAbsoluteProfile(s0);
    } else if (s0.startsWith('/uploads/')) {
      out = '${BaseUrl.value}:7778$s0';
    } else {
      out = '${BaseUrl.value}:7778/media/$s0';
    }

    debugPrint('[UnboxRealtimeList] raw profileImage: $s0');
    debugPrint('[UnboxRealtimeList] resolved imageUrl: $out');
    return out;
  }

  // ──────────────────────────────────────────────────
  // URL Sanitizer (상품 등 다른 이미지용)
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

  // 우리 서버 베이스
  String get _server => '${BaseUrl.value}:7778';

  // 상품/기타 이미지 공용 URL 빌더 (HEIC 프록시 등 포함)
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

      // 프로필의 절대 URL은 그대로 사용
      if (isProfile) return s;

      // 상품 이미지가 HEIC면 프록시로
      final isHeic = lower.endsWith('.heic') || lower.contains('.heic?');
      if (isHeic) {
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
    final visibleOrders = widget.unboxedOrders
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

    final double kImage = 96.r;
    final double kCardHeight = kImage;
    final double kGap = 8.w;
    final double kPad = 10.w;

    return Container(
      color: Colors.white,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 12.h),
        itemCount: latestOrders.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          final order = latestOrders[index];
          final user = order['user'];
          final product = order['unboxedProduct']?['product'];

          final rowUserId = user?['_id']?.toString(); // ← 가능하면 이걸 키로
          final rowNickname = user?['nickname']?.toString() ?? '';

          final productId = (product?['_id'] ?? product?['id'] ?? product?['productId'] ?? '').toString();
          final decidedAt = DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '');
          final name = product?['name']?.toString() ?? '상품명 없음';
          final price = _priceOf(order);

          final productImgUrl = _buildImageUrl(
            product?['mainImageUrl'] ?? product?['mainImage'] ?? product?['image'],
          );

          // row의 기본 프로필(서버가 준 값)
          final rawProfile =
              user?['profileImage'] ??
                  user?['profileImageUrl'] ??
                  user?['profile_image'] ??
                  user?['profile'];

          // ✅ row의 닉네임이 내 닉네임과 같으면 → fetchUserInfo의 내 이미지 사용
          String? profileImgUrl;
          if (myNickname.isNotEmpty &&
              rowNickname.isNotEmpty &&
              rowNickname == myNickname &&
              (myProfileImage != null && myProfileImage!.trim().isNotEmpty)) {
            profileImgUrl = _buildProfileImageUrl(myProfileImage);
          } else {
            profileImgUrl = _buildProfileImageUrl(rawProfile);
          }

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
                // 상품 이미지
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
                        placeholder: (c, _) =>
                        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (c, _, __) => Container(color: Colors.grey[200]),
                      )
                          : Container(color: Colors.grey[200]),
                    ),
                  ),
                ),
                SizedBox(width: kGap),
                // 텍스트 영역
                Expanded(
                  child: SizedBox(
                    height: kCardHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 프로필 + 닉네임
                        Row(
                          children: [
                            _profileAvatar(
                              profileImgUrl,
                              9.r,
                              rowUserId: rowUserId,
                              rowNickname: rowNickname,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                rowNickname.isNotEmpty ? rowNickname : '익명',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.black54, fontSize: 12.sp),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 4.h),

                        // 상품명
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

                        // 박스명 + 결정 시각
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

  // 프로필 아바타 (에러/플레이스홀더 포함)
  Widget _profileAvatar(
      String? urlResolved,
      double radius, {
        String? rowUserId,
        String? rowNickname,
      }) {
    // 이미 build에서 만든 최종 URL (null/empty 방어)
    final profileUrl = urlResolved?.trim();
    final hasIdentity =
        (rowUserId != null && rowUserId.isNotEmpty) || (rowNickname != null && rowNickname.isNotEmpty);

    // ★ 키가 있을 때만 지정 (없으면 URL 자체가 키가 됨 = 가장 안전)
    final cacheKey = hasIdentity ? _avatarCacheKeyFor(userId: rowUserId, nickname: rowNickname) : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: (profileUrl != null && profileUrl.isNotEmpty)
            ? CachedNetworkImage(
          imageUrl: profileUrl,
          cacheManager: AvatarCacheManager.instance, // ← 전용 캐시
          cacheKey: cacheKey,                        // ← 있을 때만
          useOldImageOnUrlChange: true,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // 깜빡임 최소화
          fadeInDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          memCacheWidth: (radius * 2).ceil() * 3,
          memCacheHeight: (radius * 2).ceil() * 3,
          placeholder: (c, _) => SizedBox(
            width: radius,
            height: radius,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
          ),
          errorWidget: (c, _, __) =>
              Icon(Icons.person, size: radius * 1.6, color: Colors.grey[600]),
        )
            : Icon(Icons.person, size: radius * 1.6, color: Colors.grey[600]),
      ),
    );
  }
}
