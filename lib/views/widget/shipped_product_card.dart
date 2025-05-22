import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../controllers/giftcode_controller.dart';

class ShippedProductCard extends StatefulWidget {
  final String mainImageUrl;
  final String productName;
  final String acquiredAt;
  final String brand;
  final int purchasePrice;
  final int consumerPrice;
  final String dDay;
  final bool isLocked;
  final VoidCallback onCopyPressed;
  final VoidCallback onTrackPressed;
  final String orderId;
  final String productId;

  const ShippedProductCard({
    super.key,
    required this.mainImageUrl,
    required this.productName,
    required this.brand,
    required this.acquiredAt,
    required this.purchasePrice,
    required this.consumerPrice,
    required this.dDay,
    required this.isLocked,
    required this.onCopyPressed,
    required this.onTrackPressed,
    required this.orderId,
    required this.productId,
  });
  @override
  State<ShippedProductCard> createState() => _ShippedProductCardState();
}

class _ShippedProductCardState extends State<ShippedProductCard> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFF0F1F2)),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child: Image.network(
                  widget.mainImageUrl,
                  width: 170.w,
                  height: 224.w,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12.w),

              // 텍스트 + 가격
              Expanded(
                child: SizedBox(
                  height: 224.w, // 이미지 높이와 맞춤
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 브랜드 + 상품명
                      SizedBox(height: 15.h,),
                      Text(
                        widget.brand,
                        style: TextStyle(fontSize: 14.sp, color: Colors.black),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        widget.productName,
                        style: TextStyle(fontSize: 13.sp, color: Color(0xFF465461)),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacer(), // 👈 가격을 아래로 밀어냄
                      Text(
                        '5,000 원',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '정가: ${NumberFormat('#,###').format(widget.consumerPrice)}원',
                        style: TextStyle(
                          fontSize: 17.sp,
                          color: Color(0xFF8D969D),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20,),
          // 버튼들
          Column(
            children: [
              _buildOutlinedButton(context, text: '운송장 복사', onPressed: widget.onCopyPressed),
              SizedBox(height: 8.h),
              _buildElevatedButton(context, text: '운송장 조회', onPressed: widget.onTrackPressed),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context,
      {required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }



  Widget _buildElevatedButton(BuildContext context,
      {required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }



}
