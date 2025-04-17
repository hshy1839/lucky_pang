import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductStorageCard extends StatelessWidget {
  final String imageUrl;
  final String productName;
  final String acquiredAt;
  final int purchasePrice;
  final int consumerPrice;
  final String dDay;
  final bool isLocked;
  final VoidCallback onRefundPressed;
  final VoidCallback onGiftPressed;
  final VoidCallback onDeliveryPressed;

  const ProductStorageCard({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.acquiredAt,
    required this.purchasePrice,
    required this.consumerPrice,
    required this.dDay,
    required this.isLocked,
    required this.onRefundPressed,
    required this.onGiftPressed,
    required this.onDeliveryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.network(imageUrl, width: 60.w, height: 60.w, fit: BoxFit.cover),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    Text(acquiredAt, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  ],
                ),
              ),
              Text(dDay, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12.sp)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('구매가: $purchasePrice원', style: TextStyle(fontSize: 12.sp)),
              Text('소비자가: $consumerPrice원', style: TextStyle(fontSize: 12.sp)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: onRefundPressed, child: Text('환불')),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton(onPressed: onGiftPressed, child: Text('선물')),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton(onPressed: onDeliveryPressed, child: Text('배송')),
              ),
            ],
          )
        ],
      ),
    );
  }
}
