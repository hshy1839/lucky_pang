import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
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

    final List<Map<String, dynamic>> latest20Orders = filteredOrders
        .where((order) => (order['unboxedProduct']?['product']?['price'] ?? 0) < 100000)
        .take(20)
        .toList();

    final highValueOrders = unboxedOrders
        .where((order) => (order['unboxedProduct']?['product']?['price'] ?? 0) >= 100000)
        .toList()
      ..sort((a, b) => DateTime.parse(b['unboxedProduct']?['decidedAt'] ?? '').compareTo(
          DateTime.parse(a['unboxedProduct']?['decidedAt'] ?? '')));

    final recentHighValueOrders = highValueOrders.take(30).toList();
    final formatCurrency = NumberFormat('#,###');

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
                    children: [

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 닉네임 + 프로필 사진
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24.r,
                                  backgroundColor: Colors.grey[300],
                                  child: userProfileImage != null
                                      ? ClipOval(
                                    child: Image.network(
                                      userProfileImage,
                                      fit: BoxFit.cover,
                                      width: 48.r,
                                      height: 48.r,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.person, size: 28.r, color: Colors.grey[600]);
                                      },
                                    ),
                                  )
                                      : Icon(Icons.person, size: 28.r, color: Colors.grey[600]),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    user?['nickname'] ?? '익명',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h), // 여기로 이동!

                            // 상품명 + 가격 + 날짜
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 상품 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product?['name'] ?? '상품명 없음',
                                        style: TextStyle(fontSize: 15.sp, color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        '정가: ${formatCurrency.format(consumerPrice)}원',
                                        style: TextStyle(fontSize: 15.sp, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                // 박스 정보
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${formatCurrency.format(box?['price'] ?? 0)}원 박스',
                                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '')
                                          ?.toLocal()
                                          .toString()
                                          .substring(0, 16) ??
                                          '',
                                      style: TextStyle(fontSize: 13.sp, color: Colors.white54),
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

                    title: Row(
                      children: [
                        CircleAvatar(
                          radius: 24.r,
                          backgroundColor: Colors.grey[300],
                          child: userProfileImage != null
                              ? ClipOval(
                            child: Image.network(
                              userProfileImage,
                              fit: BoxFit.cover,
                              width: 48.r,
                              height: 48.r,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, size: 28.r, color: Colors.grey[600]);
                              },
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    child:Text(
                                      product?['name'] ?? '상품명 없음',
                                      style: TextStyle(fontSize: 15.sp, color: Colors.black),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '정가: ${formatCurrency.format(consumerPrice)}원',
                                    style: TextStyle(fontSize: 15.sp, color: Color(0xFF465461)),
                                  ),
                                ],
                              ),
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                            Text('${formatCurrency.format(box?['price'] ?? 0)}원 박스',
                                    style: TextStyle(color: Colors.black, fontSize: 14.sp)),
                                SizedBox(height: 4.h),
                                Text(
                                  DateTime.tryParse(order['unboxedProduct']?['decidedAt'] ?? '')
                                      ?.toLocal()
                                      .toString()
                                      .substring(0, 16) ??
                                      '',
                                  style: TextStyle(fontSize: 13.sp, color: Colors.black45),
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
          ),
          SizedBox(height: 80,)

        ],
      ),
    );
  }
}