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

    return Container(
       color: Colors.white,
        child:ListView.builder(
      padding: EdgeInsets.only(bottom: 20),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: unboxedOrders.length,
      itemBuilder: (context, index) {
        final order = unboxedOrders[index];
        final user = order['user'];
        final product = order['unboxedProduct']?['product'];
        final box = order['box'];
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
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: Offset(0, 2))],
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
                  Text('정가 ${(product?['price'] ?? 0).toString()}원', style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${box?['price'] ?? 0}원 박스', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
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
    );
  }
}
