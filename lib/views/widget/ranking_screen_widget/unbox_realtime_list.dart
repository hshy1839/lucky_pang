import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../routes/base_url.dart';

class UnboxRealtimeList extends StatelessWidget {
  final List<Map<String, dynamic>> unboxedOrders;

  const UnboxRealtimeList({super.key, required this.unboxedOrders});

  @override
  Widget build(BuildContext context) {
    if (unboxedOrders.isEmpty) {
      return SizedBox(
        height: 100.h,
        child: Center(child: Text("최근 언박싱 기록이 없습니다.")),
      );
    }
    final List<Map<String, dynamic>> filteredOrders = unboxedOrders
        .where((order) => (order['unboxedProduct']?['product']?['consumerPrice'] ?? 0) >= 30000)
        .toList()
      ..sort((a, b) => DateTime.parse(b['unboxedProduct']?['decidedAt'] ?? '')
          .compareTo(DateTime.parse(a['unboxedProduct']?['decidedAt'] ?? '')));

    final List<Map<String, dynamic>> latest20Orders = filteredOrders.take(20).toList();

    final highValueOrders = unboxedOrders
        .where((order) => (order['unboxedProduct']?['product']?['price'] ?? 0) >= 100000)
        .toList()
      ..sort((a, b) => DateTime.parse(b['unboxedProduct']?['decidedAt'] ?? '').compareTo(
          DateTime.parse(a['unboxedProduct']?['decidedAt'] ?? '')));

    final recentHighValueOrders = highValueOrders.take(30).toList();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          if (recentHighValueOrders.isNotEmpty)
            SizedBox(
              height: 170.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentHighValueOrders.length,
                itemBuilder: (context, index) {
                  final order = recentHighValueOrders[index];
                  final user = order['user'];
                  final product = order['unboxedProduct']?['product'];
                  final box = order['box'];
                  final rawProfileImage = user?['profileImage'];
                  final userProfileImage = rawProfileImage != null && rawProfileImage.isNotEmpty
                      ? (rawProfileImage.startsWith('http')
                      ? rawProfileImage
                      : '${BaseUrl.value}:7778${rawProfileImage.startsWith('/') ? '' : '/'}$rawProfileImage')
                      : null;
                  final consumerPrice = product?['consumerPrice'] ?? 0;

                  // ✅ 30,000 미만이면 렌더링하지 않음
                  if (consumerPrice < 100000) return const SizedBox.shrink();

                  return Padding(
                    padding: EdgeInsets.only(left: 16.w, right: 20.w, bottom: 8.h, top: 0.h),
                    child: Container(
                      width: 350.w,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4.r,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(product?['mainImage'] != null && product['mainImage'].isNotEmpty
                                ? '${BaseUrl.value}:7778${product['mainImage']}'
                                : 'https://via.placeholder.com/50'),
                            radius: 24.r,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    userProfileImage != null
                                        ? CircleAvatar(radius: 12.r, backgroundImage: NetworkImage(userProfileImage))
                                        : const Icon(Icons.account_circle, size: 24, color: Colors.grey),
                                    SizedBox(width: 6.w),
                                    Expanded(
                                      child: Text(
                                        user?['nickname'] ?? 'unknown',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product?['name'] ?? '상품명 없음', style: TextStyle(fontSize: 13.sp, color: Colors.white)),
                                        SizedBox(height: 4.h),
                                        Text('정가 ${consumerPrice}원', style: TextStyle(fontSize: 12.sp, color: Colors.white70)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${box?['price'] ?? 0}원 박스', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: Colors.white)),
                                        SizedBox(height: 4.h),
                                        Text(
                                          DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '')
                                              ?.toLocal()
                                              .toString()
                                              .substring(0, 16) ??
                                              '',
                                          style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                                        ),
                                      ],
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



          ListView.builder(
            padding: EdgeInsets.only(bottom: 20),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: latest20Orders.length,
            itemBuilder: (context, index) {
              final order = latest20Orders[index];
              final user = order['user'];
              final product = order['unboxedProduct']?['product'];
              final box = order['box'];
              final consumerPrice = product?['consumerPrice'] ?? 0;

              final rawProfileImage = user?['profileImage'];
              final userProfileImage = rawProfileImage != null && rawProfileImage.isNotEmpty
                  ? (rawProfileImage.startsWith('http')
                  ? rawProfileImage
                  : '${BaseUrl.value}:7778${rawProfileImage.startsWith('/') ? '' : '/'}$rawProfileImage')
                  : null;

              return Padding(
                padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 6.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: Offset(0, 2))
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(product?['mainImage'] != null && product['mainImage'].isNotEmpty
                          ? '${BaseUrl.value}:7778${product['mainImage']}'
                          : 'https://via.placeholder.com/50'),
                      radius: 24.r,
                    ),
                    title: Row(
                      children: [
                        userProfileImage != null
                            ? CircleAvatar(radius: 12.r, backgroundImage: NetworkImage(userProfileImage))
                            : const Icon(Icons.account_circle, size: 24, color: Colors.grey),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            user?['nickname'] ?? '익명',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product?['name'] ?? '상품명 없음', style: TextStyle(fontSize: 13.sp)),
                        SizedBox(height: 4.h),
                        Text('정가 $consumerPrice원',
                            style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${box?['price'] ?? 0}원 박스',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                        SizedBox(height: 4.h),
                        Text(
                          DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '')
                              ?.toLocal()
                              .toString()
                              .substring(0, 16) ??
                              '',
                          style: TextStyle(fontSize: 11.sp, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 80,)

        ],
      ),
    );
  }
}