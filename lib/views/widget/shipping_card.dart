import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShippingCard extends StatelessWidget {
  final Map<String, dynamic> shipping;
  final bool isSelected; // ✅ 선택 여부
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ShippingCard({
    Key? key,
    required this.shipping,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipient = shipping['recipient'] ?? '';
    final phone = shipping['phone'] ?? '';
    final memo = shipping['memo'] ?? '';
    final isDefault = shipping['is_default'] ?? false;
    final shippingAddress = shipping['shippingAddress'] ?? {};
    final postcode = shippingAddress['postcode'] ?? '';
    final address = shippingAddress['address'] ?? '';
    final address2 = shippingAddress['address2'] ?? '';

    return GestureDetector(
      onTap: onTap, // ✅ 카드 전체 클릭 처리
      child: Container(
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(right: 80.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(recipient, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                      if (isDefault)
                        Container(
                          margin: EdgeInsets.only(left: 8.w),
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text('기본', style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(phone, style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4.h),
                  Text('$postcode  |  $address $address2', style: TextStyle(color: Colors.grey)),
                  if (memo.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text('메모: $memo', style: TextStyle(color: Colors.grey)),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Text('수정', style: TextStyle(color: Colors.grey)),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: onDelete,
                    child: Text('삭제', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

