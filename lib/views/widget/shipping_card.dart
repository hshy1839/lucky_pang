import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/shipping_controller.dart';

class ShippingCard extends StatelessWidget {
  final Map<String, dynamic> shipping;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDeleted; // 삭제 후 부모에게 알릴 콜백

  const ShippingCard({
    Key? key,
    required this.shipping,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDeleted,
  }) : super(key: key);

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('배송지 삭제'),
        content: Text('배송지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('확인', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final shippingId = shipping['_id'];
      final result = await ShippingController.deleteShipping(shippingId);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('배송지가 삭제되었습니다.')),
        );
        if (onDeleted != null) onDeleted!(); // 부모에 알림 (리스트 새로고침 등)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제에 실패했습니다. 다시 시도하세요.')),
        );
      }
    }
  }

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
      onTap: onTap,
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

                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => _confirmAndDelete(context), // 이 부분이 핵심!
                    child: Text('삭제', style: TextStyle(color: Colors.red)),
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
