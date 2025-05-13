import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../controllers/giftcode_controller.dart';

class ProductStorageCard extends StatefulWidget {
  final String mainImageUrl;
  final String productName;
  final String acquiredAt;
  final String brand;
  final int purchasePrice;
  final int consumerPrice;
  final String dDay;
  final bool isLocked;
  final VoidCallback onRefundPressed;
  final VoidCallback onDeliveryPressed;
  final VoidCallback onGiftPressed; // ✅ 외부 콜백으로 전달
  final String orderId;
  final String productId;

  const ProductStorageCard({
    super.key,
    required this.mainImageUrl,
    required this.productName,
    required this.brand,
    required this.acquiredAt,
    required this.purchasePrice,
    required this.consumerPrice,
    required this.dDay,
    required this.isLocked,
    required this.onRefundPressed,
    required this.onDeliveryPressed,
    required this.onGiftPressed, // ✅ 콜백 받기
    required this.orderId,
    required this.productId,
  });
  @override
  State<ProductStorageCard> createState() => _ProductStorageCardState();
}

class _ProductStorageCardState extends State<ProductStorageCard> {
  bool _giftCodeExists = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkGiftCode();
  }

  Future<void> _checkGiftCode() async {
    final exists = await GiftCodeController.checkGiftCodeExists(
      type: 'product',
      orderId: widget.orderId,
      productId: widget.productId,
    );

    setState(() {
      _giftCodeExists = exists;
      _loading = false;
    });
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
          // 버튼들
          Column(
            children: [
              _buildOutlinedButton(
                context,
                text: '포인트발급',
                onPressed: !_giftCodeExists ? widget.onRefundPressed : null,
                enabled: !_giftCodeExists,
              ),

              SizedBox(height: 8.h),
              _buildOutlinedButton(
                context,
                text: _giftCodeExists ? '선물코드 확인' : '선물하기',
                onPressed: widget.onGiftPressed, // ✅ 항상 클릭 가능
                enabled: true, // ✅ 항상 활성화 상태
              ),
              SizedBox(height: 8.h),
              _buildElevatedButton(
                context,
                text: '배송신청',
                onPressed: widget.onDeliveryPressed,
                enabled: !_giftCodeExists && !_loading, // ✅ 선물코드 있으면 비활성화
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, {
    required String text,
    VoidCallback? onPressed,
    required bool enabled,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: enabled ? Theme.of(context).primaryColor :Theme.of(context).primaryColor.withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // ✅ radius 15
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: enabled ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(0.3),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }



  Widget _buildElevatedButton(BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null, // ✅ 선택 불가 처리
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.disabled)) {
              return Theme.of(context).primaryColor.withOpacity(0.3); // ✅ 흐릿한 색
            }
            return Theme.of(context).primaryColor; // ✅ 일반 색
          }),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
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
