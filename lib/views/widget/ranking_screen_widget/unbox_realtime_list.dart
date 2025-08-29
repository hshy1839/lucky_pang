import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../routes/base_url.dart';

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
            child: SizedBox(
              width: 100.r,
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
          SizedBox(width: 12.w),

          // ▶️ 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // ⬅️ 작은 프로필 원
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
                        style: TextStyle(color: Colors.black54, fontSize: 18.sp,),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(rightTimeText, style: TextStyle(color: Colors.black26, fontSize: 14.sp)),
                  ],
                ),
                SizedBox(height: 2.h),

                // 상품명
                if (!isEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    productName ?? '상품명 없음',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22.sp),
                  ),
                ],

                SizedBox(height: 2.h),
                Text(
                  isEmpty || price == null ? '' : '정가: ${formatCurrency.format(price)} 원',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black87,  fontSize: 16.sp),
                ),
                SizedBox(height: 20.h),
                if ((boxName ?? '').isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    boxName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black87, fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ],
                // ⬇️ decidedAt
                if ((decidedAtText ?? '').isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(decidedAtText!, style: TextStyle(color: Colors.black38, fontSize: 14.sp)),
                ],
              ],
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
          final decidedAt = DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '');
          final brand = product?['brand'] ?? product?['brandName'];
          final name = product?['name'];
          final price = _priceOf(order);
          final productImgUrl = _imageUrl(product?['mainImage']);
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
            ),
          );
        },
      ),
    );
  }
}
